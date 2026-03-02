// ImmersiveView.swift
// Immersive Spaceに世界地図とアノテーションを表示する
// visionOS固有のImmersive Spaceで、Windowと同時に表示される（.mixed スタイル）

import SwiftUI
import RealityKit

struct ImmersiveView: View {
    // AppModelを通じてWindowと状態を共有
    // React NativeでいうuseContextで共有storeを読む感覚
    @Environment(AppModel.self) private var appModel

    // 廃棄済み国のマーカーEntity管理（コードをキーにする）
    @State private var markerEntities: [String: Entity] = [:]

    // フェーズ1の3カ国データ
    private let countries: [Country] = {
        let all = CountryDataService.shared.loadCountries()
        return ["JP", "US", "DE"].compactMap { code in all.first { $0.code == code } }
    }()

    var body: some View {
        RealityView { content, attachments in
            // 地図のルートエンティティを配置
            // 視界の正面やや下、約1.5m先に配置
            let mapRoot = Entity()
            mapRoot.position = [0, -0.3, -1.5]
            content.add(mapRoot)

            // 各国の選択可能なアノテーションEntityを生成
            for country in countries {
                // 国名ラベルのアタッチメントをEntityとして配置
                if let attachment = attachments.entity(for: country.code) {
                    // 地図上の位置に対応したオフセットで配置（正規化された座標）
                    attachment.position = normalizedPosition(for: country.code)
                    // タップ・ピンチ操作を受け取るためのInputTargetComponentを追加
                    attachment.components.set(InputTargetComponent())
                    // ホバーエフェクトを追加（視線を向けたときに光る）
                    attachment.components.set(HoverEffectComponent())
                    mapRoot.addChild(attachment)
                }
            }
        } attachments: {
            // 各国の選択ボタンをアタッチメントとして定義
            // RealityViewのアタッチメントはSwiftUI ViewをRealityKit空間に埋め込む仕組み
            ForEach(countries) { country in
                Attachment(id: country.code) {
                    ImmersiveCountryButton(
                        country: country,
                        isDisposed: appModel.disposedCountryCodes.contains(country.code)
                    ) {
                        // ピンチで選択 → AppModel経由でWindowに通知
                        appModel.selectedCountry = country
                    }
                }
            }
        }
        // 廃棄済み国が増えたらアノテーション色を更新
        .onChange(of: appModel.disposedCountryCodes) { _, _ in
            // アタッチメントはSwiftUI Viewなので自動で再描画される
        }
    }

    // 国コードからImmersive Space内の相対位置を返す
    // 簡略化した平面マッピング（フェーズ2でMapKitの座標変換に置き換える）
    private func normalizedPosition(for code: String) -> SIMD3<Float> {
        // 画面正面を基準にした相対配置（単位：メートル）
        switch code {
        case "JP": return [ 0.5,  0.0, 0.0]  // 右側（アジア）
        case "US": return [-0.4,  0.1, 0.0]  // 左側（北アメリカ）
        case "DE": return [ 0.1,  0.1, 0.0]  // 中央やや右（ヨーロッパ）
        default:   return [ 0.0,  0.0, 0.0]
        }
    }

}

// Immersive Space内の国選択ボタン
// visionOSの空間UIとして表示されるSwiftUI View
private struct ImmersiveCountryButton: View {
    let country: Country
    let isDisposed: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 6) {
                // ステータスバッジ
                Circle()
                    .fill(isDisposed ? statusColor : Color.white.opacity(0.3))
                    .frame(width: 16, height: 16)
                    .overlay(Circle().stroke(.white.opacity(0.6), lineWidth: 1))

                // 国名テキスト
                Text(country.name)
                    .font(.caption)
                    .fontWeight(isDisposed ? .regular : .semibold)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: 80)
            }
            .padding(10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .disabled(isDisposed)
        // ホバー時に拡大
        .hoverEffect(.highlight)
    }

    private var statusColor: Color {
        switch country.status {
        case .legal:   return .green
        case .illegal: return .red
        case .gray:    return .yellow
        case .unknown: return .white
        }
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
}
