import SwiftUI

struct ODTextStyleModifier: ViewModifier {
    let text: ODTextToken
    let color: ODColorToken

    func body(content: Content) -> some View {
        content
            .font(text.font)
            .foregroundStyle(color.color)
    }
}

struct ODForegroundStyleModifier: ViewModifier {
    let color: ODColorToken

    func body(content: Content) -> some View {
        content.foregroundStyle(color.color)
    }
}

struct ODSurfaceCardModifier: ViewModifier {
    let selected: Bool
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(ODSpacing.md)
            .background(
                selected ? ODColorToken.insetSurfaceSelected.color : ODColorToken.insetSurface.color,
                in: RoundedRectangle(cornerRadius: radius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(ODColorToken.glassBorder.color.opacity(0.45), lineWidth: 0.7)
            )
    }
}

struct ODInputFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<_Label>) -> some View {
        configuration
            .padding(.horizontal, ODSpacing.md)
            .padding(.vertical, ODSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: ODRadius.md, style: .continuous)
                    .fill(ODColorToken.insetSurface.color)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ODRadius.md, style: .continuous)
                    .stroke(ODColorToken.glassBorder.color.opacity(0.45), lineWidth: 0.7)
            )
    }
}

struct ODInlineProgressView: View {
    let label: String
    let progress: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: ODSpacing.xs) {
            if let progress {
                ProgressView(value: progress) {
                    Text(label)
                        .odTextStyle(.caption, color: .textSecondary)
                } currentValueLabel: {
                    Text("\(Int(progress * 100))%")
                        .odTextStyle(.caption, color: .textSecondary)
                }
            } else {
                ProgressView(label)
                    .odTextStyle(.caption, color: .textSecondary)
            }
        }
    }
}

struct ODIconModifier: ViewModifier {
    let icon: ODIconToken

    func body(content: Content) -> some View {
        content.font(icon.font)
    }
}

extension View {
    func odTextStyle(_ text: ODTextToken, color: ODColorToken = .textPrimary) -> some View {
        modifier(ODTextStyleModifier(text: text, color: color))
    }

    func odForeground(_ color: ODColorToken) -> some View {
        modifier(ODForegroundStyleModifier(color: color))
    }

    func odIcon(_ icon: ODIconToken) -> some View {
        modifier(ODIconModifier(icon: icon))
    }

    func odSurfaceCard(selected: Bool = false, radius: CGFloat = ODRadius.md) -> some View {
        modifier(ODSurfaceCardModifier(selected: selected, radius: radius))
    }
}
