//
//  HomeSettingsView.swift
//  A004
//
//  首页设置界面
//

import SwiftUI
import WebKit

struct HomeSettingsView: View {
    @ObservedObject var audioManager = AudioManager.shared
    @ObservedObject var localizationManager = LocalizationManager.shared
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: GameViewModel
    
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfService = false
    @State private var showContactUs = false
    @State private var showLanguageSelection = false
    @State private var showSymbolBook = false
    
    /// 恢复已购买的哥布林和钻石
    private func restorePurchasedGoblins() async {
        let storeKitManager = StoreKitManager.shared
        let allGoblins = Goblin.allGoblins
        
        // 恢复已购买的哥布林
        for goblin in allGoblins {
            if let productId = goblin.productId,
               storeKitManager.isPurchased(productId),
               !viewModel.unlockedGoblinIds.contains(goblin.id) {
                // 恢复这个哥布林
                viewModel.unlockGoblin(goblinId: goblin.id, cost: 0)
                print("✅ [恢复购买] 恢复哥布林: \(goblin.name) (productId: \(productId))")
            }
        }
        
        // 恢复已购买的钻石（只恢复一次，避免重复添加）
        let diamondProductIds = ["diamond_5.99", "diamond_9.99", "diamond_19.99", "diamond_29.99"]
        let restoreKey = "hasRestoredDiamonds"
        let hasRestored = UserDefaults.standard.bool(forKey: restoreKey)
        
        if !hasRestored {
            var totalDiamonds = 0
            for productId in diamondProductIds {
                if storeKitManager.isPurchased(productId),
                   let diamonds = storeKitManager.getDiamondsForProduct(productId) {
                    totalDiamonds += diamonds
                    print("✅ [恢复购买] 恢复钻石包: \(productId), 钻石: \(diamonds)")
                }
            }
            
            if totalDiamonds > 0 {
                viewModel.addDiamonds(totalDiamonds)
                UserDefaults.standard.set(true, forKey: restoreKey)
                print("✅ [恢复购买] 总共恢复 \(totalDiamonds) 钻石")
            }
        }
    }
    
    // 获取自定义字体
    private func customFont(size: CGFloat) -> Font {
        return FontManager.shared.customFont(size: size)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景遮罩
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isPresented = false
                    }
                
                // 普通弹窗 - 居中显示
                VStack(spacing: 0) {
                    // 标题栏
                    HStack {
                        Text(localizationManager.localized("settings.title"))
                            .font(customFont(size: 38))
                            .foregroundColor(.white)
                            .textStroke()
                        
                        Spacer()
                        
                        Button(action: {
                            audioManager.playSoundEffect("click", fileExtension: "wav")
                            isPresented = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 25)
                    .padding(.bottom, 20)
                    
                    // 内容区域 - 自适应高度，内容多时可滚动
                    ScrollView {
                        VStack(spacing: 15) {
                        // 音乐开关
                        HStack {
                            Image(systemName: "music.note")
                                .font(.title2)
                                .foregroundColor(.purple)
                            
                            Text(localizationManager.localized("settings.music"))
                                .font(customFont(size: 22))
                                .foregroundColor(.white)
                                .textStroke()
                            
                            Spacer()
                            
                            Toggle("", isOn: $audioManager.isMusicEnabled)
                                .labelsHidden()
                                .tint(.purple)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white.opacity(0.1))
                        )
                        
                        // 音效开关
                        HStack {
                            Image(systemName: "speaker.wave.2")
                                .font(.title2)
                                .foregroundColor(.blue)
                            
                            Text(localizationManager.localized("settings.sound_effects"))
                                .font(customFont(size: 22))
                                .foregroundColor(.white)
                                .textStroke()
                            
                            Spacer()
                            
                            Toggle("", isOn: $audioManager.isSoundEffectsEnabled)
                                .labelsHidden()
                                .tint(.blue)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white.opacity(0.1))
                        )
                        
                        // 语言选择按钮
                        Button(action: {
                            showLanguageSelection = true
                        }) {
                            HStack {
                                Image(systemName: "globe")
                                    .font(.title2)
                                    .foregroundColor(.cyan)
                                
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(localizationManager.localized("settings.language"))
                                        .font(customFont(size: 22))
                                        .foregroundColor(.white)
                                        .textStroke()
                                    
                                    Text("\(localizationManager.getAvailableLanguages().first { $0.code == localizationManager.currentLanguage }?.name ?? "Unknown")")
                                        .font(customFont(size: 16))
                                        .foregroundColor(.white.opacity(0.8))
                                        .textStroke()
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.white.opacity(0.1))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // 图鉴按钮
                        Button(action: {
                            audioManager.playSoundEffect("click", fileExtension: "wav")
                            showSymbolBook = true
                        }) {
                            HStack {
                                Image(systemName: "book.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                
                                Text(localizationManager.localized("settings.book"))
                                    .font(customFont(size: 22))
                                    .foregroundColor(.white)
                                    .textStroke()
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.white.opacity(0.1))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Divider()
                            .background(Color.white.opacity(0.3))
                            .padding(.vertical, 5)
                        
                        // 隐私政策按钮
                        Button(action: {
                            showPrivacyPolicy = true
                        }) {
                            HStack {
                                Image(systemName: "doc.text")
                                    .font(.title2)
                                    .foregroundColor(.green)
                                
                                Text(localizationManager.localized("settings.privacy_policy"))
                                    .font(customFont(size: 22))
                                    .foregroundColor(.white)
                                    .textStroke()
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.white.opacity(0.1))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // 使用条款按钮
                        Button(action: {
                            audioManager.playSoundEffect("click", fileExtension: "wav")
                            showTermsOfService = true
                        }) {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                
                                Text(localizationManager.localized("settings.terms_of_service"))
                                    .font(customFont(size: 22))
                                    .foregroundColor(.white)
                                    .textStroke()
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.white.opacity(0.1))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Divider()
                            .background(Color.white.opacity(0.3))
                            .padding(.vertical, 5)
                        
                        // 联系我们按钮（直接打开邮件应用）
                        Button(action: {
                            audioManager.playSoundEffect("click", fileExtension: "wav")
                            // 直接打开邮件应用，发送邮件到 dxycj250@gmail.com
                            if let url = URL(string: "mailto:dxycj250@gmail.com") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack {
                                Image(systemName: "envelope")
                                    .font(.title2)
                                    .foregroundColor(.orange)
                                
                                Text(localizationManager.localized("settings.contact_us"))
                                    .font(customFont(size: 22))
                                    .foregroundColor(.white)
                                    .textStroke()
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.white.opacity(0.1))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Discord 按钮
                        Button(action: {
                            audioManager.playSoundEffect("click", fileExtension: "wav")
                            if let url = URL(string: "https://discord.gg/cxQmzQrc6v") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack {
                                Image("Discord")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 28, height: 28)
                                
                                Text("Discord")
                                    .font(customFont(size: 22))
                                    .foregroundColor(.white)
                                    .textStroke()
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.white.opacity(0.1))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Restore 按钮
                        Button(action: {
                            audioManager.playSoundEffect("click", fileExtension: "wav")
                            print("🔄 [设置] 点击恢复购买")
                            Task { @MainActor in
                                let restored = await StoreKitManager.shared.restorePurchases()
                                if restored {
                                    print("✅ [设置] 恢复购买成功")
                                    // 恢复购买后，检查已购买的哥布林
                                    await restorePurchasedGoblins()
                                } else {
                                    print("⚠️ [设置] 没有可恢复的购买")
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                    .font(.title2)
                                    .foregroundColor(.green)
                                
                                Text(localizationManager.localized("settings.restore"))
                                    .font(customFont(size: 22))
                                    .foregroundColor(.white)
                                    .textStroke()
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.white.opacity(0.1))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Rate Us 按钮
                        Button(action: {
                            audioManager.playSoundEffect("click", fileExtension: "wav")
                            rateUs()
                        }) {
                            HStack {
                                Image(systemName: "star.fill")
                                    .font(.title2)
                                    .foregroundColor(.yellow)
                                
                                Text(localizationManager.localized("settings.rate_us"))
                                    .font(customFont(size: 22))
                                    .foregroundColor(.white)
                                    .textStroke()
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.white.opacity(0.1))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 30)
                        .padding(.bottom, 20)
                    }
                    .frame(maxHeight: geometry.size.height * 0.7) // 限制最大高度，超过时可滚动
                }
                .frame(width: min(geometry.size.width * 0.9, 500)) // 弹窗宽度为屏幕宽度的90%，最大500
                .fixedSize(horizontal: false, vertical: true) // 根据内容自适应高度，不占用多余空间
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.black.opacity(0.9))
                        .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
                )
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2) // 居中显示
                
                // 隐私政策弹窗
                if showPrivacyPolicy {
                    HTMLContentView(
                        isPresented: $showPrivacyPolicy,
                        title: localizationManager.localized("settings.privacy_policy"),
                        htmlFileName: "privacy_policy.html"
                    )
                }
                
                // 使用条款弹窗
                if showTermsOfService {
                    HTMLContentView(
                        isPresented: $showTermsOfService,
                        title: localizationManager.localized("settings.terms_of_service"),
                        htmlFileName: "terms_of_service.html"
                    )
                }
                
                // 联系我们弹窗
                if showContactUs {
                    ContactUsView(isPresented: $showContactUs)
                }
                
                // 语言选择弹窗
                if showLanguageSelection {
                    LanguageSelectionView(isPresented: $showLanguageSelection)
                }
                
                // 图鉴弹窗
                if showSymbolBook {
                    SymbolBookView(isPresented: $showSymbolBook, viewModel: nil)
                }
            }
        }
        .transition(.scale.combined(with: .opacity))
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPresented)
    }
    
    // 跳转到App Store评分页面
    private func rateUs() {
        // App Store ID
        let appStoreID = "6756869057"
        
        // 构建App Store URL
        // 使用itms-apps://格式（直接打开App Store应用）
        let appStoreURL = "itms-apps://itunes.apple.com/app/id\(appStoreID)"
        let webURL = "https://apps.apple.com/app/id\(appStoreID)"
        
        // 优先尝试使用itms-apps://格式（直接打开App Store应用）
        if let url = URL(string: appStoreURL) {
            UIApplication.shared.open(url) { success in
                if !success {
                    // 如果itms-apps://失败，尝试使用https://格式
                    if let webUrl = URL(string: webURL) {
                        UIApplication.shared.open(webUrl)
                    }
                }
            }
        } else {
            // 如果URL构建失败，使用https://格式
            if let webUrl = URL(string: webURL) {
                UIApplication.shared.open(webUrl)
            }
        }
        
        print("⭐ [Rate Us] 跳转到App Store评分页面，ID: \(appStoreID)")
    }
}

// MARK: - HTML内容视图
struct HTMLContentView: View {
    @Binding var isPresented: Bool
    let title: String
    let htmlFileName: String
    @ObservedObject var audioManager = AudioManager.shared
    @ObservedObject var localizationManager = LocalizationManager.shared
    @State private var htmlContent: String = ""
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景遮罩
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isPresented = false
                    }
                
                // 抽屉式弹窗（从底部滑出，高度85%）
                VStack(spacing: 0) {
                    Spacer()
                    
                    VStack(spacing: 0) {
                        // 标题栏
                        HStack {
                            Text(title)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button(action: {
                                audioManager.playSoundEffect("click", fileExtension: "wav")
                                isPresented = false
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 15)
                        .background(Color.black.opacity(0.95))
                        
                        // HTML内容
                        if htmlContent.isEmpty {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .frame(height: geometry.size.height * 0.85 - 100)
                        } else {
                            WebView(htmlContent: htmlContent)
                                .frame(maxWidth: .infinity)
                                .frame(height: geometry.size.height * 0.85 - 100)
                        }
                        
                        // 关闭按钮栏
                        HStack {
                            Spacer()
                            Button(localizationManager.localized("settings.close")) {
                                audioManager.playSoundEffect("click", fileExtension: "wav")
                                isPresented = false
                            }
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white.opacity(0.2))
                            )
                            Spacer()
                        }
                        .padding(.vertical, 15)
                        .background(Color.black.opacity(0.95))
                    }
                    .frame(width: geometry.size.width)
                    .frame(height: geometry.size.height * 0.85)
                    .background(Color.black.opacity(0.95))
                    .cornerRadius(25, corners: [.topLeft, .topRight])
                }
            }
            .onAppear {
                loadHTMLContent()
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    private func loadHTMLContent() {
        guard let url = Bundle.main.url(forResource: htmlFileName, withExtension: nil) else {
            htmlContent = "<html><body style='color: white;'><p>File not found: \(htmlFileName)</p></body></html>"
            return
        }
        
        do {
            htmlContent = try String(contentsOf: url, encoding: .utf8)
        } catch {
            htmlContent = "<html><body style='color: white;'><p>Error loading file: \(error.localizedDescription)</p></body></html>"
        }
    }
}

// MARK: - WebView for HTML content
struct WebView: UIViewRepresentable {
    let htmlContent: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.backgroundColor = .clear
        webView.isOpaque = false
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // 添加样式使文本在深色背景下可见
        let styledHTML = """
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    color: white;
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    padding: 20px;
                    background-color: transparent;
                }
            </style>
        </head>
        <body>
        \(htmlContent)
        </body>
        </html>
        """
        webView.loadHTMLString(styledHTML, baseURL: nil)
    }
}

// MARK: - 联系我们视图
struct ContactUsView: View {
    @Binding var isPresented: Bool
    @ObservedObject var localizationManager = LocalizationManager.shared
    @ObservedObject var audioManager = AudioManager.shared
    @State private var emailSubject: String = ""
    @State private var emailBody: String = ""
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            VStack(spacing: 20) {
                // 标题
                HStack {
                    Text(localizationManager.localized("settings.contact_us"))
                        .font(.title) // 从 .title2 增加到 .title（+5）
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                // 内容
                VStack(spacing: 15) {
                    Text(localizationManager.localized("settings.contact_us_content"))
                        .font(.title3) // 从 .body 增加到 .title3（+5）
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                    
                    // 邮箱地址
                    Button(action: {
                        if let url = URL(string: "mailto:support@example.com") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "envelope.fill")
                            Text("support@example.com")
                        }
                        .font(.title3) // 从 .headline 增加到 .title3（+5）
                        .foregroundColor(.blue)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white.opacity(0.1))
                        )
                    }
                }
                
                // 关闭按钮
                Button(localizationManager.localized("settings.close")) {
                    audioManager.playSoundEffect("click", fileExtension: "wav")
                    isPresented = false
                }
                .font(.title3) // 从 .headline 增加到 .title3（+5）
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.2))
                )
            }
            .padding(30)
            .frame(width: 350)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.black.opacity(0.95))
            )
        }
        .transition(.scale.combined(with: .opacity))
    }
}

#Preview {
    HomeSettingsView(isPresented: .constant(true), viewModel: GameViewModel())
}


