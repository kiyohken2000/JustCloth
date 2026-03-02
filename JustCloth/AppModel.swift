// AppModel.swift
// アプリ全体の状態管理
// Immersive SpaceとWindowGroup間でデータを共有するための@Observable クラス
// React NativeでいうReduxのstoreやContext providerに相当

import SwiftUI

@MainActor
@Observable
class AppModel {
    let immersiveSpaceID = "ImmersiveSpace"

    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }

    var immersiveSpaceState = ImmersiveSpaceState.closed

    // 廃棄済み国コードのセット（UserDefaultsで永続化）
    // セッターで自動的にUserDefaultsへ保存される
    var disposedCountryCodes: Set<String> {
        didSet {
            // Setは直接保存できないのでArrayに変換して保存
            UserDefaults.standard.set(Array(disposedCountryCodes), forKey: "disposedCountryCodes")
        }
    }

    // 現在選択中の国（Immersive Spaceからの選択を受け取る）
    var selectedCountry: Country? = nil

    // 国コード → 廃棄方法の記録（UserDefaultsで永続化）
    // 例: ["JP": "incinerate", "US": "cut"]
    var disposalMethods: [String: String] {
        didSet {
            UserDefaults.standard.set(disposalMethods, forKey: "disposalMethods")
        }
    }

    // 国コードの廃棄方法を保存するヘルパー
    func recordDisposal(code: String, method: DisposalMethod) {
        disposalMethods[code] = method.rawValue
    }

    // 国コードの廃棄方法を取得するヘルパー
    func disposalMethod(for code: String) -> DisposalMethod? {
        guard let raw = disposalMethods[code] else { return nil }
        return DisposalMethod(rawValue: raw)
    }

    // 選択中のBGM（nilはBGMなし。UserDefaultsで永続化）
    // 値は "bgm1"〜"bgm5" または nil
    var selectedBGM: String? {
        didSet {
            UserDefaults.standard.set(selectedBGM, forKey: "selectedBGM")
            AudioService.shared.playBGM(named: selectedBGM)
        }
    }

    // 全カ国数（エンディング判定に使う）
    let totalCountryCount: Int = CountryDataService.shared.loadCountries().count

    init() {
        // UserDefaultsから前回の廃棄済み国コードを復元
        let saved = UserDefaults.standard.stringArray(forKey: "disposedCountryCodes") ?? []
        self.disposedCountryCodes = Set(saved)

        // UserDefaultsからBGM設定を復元（didSetは走らないので直接代入）
        self.selectedBGM = UserDefaults.standard.string(forKey: "selectedBGM")

        // UserDefaultsから廃棄方法の記録を復元
        self.disposalMethods = UserDefaults.standard.dictionary(forKey: "disposalMethods") as? [String: String] ?? [:]
    }

    // 全カ国廃棄済みかどうか
    var isAllDisposed: Bool {
        disposedCountryCodes.count >= totalCountryCount
    }
}
