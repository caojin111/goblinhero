//
//  StoreKitManager.swift
//  A004
//
//  StoreKit 购买管理器
//

import Foundation
import StoreKit
import Combine

@MainActor
class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()
    
    @Published var products: [Product] = []
    @Published var purchasedProductIds: Set<String> = []
    @Published var isLoading: Bool = false
    @Published var purchaseError: String? = nil
    
    private let localizationManager = LocalizationManager.shared
    
    private var updateListenerTask: Task<Void, Error>?
    private var productIds: Set<String> = []
    
    private init() {
        // 初始化所有商品ID
        productIds = getAllProductIds()
        
        // 启动交易更新监听
        updateListenerTask = listenForTransactions()
        
        // 加载产品信息
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - 获取所有商品ID
    private func getAllProductIds() -> Set<String> {
        var ids: Set<String> = []
        
        // 哥布林商品ID
        ids.insert("king_goblin_9.99")
        ids.insert("wizard_goblin_9.99")
        ids.insert("athlete_goblin_9.99")
        
        // 钻石商品ID
        ids.insert("diamond_5.99")
        ids.insert("diamond_9.99")
        ids.insert("diamond_19.99")
        ids.insert("diamond_29.99")
        
        return ids
    }
    
    // MARK: - 加载产品信息
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            print("🛒 [StoreKit] 开始加载产品信息，商品数量: \(productIds.count)")
            products = try await Product.products(for: productIds)
            print("✅ [StoreKit] 成功加载 \(products.count) 个产品")
            
            for product in products {
                print("📦 [StoreKit] 产品: \(product.id), 价格: \(product.displayPrice), 标题: \(product.displayName)")
            }
        } catch {
            print("❌ [StoreKit] 加载产品失败: \(error.localizedDescription)")
            // 使用通用的多语言错误信息，避免显示系统英文错误
            purchaseError = localizationManager.localized("store.storekit.error.load_products_failed")
                .replacingOccurrences(of: "{error}", with: localizationManager.localized("store.storekit.error.unknown"))
        }
    }
    
    // MARK: - 购买产品
    func purchase(_ product: Product) async throws -> Transaction? {
        print("🛒 [StoreKit] 开始购买: \(product.id)")
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            
            // 完成交易
            await transaction.finish()
            
            // 更新已购买产品列表
            await updatePurchasedProducts()
            
            print("✅ [StoreKit] 购买成功: \(product.id)")
            return transaction
            
        case .userCancelled:
            print("⚠️ [StoreKit] 用户取消购买: \(product.id)")
            throw StoreKitError.userCancelled
            
        case .pending:
            print("⏳ [StoreKit] 购买待处理: \(product.id)")
            throw StoreKitError.pending
            
        @unknown default:
            print("❌ [StoreKit] 未知购买结果: \(product.id)")
            throw StoreKitError.unknown
        }
    }
    
    // MARK: - 通过 productId 购买
    func purchase(productId: String) async -> Bool {
        guard let product = products.first(where: { $0.id == productId }) else {
            print("❌ [StoreKit] 找不到产品: \(productId)")
            purchaseError = localizationManager.localized("store.storekit.error.product_not_found")
                .replacingOccurrences(of: "{productId}", with: productId)
            return false
        }
        
        do {
            _ = try await purchase(product)
            return true
        } catch {
            print("❌ [StoreKit] 购买失败: \(error.localizedDescription)")
            // 根据错误类型返回对应的多语言错误信息
            if let storeKitError = error as? StoreKitError {
                // 使用 localizedErrorDescription 获取多语言错误信息
                purchaseError = storeKitError.localizedErrorDescription
            } else {
                // 对于其他类型的错误，使用通用的购买失败信息
                purchaseError = localizationManager.localized("store.purchase_failed")
            }
            return false
        }
    }
    
    // MARK: - 恢复购买
    func restorePurchases() async -> Bool {
        print("🔄 [StoreKit] 开始恢复购买")
        
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
            print("✅ [StoreKit] 恢复购买完成")
            return true
        } catch {
            print("❌ [StoreKit] 恢复购买失败: \(error.localizedDescription)")
            // 使用通用的多语言错误信息，避免显示系统英文错误
            purchaseError = localizationManager.localized("store.storekit.error.restore_failed")
                .replacingOccurrences(of: "{error}", with: localizationManager.localized("store.storekit.error.unknown"))
            return false
        }
    }
    
    // MARK: - 检查产品是否已购买
    func isPurchased(_ productId: String) -> Bool {
        return purchasedProductIds.contains(productId)
    }
    
    // MARK: - 获取产品
    func getProduct(_ productId: String) -> Product? {
        return products.first { $0.id == productId }
    }
    
    // MARK: - 监听交易更新
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    // 在 detached task 中验证交易（不需要 MainActor）
                    let transaction: Transaction
                    switch result {
                    case .unverified:
                        throw StoreKitError.unverified
                    case .verified(let safe):
                        transaction = safe
                    }
                    
                    await transaction.finish()
                    
                    // 在主线程更新已购买产品列表
                    await MainActor.run {
                        Task { @MainActor in
                            await StoreKitManager.shared.updatePurchasedProducts()
                        }
                    }
                    print("✅ [StoreKit] 处理交易更新: \(transaction.productID)")
                } catch {
                    print("❌ [StoreKit] 交易验证失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - 更新已购买产品列表
    private func updatePurchasedProducts() async {
        var purchasedIds: Set<String> = []
        
        for await result in Transaction.currentEntitlements {
            do {
                // 验证交易
                let transaction: Transaction
                switch result {
                case .unverified:
                    throw StoreKitError.unverified
                case .verified(let safe):
                    transaction = safe
                }
                
                purchasedIds.insert(transaction.productID)
                print("✅ [StoreKit] 已购买产品: \(transaction.productID)")
            } catch {
                print("❌ [StoreKit] 交易验证失败: \(error.localizedDescription)")
            }
        }
        
        purchasedProductIds = purchasedIds
        print("📋 [StoreKit] 已购买产品列表: \(purchasedIds)")
    }
    
    // MARK: - 验证交易（仅在 MainActor 上下文中使用）
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.unverified
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - 根据 productId 获取钻石数量（用于恢复购买）
    func getDiamondsForProduct(_ productId: String) -> Int? {
        // 钻石商品映射
        let diamondProducts: [String: Int] = [
            "diamond_5.99": 100,
            "diamond_9.99": 150,
            "diamond_19.99": 350,
            "diamond_29.99": 600
        ]
        return diamondProducts[productId]
    }
}

// MARK: - StoreKit 错误
enum StoreKitError: LocalizedError {
    case userCancelled
    case pending
    case unverified
    case unknown
    
    var errorDescription: String? {
        let localizationManager = LocalizationManager.shared
        switch self {
        case .userCancelled:
            return localizationManager.localized("store.storekit.error.user_cancelled")
        case .pending:
            return localizationManager.localized("store.storekit.error.pending")
        case .unverified:
            return localizationManager.localized("store.storekit.error.unverified")
        case .unknown:
            return localizationManager.localized("store.storekit.error.unknown")
        }
    }
    
    // 提供一个非可选的方法来获取错误描述
    var localizedErrorDescription: String {
        return errorDescription ?? LocalizationManager.shared.localized("store.storekit.error.unknown")
    }
}

