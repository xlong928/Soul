# 心伴 Sound Companion

NFC 聲音療癒娃娃的 Web App 原型：領取心伴、養育成長、用實體娃娃的 NFC 打卡收集明信片、足跡星球、朋友與貓頭鷹郵局、生活履歷與年度歷程。

## 檔案

| 檔案 | 說明 |
|---|---|
| `index.html` | App 本體（獨立網址版）。不在 claude.ai 裡打開時會進入「測試模式」，資料存在瀏覽器。 |
| `claude-artifact.html` | 同一份程式的 claude.ai Artifact 版（沒有 `<html>` 外框，由 claude.ai 包裝）。 |
| `home-bgm.mp3` | 首頁背景音樂「Cozy Home Loop」。 |
| `land50m.json`、`land10m.json` | 足跡星球用的 Natural Earth 陸地資料（50m／10m）。 |
| `.nojekyll` | 讓 GitHub Pages 原樣提供檔案。 |

## 用 GitHub Pages 開成測試網址

1. 到這個 repo 的 **Settings → Pages**。
2. **Source** 選 **Deploy from a branch**，Branch 選 `main`、資料夾 `/ (root)`，按 **Save**。
3. 約一分鐘後會出現網址 `https://xlong928.github.io/Soul/xinban/`，用手機打開就能測。

GitHub Pages 是 https，所以可以用手機定位；Android 手機的 Chrome 還能讀真的 NFC 貼紙。

## 測試須知

- **真的 NFC**：Android + Chrome 89 以上，手機設定要打開 NFC。iPhone 不支援網頁讀 NFC，請用示範按鈕。
- **NFC 貼紙**：空白 NTAG213／215。在 App「我的心伴」頁最下方「測試工具：製作 NFC 貼紙」寫入心伴 ID（NDEF 文字紀錄，格式 `OWL-SS-NNNNNN`）。
- **日期相關功能**（長大、節日明信片、年度歷程）：直接改手機日期測試。
- **資料**：測試網址版的資料只存在那支手機的瀏覽器；朋友、寫信、通知主人等多人功能請用 claude.ai 版測。

## 測試用 NFC 流水號

測試保留段：`OWL-01-990001` 到 `OWL-01-990020`（正式發號不會用到 99 開頭）。

1. 在 App「我的心伴」頁最下方「測試工具：綁定測試流水號」輸入一個流水號，按「綁定」，帳號就多一隻用這個 ID 的心伴（名字預設「測試01」等），回小屋摸摸頭讓牠孵化。
2. 用任何 NFC 寫入 App（例如 NFC Tools）在空白 NTAG213／215 貼紙寫入一筆「文字（Text）」紀錄，內容就是那個流水號；或在 Android Chrome 用 App 裡的「製作 NFC 貼紙」寫入。
3. 打卡時感應這張貼紙即可。沒有綁定這個流水號的帳號感應到，會出現「這不是你的心伴」，可用來測通知主人。

| 流水號 | 流水號 | 流水號 | 流水號 |
|---|---|---|---|
| OWL-01-990001 | OWL-01-990006 | OWL-01-990011 | OWL-01-990016 |
| OWL-01-990002 | OWL-01-990007 | OWL-01-990012 | OWL-01-990017 |
| OWL-01-990003 | OWL-01-990008 | OWL-01-990013 | OWL-01-990018 |
| OWL-01-990004 | OWL-01-990009 | OWL-01-990014 | OWL-01-990019 |
| OWL-01-990005 | OWL-01-990010 | OWL-01-990015 | OWL-01-990020 |

## 外部資源

- three.js r128（cdnjs）與 OrbitControls（jsDelivr）
- Google Fonts：Huninn、Fredoka
