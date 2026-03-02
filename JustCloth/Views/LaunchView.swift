// LaunchView.swift
// 起動画面
// 「続けない」を選ぶと自分の国の国旗とステータスが表示される

import SwiftUI

struct LaunchView: View {
    let onContinue: () -> Void

    // 画面状態：最初の問いかけ or 「続けない」後の自国表示
    @State private var showMyCountry = false

    // countries.jsonのillegal件数を動的に取得
    private let illegalCount: Int = {
        CountryDataService.shared.loadCountries()
            .filter { $0.status == .illegal }
            .count
    }()

    // デバイスのロケールから自国を取得
    // 例: Locale.current.region?.identifier → "JP" → countries.jsonから検索
    private let myCountry: Country? = {
        let code = Locale.current.region?.identifier ?? ""
        return CountryDataService.shared.loadCountries()
            .first { $0.code.uppercased() == code.uppercased() }
    }()

    var body: some View {
        if showMyCountry, let country = myCountry {
            // 「続けない」を選んだ後：自国の国旗とステータスを表示
            MyCountryView(country: country, onBack: {
                showMyCountry = false
            }, onContinue: onContinue)
        } else {
            // 最初の問いかけ画面
            questionView
        }
    }

    // 「続けますか？」画面
    private var questionView: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 16) {
                Text("国旗を廃棄することは")
                    .font(.title)
                    .foregroundStyle(.secondary)

                Text("世界\(illegalCount)カ国で\n犯罪です。")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
            }

            Text("続けますか？")
                .font(.title2)
                .foregroundStyle(.secondary)
                .padding(.top, 8)

            Spacer()

            VStack(spacing: 16) {
                // 「続ける」ボタン：最初の反抗
                Button(action: onContinue) {
                    Text("続ける")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .frame(minWidth: 200)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white.opacity(0.15))
                .foregroundStyle(.primary)

                // 「続けない」ボタン：自国の国旗画面へ
                Button(action: { showMyCountry = true }) {
                    Text("続けない")
                        .font(.title3)
                        .frame(minWidth: 200)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
                .foregroundStyle(.secondary)
            }

            Spacer()
                .frame(height: 40)
        }
        .padding(48)
        .glassBackgroundEffect()
    }
}

// MARK: - 自国の国旗とステータスを表示するビュー

private struct MyCountryView: View {
    let country: Country
    let onBack: () -> Void      // 選択画面に戻る
    let onContinue: () -> Void  // そのまま続ける

    @State private var appeared = false

    private var statusColor: Color {
        switch country.status {
        case .legal:   return .green
        case .illegal: return .red
        case .gray:    return .yellow
        case .unknown: return .primary
        }
    }

    private var statusLabel: String {
        switch country.status {
        case .legal:   return "合法"
        case .illegal: return "違法"
        case .gray:    return "グレーゾーン"
        case .unknown: return "不明"
        }
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // 国旗
            FlagImageView(code: country.code)
                .frame(width: 240, height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(radius: 8)
                .allowsHitTesting(false)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)
                .animation(.easeOut(duration: 0.6).delay(0.1), value: appeared)

            // 国名とステータス
            VStack(spacing: 12) {
                Text(country.name)
                    .font(.title2)
                    .fontWeight(.bold)

                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 10, height: 10)
                    Text("国旗損壊：\(statusLabel)")
                        .font(.body)
                        .foregroundStyle(statusColor)
                        .fontWeight(.semibold)
                }

                if let penalty = country.penalty {
                    Text("罰則：\(penalty)")
                        .font(.body)
                        .foregroundStyle(.red.opacity(0.8))
                }

                if let description = country.description {
                    Text(description)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
            }
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.6).delay(0.3), value: appeared)

            Spacer()

            // ボタン群
            VStack(spacing: 12) {
                Button(action: onContinue) {
                    Text("それでも続ける")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .frame(minWidth: 200)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white.opacity(0.15))
                .foregroundStyle(.primary)

                Button(action: onBack) {
                    Text("戻る")
                        .font(.title3)
                        .frame(minWidth: 200)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
                .foregroundStyle(.secondary)
            }
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.6).delay(0.5), value: appeared)

            Spacer()
                .frame(height: 40)
        }
        .padding(48)
        .glassBackgroundEffect()
        .onAppear { appeared = true }
    }
}

#Preview(windowStyle: .automatic) {
    LaunchView(onContinue: {})
}
