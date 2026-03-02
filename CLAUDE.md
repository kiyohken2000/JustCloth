# CLAUDE.md

## プロジェクト概要

国旗損壊罪をテーマにした政治風刺・教育インタラクティブアート作品。
詳細な仕様は `just-cloth-spec.md` を参照。

---

## コンセプトの核心

「布は布です。」

説教しない。体験させる。ユーザー自身が考える余地を残す。
これを常に意識して実装すること。

---

## 開発者について

- React Native (Expo) の経験はあるが、Swift / Xcode / visionOS は初めて
- コードの説明は日本語でコメントを入れること
- 難しい概念はReact Nativeと対比して説明してくれると助かる

---

## 実装ルール

- 必ずフェーズ1から順番に実装する。フェーズ2以降は指示があるまで手をつけない
- SwiftUIとRealityKitを使うこと
- 地図はMapKit for visionOSを使うこと
- コメントは日本語で書くこと
- 1ファイルが長くなりすぎないよう適切にファイルを分割すること

---

## 言葉の使い方（重要）

App Store審査対策として以下を徹底すること。

| 使わない言葉 | 使う言葉 |
|---|---|
| 燃やす | 焼却 |
| 切り裂く | 裁断 |
| 踏みつける | 床に置く |
| 損壊 | 廃棄 |
| 破壊 | 処分 |

---

## エフェクトの方針（重要）

App Store審査で引っかからないよう、激しい表現を避ける。

- 炎のリアルな描写はしない → 光のパーティクルで代替
- 布が激しく破れる描写はしない → ゆっくり消えていく演出にする
- 音は無機質でシンプルにする → 激しい効果音は使わない

---

## フォルダ構成

```
JustCloth/
├── Models/
│   ├── Country.swift
│   └── countries.json
├── Views/
│   ├── ContentView.swift
│   ├── WorldMapView.swift
│   ├── FlagView.swift
│   ├── DisposalView.swift
│   ├── InfoView.swift
│   └── EndingView.swift
├── Services/
│   ├── CountryDataService.swift
│   └── GestureService.swift
├── Effects/
│   └── ParticleEffects.swift
└── Resources/
    └── Flags/
```

---

## 使用アセット

- 国旗SVG：GitHubのcountry-flagsリポジトリ（MITライセンス）
- 各国法律データ：countries.json（自前管理）

---

## 各国データのstatusの値

| 値 | 意味 | 地図の色 |
|---|---|---|
| legal | 合法 | 緑 |
| illegal | 違法 | 赤 |
| gray | グレーゾーン・議論中 | 黄 |
| unknown | 不明 | 白 |

---

## 現在の実装状況

- [ ] フェーズ1：世界地図表示・国選択・廃棄体験・情報表示・地図色付け（3カ国分）
- [ ] フェーズ2：195カ国全対応・進捗管理・全カ国制覇エンディング
- [ ] フェーズ3：ハンドジェスチャー精度向上・空間オーディオ・BGM・App Store申請

---

## App Store申請時の注意

- カテゴリ：教育
- 年齢制限：12+
- 申請説明文：「表現の自由と国旗損壊罪について学ぶ、教育・政治風刺インタラクティブアート作品」
- まずTestFlightで先行配布してから正式申請すること
