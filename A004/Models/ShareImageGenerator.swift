//
//  ShareImageGenerator.swift
//  A004
//
//  分享图片生成器
//

import UIKit

class ShareImageGenerator {
    static let shared = ShareImageGenerator()
    
    private init() {}
    
    /// 生成最佳记录分享图片
    func generateBestRecordImage(bestRound: Int, bestSpinInRound: Int, bestSingleGameCoins: Int) -> UIImage? {
        guard let backgroundImage = UIImage(named: "share") else {
            print("❌ [分享图片] 无法加载 share.png 背景图")
            return nil
        }
        
        let size = backgroundImage.size
        let renderer = UIGraphicsImageRenderer(size: size)
        let localizationManager = LocalizationManager.shared
        
        return renderer.image { context in
            // 绘制背景图
            backgroundImage.draw(in: CGRect(origin: .zero, size: size))
            
            // 获取字体
            let isChinese = localizationManager.currentLanguage == "zh"
            let fontSize: CGFloat = 50
            let titleFontSize: CGFloat = 40
            let fontName: String?
            
            if isChinese {
                // 尝试使用中文字体名称
                fontName = "猫啃什锦黑"
            } else {
                // 尝试使用英文字体名称
                fontName = "Calistoga-Regular"
            }
            
            let font = UIFont(name: fontName ?? "", size: fontSize) ?? UIFont.boldSystemFont(ofSize: fontSize)
            let titleFont = UIFont(name: fontName ?? "", size: titleFontSize) ?? UIFont.boldSystemFont(ofSize: titleFontSize)
            
            // 设置文本属性（黑色，左对齐）
            let textColor = UIColor.black
            let coinsTextColor = UIColor.systemYellow // 金币数量使用黄色
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .left
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: textColor,
                .paragraphStyle: paragraphStyle
            ]
            
            let coinsAttributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: coinsTextColor,
                .paragraphStyle: paragraphStyle
            ]
            
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: textColor,
                .paragraphStyle: paragraphStyle
            ]
            
            // 获取标题文本
            let progressTitle = localizationManager.localized("home.best_round")
            let coinsTitle = localizationManager.localized("home.best_single_game_coins")
            
            // 绘制文本
            let progressText = "\(bestRound)-\(bestSpinInRound)"
            let coinsText = "\(bestSingleGameCoins)"
            
            // 左上角起始位置
            let startX: CGFloat = 40
            let startY: CGFloat = 40
            let lineSpacing: CGFloat = 20
            
            // 计算标题和文本的尺寸
            let progressTitleRect = progressTitle.boundingRect(
                with: CGSize(width: size.width - startX * 2, height: size.height),
                options: .usesLineFragmentOrigin,
                attributes: titleAttributes,
                context: nil
            )
            
            let progressTextRect = progressText.boundingRect(
                with: CGSize(width: size.width - startX * 2, height: size.height),
                options: .usesLineFragmentOrigin,
                attributes: attributes,
                context: nil
            )
            
            let coinsTitleRect = coinsTitle.boundingRect(
                with: CGSize(width: size.width - startX * 2, height: size.height),
                options: .usesLineFragmentOrigin,
                attributes: titleAttributes,
                context: nil
            )
            
            let coinsTextRect = coinsText.boundingRect(
                with: CGSize(width: size.width - startX * 2, height: size.height),
                options: .usesLineFragmentOrigin,
                attributes: coinsAttributes,
                context: nil
            )
            
            // 绘制最佳进度标题和文本（带底框）
            var currentY = startY
            let padding: CGFloat = 10
            
            // 第一组：最佳进度
            let group1Width = max(progressTitleRect.width, progressTextRect.width) + padding * 2
            let group1Height = progressTitleRect.height + lineSpacing + progressTextRect.height + padding * 2
            let group1Rect = CGRect(x: startX - padding, y: currentY - padding, width: group1Width, height: group1Height)
            
            // 绘制半透明黑色底框（圆角矩形）
            UIColor.black.withAlphaComponent(0.5).setFill()
            let path1 = UIBezierPath(roundedRect: group1Rect, cornerRadius: 10)
            path1.fill()
            
            progressTitle.draw(
                in: CGRect(x: startX, y: currentY, width: size.width - startX * 2, height: progressTitleRect.height),
                withAttributes: titleAttributes
            )
            
            currentY += progressTitleRect.height + lineSpacing
            progressText.draw(
                in: CGRect(x: startX, y: currentY, width: size.width - startX * 2, height: progressTextRect.height),
                withAttributes: attributes
            )
            
            // 第二组：最佳单局金币
            currentY += progressTextRect.height + lineSpacing * 2
            let group2Width = max(coinsTitleRect.width, coinsTextRect.width) + padding * 2
            let group2Height = coinsTitleRect.height + lineSpacing + coinsTextRect.height + padding * 2
            let group2Rect = CGRect(x: startX - padding, y: currentY - padding, width: group2Width, height: group2Height)
            
            // 绘制半透明黑色底框（圆角矩形）
            UIColor.black.withAlphaComponent(0.5).setFill()
            let path2 = UIBezierPath(roundedRect: group2Rect, cornerRadius: 10)
            path2.fill()
            
            coinsTitle.draw(
                in: CGRect(x: startX, y: currentY, width: size.width - startX * 2, height: coinsTitleRect.height),
                withAttributes: titleAttributes
            )
            
            currentY += coinsTitleRect.height + lineSpacing
            coinsText.draw(
                in: CGRect(x: startX, y: currentY, width: size.width - startX * 2, height: coinsTextRect.height),
                withAttributes: coinsAttributes
            )
            
            // 绘制左下角的挑战文本
            drawChallengeText(in: context, size: size, localizationManager: localizationManager, fontSize: fontSize)
            
            // 绘制右下角的 app icon 和 app name
            drawAppInfo(in: context, size: size, localizationManager: localizationManager)
        }
    }
    
    /// 绘制左下角的挑战文本
    private func drawChallengeText(in context: UIGraphicsImageRendererContext, size: CGSize, localizationManager: LocalizationManager, fontSize: CGFloat) {
        // 获取挑战文本
        let challengeText = localizationManager.localized("share.challenge_text")
        
        // 获取字体（字号比最佳单局金币大10号，即 fontSize + 10）
        let isChinese = localizationManager.currentLanguage == "zh"
        let challengeFontSize: CGFloat = fontSize + 10
        let fontName: String?
        
        if isChinese {
            fontName = "猫啃什锦黑"
        } else {
            fontName = "Calistoga-Regular"
        }
        
        let challengeFont = UIFont(name: fontName ?? "", size: challengeFontSize) ?? UIFont.boldSystemFont(ofSize: challengeFontSize)
        
        // 设置文本属性（白色字体，黑色描边）
        let textColor = UIColor.white
        let strokeColor = UIColor.black
        let strokeWidth: CGFloat = 3.0
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: challengeFont,
            .foregroundColor: textColor,
            .strokeColor: strokeColor,
            .strokeWidth: -strokeWidth, // 负值表示描边在内部
            .paragraphStyle: paragraphStyle
        ]
        
        // 计算文本尺寸
        let textRect = challengeText.boundingRect(
            with: CGSize(width: size.width, height: size.height),
            options: .usesLineFragmentOrigin,
            attributes: attributes,
            context: nil
        )
        
        // 左下角位置
        let margin: CGFloat = 40
        let textX = margin
        let textY = size.height - textRect.height - margin
        
        // 绘制文本
        challengeText.draw(
            in: CGRect(x: textX, y: textY, width: textRect.width, height: textRect.height),
            withAttributes: attributes
        )
    }
    
    /// 绘制右下角的 app icon 和 app name（带黑色底框）
    private func drawAppInfo(in context: UIGraphicsImageRendererContext, size: CGSize, localizationManager: LocalizationManager) {
        // 获取 app icon
        var appIcon: UIImage? = nil
        if let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
           let iconName = iconFiles.last {
            appIcon = UIImage(named: iconName)
        }
        
        // 如果没找到，尝试直接使用 AppIcon
        if appIcon == nil {
            appIcon = UIImage(named: "AppIcon")
        }
        
        // 获取 app name
        let appName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ??
                     Bundle.main.localizedInfoDictionary?["CFBundleDisplayName"] as? String ??
                     Bundle.main.infoDictionary?["CFBundleName"] as? String ??
                     "App"
        
        // 获取玩家名字
        let playerName = UserDefaults.standard.string(forKey: "playerName") ?? ""
        
        // 右下角位置
        let iconSize: CGFloat = 40
        let spacing: CGFloat = 8
        let margin: CGFloat = 20
        let padding: CGFloat = 10
        let nameSpacing: CGFloat = 4 // 玩家名字和app name之间的间距
        
        // 计算 app name 的尺寸
        let nameFont = UIFont.systemFont(ofSize: 16, weight: .medium)
        let nameAttributes: [NSAttributedString.Key: Any] = [
            .font: nameFont,
            .foregroundColor: UIColor.white
        ]
        let nameRect = appName.boundingRect(
            with: CGSize(width: size.width, height: size.height),
            options: .usesLineFragmentOrigin,
            attributes: nameAttributes,
            context: nil
        )
        
        // 计算玩家名字的尺寸（如果有）
        var playerNameRect = CGRect.zero
        if !playerName.isEmpty {
            let playerNameFont = UIFont.systemFont(ofSize: 14, weight: .regular)
            let playerNameAttributes: [NSAttributedString.Key: Any] = [
                .font: playerNameFont,
                .foregroundColor: UIColor.white.withAlphaComponent(0.8)
            ]
            playerNameRect = playerName.boundingRect(
                with: CGSize(width: size.width, height: size.height),
                options: .usesLineFragmentOrigin,
                attributes: playerNameAttributes,
                context: nil
            )
        }
        
        // 计算总宽度和高度（包括内边距和玩家名字）
        let maxNameWidth = max(nameRect.width, playerNameRect.width)
        let totalWidth = iconSize + spacing + maxNameWidth + padding * 2
        let totalHeight = (playerNameRect.height > 0 ? playerNameRect.height + nameSpacing : 0) + nameRect.height + padding * 2
        
        // 右下角起始位置
        let startX = size.width - totalWidth - margin
        let startY = size.height - totalHeight - margin
        
        // 绘制黑色底框（圆角矩形）
        let backgroundRect = CGRect(x: startX, y: startY, width: totalWidth, height: totalHeight)
        UIColor.black.withAlphaComponent(0.7).setFill()
        let backgroundPath = UIBezierPath(roundedRect: backgroundRect, cornerRadius: 10)
        backgroundPath.fill()
        
        // 绘制 app icon
        if let icon = appIcon {
            let iconRect = CGRect(
                x: startX + padding,
                y: startY + padding + (totalHeight - padding * 2 - iconSize) / 2,
                width: iconSize,
                height: iconSize
            )
            icon.draw(in: iconRect)
        }
        
        // 绘制玩家名字（在app name上方，如果有）
        let textX = startX + padding + iconSize + spacing
        var currentTextY = startY + padding
        
        if !playerName.isEmpty {
            let playerNameFont = UIFont.systemFont(ofSize: 14, weight: .regular)
            let playerNameAttributes: [NSAttributedString.Key: Any] = [
                .font: playerNameFont,
                .foregroundColor: UIColor.white.withAlphaComponent(0.8)
            ]
            playerName.draw(
                in: CGRect(x: textX, y: currentTextY, width: playerNameRect.width, height: playerNameRect.height),
                withAttributes: playerNameAttributes
            )
            currentTextY += playerNameRect.height + nameSpacing
        }
        
        // 绘制 app name
        appName.draw(
            in: CGRect(x: textX, y: currentTextY, width: nameRect.width, height: nameRect.height),
            withAttributes: nameAttributes
        )
    }
    
    /// 生成本局游戏分享图片
    func generateGameResultImage(currentRound: Int, currentSpinInRound: Int, singleGameCoins: Int) -> UIImage? {
        guard let backgroundImage = UIImage(named: "share") else {
            print("❌ [分享图片] 无法加载 share.png 背景图")
            return nil
        }
        
        let size = backgroundImage.size
        let renderer = UIGraphicsImageRenderer(size: size)
        let localizationManager = LocalizationManager.shared
        
        return renderer.image { context in
            // 绘制背景图
            backgroundImage.draw(in: CGRect(origin: .zero, size: size))
            
            // 获取字体
            let isChinese = localizationManager.currentLanguage == "zh"
            let fontSize: CGFloat = 50
            let titleFontSize: CGFloat = 40
            let fontName: String?
            
            if isChinese {
                // 尝试使用中文字体名称
                fontName = "猫啃什锦黑"
            } else {
                // 尝试使用英文字体名称
                fontName = "Calistoga-Regular"
            }
            
            let font = UIFont(name: fontName ?? "", size: fontSize) ?? UIFont.boldSystemFont(ofSize: fontSize)
            let titleFont = UIFont(name: fontName ?? "", size: titleFontSize) ?? UIFont.boldSystemFont(ofSize: titleFontSize)
            
            // 设置文本属性（黑色，左对齐）
            let textColor = UIColor.black
            let coinsTextColor = UIColor.systemYellow // 累计金币使用黄色
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .left
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: textColor,
                .paragraphStyle: paragraphStyle
            ]
            
            // 累计金币数字使用黄色
            let coinsAttributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: coinsTextColor,
                .paragraphStyle: paragraphStyle
            ]
            
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: textColor,
                .paragraphStyle: paragraphStyle
            ]
            
            // 获取标题文本
            let progressTitle = localizationManager.localized("game_over.survival_rounds")
            let coinsTitle = localizationManager.localized("game_over.total_coins")
            
            // 绘制文本
            let progressText = "\(currentRound)-\(currentSpinInRound)"
            let coinsText = "\(singleGameCoins)"
            
            // 左上角起始位置
            let startX: CGFloat = 40
            let startY: CGFloat = 40
            let lineSpacing: CGFloat = 20
            
            // 计算标题和文本的尺寸
            let progressTitleRect = progressTitle.boundingRect(
                with: CGSize(width: size.width - startX * 2, height: size.height),
                options: .usesLineFragmentOrigin,
                attributes: titleAttributes,
                context: nil
            )
            
            let progressTextRect = progressText.boundingRect(
                with: CGSize(width: size.width - startX * 2, height: size.height),
                options: .usesLineFragmentOrigin,
                attributes: attributes,
                context: nil
            )
            
            let coinsTitleRect = coinsTitle.boundingRect(
                with: CGSize(width: size.width - startX * 2, height: size.height),
                options: .usesLineFragmentOrigin,
                attributes: titleAttributes,
                context: nil
            )
            
            let coinsTextRect = coinsText.boundingRect(
                with: CGSize(width: size.width - startX * 2, height: size.height),
                options: .usesLineFragmentOrigin,
                attributes: coinsAttributes,
                context: nil
            )
            
            // 绘制本局进度标题和文本（带底框）
            var currentY = startY
            let padding: CGFloat = 10
            
            // 第一组：本局进度
            let group1Width = max(progressTitleRect.width, progressTextRect.width) + padding * 2
            let group1Height = progressTitleRect.height + lineSpacing + progressTextRect.height + padding * 2
            let group1Rect = CGRect(x: startX - padding, y: currentY - padding, width: group1Width, height: group1Height)
            
            // 绘制半透明黑色底框（圆角矩形）
            UIColor.black.withAlphaComponent(0.5).setFill()
            let path1 = UIBezierPath(roundedRect: group1Rect, cornerRadius: 10)
            path1.fill()
            
            progressTitle.draw(
                in: CGRect(x: startX, y: currentY, width: size.width - startX * 2, height: progressTitleRect.height),
                withAttributes: titleAttributes
            )
            
            currentY += progressTitleRect.height + lineSpacing
            progressText.draw(
                in: CGRect(x: startX, y: currentY, width: size.width - startX * 2, height: progressTextRect.height),
                withAttributes: attributes
            )
            
            // 第二组：本局单局金币
            currentY += progressTextRect.height + lineSpacing * 2
            let group2Width = max(coinsTitleRect.width, coinsTextRect.width) + padding * 2
            let group2Height = coinsTitleRect.height + lineSpacing + coinsTextRect.height + padding * 2
            let group2Rect = CGRect(x: startX - padding, y: currentY - padding, width: group2Width, height: group2Height)
            
            // 绘制半透明黑色底框（圆角矩形）
            UIColor.black.withAlphaComponent(0.5).setFill()
            let path2 = UIBezierPath(roundedRect: group2Rect, cornerRadius: 10)
            path2.fill()
            
            coinsTitle.draw(
                in: CGRect(x: startX, y: currentY, width: size.width - startX * 2, height: coinsTitleRect.height),
                withAttributes: titleAttributes
            )
            
            currentY += coinsTitleRect.height + lineSpacing
            coinsText.draw(
                in: CGRect(x: startX, y: currentY, width: size.width - startX * 2, height: coinsTextRect.height),
                withAttributes: coinsAttributes
            )
            
            // 绘制左下角的挑战文本
            drawChallengeText(in: context, size: size, localizationManager: localizationManager, fontSize: fontSize)
            
            // 绘制右下角的 app icon 和 app name
            drawAppInfo(in: context, size: size, localizationManager: localizationManager)
        }
    }
}

