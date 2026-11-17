-- 心伴 ID 資料庫：每隻心伴一組獨立 ID，記錄種類、領取（註冊）時間、出生（孵化）時間
-- ID 格式 PPP-SS-NNNNNN（例：OWL-01-000001）；990000 以上保留給測試

-- 種類：每年的角色一個款式碼，並保管下一個要發的流水號
create table public.species (
  code         text primary key check (code ~ '^[A-Z]{3}-[0-9]{2}$'),
  prefix       text not null check (prefix ~ '^[A-Z]{3}$'),
  style        smallint not null check (style between 1 and 99),
  name_zh      text not null,
  year         smallint not null,
  next_serial  integer not null default 1 check (next_serial between 1 and 990000),
  created_at   timestamptz not null default now(),
  unique (prefix, style)
);
comment on table public.species is '心伴種類（每年一種角色）。next_serial 為下一個正式流水號，990000 以上保留給測試。';

insert into public.species (code, prefix, style, name_zh, year) values ('OWL-01', 'OWL', 1, '貓頭鷹', 2026);

-- 心伴
create table public.companions (
  id              text primary key check (id ~ '^[A-Z]{3}-[0-9]{2}-[0-9]{6}$'),
  species_code    text not null references public.species(code),
  serial          integer not null check (serial between 1 and 999999),
  is_test         boolean not null default false,
  status          text not null default 'active' check (status in ('unclaimed', 'active', 'retired')),
  owner_id        uuid references auth.users(id) on delete set null,
  name            text check (char_length(name) between 1 and 12),
  egg_pattern     smallint not null default floor(random() * 8)::smallint check (egg_pattern between 0 and 7),
  registered_at   timestamptz,
  born_at         timestamptz,
  fate_stem       smallint check (fate_stem between 0 and 9),
  nfc_written_at  timestamptz,
  created_at      timestamptz not null default now(),
  unique (species_code, serial),
  check (born_at is null or (registered_at is not null and born_at >= registered_at)),
  check (status <> 'active' or (owner_id is not null and registered_at is not null))
);
comment on table public.companions is '每隻心伴一列。registered_at＝領取（註冊）時間；born_at＝摸摸頭孵化的出生時間；fate_stem＝命定天干（內部資料，0 庚 1 辛 2 壬 3 癸 4 甲 5 乙 6 丙 7 丁 8 戊 9 己）。';
create index companions_owner_id_idx on public.companions(owner_id);
create index companions_species_code_idx on public.companions(species_code);

-- 命定天干：註冊時間（台北時間）YYYYMMDDHHmm 各位數相加；10 的倍數 → 0，否則一直相加到剩一位數
create function public.fate_stem_of(t timestamptz) returns smallint
language sql immutable set search_path = '' as $$
  with d as (select to_char(t at time zone 'Asia/Taipei', 'YYYYMMDDHH24MI') as s),
       total as (select sum(substr(d.s, i, 1)::int) as v from d, generate_series(1, 12) as i)
  select (case when v % 10 = 0 then 0 else 1 + (v - 1) % 9 end)::smallint from total
$$;

-- 領取一隻新的心伴：在同一個交易裡鎖住種類、取號、加一
create function public.claim_companion(p_species text default 'OWL-01') returns public.companions
language plpgsql security definer set search_path = '' as $$
declare
  sp public.species;
  n  integer;
  r  public.companions;
begin
  if auth.uid() is null then raise exception '需要登入才能領取心伴' using errcode = '42501'; end if;
  select * into sp from public.species where code = p_species for update;
  if not found then raise exception '沒有這個種類：%', p_species; end if;
  n := sp.next_serial;
  if n >= 990000 then raise exception '% 的正式流水號已發完', p_species; end if;
  update public.species set next_serial = n + 1 where code = p_species;
  insert into public.companions (id, species_code, serial, status, owner_id, registered_at, fate_stem)
  values (sp.prefix || '-' || lpad(sp.style::text, 2, '0') || '-' || lpad(n::text, 6, '0'),
          p_species, n, 'active', auth.uid(), now(), public.fate_stem_of(now()))
  returning * into r;
  return r;
end $$;

-- 綁定一個還沒有主人的測試流水號
create function public.bind_test_companion(p_id text) returns public.companions
language plpgsql security definer set search_path = '' as $$
declare r public.companions;
begin
  if auth.uid() is null then raise exception '需要登入' using errcode = '42501'; end if;
  update public.companions
     set owner_id = auth.uid(), status = 'active', registered_at = now(), fate_stem = public.fate_stem_of(now())
   where id = upper(p_id) and is_test and owner_id is null
  returning * into r;
  if not found then raise exception '這個測試流水號不存在或已經被綁定'; end if;
  return r;
end $$;

-- 孵化：第一次摸摸頭，記下出生時間（只有主人、只記一次）
create function public.hatch_companion(p_id text) returns public.companions
language plpgsql security definer set search_path = '' as $$
declare r public.companions;
begin
  update public.companions set born_at = now()
   where id = p_id and owner_id = auth.uid() and born_at is null
  returning * into r;
  if not found then
    select * into r from public.companions where id = p_id and owner_id = auth.uid();
    if not found then raise exception '這不是你的心伴'; end if;
  end if;
  return r;
end $$;

-- 改名字（最多 12 個字）
create function public.rename_companion(p_id text, p_name text) returns public.companions
language plpgsql security definer set search_path = '' as $$
declare r public.companions;
begin
  update public.companions set name = nullif(btrim(p_name), '')
   where id = p_id and owner_id = auth.uid()
  returning * into r;
  if not found then raise exception '這不是你的心伴'; end if;
  return r;
end $$;

-- NFC 感應時比對：只回答「我的／別人的／不存在」，不透露主人是誰
create function public.check_companion(p_id text) returns text
language sql stable security definer set search_path = '' as $$
  select coalesce((select case when owner_id = auth.uid() then 'mine' when owner_id is null then 'unclaimed' else 'other' end
                     from public.companions where id = upper(p_id)), 'unknown')
$$;

-- 權限：表只能透過上面的函式寫入；主人只讀得到自己的心伴
alter table public.species enable row level security;
alter table public.companions enable row level security;
create policy "種類目錄大家都看得到" on public.species for select to anon, authenticated using (true);
create policy "主人看得到自己的心伴" on public.companions for select to authenticated using (owner_id = (select auth.uid()));

revoke insert, update, delete on public.species, public.companions from anon, authenticated;
revoke all on function public.claim_companion(text), public.bind_test_companion(text), public.hatch_companion(text),
                       public.rename_companion(text, text), public.check_companion(text) from public, anon;
grant execute on function public.claim_companion(text), public.bind_test_companion(text), public.hatch_companion(text),
                          public.rename_companion(text, text), public.check_companion(text) to authenticated;

-- 測試流水號 OWL-01-990001 ～ 990020（還沒有主人）
insert into public.companions (id, species_code, serial, is_test, status)
select 'OWL-01-' || lpad(n::text, 6, '0'), 'OWL-01', n, true, 'unclaimed' from generate_series(990001, 990020) as n;

-- 管理用檢視（放在不對外的 admin schema，只在 Supabase 後台查詢）
create schema if not exists admin;
revoke all on schema admin from public, anon, authenticated;
create view admin.companion_registry with (security_invoker = true) as
select c.id, s.name_zh as species, s.year as species_year, c.serial, c.is_test, c.status,
       c.name, u.email as owner_email, c.owner_id, c.egg_pattern,
       c.registered_at, c.born_at, c.fate_stem,
       (array['庚','辛','壬','癸','甲','乙','丙','丁','戊','己'])[c.fate_stem + 1] as fate_stem_zh,
       c.nfc_written_at, c.created_at
  from public.companions c
  join public.species s on s.code = c.species_code
  left join auth.users u on u.id = c.owner_id;
