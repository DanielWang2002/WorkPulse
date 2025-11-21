import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    
    var body: some View {
        ZStack {
            // Background matching MainView's idle state roughly
            Color(red: 0.1, green: 0.1, blue: 0.2)
                .ignoresSafeArea()
            
            VStack(alignment: .leading) {
                Text("歷史紀錄")
                    .font(.system(.largeTitle, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    .padding(.top, 20)
                
                List {
                    ForEach(viewModel.sortedKeys, id: \.self) { dateKey in
                        Section {
                            if let sessions = viewModel.groupedSessions[dateKey] {
                                ForEach(sessions) { session in
                                    NavigationLink(destination: SessionDetailView(session: session)) {
                                        SessionRow(session: session)
                                    }
                                    .listRowBackground(Color.white.opacity(0.05)) // Glass effect rows
                                    .listRowSeparatorTint(.white.opacity(0.1))
                                }
                                .onDelete { indexSet in
                                    viewModel.deleteSession(at: indexSet, in: dateKey)
                                }
                            }
                        } header: {
                            Text(dateKey)
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.vertical, 8)
                        }
                    }
                }
                .scrollContentBackground(.hidden) // Hide default list background
                .listStyle(.plain)
            }
        }
        .onAppear {
            viewModel.fetchHistory()
        }
    }
}

struct SessionRow: View {
    @ObservedObject var session: WorkSession
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 40, height: 40)
                    .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(session.unwrappedTaskName)
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack(spacing: 12) {
                    Label {
                        Text(timeString(from: session.focusDuration))
                            .foregroundColor(.white.opacity(0.7))
                    } icon: {
                        Image(systemName: "clock")
                            .foregroundColor(.cyan)
                    }
                    .font(.caption)
                    
                    if session.breakDuration > 0 {
                        Label {
                            Text(timeString(from: session.breakDuration))
                                .foregroundColor(.white.opacity(0.7))
                        } icon: {
                            Image(systemName: "cup.and.saucer")
                                .foregroundColor(.orange)
                        }
                        .font(.caption)
                    }
                }
            }
            
            Spacer()
            
            if let start = session.startTime {
                Text(start, style: .time)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.4))
                    .monospacedDigit()
            }
        }
        .padding(.vertical, 6)
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        return "\(minutes) 分鐘"
    }
}
