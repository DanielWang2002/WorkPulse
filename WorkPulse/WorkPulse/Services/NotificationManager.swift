import UserNotifications
#if os(macOS)
import AppKit
#endif

/// 通知管理器
/// 負責請求權限與發送本地通知
class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    #if os(macOS)
    private let synthesizer = NSSpeechSynthesizer()
    #endif
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self // Keep delegate assignment
        requestAuthorization()
    }
    
    /// 請求通知權限
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ 通知權限已取得")
            } else if let error = error {
                print("⚠️ 請求通知權限失敗: \(error.localizedDescription)")
            }
        }
    }
    
    /// 排程通知
    /// - Parameters:
    ///   - title: 通知標題
    ///   - body: 通知內容
    ///   - timeInterval: 多少秒後觸發
    func scheduleNotification(title: String, body: String, timeInterval: TimeInterval) {
        // 確保時間大於 0
        guard timeInterval > 0 else { return }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        
        // 建立觸發器
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        
        // 建立請求
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        // 加入排程
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("⚠️ 無法排程通知: \(error.localizedDescription)")
            }
        }
        
        // 設定語音排程
        DispatchQueue.main.asyncAfter(deadline: .now() + timeInterval) { [weak self] in
            self?.speak(text: body)
        }
    }
    
    /// 取消所有未發送的通知 (例如使用者提早結束工作)
    func cancelAllPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        #if os(macOS)
        synthesizer.stopSpeaking()
        #endif
    }
    
    /// 播放系統提示音 (Beep)
    func playSystemSound() {
        #if os(macOS)
        NSSound.beep()
        #endif
    }
    
    func speak(text: String) {
        #if os(macOS)
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking()
        }
        synthesizer.startSpeaking(text)
        #endif
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    // 當 App 在前台時也要顯示通知
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
