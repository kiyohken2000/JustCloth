// WorldMapView.swift
// 世界地図画面
// 通常は点のみ表示、タップで国名を展開、もう一度タップで廃棄フローへ

import SwiftUI
import MapKit
import CoreLocation

struct WorldMapView: View {
    @Environment(AppModel.self) private var appModel

    // 全カ国廃棄済みになったときに呼ばれるコールバック
    var onEnding: (() -> Void)? = nil

    // 世界全体が見渡せるカメラ位置
    @State private var cameraPosition: MapCameraPosition = .camera(
        MapCamera(
            centerCoordinate: CLLocationCoordinate2D(latitude: 20, longitude: 0),
            distance: 15_000_000,
            heading: 0,
            pitch: 0
        )
    )

    // ズームの最小・最大距離（メートル）
    private let minDistance: Double = 1_000_000
    private let maxDistance: Double = 40_000_000

    // 現在国名を展開表示している国コード
    @State private var expandedCode: String? = nil

    // 現在のズーム距離（メートル）
    @State private var distance: Double = 15_000_000

    // 現在のカメラ中心座標（ズーム時に維持するために別途保持）
    @State private var centerCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 20, longitude: 0)

    // 廃棄フローを開く国
    @State private var selectedCountry: Country? = nil

    // 一括操作の確認ダイアログ表示制御
    @State private var showMarkAllDisposedConfirm = false
    @State private var showMarkAllUndisposedConfirm = false

    // BGM選択ポップオーバーの表示制御
    @State private var showBGMPicker = false

    // 全195カ国データ
    private let countries: [Country] = CountryDataService.shared.loadCountries()

    var body: some View {
        ZStack(alignment: .bottom) {
            // 上部ボタン群（左：一括操作、右：ズーム）
            VStack {
                HStack(alignment: .top) {
                    // 左上ボタン群（一括操作 + BGM選択）
                    VStack(spacing: 8) {
                        // 一括操作ボタン
                        VStack(spacing: 2) {
                            Button(action: { showMarkAllDisposedConfirm = true }) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18, weight: .medium))
                                    .frame(width: 44, height: 44)
                                    .foregroundStyle(.green)
                            }
                            Divider().frame(width: 30)
                            Button(action: { showMarkAllUndisposedConfirm = true }) {
                                Image(systemName: "arrow.counterclockwise.circle.fill")
                                    .font(.system(size: 18, weight: .medium))
                                    .frame(width: 44, height: 44)
                                    .foregroundStyle(.orange)
                            }
                        }
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

                        // BGM選択ボタン
                        Button(action: { showBGMPicker = true }) {
                            Image(systemName: appModel.selectedBGM == nil ? "music.note.list" : "music.note")
                                .font(.system(size: 18, weight: .medium))
                                .frame(width: 44, height: 44)
                                // BGM再生中は強調表示
                                .foregroundStyle(appModel.selectedBGM == nil ? .secondary : .primary)
                        }
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        // BGM選択ポップオーバー
                        .popover(isPresented: $showBGMPicker) {
                            BGMPickerView(
                                selectedBGM: appModel.selectedBGM,
                                onSelect: { track in
                                    appModel.selectedBGM = track.fileName
                                    showBGMPicker = false
                                }
                            )
                        }
                    }
                    .padding(.top, 20)
                    .padding(.leading, 20)

                    Spacer()

                    // ズームボタン（右上）
                    VStack(spacing: 2) {
                        Button(action: zoomIn) {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .medium))
                                .frame(width: 44, height: 44)
                        }
                        Divider().frame(width: 30)
                        Button(action: zoomOut) {
                            Image(systemName: "minus")
                                .font(.system(size: 18, weight: .medium))
                                .frame(width: 44, height: 44)
                        }
                    }
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .padding(.top, 20)
                    .padding(.trailing, 20)
                }
                Spacer()
            }
            .zIndex(1)

            Map(position: $cameraPosition) {
                ForEach(countries) { country in
                    let isDisposed = appModel.disposedCountryCodes.contains(country.code)
                    let isExpanded = expandedCode == country.code

                    Annotation(
                        "",
                        coordinate: coordinate(for: country.code),
                        anchor: .bottom
                    ) {
                        CountryAnnotationView(
                            country: country,
                            isDisposed: isDisposed,
                            isExpanded: isExpanded,
                            disposalMethod: appModel.disposalMethod(for: country.code),
                            onTap: {
                                handleTap(country: country, isDisposed: isDisposed, isExpanded: isExpanded)
                            },
                            onClose: {
                                expandedCode = nil
                            }
                        )
                    }
                }
            }
            .mapStyle(.standard(elevation: .flat, emphasis: .muted, pointsOfInterest: .excludingAll, showsTraffic: false))
            .ignoresSafeArea()
            // カメラが動くたびに中心座標を保存（ズーム時に位置を維持するため）
            .onMapCameraChange { context in
                centerCoordinate = context.camera.centerCoordinate
            }

            // 下部：進捗表示 / 全カ国廃棄済み時はエンディングボタン
            VStack(spacing: 12) {
                Text("\(appModel.disposedCountryCodes.count) / \(countries.count)カ国")
                    .font(.headline)
                    .foregroundStyle(.primary)

                if appModel.isAllDisposed {
                    // 全カ国廃棄済みになったらエンディングへのボタンを表示
                    Button(action: { onEnding?() }) {
                        Text("世界中の布を廃棄しました")
                            .font(.body)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.white.opacity(0.2))
                } else {
                    Text(expandedCode == nil ? "点をタップして国を選択" : "国名をタップして廃棄フローへ")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
            .padding(.bottom, 24)
        }
        .onAppear {
            // 起動時にUserDefaultsから復元したBGMを再開
            AudioService.shared.resumeBGMIfNeeded(named: appModel.selectedBGM)
        }
        .sheet(item: $selectedCountry) { country in
            FlagView(
                country: country,
                onDisposed: {
                    appModel.disposedCountryCodes.insert(country.code)
                    selectedCountry = nil
                    expandedCode = nil
                },
                onDismiss: {
                    selectedCountry = nil
                }
            )
        }
        // 全国を廃棄済みにする確認ダイアログ
        .confirmationDialog(
            "全\(countries.count)カ国を廃棄済みにしますか？",
            isPresented: $showMarkAllDisposedConfirm,
            titleVisibility: .visible
        ) {
            Button("廃棄済みにする", role: .destructive) {
                appModel.disposedCountryCodes = Set(countries.map { $0.code })
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("この操作は取り消せません。")
        }
        // 全国を未廃棄に戻す確認ダイアログ
        .confirmationDialog(
            "全\(countries.count)カ国を未廃棄に戻しますか？",
            isPresented: $showMarkAllUndisposedConfirm,
            titleVisibility: .visible
        ) {
            Button("未廃棄に戻す", role: .destructive) {
                appModel.disposedCountryCodes = []
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("廃棄済みの記録がすべてリセットされます。")
        }
    }

    // タップ処理
    // 未廃棄・未展開 → 吹き出し展開
    // 未廃棄・展開済み → 廃棄フローへ
    // 廃棄済み・未展開 → 情報吹き出し展開
    // 廃棄済み・展開済み → 閉じる
    private func handleTap(country: Country, isDisposed: Bool, isExpanded: Bool) {
        if isExpanded {
            if isDisposed {
                // 廃棄済みの展開済み → 閉じる
                expandedCode = nil
            } else {
                // 未廃棄の展開済み → 廃棄フローへ
                selectedCountry = country
                expandedCode = nil
            }
        } else {
            // 未展開 → 展開（他の展開中の吹き出しは閉じる）
            expandedCode = country.code
        }
    }

    // ズームイン（距離を半分に）
    private func zoomIn() {
        let newDistance = max(distance / 2, minDistance)
        distance = newDistance
        updateCamera(distance: newDistance)
    }

    // ズームアウト（距離を2倍に）
    private func zoomOut() {
        let newDistance = min(distance * 2, maxDistance)
        distance = newDistance
        updateCamera(distance: newDistance)
    }

    // 現在の中心座標を維持しつつ距離だけ変更
    // centerCoordinateはonMapCameraChangeで常に最新値を保持している
    private func updateCamera(distance: Double) {
        withAnimation(.easeInOut(duration: 0.4)) {
            cameraPosition = .camera(MapCamera(
                centerCoordinate: centerCoordinate,
                distance: distance,
                heading: 0,
                pitch: 0
            ))
        }
    }

    // 国コードから地図上の座標を返す
    private func coordinate(for code: String) -> CLLocationCoordinate2D {
        CountryDataService.shared.coordinate(forCode: code)
    }
}

// 地図上のAnnotation
// isExpanded=false → 小さな点のみ
// isExpanded=true  → 国名ラベルを表示
// isDisposed=true  → ステータス色の点（展開なし）
private struct CountryAnnotationView: View {
    let country: Country
    let isDisposed: Bool
    let isExpanded: Bool
    let disposalMethod: DisposalMethod?  // 廃棄済みの場合の廃棄方法
    let onTap: () -> Void
    let onClose: () -> Void

    var body: some View {
        if isExpanded {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    if isDisposed {
                        // 廃棄済み：情報表示吹き出し（タップで閉じる）
                        disposedInfoBubble
                            .onTapGesture { onClose() }
                    } else {
                        // 未廃棄：廃棄フロー誘導吹き出し
                        undisposedBubble
                    }

                    // ×ボタン（共通）
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.gray)
                            .frame(width: 20, height: 20)
                            .background(Color.gray.opacity(0.15), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .padding(5)
                }

                Triangle()
                    .fill(Color.white.opacity(0.95))
                    .frame(width: 10, height: 6)

                dot(color: isDisposed ? statusColor : .orange, size: 12)
            }
            .animation(.spring(duration: 0.2), value: isExpanded)
        } else {
            // 通常状態：点のみ（視線でフォーカス → ピンチで展開）
            Button(action: onTap) {
                // 視線が当たるヒットエリアを大きめに確保し、見た目は小さな点にする
                ZStack {
                    // タップ受付用の透明な大きめ領域（視線フォーカスを取りやすくする）
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 32, height: 32)

                    dot(color: isDisposed ? statusColor : .white, size: isDisposed ? 10 : 8)
                        .overlay(
                            Circle().stroke(isDisposed ? statusColor.opacity(0.6) : Color.gray.opacity(0.5), lineWidth: 1)
                        )
                }
            }
            .buttonStyle(.plain)
            // visionOSの視線フォーカス時にハイライトを表示
            .hoverEffect(.highlight)
            .animation(.spring(duration: 0.2), value: isExpanded)
        }
    }

    // 廃棄済み国の情報表示吹き出し
    private var disposedInfoBubble: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 廃棄方法に応じたエフェクト付き国旗
            disposedFlagThumbnail
                .frame(width: 140, height: 93)
                .allowsHitTesting(false)

            // 国名
            Text(country.name)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.black)
                .frame(maxWidth: 160)

            Divider()

            // 合法/違法ステータス
            HStack(spacing: 4) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(statusLabel)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(statusColor)
            }

            // 罰則
            if let penalty = country.penalty {
                Text("罰則：\(penalty)")
                    .font(.system(size: 11))
                    .foregroundStyle(.red.opacity(0.8))
                    .frame(maxWidth: 160)
            }

            // 説明
            if let description = country.description {
                Text(description)
                    .font(.system(size: 11))
                    .foregroundStyle(Color(white: 0.3))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: 160)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 20)   // ×ボタン分の余白
        .padding(.bottom, 10)
        .background(Color.white.opacity(0.97), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(statusColor.opacity(0.4), lineWidth: 1.5))
        .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
    }

    // 未廃棄国の廃棄フロー誘導吹き出し
    private var undisposedBubble: some View {
        VStack(spacing: 6) {
            // 国旗（WKWebViewがタップを吸収するため透明レイヤーで覆う）
            ZStack {
                FlagImageView(code: country.code)
                    .frame(width: 80, height: 53)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(0.3), lineWidth: 0.5))
                    .allowsHitTesting(false)

                Color.clear
                    .frame(width: 80, height: 53)
                    .contentShape(Rectangle())
                    .onTapGesture(perform: onTap)
            }

            Text(country.name)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.black)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 120)
                .onTapGesture(perform: onTap)
        }
        .padding(.horizontal, 10)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .background(Color.white.opacity(0.95), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.4), lineWidth: 1))
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
    }

    private func dot(color: Color, size: CGFloat) -> some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
    }

    private var statusColor: Color {
        switch country.status {
        case .legal:   return .green
        case .illegal: return .red
        case .gray:    return .yellow
        case .unknown: return .white
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

    // 廃棄方法に応じたエフェクト付きサムネイル（CompletedPhaseViewと同じ表現）
    @ViewBuilder
    private var disposedFlagThumbnail: some View {
        let w: CGFloat = 140
        let h: CGFloat = 93

        switch disposalMethod ?? .incinerate {
        case .incinerate:
            ZStack {
                FlagImageView(code: country.code)
                    .frame(width: w, height: h)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .saturation(0.0)
                    .brightness(-0.15)
                RoundedRectangle(cornerRadius: 4)
                    .fill(LinearGradient(
                        colors: [.black.opacity(0.6), .brown.opacity(0.3), .clear],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: w, height: h)
            }
            .shadow(color: .black.opacity(0.3), radius: 4)

        case .cut:
            ZStack {
                FlagImageView(code: country.code)
                    .frame(width: w, height: h)
                    .clipShape(Rectangle().path(in: CGRect(x: 0, y: h/2, width: w, height: h/2)))
                    .offset(x: 5, y: 4)
                FlagImageView(code: country.code)
                    .frame(width: w, height: h)
                    .clipShape(Rectangle().path(in: CGRect(x: 0, y: 0, width: w, height: h/2)))
                    .offset(x: -5, y: -4)
            }

        case .recycle:
            ZStack {
                FlagImageView(code: country.code)
                    .frame(width: w, height: h)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .blur(radius: 2)
                    .saturation(0.3)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.green.opacity(0.35))
                    .frame(width: w, height: h)
                Image(systemName: "arrow.3.trianglepath")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .shadow(color: .green.opacity(0.3), radius: 4)
        }
    }
}

// 吹き出しの三角形
private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - BGM選択ピッカー

/// ポップオーバーで表示するBGM選択UI
private struct BGMPickerView: View {
    let selectedBGM: String?
    let onSelect: (BGMTrack) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("BGM")
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 4)

            Divider()

            ForEach(BGMTrack.allCases) { track in
                let isCurrent = track.fileName == selectedBGM

                Button(action: { onSelect(track) }) {
                    HStack(spacing: 12) {
                        Image(systemName: isCurrent ? "checkmark" : "")
                            .font(.system(size: 14, weight: .bold))
                            .frame(width: 16)
                            .foregroundStyle(.primary)

                        Text(track.label)
                            .font(.body)
                            .foregroundStyle(.primary)

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .background(isCurrent ? Color.white.opacity(0.08) : Color.clear)
            }

            Divider()
                .padding(.bottom, 4)
        }
        .frame(minWidth: 180)
    }
}

#Preview(windowStyle: .automatic) {
    WorldMapView()
        .environment(AppModel())
}
