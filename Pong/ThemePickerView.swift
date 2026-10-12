import SwiftUI

struct ThemePickerView: View {
    @ObservedObject private var store = ThemeStore.shared
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 170, maximum: 220), spacing: 16)]

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            VStack(spacing: 16) {
                header
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(Theme.all) { item in
                            ThemeCard(theme: item, store: store)
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom, 8)
                }
                footer
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 20)
        }
        .overlay { if store.isBusy { ProgressView().tint(theme.text) } }
        .alert("", isPresented: Binding(get: { store.message != nil },
                                         set: { if !$0 { store.message = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(store.message ?? "")
        }
    }

    private var header: some View {
        HStack {
            Text("THEMES")
                .font(.system(size: 28, weight: .heavy, design: .monospaced))
                .foregroundStyle(theme.text)
                .kerning(4)
            Spacer()
            Button { dismiss() } label: {
                Text("DONE")
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundStyle(theme.background)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 20)
                    .background(theme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            if !store.hasEverything {
                Button {
                    Task { await store.purchase(Theme.bundleProductID) }
                } label: {
                    Text(bundleLabel)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(theme.background)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 18)
                        .background(theme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(store.price(for: Theme.bundleProductID) == nil || store.isBusy)
            }
            Spacer()
            Button {
                Task { await store.restore() }
            } label: {
                Text("RESTORE PURCHASES")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(theme.text.opacity(0.7))
            }
            .disabled(store.isBusy)
        }
    }

    private var bundleLabel: String {
        if let price = store.price(for: Theme.bundleProductID) {
            return "UNLOCK ALL THEMES  \(price)"
        }
        return "UNLOCK ALL THEMES"
    }
}

private struct ThemeCard: View {
    let theme: Theme
    @ObservedObject var store: ThemeStore
    @Environment(\.theme) private var activeTheme

    private var unlocked: Bool { store.isUnlocked(theme) }
    private var selected: Bool { store.current.id == theme.id }

    var body: some View {
        VStack(spacing: 10) {
            ThemePreview(theme: theme)
                .frame(height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(selected ? activeTheme.accent : activeTheme.text.opacity(0.2),
                                lineWidth: selected ? 3 : 1)
                )

            Text(theme.name.uppercased())
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(activeTheme.text)

            Button(action: tap) {
                Text(buttonTitle)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(selected ? activeTheme.text : activeTheme.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(selected ? Color.clear : activeTheme.accent)
                    .overlay(RoundedRectangle(cornerRadius: 8)
                        .stroke(activeTheme.accent, lineWidth: selected ? 2 : 0))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .disabled(selected || (!unlocked && priceText == nil) || store.isBusy)
        }
    }

    private var priceText: String? {
        theme.productID.flatMap { store.price(for: $0) }
    }

    private var buttonTitle: String {
        if selected { return "SELECTED" }
        if unlocked { return "SELECT" }
        return priceText ?? "UNAVAILABLE"
    }

    private func tap() {
        if unlocked {
            store.select(theme)
        } else if let productID = theme.productID {
            Task {
                await store.purchase(productID)
                if store.isUnlocked(theme) { store.select(theme) }
            }
        }
    }
}

/// A miniature court showing a theme's colours.
private struct ThemePreview: View {
    let theme: Theme

    var body: some View {
        Canvas { ctx, size in
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(theme.background))

            var net = Path()
            var y: CGFloat = 4
            while y < size.height {
                net.addRect(CGRect(x: size.width / 2 - 1, y: y, width: 2, height: 6))
                y += 11
            }
            ctx.fill(net, with: .color(theme.net))

            let paddleH = size.height * 0.4
            let left = Path(roundedRect: CGRect(x: 12, y: size.height * 0.2, width: 7, height: paddleH), cornerRadius: 2)
            let right = Path(roundedRect: CGRect(x: size.width - 19, y: size.height * 0.45, width: 7, height: paddleH), cornerRadius: 2)
            ctx.fill(left, color: theme.paddle, theme: theme)
            ctx.fill(right, color: theme.paddle, theme: theme)
            ctx.fill(Path(ellipseIn: CGRect(x: size.width * 0.62, y: size.height * 0.3, width: 9, height: 9)),
                     color: theme.ball, theme: theme)
        }
    }
}

#Preview {
    ThemePickerView()
}
