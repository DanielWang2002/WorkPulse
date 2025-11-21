import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .timer
    
    enum Tab {
        case timer
        case history
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 🔸 自訂上方 bar（取代原本白色 title bar）
            HStack {
                // 預留空間給紅綠燈 (約 80pt)
                Spacer().frame(width: 80)
                
                // Sidebar Toggle Button
                Button(action: {
                    NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
                }) {
                    Image(systemName: "sidebar.left")
                        .font(.title3)
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 8)
                
                Text("WorkPulse")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                // 右邊可以放你自己的按鈕
                Button(action: {
                    // 未來功能：開啟設定或其他
                }) {
                    Image(systemName: "command")
                        .foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.15, green: 0.15, blue: 0.25), Color(red: 0.1, green: 0.1, blue: 0.2)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            
            // 🔸 下面才是你的主內容
            NavigationSplitView {
                List(selection: $selectedTab) {
                    HStack {
                        Image(systemName: "timer")
                            .foregroundColor(.white)
                        Text("專注計時")
                            .foregroundColor(.white)
                    }
                    .tag(Tab.timer)
                    
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(.white)
                        Text("歷史紀錄")
                            .foregroundColor(.white)
                    }
                    .tag(Tab.history)
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)
                .background(Color(red: 0.15, green: 0.15, blue: 0.25)) // 深色側邊欄背景
                .foregroundColor(.white) // 強制文字為白色
            } detail: {
                NavigationStack {
                    switch selectedTab {
                    case .timer:
                        MainView()
                    case .history:
                        HistoryView()
                    }
                }
            }
        }
        .background(Color(red: 0.1, green: 0.1, blue: 0.2)) // 確保整體背景一致
        .ignoresSafeArea() // 讓背景延伸到所有邊緣 (包含底部)
    }
}
