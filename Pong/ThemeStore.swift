import SwiftUI
import StoreKit

/// Owns the selected theme and which paid themes the user has unlocked (StoreKit 2).
@MainActor
final class ThemeStore: ObservableObject {
    static let shared = ThemeStore()

    @Published private(set) var selectedID: String
    @Published private(set) var purchasedIDs: Set<String>
    @Published private(set) var products: [String: Product] = [:]
    @Published private(set) var isBusy = false
    @Published var message: String?

    private let defaults = UserDefaults.standard
    private let selectedKey = "selectedThemeID"
    // Only a launch-time cache so a paid theme doesn't flash back to Classic
    // before StoreKit answers; `refreshEntitlements()` is authoritative.
    private let cacheKey = "purchasedProductIDs"
    private var updatesTask: Task<Void, Never>?

    private init() {
        selectedID = defaults.string(forKey: selectedKey) ?? Theme.classic.id
        purchasedIDs = Set(defaults.stringArray(forKey: cacheKey) ?? [])
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(result)
            }
        }
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    /// The theme to render with. Falls back to Classic if the selection isn't unlocked.
    var current: Theme {
        let theme = Theme.all.first { $0.id == selectedID } ?? .classic
        return isUnlocked(theme) ? theme : .classic
    }

    var hasEverything: Bool { purchasedIDs.contains(Theme.bundleProductID) }

    func isUnlocked(_ theme: Theme) -> Bool {
        guard let productID = theme.productID else { return true }
        return purchasedIDs.contains(productID) || hasEverything
    }

    func price(for productID: String) -> String? {
        products[productID]?.displayPrice
    }

    func select(_ theme: Theme) {
        guard isUnlocked(theme) else { return }
        selectedID = theme.id
        defaults.set(theme.id, forKey: selectedKey)
    }

    // MARK: StoreKit

    func loadProducts() async {
        do {
            let fetched = try await Product.products(for: Theme.paidProductIDs)
            products = Dictionary(uniqueKeysWithValues: fetched.map { ($0.id, $0) })
            if fetched.isEmpty { message = "Store is unavailable right now." }
        } catch {
            message = "Couldn't reach the App Store."
        }
    }

    func purchase(_ productID: String) async {
        guard let product = products[productID] else {
            await loadProducts()
            return
        }
        isBusy = true
        defer { isBusy = false }
        do {
            switch try await product.purchase() {
            case .success(let result):
                await handle(result)
            case .pending:
                message = "Purchase is pending approval."
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            message = "Purchase failed. Please try again."
        }
    }

    func restore() async {
        isBusy = true
        defer { isBusy = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            message = "Purchases restored."
        } catch {
            message = "Couldn't restore purchases."
        }
    }

    func refreshEntitlements() async {
        var owned = Set<String>()
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result, transaction.revocationDate == nil {
                owned.insert(transaction.productID)
            }
        }
        setPurchased(owned)
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else {
            message = "Couldn't verify that purchase."
            return
        }
        var owned = purchasedIDs
        if transaction.revocationDate == nil {
            owned.insert(transaction.productID)
        } else {
            owned.remove(transaction.productID)
        }
        setPurchased(owned)
        await transaction.finish()
    }

    private func setPurchased(_ ids: Set<String>) {
        purchasedIDs = ids
        defaults.set(Array(ids), forKey: cacheKey)
    }
}
