import AVFoundation
import SwiftUI // Required for ObservableObject and @Published
import Combine

/// 音訊管理器
/// 負責播放與控制粉紅噪音
class AudioManager: ObservableObject {
    static let shared = AudioManager()
    
    private var audioPlayer: AVAudioPlayer?
    
    @Published var isPlaying: Bool = false
    @Published var volume: Float = 0.5 {
        didSet {
            audioPlayer?.volume = volume
        }
    }
    
    private init() {
        setupAudioSession()
        setupPlayer()
    }
    
    /// 設定音訊 Session
    private func setupAudioSession() {
        // macOS 上通常不需要像 iOS 那樣設定 AVAudioSession，但為了保險起見或是未來擴充
        // 這裡保留一個設定點
    }
    
    /// 初始化播放器
    /// 注意：請確保專案 Bundle 中有名為 "pink_noise.wav" 的檔案
    private func setupPlayer() {
        guard let url = Bundle.main.url(forResource: "pink_noise", withExtension: "wav") else {
            print("⚠️ 錯誤：找不到 pink_noise.wav 音檔。請將音檔放入專案資源中。")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1 // 無限循環
            audioPlayer?.volume = volume
            audioPlayer?.prepareToPlay()
        } catch {
            print("⚠️ 錯誤：無法初始化 AVAudioPlayer: \(error.localizedDescription)")
        }
    }
    
    /// 開始播放
    func play() {
        guard let player = audioPlayer else {
            setupPlayer() // 嘗試重新初始化
            return
        }
        
        if !player.isPlaying {
            player.play()
            isPlaying = true
        }
    }
    
    /// 暫停播放
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
    }
    
    /// 切換播放狀態
    func toggle() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
}
