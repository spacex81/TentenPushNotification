import SwiftUI

struct WalkieTalkieView: View {
    @State private var isTransmitting = false
    
    var body: some View {
        VStack {
            Spacer()
            Rectangle()
                .foregroundColor(isTransmitting ? Color.red : Color.blue)
                .frame(width: 200, height: 50)
                .cornerRadius(10)
                .overlay(
                    Text(isTransmitting ? "Release to Stop" : "Press and Hold to Talk")
                        .foregroundColor(.white)
                )
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !isTransmitting {
                                print("Rectangle pressed - starting transmission")
                                withAnimation {
                                    startTransmitting()
                                }
                            }
                        }
                        .onEnded { _ in
                            if isTransmitting {
                                print("Rectangle released - stopping transmission")
                                withAnimation {
                                    stopTransmitting()
                                }
                            }
                        }
                )
            Spacer()
        }
        .onAppear() {
            print("WalkieTalkieView-onAppear")
        }
        .padding()
        .background(Color.white.edgesIgnoringSafeArea(.all))
    }
    
    private func startTransmitting() {
        print("Start Transmitting")
        isTransmitting = true
        AudioStreamManager.shared.startTransmittingAudio()
    }
    
    private func stopTransmitting() {
        print("Stop Transmitting")
        isTransmitting = false
        AudioStreamManager.shared.stopTransmittingAudio()
    }
}

#Preview {
    WalkieTalkieView()
}
