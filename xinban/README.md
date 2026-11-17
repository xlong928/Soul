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

## 外部資源

- three.js r128（cdnjs）與 OrbitControls（jsDelivr）
- Google Fonts：Huninn、Fredoka
