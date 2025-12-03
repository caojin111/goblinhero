//
//  LocalizationManager.swift
//  A004
//
//  多语言管理器
//

import Foundation

class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: String = "en" {
        didSet {
            saveLanguage()
        }
    }
    
    private var translations: [String: Any] = [:]
    
    private init() {
        loadLanguage()
        loadTranslations()
    }
    
    /// 加载语言设置
    private func loadLanguage() {
        currentLanguage = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "en"
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
