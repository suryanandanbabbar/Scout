import SwiftUI

struct PianoKeyboardView: View {
    // Provide active MIDI note numbers (e.g., 60 for C4)
    var activeMIDINotes: Set<Int> = []
    
    private let whiteKeys = [0,2,4,5,7,9,11] // pitch classes
    private let blackKeys = [1,3,6,8,10]
    
    private let octaves = Array(3...5) // show 3 octaves
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            HStack(spacing: 2) {
                ForEach(octaves, id: \.self) { octave in
                    HStack(spacing: 2) {
                        ForEach(whiteKeys, id: \.self) { pc in
                            let midi = octave*12 + pc
                            RoundedRectangle(cornerRadius: 6)
                                .fill(activeMIDINotes.contains(midi) ? .gray.opacity(0.6) : .white)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(.black.opacity(0.3), lineWidth: 1))
                                .frame(width: 24)
                        }
                    }
                }
            }
            .frame(maxHeight: .infinity)
            
            // Black keys overlay
            HStack(spacing: 2) {
                ForEach(octaves, id: \.self) { octave in
                    HStack(spacing: 2) {
                        ForEach(0..<7, id: \.self) { idx in
                            let pc = whiteKeys[idx]
                            let nextPC = idx < 6 ? whiteKeys[idx+1] : (whiteKeys[idx] + 2)
                            let hasBlack = [0,1,3,4,5].contains(idx) // black keys positions over white keys sequence
                            ZStack {
                                Color.clear.frame(width: 24)
                                if hasBlack {
                                    let blackPC = (pc + 1) % 12
                                    let midi = octave*12 + blackPC
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(activeMIDINotes.contains(midi) ? .black.opacity(0.5) : .black)
                                        .frame(width: 16, height: 80)
                                        .offset(x: 12, y: 0)
                                        .shadow(radius: 1)
                                }
                            }
                        }
                    }
                }
            }
        }
        .background(Color.black.opacity(0.05))
        .animation(.easeOut(duration: 0.08), value: activeMIDINotes)
    }
}

#Preview {
    PianoKeyboardView()
}
