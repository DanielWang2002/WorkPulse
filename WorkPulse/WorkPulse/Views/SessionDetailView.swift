import SwiftUI

struct SessionDetailView: View {
    @ObservedObject var session: WorkSession
    
    var body: some View {
        ZStack {
            Color(red: 0.1, green: 0.1, blue: 0.2)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header Card
                    VStack(spacing: 16) {
                        Text(session.unwrappedTaskName)
                            .font(.system(.title, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        HStack(spacing: 40) {
                            statItem(title: "專注時間", value: timeString(from: session.focusDuration), color: .cyan)
                            statItem(title: "休息時間", value: timeString(from: session.breakDuration), color: .orange)
                        }
                    }
                    .padding(30)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                    )
                    
                    // Time Info
                    VStack(alignment: .leading, spacing: 16) {
                        Text("時間資訊")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.leading, 4)
                        
                        VStack(spacing: 0) {
                            infoRow(icon: "play.circle.fill", title: "開始時間", value: session.unwrappedStartTime.formatted(date: .omitted, time: .standard))
                            Divider().background(.white.opacity(0.1))
                            if let endTime = session.endTime {
                                infoRow(icon: "stop.circle.fill", title: "結束時間", value: endTime.formatted(date: .omitted, time: .standard))
                            }
                        }
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                    }
                    
                    // Break Events
                    VStack(alignment: .leading, spacing: 16) {
                        Text("休息紀錄")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.leading, 4)
                        
                        if session.breakEventArray.isEmpty {
                            Text("本次工作全程專注，沒有休息！")
                                .foregroundColor(.white.opacity(0.4))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(session.breakEventArray) { event in
                                    HStack {
                                        Image(systemName: getIcon(for: event.unwrappedType))
                                            .foregroundColor(.white)
                                            .frame(width: 30, height: 30)
                                            .background(Circle().fill(getColor(for: event.unwrappedType).opacity(0.8)))
                                        
                                        Text(event.typeDisplayName)
                                            .foregroundColor(.white)
                                            .fontWeight(.medium)
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing) {
                                            if let start = event.startTime {
                                                Text(start, style: .time)
                                                    .font(.caption2)
                                                    .foregroundColor(.white.opacity(0.5))
                                            }
                                            Text(timeString(from: event.duration))
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.8))
                                                .monospacedDigit()
                                        }
                                    }
                                    .padding()
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("紀錄詳情")
    }
    
    private func statItem(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .textCase(.uppercase)
            Text(value)
                .font(.system(.title2, design: .rounded))
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
    
    private func infoRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.6))
            Text(title)
                .foregroundColor(.white.opacity(0.8))
            Spacer()
            Text(value)
                .foregroundColor(.white)
                .fontWeight(.medium)
        }
        .padding()
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d 分 %02d 秒", minutes, seconds)
    }
    
    private func getIcon(for type: String) -> String {
        switch type {
        case "toilet": return "toilet.fill"
        case "meal": return "fork.knife"
        default: return "cup.and.saucer.fill"
        }
    }
    
    private func getColor(for type: String) -> Color {
        switch type {
        case "toilet": return .blue
        case "meal": return .orange
        default: return .green
        }
    }
}
