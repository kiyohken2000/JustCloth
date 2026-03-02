// ContentView.swift
// アプリのエントリーポイント
// 現在の画面状態を管理し、起動画面から遷移を制御する
// React NativeでいうNavigatorのルートに相当

import SwiftUI

// アプリ全体の画面状態
enum AppScreen {
    case launch    // 起動画面（「続けますか？」）
    case worldMap  // 世界地図
    case ending    // 全カ国制覇エンディング
}

struct ContentView: View {
    @Environment(AppModel.self) private var appModel

    @State private var currentScreen: AppScreen = .launch

    var body: some View {
        switch currentScreen {
        case .launch:
            LaunchView(onContinue: {
                currentScreen = .worldMap
            })

        case .worldMap:
            WorldMapView(onEnding: {
                currentScreen = .ending
            })

        case .ending:
            EndingView(onRestart: {
                // 廃棄済みデータをリセットしてトップに戻る
                appModel.disposedCountryCodes = []
                currentScreen = .launch
            })
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
