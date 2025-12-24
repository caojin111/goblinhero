//
//  StoryIntroView.swift
//  A004
//
//  故事介绍幻灯片视图
//

import SwiftUI

struct StoryIntroView: View {
    @ObservedObject var localizationManager = LocalizationManager.shared
    @ObservedObject var audioManager = AudioManager.shared
    @Binding var isPresented: Bool
    @State private var currentPage: Int = 0
    
    // 获取自定义字体
    private func customFont(size: CGFloat) -> Font {
        return FontManager.shared.customFont(size: size)
    }
    
    // 故事页面数据（5页）
    let storyPages: [StoryPage] = [
        StoryPage(
            title: "story.page1.title",
            content: "story.page1.content",
            imageName: "story_1"
        ),
        StoryPage(
            title: "story.page2.title",
            content: "story.page2.content",
            imageName: "story_2"
        ),
        StoryPage(
            title: "story.page3.title",
            content: "story.page3.content",
            imageName: "story_3"
        ),
        StoryPage(
            title: "story.page4.title",
            content: "story.page4.content",
            imageName: "story_4"
        ),
        StoryPage(
            title: "story.page5.title",
            content: "story.page5.content",
            imageName: "story_5"
        )
    ]
    
    var body: some View {
        ZStack {
            // 纯黑背景
            Color.black
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 故事内容区域（带翻书动画）
                TabView(selection: $currentPage) {
                    ForEach(Array(storyPages.enumerated()), id: \.offset) { index, page in
                        StoryPageView(
                            page: page,
                            localizationManager: localizationManager
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                // 底部按钮区域（只有下一页按钮）
                HStack {
                    Spacer()
                    
                    // 下一页/开始按钮（使用 resource_bar 样式）
                    Button(action: {
                        if currentPage < storyPages.count - 1 {
                            withAnimation(.easeInOut(duration: 0.6)) {
                                currentPage += 1
                            }
                        } else {
                            // 最后一页，完成故事介绍
                            completeStory()
                        }
                    }) {
                        ZStack {
                            // resource_bar 背景图
                            Image("resource_bar")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 60)
                            
                            // 按钮文字
                        HStack(spacing: 8) {
                            Text(currentPage < storyPages.count - 1 ?
                                 localizationManager.localized("story.next") :
                                 localizationManager.localized("story.start"))
                            if currentPage < storyPages.count - 1 {
                                Image(systemName: "chevron.right")
                            }
                        }
                        .font(customFont(size: 16))
                        .foregroundColor(.white)
                        .textStroke()
                        }
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            // 播放背景故事音乐
            audioManager.playBackgroundMusic(fileName: "bg_story", fileExtension: "mp3")
        }
        .onDisappear {
            // 停止背景故事音乐
            audioManager.stopMusic()
        }
    }
    
    /// 完成故事介绍
    private func completeStory() {
        print("📖 [故事介绍] 用户完成故事介绍")
        markStoryCompleted()
        isPresented = false
    }
    
    /// 标记故事介绍已完成
    private func markStoryCompleted() {
        UserDefaults.standard.set(true, forKey: "hasSeenStoryIntro")
    }
}

// MARK: - 故事页面数据模型
struct StoryPage {
    let title: String // 本地化键
    let content: String // 本地化键
    let imageName: String // 图片名称（story_1 到 story_5）
}

// MARK: - 单个故事页面视图
struct StoryPageView: View {
    let page: StoryPage
    @ObservedObject var localizationManager: LocalizationManager
    @State private var visibleLines: Set<Int> = []
    
    // 获取自定义字体
    private func customFont(size: CGFloat) -> Font {
        return FontManager.shared.customFont(size: size)
    }
    
    var fullText: String {
        return localizationManager.localized(page.content)
    }
    
    var textLines: [String] {
        let lines = fullText.components(separatedBy: "\n")
        // 如果没有换行符，将文本按一定长度分割（每行约25个字符）
        if lines.count == 1 && !fullText.isEmpty {
            let text = fullText
            var result: [String] = []
            var currentLine = ""
            
            // 改进的分割逻辑：按字符分割，每行约25个字符
            for (index, char) in text.enumerated() {
                currentLine += String(char)
            
                // 定义标点符号（中文和英文）
                let isPunctuation = char == "。" || char == "，" || char == "." || char == "," || 
                                   char == "？" || char == "?" || char == "！" || char == "!" ||
                                   char == "：" || char == ":"
                
                // 检查是否应该换行
                // 情况1：达到最小长度（20字符）且遇到标点符号
                // 情况2：达到推荐长度（25字符）且遇到空格或标点符号
                // 情况3：强制换行（35字符）
                let shouldBreak = (
                    (currentLine.count >= 20 && isPunctuation) ||
                    (currentLine.count >= 25 && (char == " " || isPunctuation)) ||
                    currentLine.count >= 35
                )
                
                if shouldBreak {
                    let trimmedLine = currentLine.trimmingCharacters(in: .whitespaces)
                    if !trimmedLine.isEmpty {
                        result.append(trimmedLine)
                    }
                    currentLine = ""
                }
            }
            
            // 添加最后一行
            if !currentLine.isEmpty {
                let trimmedLine = currentLine.trimmingCharacters(in: .whitespaces)
                if !trimmedLine.isEmpty {
                    result.append(trimmedLine)
                }
            }
            
            // 如果分割后还是只有一行，也要返回（至少会有一行渐显效果）
            let finalResult = result.isEmpty ? [fullText] : result
            print("📖 [故事文本分割] 页面: \(page.imageName), 原始文本长度: \(fullText.count), 分割后行数: \(finalResult.count)")
            print("📖 [故事文本分割] 分割结果: \(finalResult)")
            return finalResult
        }
        let filteredLines = lines.filter { !$0.isEmpty }
        print("📖 [故事文本分割] 页面: \(page.imageName), 原始行数: \(lines.count), 过滤后行数: \(filteredLines.count)")
        return filteredLines
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 30) {
                Spacer()
                
                // 故事图片（统一大小，使用固定尺寸，参考第五页规格）
                // 使用固定的宽高比和尺寸，确保所有图片显示一致
                Image(page.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: geometry.size.width * 0.8 * 1.2,
                        height: geometry.size.height * 0.5 * 1.2
                    )
                    .clipped() // 确保超出部分被裁剪
                    .padding(.horizontal, 20)
            
                // 故事文本（逐行渐显效果）
                VStack(alignment: .center, spacing: 8) {
                    ForEach(Array(textLines.enumerated()), id: \.offset) { index, line in
                        Text(line)
                            .font(customFont(size: 23)) // 从18增大5号到23
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                            .lineLimit(nil) // 允许多行显示
                            .fixedSize(horizontal: false, vertical: true) // 允许垂直扩展，水平自适应
                            .opacity(visibleLines.contains(index) ? 1.0 : 0.0)
                            .animation(.easeIn(duration: 1.0).delay(Double(index) * 0.6), value: visibleLines.contains(index))
                    }
                }
                .frame(maxWidth: .infinity) // 确保容器宽度填满
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
            
            Spacer()
        }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onAppear {
                startLineAnimation()
            }
            .onDisappear {
                visibleLines.removeAll()
            }
            .id("\(page.imageName)_\(page.content)") // 使用唯一ID确保页面切换时重新初始化
        }
    }
    
    private func startLineAnimation() {
        visibleLines.removeAll()
        let lines = textLines
        print("📖 [渐显动画] 开始动画，总行数: \(lines.count), 页面: \(page.imageName)")
        
        // 确保至少有一行会显示（即使只有一行，也要有渐显效果）
        if lines.isEmpty {
            print("⚠️ [渐显动画] 警告：没有文本行可显示")
            return
        }
        
        for index in 0..<lines.count {
            let delay = Double(index) * 0.6
            print("📖 [渐显动画] 计划显示第\(index + 1)行，延迟: \(delay)秒")
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.visibleLines.insert(index)
                print("📖 [渐显动画] ✅ 第\(index + 1)行已显示")
            }
            }
    }
}

#Preview {
    StoryIntroView(isPresented: .constant(true))
}

