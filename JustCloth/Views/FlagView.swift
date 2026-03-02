// FlagView.swift
// 国旗表示 + 廃棄方法選択画面
// 国旗SVGを表示し、警告を挟んだ後に焼却/裁断/リサイクルを選択させる

import SwiftUI
import RealityKit

// 廃棄方法（rawValueはUserDefaults保存用）
enum DisposalMethod: String, CaseIterable {
    case incinerate  // 焼却
    case cut         // 裁断
    case recycle     // リサイクル

    var label: String {
        switch self {
        case .incinerate: return "焼却"
        case .cut:        return "裁断"
        case .recycle:    return "リサイクル"
        }
    }

    var icon: String {
        switch self {
        case .incinerate: return "flame"
        case .cut:        return "scissors"
        case .recycle:    return "arrow.3.trianglepath"
        }
    }
}

// FlagViewの表示フェーズ
private enum FlagViewPhase {
    case warning       // 警告画面（廃棄前）
    case selectMethod  // 廃棄方法選択
    case disposing     // 廃棄中（エフェクト再生）
    case completed     // 廃棄完了メッセージ
    case info          // 情報表示
}

struct FlagView: View {
    let country: Country
    let onDisposed: () -> Void  // 廃棄完了コールバック
    let onDismiss: () -> Void   // キャンセルコールバック

    @Environment(AppModel.self) private var appModel
    @State private var phase: FlagViewPhase = .warning
    @State private var selectedMethod: DisposalMethod? = nil

    var body: some View {
        VStack(spacing: 0) {
            switch phase {
            case .warning:
                WarningPhaseView(
                    country: country,
                    onProceed: {
                        // 「それでも廃棄する」「つまらないですね。廃棄する」
                        phase = .selectMethod
                    },
                    onDismiss: onDismiss
                )

            case .selectMethod:
                SelectMethodPhaseView(country: country) { method in
                    selectedMethod = method
                    phase = .disposing
                }

            case .disposing:
                DisposingPhaseView(country: country, method: selectedMethod ?? .incinerate) {
                    phase = .completed
                }

            case .completed:
                CompletedPhaseView(country: country, method: selectedMethod ?? .incinerate) {
                    phase = .info
                }

            case .info:
                InfoPhaseView(country: country) {
                    // 廃棄完了時に使用した廃棄方法を記録
                    if let method = selectedMethod {
                        appModel.recordDisposal(code: country.code, method: method)
                    }
                    onDisposed()
                }
            }
        }
        .frame(minWidth: 480, minHeight: 560)
        .padding(40)
        .glassBackgroundEffect()
    }
}

// MARK: - 警告フェーズ

private struct WarningPhaseView: View {
    let country: Country
    let onProceed: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // 国旗SVG表示
            FlagImageView(code: country.code)
                .frame(width: 240, height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(radius: 8)

            // 警告文（合法・違法・グレーで分岐）
            VStack(spacing: 12) {
                switch country.status {
                case .illegal:
                    Text("警告")
                        .font(.headline)
                        .foregroundStyle(.red)
                    Text("\(country.name)では\nこの行為は\(country.penalty ?? "罰則あり")に\n相当します。")
                        .font(.title3)
                        .multilineTextAlignment(.center)
                    Text("それでも廃棄しますか？")
                        .foregroundStyle(.secondary)

                case .legal:
                    Text("\(country.name)では\nこの行為は合法です。")
                        .font(.title3)
                        .multilineTextAlignment(.center)
                    Text("つまらないですね。")
                        .foregroundStyle(.secondary)
                        .italic()

                case .gray:
                    Text("\(country.name)では\nこの行為はグレーゾーンです。")
                        .font(.title3)
                        .multilineTextAlignment(.center)

                case .unknown:
                    Text("\(country.name)の法律は不明です。")
                        .font(.title3)
                        .multilineTextAlignment(.center)
                }
            }

            Spacer()

            // アクションボタン
            VStack(spacing: 12) {
                Button(action: onProceed) {
                    Text(country.status == .illegal ? "それでも廃棄する" : "廃棄する")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .frame(minWidth: 240)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white.opacity(0.15))

                Button(action: onDismiss) {
                    Text("やめる")
                        .frame(minWidth: 240)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
                .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - 廃棄方法選択フェーズ

private struct SelectMethodPhaseView: View {
    let country: Country
    let onSelect: (DisposalMethod) -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // 国旗表示
            FlagImageView(code: country.code)
                .frame(width: 200, height: 133)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(radius: 6)

            Text("この布の廃棄方法を\n選んでください。")
                .font(.title2)
                .multilineTextAlignment(.center)

            // 廃棄方法ボタン
            VStack(spacing: 12) {
                ForEach(DisposalMethod.allCases, id: \.self) { method in
                    Button {
                        // ボタンタップ時にタップ音を再生
                        AudioService.shared.playTapSE()
                        onSelect(method)
                    } label: {
                        Label(method.label, systemImage: method.icon)
                            .font(.title3)
                            .frame(minWidth: 240)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                }
            }

            Spacer()
        }
    }
}

// MARK: - 廃棄中フェーズ（RealityKitパーティクルエフェクト）

private struct DisposingPhaseView: View {
    let country: Country
    let method: DisposalMethod
    let onComplete: () -> Void

    // 画面エフェクト用のアニメーション状態
    @State private var flagScale: CGFloat = 1.0
    @State private var flagOpacity: Double = 1.0
    @State private var cutRotation: Double = 0

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // 国旗＋パーティクルエフェクトを重ねて表示
            ZStack {
                // 国旗（背景）
                FlagImageView(code: country.code)
                    .frame(width: 240, height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(radius: 8)
                    .scaleEffect(flagScale)
                    .opacity(flagOpacity)
                    // 裁断：回転しながら消える
                    .rotationEffect(.degrees(method == .cut ? cutRotation : 0))

                // RealityKitパーティクルを国旗の上に重ねる
                RealityView { content in
                    let emitter = ParticleEffects.makeEmitter(for: method)
                    emitter.position = [0, 0, -0.1]
                    content.add(emitter)
                }
                .frame(width: 240, height: 240)
                .allowsHitTesting(false)

            }

            Text("\(method.label)中…")
                .font(.title3)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .onAppear {
            // 廃棄方法に応じたSEを再生
            AudioService.shared.playDisposalSE(for: method)

            // 廃棄方法ごとのアニメーション開始
            startAnimation()

            // 3秒後に次フェーズへ（エフェクトが十分に表示される時間）
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                onComplete()
            }
        }
    }

    // 廃棄方法ごとのアニメーション
    private func startAnimation() {
        switch method {
        case .incinerate:
            // 焼却：国旗が縮んで消える
            withAnimation(.easeIn(duration: 1.5).delay(1.5)) {
                flagScale = 0.6
                flagOpacity = 0.0
            }

        case .cut:
            // 裁断：国旗が回転しながら消える
            withAnimation(.linear(duration: 1.8).delay(0.4)) {
                cutRotation = 15
            }
            withAnimation(.easeIn(duration: 1.2).delay(0.5)) {
                flagOpacity = 0.0
                flagScale = 0.85
            }

        case .recycle:
            // リサイクル：国旗が縮みながら消える
            withAnimation(.easeOut(duration: 1.5).delay(1.0)) {
                flagScale = 0.7
                flagOpacity = 0.0
            }
        }
    }
}

// MARK: - 廃棄完了メッセージフェーズ

private struct CompletedPhaseView: View {
    let country: Country
    let method: DisposalMethod
    let onNext: () -> Void

    @State private var appeared = false

    // 廃棄方法ごとのメッセージ（仕様通り）
    private var completionText: (main: String, sub: String) {
        switch method {
        case .incinerate:
            return ("布は布になりました。", "（もともと布でした）")
        case .cut:
            return ("布は2枚の布になりました。", "（もともと布でした）")
        case .recycle:
            return ("布は別の何かになります。", "（もともと布でした）")
        }
    }

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            // 廃棄後の国旗イメージ（方法ごとに視覚的に表現）
            disposedFlagImage
                .opacity(appeared ? 1 : 0)
                .animation(.easeIn(duration: 0.6), value: appeared)

            VStack(spacing: 16) {
                Text("\(method.label)完了。")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text(completionText.main)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(completionText.sub)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onNext) {
                Text("続ける")
                    .font(.title3)
                    .frame(minWidth: 200)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(.white.opacity(0.15))
        }
        .onAppear { appeared = true }
    }

    // 廃棄方法ごとの「廃棄後」国旗ビジュアル
    @ViewBuilder
    private var disposedFlagImage: some View {
        switch method {
        case .incinerate:
            // 焼却：モノクロ化＋黒のオーバーレイで焼け焦げた表現
            ZStack {
                FlagImageView(code: country.code)
                    .frame(width: 200, height: 133)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .saturation(0.0)          // モノクロ
                    .brightness(-0.15)
                    .allowsHitTesting(false)

                // 焦げた質感のオーバーレイ
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [.black.opacity(0.6), .brown.opacity(0.3), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200, height: 133)
            }
            .shadow(color: .black.opacity(0.4), radius: 6)

        case .cut:
            // 裁断：2枚に分割されたような表現（上下にズレて重なる）
            ZStack {
                // 下半分（ずらして表示）
                FlagImageView(code: country.code)
                    .frame(width: 200, height: 133)
                    .clipShape(
                        Rectangle().path(in: CGRect(x: 0, y: 66, width: 200, height: 67))
                    )
                    .offset(x: 8, y: 6)
                    .shadow(radius: 3)
                    .allowsHitTesting(false)

                // 上半分（ずらして表示）
                FlagImageView(code: country.code)
                    .frame(width: 200, height: 133)
                    .clipShape(
                        Rectangle().path(in: CGRect(x: 0, y: 0, width: 200, height: 67))
                    )
                    .offset(x: -8, y: -6)
                    .shadow(radius: 3)
                    .allowsHitTesting(false)
            }
            .frame(width: 220, height: 155)

        case .recycle:
            // リサイクル：ぼかし＋緑ティントで「何か別のもの」感
            ZStack {
                FlagImageView(code: country.code)
                    .frame(width: 200, height: 133)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .blur(radius: 3)
                    .saturation(0.3)
                    .allowsHitTesting(false)

                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.green.opacity(0.35))
                    .frame(width: 200, height: 133)

                // リサイクルマーク
                Image(systemName: "arrow.3.trianglepath")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(.white.opacity(0.9))
                    .shadow(radius: 4)
            }
            .shadow(color: .green.opacity(0.3), radius: 8)
        }
    }
}

// MARK: - 情報表示フェーズ

private struct InfoPhaseView: View {
    let country: Country
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 12) {
                Text(country.name)
                    .font(.title2)
                    .fontWeight(.bold)

                Text("人口：\(country.population)")
                    .foregroundStyle(.secondary)

                Divider()

                // 国旗損壊の法的ステータス
                HStack {
                    Text("国旗損壊：")
                    Text(legalStatusText)
                        .foregroundStyle(legalStatusColor)
                        .fontWeight(.semibold)
                }

                if let penalty = country.penalty {
                    Text("罰則：\(penalty)")
                        .foregroundStyle(.red.opacity(0.8))
                }

                Divider()

                // 説明文
                if let description = country.description {
                    Text(description)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)
                }

                // 締めの一文
                if let closing = country.closing {
                    Text(closing)
                        .font(.body)
                        .italic()
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }

                Divider()

                // 仕様で必ず表示する素材情報
                Text("素材：ポリエステル65% 綿35%")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Button(action: onClose) {
                Text("地図に戻る")
                    .font(.title3)
                    .frame(minWidth: 200)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(.white.opacity(0.15))
        }
    }

    private var legalStatusText: String {
        switch country.status {
        case .legal:   return "合法"
        case .illegal: return "違法"
        case .gray:    return "グレーゾーン（議論中）"
        case .unknown: return "不明"
        }
    }

    private var legalStatusColor: Color {
        switch country.status {
        case .legal:   return .green
        case .illegal: return .red
        case .gray:    return .yellow
        case .unknown: return .primary
        }
    }
}

// MARK: - 国旗SVG表示ビュー
// UIImage/SwiftUI ImageはSVG非対応のため、WKWebViewでHTMLとしてレンダリングする
// React NativeでいうWebViewコンポーネント + UIViewRepresentableに相当

import WebKit

struct FlagImageView: View {
    let code: String

    var body: some View {
        if let svgString = loadSVGString(code: code) {
            SVGWebView(svgString: svgString)
        } else {
            // フォールバック：国コードテキスト表示
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.gray.opacity(0.2))
                Text(code)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // BundleからSVGテキストを読み込む
    private func loadSVGString(code: String) -> String? {
        let fileName = code.lowercased()
        // Flags/ サブディレクトリなしでフラットに配置されている
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "svg") else {
            return nil
        }
        return try? String(contentsOf: url, encoding: .utf8)
    }
}

// WKWebViewをSwiftUIに橋渡しするラッパー
// React NativeでいうUIViewRepresentableはViewRepresentableに相当
private struct SVGWebView: UIViewRepresentable {
    let svgString: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // SVGをHTMLでラップして表示
        // viewBox全体をfitさせるためwidth/height=100%でラップ
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
          html, body { margin: 0; padding: 0; background: transparent; }
          svg { width: 100%; height: 100%; display: block; }
        </style>
        </head>
        <body>
        \(svgString)
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }
}
