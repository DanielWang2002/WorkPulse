import SwiftUI

@main
struct WorkPulseApp: App {
    // 初始化 Core Data Controller
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            // 這裡之後會換成 MainView 或 ContentView
            // 暫時先放一個 Placeholder
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.hiddenTitleBar) // 隱藏系統 title bar
        .windowToolbarStyle(.unified) // 工具列和內容統一風格
    }
}
