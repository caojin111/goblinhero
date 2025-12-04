//
//  HomeSettingsView.swift
//  A004
//
//  首页设置界面
//

import SwiftUI

struct HomeSettingsView: View {
    @ObservedObject var audioManager = AudioManager.shared
    @ObservedObject var localizationManager = LocalizationManager.shared
    @Binding var isPresented: Bool
    
    @State private var showPrivacyPolicy = false
    @State private var showContactUs = false
    
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
            
            VStack(spacing: 25) {
                // 标题
                Text(localizationManager.localized("settings.title"))
                    .font(customFont(size: 28))
                    .foregroundColor(.white)
                    .textStroke()
                
                // 设置选项
                VStack(spacing: 15) {
                    // 音乐开关
                    HStack {
                        Image(systemName: "music.note")
                            .font(.title2)
                            .foregroundColor(.purple)
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text(localizationManager.localized("settings.music"))
                                .font(customFont(size: 17))
                                .foregroundColor(.white)
                                .textStroke()
                            
                            Text(localizationManager.localized("settings.music_description"))
                                .font(customFont(size: 12))
                                .foregroundColor(.white.opacity(0.8))
                                .textStroke()
                        }
                        
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
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text(localizationManager.localized("settings.sound_effects"))
                                .font(customFont(size: 17))
                                .foregroundColor(.white)
                                .textStroke()
                            
                            Text(localizationManager.localized("settings.sound_effects_description"))
                                .font(customFont(size: 12))
                                .foregroundColor(.white.opacity(0.8))
                                .textStroke()
                        }
                        
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
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text(localizationManager.localized("settings.privacy_policy"))
                                    .font(customFont(size: 17))
                                    .foregroundColor(.white)
                                    .textStroke()
                                
                                Text(localizationManager.localized("settings.privacy_policy_description"))
                                    .font(customFont(size: 12))
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
                    
                    // 联系我们按钮
                    Button(action: {
                        showContactUs = true
                    }) {
                        HStack {
                            Image(systemName: "envelope")
                                .font(.title2)
                                .foregroundColor(.orange)
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text(localizationManager.localized("settings.contact_us"))
                                    .font(customFont(size: 17))
                                    .foregroundColor(.white)
                                    .textStroke()
                                
                                Text(localizationManager.localized("settings.contact_us_description"))
                                    .font(customFont(size: 12))
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
                }
                
                // 关闭按钮
                Button(localizationManager.localized("settings.close")) {
                    isPresented = false
                }
                .font(customFont(size: 17))
                .foregroundColor(.white)
                .textStroke()
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.2))
                )
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.black.opacity(0.9))
            )
            .padding(40)
            
            // 隐私政策弹窗
            if showPrivacyPolicy {
                PrivacyPolicyView(isPresented: $showPrivacyPolicy)
            }
            
            // 联系我们弹窗
            if showContactUs {
                ContactUsView(isPresented: $showContactUs)
            }
        }
        .transition(.scale)
    }
}

// MARK: - 隐私政策视图
struct PrivacyPolicyView: View {
    @Binding var isPresented: Bool
    @ObservedObject var localizationManager = LocalizationManager.shared
    
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
                    Text(localizationManager.localized("settings.privacy_policy"))
                        .font(.title2)
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
                ScrollView {
                    Text(localizationManager.localized("settings.privacy_policy_content"))
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .lineSpacing(8)
                }
                
                // 关闭按钮
                Button(localizationManager.localized("settings.close")) {
                    isPresented = false
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.2))
                )
            }
            .padding(30)
            .frame(width: 350, height: 500)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.black.opacity(0.95))
            )
        }
        .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - 联系我们视图
struct ContactUsView: View {
    @Binding var isPresented: Bool
    @ObservedObject var localizationManager = LocalizationManager.shared
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
                        .font(.title2)
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
                        .font(.body)
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
                        .font(.headline)
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
                    isPresented = false
                }
                .font(.headline)
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

