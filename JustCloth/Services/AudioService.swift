// AudioService.swift
// SE・BGMの再生管理サービス
// AVAudioPlayerを使ってmp3ファイルを再生する
// React NativeでいうAudio APIのラッパーに相当

import AVFoundation

// MARK: - BGMトラック定義

/// BGMトラック（BGMなしを含む）
enum BGMTrack: CaseIterable, Identifiable {
    case none
    case bgm1
    case bgm2
    case bgm3
    case bgm4
    case bgm5

    var id: String { fileName ?? "none" }

    /// ファイル名（noneはnil）
    var fileName: String? {
        switch self {
        case .none: return nil
        case .bgm1: return "bgm1"
        case .bgm2: return "bgm2"
        case .bgm3: return "bgm3"
        case .bgm4: return "bgm4"
        case .bgm5: return "bgm5"
        }
    }

    /// UI表示名
    var label: String {
        switch self {
        case .none: return "なし"
        case .bgm1: return "BGM 1"
        case .bgm2: return "BGM 2"
        case .bgm3: return "BGM 3"
        case .bgm4: return "BGM 4"
        case .bgm5: return "BGM 5"
        }
    }

    /// AppModelのselectedBGM文字列からBGMTrackを生成
    static func from(fileName: String?) -> BGMTrack {
        guard let name = fileName else { return .none }
        return BGMTrack.allCases.first { $0.fileName == name } ?? .none
    }
}

// MARK: - AudioService

/// アプリ全体の音声再生を管理するシングルトン
@MainActor
class AudioService {
    static let shared = AudioService()

    // 各SEのプレイヤー（廃棄方法ごと）
    private var burnPlayer: AVAudioPlayer?
    private var cutPlayer: AVAudioPlayer?
    private var recyclingPlayer: AVAudioPlayer?
    private var tapPlayer: AVAudioPlayer?

    // BGM用プレイヤー（1つだけ。切り替え時に差し替える）
    private var bgmPlayer: AVAudioPlayer?

    private init() {
        // 各SEをプリロード（遅延なし再生のため）
        burnPlayer      = makePlayer(named: "burn")
        cutPlayer       = makePlayer(named: "cut")
        recyclingPlayer = makePlayer(named: "recycling")
        tapPlayer       = makePlayer(named: "tap")
    }

    // MARK: - SE再生

    /// 廃棄方法に対応するSEを再生
    func playDisposalSE(for method: DisposalMethod) {
        switch method {
        case .incinerate:
            play(player: &burnPlayer, named: "burn")
        case .cut:
            play(player: &cutPlayer, named: "cut")
        case .recycle:
            play(player: &recyclingPlayer, named: "recycling")
        }
    }

    /// タップ音を再生（国選択・ボタン操作時）
    func playTapSE() {
        play(player: &tapPlayer, named: "tap")
    }

    // MARK: - BGM再生

    /// BGMを切り替える（nil = 停止）
    /// AppModelのselectedBGMのdidSetから呼ばれる
    func playBGM(named name: String?) {
        // 現在のBGMを停止
        bgmPlayer?.stop()
        bgmPlayer = nil

        guard let name = name else { return }

        // 新しいBGMをロードしてループ再生
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else {
            print("⚠️ AudioService: \(name).mp3 が見つかりません")
            return
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1  // 無限ループ
            player.volume = 0.5        // BGMはSEより小さめ
            player.prepareToPlay()
            player.play()
            bgmPlayer = player
        } catch {
            print("⚠️ AudioService: \(name).mp3 の読み込みに失敗しました: \(error)")
        }
    }

    /// アプリ起動時にUserDefaultsから復元したBGMを再開する
    func resumeBGMIfNeeded(named name: String?) {
        // すでに再生中なら何もしない
        guard bgmPlayer == nil else { return }
        playBGM(named: name)
    }

    // MARK: - Private

    /// プレイヤーを再生（必要に応じて再初期化）
    private func play(player: inout AVAudioPlayer?, named name: String) {
        // すでに再生中なら頭から再生しなおす
        if let p = player {
            p.currentTime = 0
            p.play()
        } else {
            // プレイヤーがnilの場合は再生成してから再生
            player = makePlayer(named: name)
            player?.play()
        }
    }

    /// Bundleからmp3ファイルを読み込んでAVAudioPlayerを生成
    private func makePlayer(named name: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else {
            print("⚠️ AudioService: \(name).mp3 が見つかりません")
            return nil
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            return player
        } catch {
            print("⚠️ AudioService: \(name).mp3 の読み込みに失敗しました: \(error)")
            return nil
        }
    }
}
