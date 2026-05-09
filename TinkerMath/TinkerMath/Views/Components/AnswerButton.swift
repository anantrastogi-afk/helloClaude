import SwiftUI

struct AnswerButton: View {
    let label: String
    let text: String
    let state: AnswerButtonState
    let action: () -> Void

    enum AnswerButtonState {
        case idle, selected, correct, incorrect
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(label)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .frame(width: 32, height: 32)
                    .background(labelBackground)
                    .foregroundColor(labelForeground)
                    .clipShape(Circle())

                Text(text)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                if state == .correct {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 20))
                } else if state == .incorrect {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 20))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(buttonBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(borderColor, lineWidth: state == .idle ? 1.5 : 2.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(state != .idle)
    }

    private var labelBackground: Color {
        switch state {
        case .idle: return Color(.systemGray5)
        case .selected: return .blue
        case .correct: return .green
        case .incorrect: return .red
        }
    }

    private var labelForeground: Color {
        state == .idle ? .primary : .white
    }

    private var textColor: Color {
        switch state {
        case .correct: return .green
        case .incorrect: return .red
        default: return .primary
        }
    }

    private var buttonBackground: Color {
        switch state {
        case .correct: return Color.green.opacity(0.08)
        case .incorrect: return Color.red.opacity(0.08)
        case .selected: return Color.blue.opacity(0.08)
        case .idle: return Color(.systemBackground)
        }
    }

    private var borderColor: Color {
        switch state {
        case .correct: return .green
        case .incorrect: return .red
        case .selected: return .blue
        case .idle: return Color(.systemGray4)
        }
    }
}
