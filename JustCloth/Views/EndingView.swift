// EndingView.swift
// 全カ国制覇エンディング画面
// 全ての国の布を廃棄したときに表示される

import SwiftUI

struct EndingView: View {
    let onRestart: () -> Void  // 最初からやり直すコールバック

    // 登場アニメーション用
    @State private var appeared = false

    // 全カ国データからステータス別カ国数を集計
    private var stats: (legal: Int, illegal: Int, gray: Int, unknown: Int) {
        let countries = CountryDataService.shared.loadCountries()
        let legal   = countries.filter { $0.status == .legal }.count
        let illegal = countries.filter { $0.status == .illegal }.count
        let gray    = countries.filter { $0.status == .gray }.count
        let unknown = countries.filter { $0.status == .unknown }.count
        return (legal, illegal, gray, unknown)
    }

    // 合法カ国が過半数かどうかのメッセージ用
    private var legalMajority: Bool {
        let total = stats.legal + stats.illegal + stats.gray + stats.unknown
        return stats.legal > total / 2
    }

    var body: some View {
        VStack(spacing: 48) {
            Spacer()

            VStack(spacing: 24) {
                // メインメッセージ
                Text("195カ国の布を\n廃棄しました。")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.easeOut(duration: 0.8).delay(0.2), value: appeared)

                // 統計内訳（仕様書: 合法/違法/グレーゾーン/不明 のカ国数）
                VStack(alignment: .center, spacing: 8) {
                    statRow(label: "合法", count: stats.legal, color: .green, delay: 0.6)
                    statRow(label: "違法", count: stats.illegal, color: .red, delay: 0.8)
                    statRow(label: "グレーゾーン", count: stats.gray, color: .yellow, delay: 1.0)
                    statRow(label: "不明", count: stats.unknown, color: .white.opacity(0.6), delay: 1.2)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.8).delay(0.5), value: appeared)
            }

            // 締めのメッセージ（仕様書: 世界の半分以上の国で〜）
            VStack(spacing: 16) {
                Divider()
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(1.4), value: appeared)

                // コンセプトの核心
                Text("布は布です。")
                    .font(.title2)
                    .fontWeight(.bold)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.8).delay(2.2), value: appeared)

                Divider()
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(1.4), value: appeared)
            }
            .padding(.horizontal)

            Spacer()

            // やり直しボタン
            Button(action: onRestart) {
                Text("もう一度やり直す")
                    .font(.title3)
                    .frame(minWidth: 240)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .foregroundStyle(.secondary)
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.8).delay(2.8), value: appeared)

            Spacer()
                .frame(height: 40)
        }
        .padding(48)
        .glassBackgroundEffect()
        .onAppear {
            appeared = true
        }
    }

    // 統計行（ラベル・カ国数・色のセット）
    @ViewBuilder
    private func statRow(label: String, count: Int, color: Color, delay: Double) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text("\(label)：\(count)カ国")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview(windowStyle: .automatic) {
    EndingView(onRestart: {})
}
