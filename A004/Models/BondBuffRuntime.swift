//
//  BondBuffRuntime.swift
//  A004
//
//  运行时羁绊状态（供其他流程查询类型计数羁绊是否激活）
//

import Foundation

class BondBuffRuntime {
    static let shared = BondBuffRuntime()
    private init() {}
    
    /// 当前激活的“类型计数”羁绊名称键（如 human_3_bond 等）
    var activeTypeBonds: [String] = []
}

