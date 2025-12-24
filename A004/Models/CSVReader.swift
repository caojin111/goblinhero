//
//  CSVReader.swift
//  A004
//
//  CSV文件读取工具
//

import Foundation

class CSVReader {
    /// 读取CSV文件并返回字典数组（支持UTF-8和UTF-8-BOM）
    static func readCSV(fileName: String) -> [[String: String]]? {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "csv") else {
            print("❌ [CSV读取] 找不到文件: \(fileName).csv")
            return nil
        }
        
        // 尝试读取文件数据
        guard let data = try? Data(contentsOf: url) else {
            print("❌ [CSV读取] 无法读取文件数据: \(fileName).csv")
            return nil
        }
        
        // 移除UTF-8-BOM（如果存在）
        let bom: [UInt8] = [0xEF, 0xBB, 0xBF]
        let dataWithoutBOM: Data
        if data.starts(with: bom) {
            dataWithoutBOM = data.subdata(in: bom.count..<data.count)
        } else {
            dataWithoutBOM = data
        }
        
        // 转换为字符串
        guard let content = String(data: dataWithoutBOM, encoding: .utf8) else {
            print("❌ [CSV读取] 无法将数据转换为UTF-8字符串: \(fileName).csv")
            return nil
        }
        
        return parseCSV(content: content)
    }
    
    /// 解析CSV内容
    private static func parseCSV(content: String) -> [[String: String]] {
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard !lines.isEmpty else { return [] }
        
        // 解析表头
        let headers = parseCSVLine(lines[0])
        guard !headers.isEmpty else { return [] }
        
        // 解析数据行
        var result: [[String: String]] = []
        for i in 1..<lines.count {
            let values = parseCSVLine(lines[i])
            guard values.count == headers.count else {
                print("⚠️ [CSV读取] 第\(i+1)行列数不匹配，跳过")
                continue
            }
            
            var dict: [String: String] = [:]
            for (index, header) in headers.enumerated() {
                dict[header] = values[index]
            }
            result.append(dict)
        }
        
        return result
    }
    
    /// 解析CSV行（处理引号内的逗号和转义引号）
    private static func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        var chars = Array(line)
        var i = 0
        
        while i < chars.count {
            let char = chars[i]
            
            if char == "\"" {
                // 检查是否是转义的引号（两个连续的引号）
                if i + 1 < chars.count && chars[i + 1] == "\"" {
                    // 转义的引号，添加一个引号到current
                    current.append("\"")
                    i += 2 // 跳过两个引号
                    continue
                } else {
                    // 普通的引号，切换引号状态
                    inQuotes.toggle()
                }
            } else if char == "," && !inQuotes {
                // 字段分隔符（不在引号内）
                result.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                // 普通字符
                current.append(char)
            }
            
            i += 1
        }
        
        // 添加最后一个字段
        result.append(current.trimmingCharacters(in: .whitespaces))
        
        // 移除字段两端的引号（但保留内部的转义引号）
        return result.map { field in
            var trimmed = field.trimmingCharacters(in: .whitespaces)
            // 如果字段以引号开始和结束，移除它们
            if trimmed.hasPrefix("\"") && trimmed.hasSuffix("\"") && trimmed.count > 1 {
                trimmed = String(trimmed.dropFirst().dropLast())
            }
            return trimmed
        }
    }
    
    /// 解析用引号分割的ID列表（如 "1,2,3"）
    static func parseIDList(_ value: String) -> [Int] {
        guard !value.isEmpty else { return [] }
        
        // 移除引号并分割
        let cleaned = value.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        return cleaned.split(separator: ",")
            .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
    }
}
