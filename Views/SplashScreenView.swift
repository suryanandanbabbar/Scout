import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var size = 0.8
    @State private var opacity = 0.5

    // Match the color scheme from ContentView
    private let backgroundColor = Color(red: 0.05, green: 0.0, blue: 0.1)
    private let accentColor = Color.purple

    var body: some View {
        if isActive {
            ContentView()
        } else {
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Image(systemName: "pianokeys.inverse")
                        .font(.system(size: 120, weight: .light))
                }
                .foregroundColor(.white)
                .shadow(color: accentColor.opacity(0.8), radius: 20, x: 0, y: 0)
                .scaleEffect(size)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.easeIn(duration: 1.5)) {
                        self.size = 1.0
                        self.opacity = 1.0
                    }
                }
            }
            .onAppear {
                // Waiting for 2.5 seconds then switching to ContentView
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation {
                        self.isActive = true
                    }
                }
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
