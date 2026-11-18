-- 撿到別人的心伴：感應到不是自己的心伴時，可以通知主人。主人只看得到「哪一隻、何時、在哪裡」，看不到是誰撿到的
create table public.found_reports (
  id            bigint generated always as identity primary key,
  companion_id  text not null references public.companions(id) on delete cascade,
  owner_id      uuid not null references auth.users(id) on delete cascade,
  reporter_id   uuid references auth.users(id) on delete set null,
  lat           double precision not null check (lat between -90 and 90),
  lon           double precision not null check (lon between -180 and 180),
  landmark      text check (char_length(landmark) <= 40),
  reported_at   timestamptz not null default now()
);
comment on table public.found_reports is '撿到心伴的通知。reporter_id 只留在後台，主人讀不到。';
create index found_reports_owner_idx on public.found_reports(owner_id, reported_at desc);
create index found_reports_companion_idx on public.found_reports(companion_id);
create index found_reports_reporter_idx on public.found_reports(reporter_id);

alter table public.found_reports enable row level security;
revoke all on public.found_reports from anon, authenticated;
-- 主人只能讀自己心伴的通知，而且讀不到 reporter_id
grant select (id, companion_id, owner_id, lat, lon, landmark, reported_at) on public.found_reports to authenticated;
create policy "主人看得到自己心伴的撿到通知" on public.found_reports for select to authenticated using (owner_id = (select auth.uid()));

-- 通知主人：同一個人對同一隻心伴 6 小時內只算一次；沒有主人或是自己的心伴就不寄
create function public.report_found(p_id text, p_lat double precision, p_lon double precision, p_landmark text default null) returns boolean
language plpgsql security definer set search_path = '' as $$
declare o uuid;
begin
  if auth.uid() is null then raise exception '需要登入' using errcode = '42501'; end if;
  select owner_id into o from public.companions where id = upper(p_id);
  if o is null or o = auth.uid() then return false; end if;
  if exists (select 1 from public.found_reports
              where companion_id = upper(p_id) and reporter_id = auth.uid() and reported_at > now() - interval '6 hours') then
    return true;
  end if;
  insert into public.found_reports (companion_id, owner_id, reporter_id, lat, lon, landmark)
  values (upper(p_id), o, auth.uid(), round(p_lat::numeric, 4)::double precision, round(p_lon::numeric, 4)::double precision, left(p_landmark, 40));
  return true;
end $$;
revoke all on function public.report_found(text, double precision, double precision, text) from public, anon;
grant execute on function public.report_found(text, double precision, double precision, text) to authenticated;
