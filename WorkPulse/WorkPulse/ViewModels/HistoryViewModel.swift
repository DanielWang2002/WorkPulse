import SwiftUI
import CoreData
import Combine

/// 歷史紀錄 ViewModel
/// 負責查詢與整理歷史資料
class HistoryViewModel: ObservableObject {
    @Published var sessions: [WorkSession] = []
    @Published var groupedSessions: [String: [WorkSession]] = [:]
    @Published var sortedKeys: [String] = []
    
    private let viewContext = PersistenceController.shared.container.viewContext
    
    init() {
        fetchHistory()
        
        // 監聽資料重置通知
        NotificationCenter.default.addObserver(self, selector: #selector(fetchHistory), name: NSNotification.Name("DataDidReset"), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func fetchHistory() {
        let request: NSFetchRequest<WorkSession> = WorkSession.fetchRequest() as! NSFetchRequest<WorkSession>
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WorkSession.startTime, ascending: false)]
        
        do {
            sessions = try viewContext.fetch(request)
            groupSessionsByDate()
        } catch {
            print("無法讀取歷史紀錄: \(error)")
        }
    }
    
    private func groupSessionsByDate() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        formatter.locale = Locale(identifier: "zh_TW")
        
        let grouped = Dictionary(grouping: sessions) { session in
            if let date = session.startTime {
                return formatter.string(from: date)
            }
            return "未知日期"
        }
        
        self.groupedSessions = grouped
        self.sortedKeys = grouped.keys.sorted(by: >)
    }
    
    func deleteSession(at offsets: IndexSet, in dateKey: String) {
        guard let sessionsInDate = groupedSessions[dateKey] else { return }
        
        offsets.map { sessionsInDate[$0] }.forEach { session in
            viewContext.delete(session)
        }
        
        do {
            try viewContext.save()
            fetchHistory() // 重新整理
        } catch {
            print("刪除失敗: \(error)")
        }
    }
}
