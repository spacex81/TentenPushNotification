import SwiftUI
import UIKit

struct ConfirmationText: View {
    var font: Font
    
    var body: some View {
        Text("pin copied!")
            .font(font)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
            )
            .foregroundColor(.black)
    }
}

struct PinText: View {
    @Binding var isPressed: Bool
    var isShimmering: Bool
    var pin: String
    var font: Font
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.5)) {
                isPressed.toggle()
            }
            UIPasteboard.general.string = pin
        } label: {
            HStack {
                Text("PIN: ")
                if isShimmering {
                    Text(pin)
                        .shimmering()
                } else {
                    Text(pin)
                }
                Image(systemName: "clipboard")
            }
            .font(font)
            .foregroundColor(.gray)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray, lineWidth: 5)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.black))
            )
        }
    }
}

struct PinButton: View {
    @State private var isPressed = false
    
    var isShimmering: Bool
    var pin: String
    let font = Font.largeTitle // Customize font here
    
    init(pin: String, isShimmering: Bool = true) {
        self.pin = pin
        self.isShimmering = isShimmering
    }
    
    var body: some View {
        ZStack {
            if isPressed {
                ConfirmationText(font: font)
                    .transition(.scale(scale: 0.1, anchor: .center).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.5)) {
                                isPressed = false
                            }
                        }
                    }
            } else {
                PinText(isPressed: $isPressed, isShimmering: isShimmering, pin: pin, font: font)
                    .transition(.scale(scale: 0.1, anchor: .center).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.5), value: isPressed)
    }
}

#Preview {
    PinButton(pin: "2frna4m")
}
