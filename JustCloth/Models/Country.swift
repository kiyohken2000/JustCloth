// Country.swift
// 国データモデルの定義
// React NativeでいうTypeScriptの型定義に相当する

import Foundation

// 国旗損壊に関する法的ステータス
enum LegalStatus: String, Codable {
    case legal    // 合法
    case illegal  // 違法
    case gray     // グレーゾーン・議論中
    case unknown  // 不明

    // 地図上の色付けに使うラベル
    var displayLabel: String {
        switch self {
        case .legal:   return "合法"
        case .illegal: return "違法"
        case .gray:    return "グレーゾーン"
        case .unknown: return "不明"
        }
    }
}

// 各国データの構造体
// React NativeでいうJSONデータをマッピングするinterface/typeに相当
struct Country: Codable, Identifiable {
    // Identifiableに必要なid（codeを流用）
    var id: String { code }

    let code: String        // ISO 3166-1 alpha-2国コード（例: "JP"）
    let name: String        // 国名（日本語）
    let population: String  // 人口（表示用文字列）
    let status: LegalStatus // 法的ステータス
    let description: String? // 法律・判例・エピソードの説明文
    let penalty: String?    // 罰則（違法な国のみ）
    let closing: String?    // 締めの一文

    // 国旗SVGのファイル名（例: "jp.svg"）
    var flagFileName: String {
        return code.lowercased() + ".svg"
    }
}

// JSONファイルのルート構造
// countries.json の { "countries": [...] } に対応
struct CountriesData: Codable {
    let countries: [Country]
}
