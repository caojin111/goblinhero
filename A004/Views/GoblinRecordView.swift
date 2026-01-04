//
//  GoblinRecordView.swift
//  A004
//
//  哥布林记录弹窗视图
//

import SwiftUI

struct GoblinRecordView: View {
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject var localizationManager = LocalizationManager.shared
    @ObservedObject var audioManager = AudioManager.shared
    @Binding var isPresented: Bool
    
    // 获取自定义字体
    private func customFont(size: CGFloat) -> Font {
        return FontManager.shared.customFont(size: size)
    }
    
    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    audioManager.playSoundEffect("click", fileExtension: "wav")
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                }
            
            // 弹窗内容
            VStack(spacing: 0) {
                // 标题栏
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(localizationManager.localized("home.goblin"))
                            .font(customFont(size: 24))
                            .foregroundColor(.white)
                            .textStroke()
                        
                        // 玩家名字（如果有）
                        if !viewModel.playerName.isEmpty {
                            Text(viewModel.playerName)
                                .font(customFont(size: 16))
                                .foregroundColor(.white.opacity(0.7))
                                .textStroke()
                        }
                    }
                    .offset(y: 20) // 下移20像素
                    
                    Spacer()
                    
                    Button(action: {
                        audioManager.playSoundEffect("click", fileExtension: "wav")
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 15)
                .background(Color.clear) // 改为透明，让背景图片显示
                
                // 记录内容
                VStack(spacing: 20) {
                    // 最佳进度
                    VStack(alignment: .leading, spacing: 8) {
                        Text(localizationManager.localized("home.best_round"))
                            .font(customFont(size: 18))
                            .foregroundColor(.white.opacity(0.8))
                            .textStroke()
                        
                        Text(viewModel.bestRound > 0 ? "\(viewModel.bestRound)-\(viewModel.bestSpinInRound)" : "0")
                            .font(customFont(size: 24))
                            .foregroundColor(.white)
                            .textStroke()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: "2A2B2D"))
                    )
                    
                    // 最佳单局金币
                    VStack(alignment: .leading, spacing: 8) {
                        Text(localizationManager.localized("home.best_single_game_coins"))
                            .font(customFont(size: 18))
                            .foregroundColor(.white.opacity(0.8))
                            .textStroke()
                        
                        Text("\(viewModel.bestSingleGameCoins)")
                            .font(customFont(size: 24))
                            .foregroundColor(.yellow)
                            .textStroke()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: "2A2B2D"))
                    )
                    
                    // 分享按钮
                    Button(action: {
                        audioManager.playSoundEffect("click", fileExtension: "wav")
                        shareBestRecord()
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text(localizationManager.localized("share.button"))
                        }
                        .font(customFont(size: 18))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.8))
                        )
                    }
                }
                .padding(20)
                .background(Color.clear) // 改为透明，让背景图片显示
            }
            .background(
                ZStack {
                    // 背景图片
                    Image("avatar_info")
                        .resizable()
                        .scaledToFill()
                        .clipped()
                }
                    .shadow(color: .black.opacity(0.4), radius: 15, x: 0, y: 8)
            )
            .frame(width: 320)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .transition(.scale.combined(with: .opacity))
            .sheet(isPresented: $showShareSheet) {
                if let shareImage = shareImage {
                    ShareSheet(items: [shareImage])
                }
            }
        }
    }
    
    @State private var showShareSheet = false
    @State private var shareImage: UIImage? = nil
    
    private func shareBestRecord() {
        let image = ShareImageGenerator.shared.generateBestRecordImage(
            bestRound: viewModel.bestRound,
            bestSpinInRound: viewModel.bestSpinInRound,
            bestSingleGameCoins: viewModel.bestSingleGameCoins
        )
        
        if let image = image {
            shareImage = image
            showShareSheet = true
        } else {
            print("❌ [分享] 无法生成分享图片")
        }
    }
}

#Preview {
    let viewModel = GameViewModel()
    viewModel.bestRound = 10
    viewModel.bestSpinInRound = 5
    viewModel.bestDifficulty = "普通"
    viewModel.bestSingleGameCoins = 5000
    return GoblinRecordView(viewModel: viewModel, isPresented: .constant(true))
}

