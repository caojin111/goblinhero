//
//  SymbolBookView.swift
//  A004
//
//  图鉴视图
//

import SwiftUI

struct SymbolBookView: View {
    @Binding var isPresented: Bool
    var viewModel: GameViewModel?
    @ObservedObject var localizationManager = LocalizationManager.shared
    @State private var selectedTab: BookTab = .symbols
    @State private var selectedSymbol: Symbol?
    @State private var showSymbolDetail: Bool = false
    
    enum BookTab {
        case symbols
        case bonds
    }
    
    // 获取自定义字体
    private func customFont(size: CGFloat) -> Font {
        return FontManager.shared.customFont(size: size)
    }
    
    // 获取type的多语言名称
    private func getTypeLocalizedName(_ type: String) -> String {
        var key = "symbol_type.\(type)"
        var localized = localizationManager.localized(key)
        if localized != key { return localized }
        let lowercasedType = type.lowercased()
        if lowercasedType != type {
            key = "symbol_type.\(lowercasedType)"
            localized = localizationManager.localized(key)
            if localized != key { return localized }
        }
        return type.capitalized
    }
    
    var body: some View {
        ZStack {
            // 背景
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            VStack(spacing: 0) {
                // 标题栏
                HStack {
                    Text(localizationManager.localized("book.title"))
                        .font(customFont(size: 28))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .textStroke()
                    
                    Spacer()
                    
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 15)
                
                // 分页切换
                HStack(spacing: 0) {
                    // 符号页
                    Button(action: {
                        selectedTab = .symbols
                    }) {
                        Text(localizationManager.localized("book.symbols"))
                            .font(customFont(size: 18))
                            .fontWeight(.bold)
                            .foregroundColor(selectedTab == .symbols ? .white : .white.opacity(0.6))
                            .textStroke()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                selectedTab == .symbols ?
                                    Color.white.opacity(0.2) : Color.clear
                            )
                    }
                    
                    // 羁绊页
                    Button(action: {
                        selectedTab = .bonds
                    }) {
                        Text(localizationManager.localized("book.bonds"))
                            .font(customFont(size: 18))
                            .fontWeight(.bold)
                            .foregroundColor(selectedTab == .bonds ? .white : .white.opacity(0.6))
                            .textStroke()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                selectedTab == .bonds ?
                                    Color.white.opacity(0.2) : Color.clear
                            )
                    }
                }
                .background(Color.white.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal, 20)
                .padding(.bottom, 15)
                
                // 内容区域
                ScrollView {
                    if selectedTab == .symbols {
                        SymbolsPageView(
                            onSymbolTap: { symbol in
                                selectedSymbol = symbol
                                showSymbolDetail = true
                            }
                        )
                    } else {
                        BondsPageView()
                    }
                }
            }
            .frame(maxWidth: 500)
            .frame(maxHeight: UIScreen.main.bounds.height * 0.85)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.black.opacity(0.9))
            )
            .padding(40)
            
            // 符号详情弹窗
            if showSymbolDetail, let symbol = selectedSymbol {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showSymbolDetail = false
                        }
                    
                    SymbolBuffTipView(symbol: symbol, isDismissing: false)
                        .onTapGesture {
                            showSymbolDetail = false
                        }
                }
            }
        }
        .transition(.scale)
    }
}

// MARK: - 符号页视图
struct SymbolsPageView: View {
    let onSymbolTap: (Symbol) -> Void
    @ObservedObject var localizationManager = LocalizationManager.shared
    
    // 获取自定义字体
    private func customFont(size: CGFloat) -> Font {
        return FontManager.shared.customFont(size: size)
    }
    
    // 按稀有度排序的符号列表
    private var sortedSymbols: [Symbol] {
        let allSymbols = SymbolLibrary.allSymbols
        let rarityOrder: [SymbolRarity] = [.common, .rare, .epic, .legendary]
        return rarityOrder.flatMap { rarity in
            allSymbols.filter { $0.rarity == rarity }
        }
    }
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10)
        ], spacing: 15) {
            ForEach(sortedSymbols) { symbol in
                SymbolBookItemView(symbol: symbol) {
                    onSymbolTap(symbol)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}

// MARK: - 符号图鉴项视图
struct SymbolBookItemView: View {
    let symbol: Symbol
    let onTap: () -> Void
    @ObservedObject var localizationManager = LocalizationManager.shared
    
    // 获取自定义字体
    private func customFont(size: CGFloat) -> Font {
        return FontManager.shared.customFont(size: size)
    }
    
    var body: some View {
        Button(action: {
            AudioManager.shared.playSoundEffect("click", fileExtension: "wav")
            onTap()
        }) {
            VStack(spacing: 8) {
                // 符号图标
                if symbol.isImageResource {
                    Image(symbol.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                } else {
                    Text(symbol.icon)
                        .font(.system(size: 50))
                }
                
                // 符号名称
                Text(localizationManager.localized("symbols.\(symbol.nameKey).name"))
                    .font(customFont(size: 14))
                    .foregroundColor(.white)
                    .textStroke()
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(localizationManager.currentLanguage == "en" ? 0.7 : 1.0) // 英文时允许缩小到70%
                    .frame(height: 36)
                
                // 稀有度标签
                Text(symbol.rarity.displayName)
                    .font(customFont(size: 10))
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(symbol.rarity.color.opacity(0.3))
                    )
                    .foregroundColor(.white)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(symbol.rarity.color.opacity(0.5), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 羁绊页视图
struct BondsPageView: View {
    @ObservedObject var localizationManager = LocalizationManager.shared
    
    // 获取自定义字体
    private func customFont(size: CGFloat) -> Font {
        return FontManager.shared.customFont(size: size)
    }
    
    // 获取所有羁绊
    private var allBonds: [BondBuff] {
        return BondBuffConfigManager.shared.getAllBondBuffs()
    }
    
    // 获取type的多语言名称
    private func getTypeLocalizedName(_ type: String) -> String {
        var key = "symbol_type.\(type)"
        var localized = localizationManager.localized(key)
        if localized != key { return localized }
        let lowercasedType = type.lowercased()
        if lowercasedType != type {
            key = "symbol_type.\(lowercasedType)"
            localized = localizationManager.localized(key)
            if localized != key { return localized }
        }
        return type.capitalized
    }
    
    // 根据符号ID获取符号
    private func getSymbol(byConfigId configId: Int) -> Symbol? {
        return SymbolConfigManager.shared.getSymbol(byConfigId: configId)
    }
    
    var body: some View {
        VStack(spacing: 15) {
            ForEach(allBonds) { bond in
                BondBookItemView(bond: bond, getSymbol: getSymbol, getTypeLocalizedName: getTypeLocalizedName)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}

// MARK: - 羁绊图鉴项视图
struct BondBookItemView: View {
    let bond: BondBuff
    let getSymbol: (Int) -> Symbol?
    let getTypeLocalizedName: (String) -> String
    @ObservedObject var localizationManager = LocalizationManager.shared
    
    // 获取自定义字体
    private func customFont(size: CGFloat) -> Font {
        return FontManager.shared.customFont(size: size)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 羁绊名称
            Text(bond.name)
                .font(customFont(size: 20))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .textStroke()
            
            // 羁绊描述
            RichTextView(bond.description, defaultColor: .white.opacity(0.9), font: customFont(size: 16), multilineTextAlignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            
            // 羁绊成员
            HStack(spacing: 8) {
                if let requiredType = bond.requiredType, let requiredCount = bond.requiredCount {
                    // 数量累加型羁绊：显示为"任意不同#类型成员*数量"
                    HStack(spacing: 4) {
                        Text(localizationManager.localized("book.any_different"))
                            .font(customFont(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("#\(getTypeLocalizedName(requiredType))")
                            .font(customFont(size: 14))
                            .foregroundColor(Color(hex: "#E74875"))
                        
                        Text(localizationManager.localized("book.member"))
                            .font(customFont(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("×\(requiredCount)")
                            .font(customFont(size: 14))
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                    }
                } else {
                    // 固定符号型羁绊：显示成员icon
                    ForEach(bond.requiredSymbolIds, id: \.self) { symbolId in
                        if let symbol = getSymbol(symbolId) {
                            if symbol.isImageResource {
                                Image(symbol.imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 40)
                            } else {
                                Text(symbol.icon)
                                    .font(.system(size: 40))
                            }
                        }
                    }
                }
            }
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(bond.cardColor.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(bond.cardColor.opacity(0.5), lineWidth: 2)
                )
        )
    }
}

#Preview {
    SymbolBookView(isPresented: .constant(true), viewModel: nil)
}
