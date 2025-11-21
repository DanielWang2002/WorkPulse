# WorkPulse

WorkPulse 是一款專為 macOS 設計的現代化番茄鐘與工作管理應用程式。結合了優雅的介面設計與強大的功能，幫助您保持專注並追蹤工作效率。

## ✨ 特色功能

- **專注計時器**：視覺化的圓環倒數計時，支援目標設定模式。
- **休息管理**：提供上廁所、買飯、休息等快速按鈕，並分別記錄時間。
- **歷史紀錄**：詳細記錄每日的專注與休息時段，並提供圖表統計。
- **沉浸式體驗**：
  - **動態背景**：根據當前狀態（專注、休息、暫停）變換背景色調與動畫。
  - **客製化介面**：隱藏系統標題列，採用現代化的深色玻璃擬態風格 (Glassmorphism)。
  - **語音通知**：時間到時透過語音提醒您起身活動。
  - **粉紅噪音**：內建專注背景白噪音，幫助您隔絕干擾。
- **貼心設計**：
  - 底部資訊列顯示今日總專注時間。
  - 側邊欄可收折，適應不同視窗大小。
  - 支援深色模式與高對比文字顯示。

## 🛠️ 技術堆疊

- **語言**：Swift 5
- **框架**：SwiftUI, Combine
- **資料儲存**：Core Data
- **平台**：macOS 13.0+
- **其他技術**：
  - `NSSpeechSynthesizer` (語音合成)
  - `AVFoundation` (音效播放)
  - `UserNotifications` (本地通知)

## 🚀 安裝與執行

1. Clone 此專案：
   ```bash
   git clone https://github.com/DanielWang2002/WorkPulse.git
   ```
2. 使用 Xcode 開啟 `WorkPulse.xcodeproj`。
3. 選擇目標裝置 (My Mac) 並執行 (Cmd + R)。

## 🤖 Vibe Coding

本專案由 **Vibe Coding** 輔助開發撰寫。
透過自然語言對話與 AI 協作，快速迭代出符合需求且具備高品質 UI/UX 的應用程式。

---
Developed with ❤️ by Daniel Wang & Vibe Coding AI.
