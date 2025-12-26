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
    
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfService = false
    @State private var showContactUs = false
    @State private var showLanguageSelection = false
    @State private var showSymbolBook = false
    
    // 获取自定义字体
    private func customFont(size: CGFloat) -> Font {
        return FontManager.shared.customFont(size: size)
    }
    
    var body: some View {
        ZStack {
            // 背景
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // 抽屉式窗口 - 从底部滑出
            VStack {
                Spacer()
                
                VStack(spacing: 0) {
                    // 拖拽指示器
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 40, height: 5)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                    
                    ScrollView {
                        VStack(spacing: 25) {
                            // 标题
                            Text(localizationManager.localized("settings.title"))
                                .font(customFont(size: 38)) // 从 33 增加到 38（+5）
                                .foregroundColor(.white)
                                .textStroke()
                            
                            // 设置选项
                            VStack(spacing: 15) {
                                            // 音乐开关
                                HStack {
                                    Image(systemName: "music.note")
                                        .font(.title2)
                                        .foregroundColor(.purple)
                                    
                                    Text(localizationManager.localized("settings.music"))
                                        .font(customFont(size: 22)) // 从 17 增加到 22（+5）
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
                                        .font(customFont(size: 22)) // 从 17 增加到 22（+5）
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
                                                .font(customFont(size: 22)) // 从 17 增加到 22（+5）
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
                                            .font(customFont(size: 22)) // 从 17 增加到 22（+5）
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
                                            .font(customFont(size: 22)) // 从 17 增加到 22（+5）
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
                                    if let url = URL(string: "https://discord.gg/genAZ3Kp") {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    HStack {
                                        Image("Discord")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 28, height: 28)
                                        
                                        Text("Discord")
                                            .font(customFont(size: 22)) // 从 17 增加到 22（+5）
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
                                    // TODO: 这里应该调用 StoreKit 恢复购买
                                    // StoreKitManager.shared.restorePurchases { restored in
                                    //     if restored {
                                    //         print("✅ [设置] 恢复购买成功")
                                    //     } else {
                                    //         print("⚠️ [设置] 没有可恢复的购买")
                                    //     }
                                    // }
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
                            }
                            
                            // 关闭按钮
                            Button(localizationManager.localized("settings.close")) {
                                audioManager.playSoundEffect("click", fileExtension: "wav")
                                isPresented = false
                            }
                            .font(customFont(size: 22)) // 从 17 增加到 22（+5）
                            .foregroundColor(.white)
                            .textStroke()
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white.opacity(0.2))
                            )
                            .padding(.bottom, 30) // 底部内边距
                        }
                        .padding(.horizontal, 30)
                        .padding(.top, 10)
                    }
                }
                .frame(maxHeight: UIScreen.main.bounds.height * 0.95) // 抽屉高度为屏幕的95%，接近全屏，和商店页面一样高
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.black.opacity(0.9))
                )
                .padding(.horizontal, 0)
            }
            
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
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPresented)
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
import WebKit

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
    HomeSettingsView(isPresented: .constant(true))
}

