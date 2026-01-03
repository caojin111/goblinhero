//
//  LocalizationManager.swift
//  A004
//
//  多语言管理器
//

import Foundation

class LocalizationManager: ObservableObject {
    static let shared: LocalizationManager = {
        let instance = LocalizationManager()
        return instance
    }()
    
    private var isInitializing: Bool = false
    @Published var currentLanguage: String = "en" {
        didSet {
            saveLanguage()
            // 只有在初始化完成后才通知签到配置管理器更新语言
            if !isInitializing {
                DailySignInConfigManager.shared.updateLanguage()
            }
        }
    }
    
    private var translations: [String: Any] = [:]
    
    private init() {
        // 标记正在初始化，避免触发 didSet 中的 updateLanguage
        isInitializing = true
        
        // 初始化操作（Bundle.main 访问需要在主线程）
        loadLanguage()
        loadTranslations()
        
        // 初始化完成
        isInitializing = false
    }
    
    /// 加载语言设置
    private func loadLanguage() {
        // 如果用户已经手动选择过语言，使用保存的语言
        if let savedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage") {
            currentLanguage = savedLanguage
            print("🌐 [多语言] 使用用户保存的语言: \(savedLanguage)")
            return
        }
        
        // 首次启动，根据系统语言自动设置
        let systemLanguage = detectSystemLanguage()
        currentLanguage = systemLanguage
        print("🌐 [多语言] 检测到系统语言，设置为: \(systemLanguage)")
    }
    
    /// 检测系统语言
    private func detectSystemLanguage() -> String {
        // 获取系统首选语言列表
        let preferredLanguages = Locale.preferredLanguages
        
        // 遍历首选语言列表，查找支持的语言
        for languageCode in preferredLanguages {
            // 提取语言代码（例如 "zh-Hans" -> "zh", "en-US" -> "en"）
            let languagePrefix = languageCode.prefix(2).lowercased()
            
            // 如果是中文（包括简体中文 zh-Hans 和繁体中文 zh-Hant）
            if languagePrefix == "zh" {
                print("🌐 [多语言] 检测到中文系统语言: \(languageCode)")
                return "zh"
            }
            
            // 如果是英文
            if languagePrefix == "en" {
                print("🌐 [多语言] 检测到英文系统语言: \(languageCode)")
                return "en"
            }
        }
        
        // 默认返回英文
        print("🌐 [多语言] 未检测到支持的语言，默认使用英文")
        return "en"
    }
    
    /// 保存语言设置
    private func saveLanguage() {
        UserDefaults.standard.set(currentLanguage, forKey: "selectedLanguage")
        objectWillChange.send()
    }
    
    /// 加载翻译文件
    private func loadTranslations() {
        guard let url = Bundle.main.url(forResource: "Localization", withExtension: "json") else {
            print("❌ [多语言] 找不到 Localization.json 文件")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            
            if let jsonDict = jsonObject as? [String: Any],
               let translationsDict = jsonDict["translations"] as? [String: Any] {
                translations = translationsDict
                print("✅ [多语言] 翻译文件加载成功")
            }
        } catch {
            print("❌ [多语言] 加载翻译文件失败: \(error)")
        }
    }
    
    /// 获取翻译文本
    func localized(_ key: String) -> String {
        return getValue(for: key) as? String ?? key
    }
    
    /// 获取翻译文本（支持嵌套键，如 "home.personal_records"）
    func localized(_ keys: String...) -> String {
        return getValue(for: keys.joined(separator: ".")) as? String ?? keys.joined(separator: ".")
    }
    
    /// 获取翻译值（支持任意类型）
    private func getValue(for key: String) -> Any? {
        guard let languageDict = translations[currentLanguage] as? [String: Any] else {
            return nil
        }
        
        let keyComponents = key.split(separator: ".")
        var currentDict = languageDict
        
        for component in keyComponents {
            if let nextDict = currentDict[String(component)] as? [String: Any] {
                currentDict = nextDict
            } else if let value = currentDict[String(component)] {
                return value
            } else {
                return nil
            }
        }
        
        return nil
    }
    
    /// 获取可用语言列表
    func getAvailableLanguages() -> [(code: String, name: String)] {
        guard let url = Bundle.main.url(forResource: "Localization", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
              let jsonDict = jsonObject as? [String: Any],
              let languagesDict = jsonDict["languages"] as? [String: String] else {
            return []
        }
        
        return languagesDict.map { (code: $0.key, name: $0.value) }
            .sorted { $0.code == "en" ? true : $1.code == "en" ? false : $0.name < $1.name }
    }
    
    /// 获取难度名称
    func getDifficultyName(_ difficulty: String) -> String {
        return localized("difficulty.\(difficulty)")
    }
}
