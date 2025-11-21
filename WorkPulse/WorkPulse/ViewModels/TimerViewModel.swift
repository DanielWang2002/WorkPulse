import SwiftUI
import CoreData
import Combine

/// 計時器狀態
enum TimerState {
    case idle       // 尚未開始
    case working    // 工作中
    case paused     // 暫停中 (工作暫停)
    case onBreak    // 休息中
}

/// 計時器 ViewModel
/// 負責核心計時邏輯、狀態管理與資料儲存
class TimerViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var state: TimerState = .idle
    @Published var taskName: String = ""
    
    // 計時相關
    @Published var currentFocusDuration: TimeInterval = 0 // 當前專注秒數
    @Published var currentBreakDuration: TimeInterval = 0 // 當前休息秒數 (單次)
    @Published var totalBreakDuration: TimeInterval = 0   // 累計休息秒數 (本次 Session)
    @Published var todayTotalFocusDuration: TimeInterval = 0 // 今日累積專注時間
    
    // 倒數計時設定
    @Published var targetFocusMinutes: Int = 25
    @Published var isTargetModeEnabled: Bool = false
    @Published var remainingTargetTime: TimeInterval = 0
    
    // 休息類型
    @Published var selectedBreakType: String = "rest"
    
    // MARK: - Dependencies
    
    private let viewContext = PersistenceController.shared.container.viewContext
    private let audioManager = AudioManager.shared
    private let notificationManager = NotificationManager.shared
    
    // MARK: - Private Properties
    
    private var timer: AnyCancellable?
    private var currentSession: WorkSession?
    private var currentBreakEvent: BreakEvent?
    private var sessionStartTime: Date?
    
    // MARK: - Initialization
    
    init() {
        fetchTodayTotalFocus()
        
        // 監聽資料重置通知
        NotificationCenter.default.addObserver(self, selector: #selector(handleDataReset), name: NSNotification.Name("DataDidReset"), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleDataReset() {
        // 重置所有狀態
        state = .idle
        taskName = ""
        currentFocusDuration = 0
        currentBreakDuration = 0
        totalBreakDuration = 0
        todayTotalFocusDuration = 0
        currentSession = nil
        currentBreakEvent = nil
        sessionStartTime = nil
        stopTimer()
        audioManager.pause()
        notificationManager.cancelAllPendingNotifications()
        
        // 重新抓取今日統計 (應該為 0)
        fetchTodayTotalFocus()
    }
    
    // MARK: - User Actions
    
    /// 開始工作
    func startSession() {
        guard state == .idle else { return }
        
        // 建立新的 Session
        let newSession = WorkSession(context: viewContext)
        newSession.id = UUID()
        newSession.taskName = taskName.isEmpty ? "未命名工作" : taskName
        newSession.startTime = Date()
        newSession.createdAt = Date()
        newSession.focusDuration = 0
        newSession.breakDuration = 0
        
        currentSession = newSession
        sessionStartTime = Date()
        
        // 如果有設定目標時間
        if isTargetModeEnabled {
            remainingTargetTime = TimeInterval(targetFocusMinutes * 60)
            // 排程通知
            notificationManager.scheduleNotification(
                title: "專注時間結束",
                body: "您設定的 \(targetFocusMinutes) 分鐘專注時間已到，休息一下吧！",
                timeInterval: remainingTargetTime
            )
        }
        
        // 自動播放粉紅噪音 (可選，這裡預設開啟)
        audioManager.play()
        
        state = .working
        startTimer()
    }
    
    /// 暫停工作
    func pauseSession() {
        guard state == .working else { return }
        state = .paused
        stopTimer()
        audioManager.pause()
        notificationManager.cancelAllPendingNotifications()
    }
    
    /// 恢復工作
    func resumeSession() {
        guard state == .paused else { return }
        state = .working
        startTimer()
        audioManager.play()
        
        // 如果是目標模式，重新排程剩餘時間的通知
        if isTargetModeEnabled && remainingTargetTime > 0 {
            notificationManager.scheduleNotification(
                title: "專注時間結束",
                body: "您設定的專注時間已到，休息一下吧！",
                timeInterval: remainingTargetTime
            )
        }
    }
    
    /// 結束工作
    func stopSession() {
        guard state != .idle, let session = currentSession else { return }
        
        // 如果正在休息，先結束休息
        if state == .onBreak {
            endBreak()
        }
        
        stopTimer()
        audioManager.pause()
        notificationManager.cancelAllPendingNotifications()
        
        // 更新 Session 資料
        session.endTime = Date()
        session.focusDuration = currentFocusDuration
        session.breakDuration = totalBreakDuration
        
        saveContext()
        
        // 重置狀態
        state = .idle
        currentFocusDuration = 0
        currentBreakDuration = 0
        totalBreakDuration = 0
        currentSession = nil
        sessionStartTime = nil
        
        // 更新今日統計
        fetchTodayTotalFocus()
    }
    
    /// 開始休息
    func startBreak(type: String) {
        guard state == .working else { return }
        
        // 先暫停工作計時
        stopTimer()
        audioManager.pause()
        notificationManager.cancelAllPendingNotifications()
        
        state = .onBreak
        selectedBreakType = type
        currentBreakDuration = 0
        
        // 建立休息事件
        if let session = currentSession {
            let breakEvent = BreakEvent(context: viewContext)
            breakEvent.id = UUID()
            breakEvent.type = type
            breakEvent.startTime = Date()
            breakEvent.workSession = session
            currentBreakEvent = breakEvent
        }
        
        // 開始休息計時
        startTimer()
    }
    
    /// 結束休息 (回到工作)
    func endBreak() {
        guard state == .onBreak else { return }
        
        stopTimer()
        
        // 更新休息事件
        if let breakEvent = currentBreakEvent {
            breakEvent.endTime = Date()
            breakEvent.duration = currentBreakDuration
            totalBreakDuration += currentBreakDuration
        }
        
        currentBreakEvent = nil
        currentBreakDuration = 0
        
        // 回到工作狀態
        state = .working
        audioManager.play()
        startTimer()
        
        // 如果是目標模式，重新排程剩餘時間的通知
        if isTargetModeEnabled && remainingTargetTime > 0 {
            notificationManager.scheduleNotification(
                title: "專注時間結束",
                body: "您設定的專注時間已到，休息一下吧！",
                timeInterval: remainingTargetTime
            )
        }
    }
    
    // MARK: - Timer Logic
    
    private func startTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }
    
    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }
    
    private func tick() {
        if state == .working {
            currentFocusDuration += 1
            
                // 檢查是否達到目標
                if isTargetModeEnabled {
                    let targetSeconds = Double(targetFocusMinutes * 60)
                    if currentFocusDuration >= targetSeconds {
                        // 修正：確保時間不會超過目標時間
                        currentFocusDuration = targetSeconds
                        
                        // 時間到
                        notificationManager.playSystemSound()
                        notificationManager.speak(text: "專注時間結束，請站起來活動一下！")
                        
                        // 自動暫停計時與音樂
                        pauseSession()
                        isTargetModeEnabled = false // 關閉目標模式
                    }
                }
        } else if state == .onBreak {
            currentBreakDuration += 1
        }
    }
    
    // MARK: - Core Data Helpers
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Core Data 儲存失敗: \(nsError), \(nsError.userInfo)")
        }
    }
    
    /// 計算今日累積專注時間
    func fetchTodayTotalFocus() {
        let request: NSFetchRequest<WorkSession> = WorkSession.fetchRequest() as! NSFetchRequest<WorkSession>
        
        // 設定今日範圍
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        request.predicate = NSPredicate(format: "startTime >= %@ AND startTime < %@", startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            let sessions = try viewContext.fetch(request)
            let total = sessions.reduce(0) { $0 + $1.focusDuration }
            todayTotalFocusDuration = total
        } catch {
            print("無法獲取今日統計: \(error)")
        }
    }
}
