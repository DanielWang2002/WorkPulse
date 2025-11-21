import SwiftUI

struct MainView: View {
    @StateObject private var viewModel = TimerViewModel()
    @StateObject private var audioManager = AudioManager.shared
    
    // 動畫狀態
    @State private var breathingPhase: Bool = false
    @State private var backgroundRotation: Double = 0
    
    // 設定頁面狀態
    @State private var showSettings = false
    @State private var showResetAlert = false
    
    var body: some View {
        ZStack {
            // MARK: - Dynamic Background
            AnimatedBackground(state: viewModel.state)
                .ignoresSafeArea()
            
            // MARK: - Content Layer
            VStack(spacing: 0) {
                // Header
                headerView
                    .padding(.top, 20)
                
                Spacer()
                
                // Timer Ring & Time
                ZStack {
                    // 呼吸光暈效果
                    if viewModel.state == .working {
                        Circle()
                            .fill(themeColor.opacity(0.2))
                            .frame(width: 320, height: 320)
                            .scaleEffect(breathingPhase ? 1.1 : 1.0)
                            .opacity(breathingPhase ? 0.6 : 0.3)
                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: breathingPhase)
                    }
                    
                    timerRingView
                    timerTextView
                }
                .frame(height: 350)
                .padding(.vertical, 20)
                
                Spacer()
                
                // Controls
                VStack(spacing: 24) {
                    statusLabel
                    controlButtonsView
                }
                .padding(.bottom, 40)
                
                // Footer
                footerView
                    .background(.ultraThinMaterial) // 增加背景材質以提升對比度
                    .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.white.opacity(0.1)),
                        alignment: .top
                    )
            }

        }
        // 移除固定 frame，改由 WindowGroup 控制，並允許彈性伸縮
        .ignoresSafeArea(.all, edges: .bottom) // 確保底部延伸到邊緣，解決白條問題
        .onAppear {
            breathingPhase = true
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                backgroundRotation = 360
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(showResetAlert: $showResetAlert)
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        VStack(spacing: 12) {
            // 頂部工具列 (包含設定按鈕)
            HStack {
                Spacer()
                Button(action: { showSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
                .padding(.trailing, 20)
            }
            
            Text(currentDateString)
                .font(.system(.title3, design: .rounded))
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.9))
                .tracking(2)
            
            TextField("輸入工作目標...", text: $viewModel.taskName)
                .textFieldStyle(.plain)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.3)) // 加深背景以凸顯白色文字
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
                .overlay(
                    Capsule()
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
                .frame(maxWidth: 450)
                .disabled(viewModel.state != .idle)
        }
    }
    
    @State private var isRotating = false // 控制旋轉動畫狀態

    // ... (existing code)

    private var timerRingView: some View {
        ZStack {
            // 背景軌道
            Circle()
                .stroke(.white.opacity(0.1), lineWidth: 24)
                .frame(width: 280, height: 280)
            
            // 進度條
            if viewModel.isTargetModeEnabled && viewModel.state != .idle {
                let progress = calculateProgress()
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [themeColor.opacity(0.5), themeColor]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 24, lineCap: .round)
                    )
                    .frame(width: 280, height: 280)
                    .rotationEffect(.degrees(-90)) // 固定從 12 點鐘方向開始
                    .shadow(color: themeColor.opacity(0.5), radius: 10, x: 0, y: 0)
                    .animation(.linear(duration: 1), value: progress)
            } else {
                // 裝飾性旋轉圈 (非目標模式) - 改為全圓光暈旋轉，避免像進度條
                Circle()
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [themeColor.opacity(0), themeColor, themeColor.opacity(0)]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 24, lineCap: .round)
                    )
                    .frame(width: 280, height: 280)
                    // Gradient Peak 在 180度 (9點鐘)，+90度 -> 12點鐘
                    .rotationEffect(.degrees((isRotating ? 360 : 0) + 90))
                    .animation(isRotating ? Animation.linear(duration: 3).repeatForever(autoreverses: false) : .default, value: isRotating)
                    .onAppear {
                        // 確保視圖出現時若在工作中則開始旋轉
                        if viewModel.state == .working {
                            isRotating = true
                        }
                    }
                    .onChange(of: viewModel.state) { newState in
                        if newState == .working {
                            isRotating = true
                        } else {
                            isRotating = false
                        }
                    }
            }
        }
    }
    
    private var timerTextView: some View {
        VStack(spacing: 8) {
            Text(timeString(from: currentDisplayTime))
                .font(.system(size: 80, weight: .thin, design: .rounded))
                .monospacedDigit()
                .foregroundColor(.white)
                .contentTransition(.numericText())
                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
            
            if viewModel.isTargetModeEnabled && viewModel.state == .working {
                Text("剩餘: \(timeString(from: viewModel.remainingTargetTime))")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.9)) // 提高對比度
                    .monospacedDigit()
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            }
        }
    }
    
    private var statusLabel: some View {
        Text(statusText)
            .font(.headline)
            .fontWeight(.bold)
            .foregroundColor(themeColor)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(.white.opacity(0.9))
                    .shadow(color: themeColor.opacity(0.3), radius: 10, x: 0, y: 0)
            )
    }
    
    private var controlButtonsView: some View {
        VStack(spacing: 30) {
            HStack(spacing: 40) {
                if viewModel.state == .idle {
                    glassButton(title: "開始專注", icon: "play.fill", color: .white, textColor: .blue, action: viewModel.startSession)
                } else if viewModel.state == .working {
                    glassButton(title: "暫停", icon: "pause.fill", color: .white.opacity(0.2), textColor: .white, action: viewModel.pauseSession)
                    glassButton(title: "結束", icon: "stop.fill", color: .red.opacity(0.8), textColor: .white, action: viewModel.stopSession)
                } else if viewModel.state == .paused {
                    glassButton(title: "繼續", icon: "play.fill", color: .green.opacity(0.8), textColor: .white, action: viewModel.resumeSession)
                    glassButton(title: "結束", icon: "stop.fill", color: .red.opacity(0.8), textColor: .white, action: viewModel.stopSession)
                } else if viewModel.state == .onBreak {
                    glassButton(title: "結束休息", icon: "figure.walk.departure", color: .indigo, textColor: .white, action: viewModel.endBreak)
                }
            }
            
            if viewModel.state == .working {
                HStack(spacing: 32) { // 增加間距
                    breakCircleButton(type: "toilet", icon: "toilet.fill", title: "上廁所")
                    breakCircleButton(type: "meal", icon: "fork.knife", title: "買飯")
                    breakCircleButton(type: "rest", icon: "cup.and.saucer.fill", title: "休息")
                }
            }
        }
    }
    
    private func glassButton(title: String, icon: String, color: Color, textColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.title3.bold())
            .foregroundColor(textColor)
            .frame(width: 160, height: 60)
            .background(
                Capsule()
                    .fill(color)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            )
            .overlay(
                Capsule()
                    .stroke(.white.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(1.0)
    }
    
    private func breakCircleButton(type: String, icon: String, title: String) -> some View {
        Button(action: { viewModel.startBreak(type: type) }) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.4)) // 加深背景顏色
                        .frame(width: 80, height: 80) // 加大尺寸 (60 -> 80)
                        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        )
                    
                    Image(systemName: icon)
                        .font(.title) // 加大圖示 (title2 -> title)
                        .foregroundColor(.white)
                }
                Text(title)
                    .font(.body) // 加大文字 (caption -> body)
                    .fontWeight(.medium)
                    .foregroundColor(.white) // 純白文字
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
            }
        }
        .buttonStyle(.plain)
    }
    
    private var footerView: some View {
        HStack {
            // 音效控制
            HStack(spacing: 16) {
                Button(action: { audioManager.toggle() }) {
                    Image(systemName: audioManager.isPlaying ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .font(.title3)
                        .foregroundColor(audioManager.isPlaying ? .white : .white.opacity(0.5))
                }
                .buttonStyle(.plain)
                
                if audioManager.isPlaying {
                    Slider(value: $audioManager.volume, in: 0...1)
                        .frame(width: 100)
                        .tint(.white)
                }
            }
            
            Spacer()
            
            // 統計資訊
            HStack(spacing: 20) {
                Label("\(timeString(from: viewModel.todayTotalFocusDuration))", systemImage: "clock.fill")
                if viewModel.totalBreakDuration > 0 {
                    Label("\(timeString(from: viewModel.totalBreakDuration))", systemImage: "bed.double.fill")
                }
            }
            .font(.subheadline)
            .foregroundColor(.white) // 純白字體提高對比
            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1) // 增加陰影
            
            Spacer()
            
            // 目標設定
            if viewModel.state == .idle {
                HStack(spacing: 12) {
                    Toggle("目標", isOn: $viewModel.isTargetModeEnabled)
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .tint(.white.opacity(0.5))
                    
                    if viewModel.isTargetModeEnabled {
                        TextField("25", value: $viewModel.targetFocusMinutes, formatter: NumberFormatter())
                            .frame(width: 30)
                            .textFieldStyle(.plain)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(4)
                        Text("分")
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                .font(.subheadline)
            }
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 20)
        .padding(.bottom, 20) // 額外增加底部間距，避免被視窗邊緣切掉
        .background(Color.black.opacity(0.6)) // 加深背景顏色以提升對比度
    }
    
    // MARK: - Helpers
    
    private var currentDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.dateFormat = "MM月dd日 EEEE"
        return formatter.string(from: Date())
    }
    
    private func calculateProgress() -> CGFloat {
        guard viewModel.isTargetModeEnabled, viewModel.targetFocusMinutes > 0 else { return 0 }
        let totalSeconds = Double(viewModel.targetFocusMinutes * 60)
        let remaining = viewModel.remainingTargetTime
        return 1.0 - (remaining / totalSeconds)
    }
    
    private var statusText: String {
        switch viewModel.state {
        case .idle: return "準備就緒"
        case .working: return "深度專注"
        case .paused: return "暫停中"
        case .onBreak:
            switch viewModel.selectedBreakType {
            case "toilet": return "上廁所"
            case "meal": return "用餐時間"
            default: return "休息片刻"
            }
        }
    }
    
    private var themeColor: Color {
        switch viewModel.state {
        case .idle: return Color(red: 0.4, green: 0.6, blue: 1.0) // Soft Blue
        case .working: return Color(red: 0.3, green: 0.9, blue: 1.0) // Cyan/Electric Blue
        case .paused: return Color(red: 1.0, green: 0.8, blue: 0.4) // Warm Yellow
        case .onBreak: return Color(red: 0.4, green: 1.0, blue: 0.6) // Mint Green
        }
    }
    
    private var currentDisplayTime: TimeInterval {
        viewModel.state == .onBreak ? viewModel.currentBreakDuration : viewModel.currentFocusDuration
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        let seconds = Int(timeInterval) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var showResetAlert: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("設定")
                .font(.title2)
                .fontWeight(.bold)
            
            Divider()
            
            Button(action: { showResetAlert = true }) {
                Label("清除所有資料", systemImage: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .alert("確定要清除所有資料嗎？", isPresented: $showResetAlert) {
                Button("取消", role: .cancel) { }
                Button("清除", role: .destructive) {
                    PersistenceController.shared.deleteAllData()
                    dismiss()
                }
            } message: {
                Text("此動作無法復原，所有歷史紀錄將被刪除。")
            }
            
            Spacer()
            
            Button("關閉") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(width: 300, height: 200)
    }
}

// MARK: - Animated Background
struct AnimatedBackground: View {
    var state: TimerState
    @State private var animate = false
    
    var body: some View {
        ZStack {
            // Base Color
            baseColor
            
            // Moving Gradients
            GeometryReader { geo in
                Circle()
                    .fill(gradientColor1.opacity(0.4))
                    .frame(width: geo.size.width * 0.8)
                    .blur(radius: 60)
                    .offset(x: animate ? -50 : 50, y: animate ? -50 : 50)
                    .animation(.easeInOut(duration: 10).repeatForever(autoreverses: true), value: animate)
                
                Circle()
                    .fill(gradientColor2.opacity(0.4))
                    .frame(width: geo.size.width * 0.6)
                    .blur(radius: 60)
                    .offset(x: animate ? 100 : -100, y: animate ? 100 : -100)
                    .animation(.easeInOut(duration: 15).repeatForever(autoreverses: true), value: animate)
            }
        }
        .onAppear {
            animate = true
        }
    }
    
    var baseColor: Color {
        switch state {
        case .idle: return Color(red: 0.1, green: 0.1, blue: 0.2) // Dark Blue Grey
        case .working: return Color(red: 0.05, green: 0.05, blue: 0.15) // Deep Space Blue
        case .paused: return Color(red: 0.2, green: 0.15, blue: 0.1) // Dark Warm Brown
        case .onBreak: return Color(red: 0.1, green: 0.2, blue: 0.15) // Dark Forest Green
        }
    }
    
    var gradientColor1: Color {
        switch state {
        case .idle: return Color.blue
        case .working: return Color.indigo
        case .paused: return Color.orange
        case .onBreak: return Color.green
        }
    }
    
    var gradientColor2: Color {
        switch state {
        case .idle: return Color.purple
        case .working: return Color.cyan
        case .paused: return Color.pink
        case .onBreak: return Color.teal
        }
    }
}
