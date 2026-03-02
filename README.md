# Just Cloth

**「布は布です。」**

国旗損壊罪をテーマにした政治風刺・教育インタラクティブアート作品。
世界195カ国の国旗を「布として廃棄」する体験を通じて、各国の国旗損壊に関する法律と表現の自由について考えるvisionOSアプリ。

---

## コンセプト

国旗をポリエステルと綿でできた布として扱うことで、愛国心や「国旗を敬え」という価値観の押し付けに対する反抗・憤り・ばかばかしさを体験として表現する。

説教しない。体験させる。

---

## 機能

- 世界地図（MapKit for visionOS）に195カ国の国旗ポイントを表示
- 各国の国旗損壊に関する法的ステータスを色分け表示（合法 / 違法 / グレーゾーン / 不明）
- 焼却 / 裁断 / リサイクルの3種類の廃棄体験
- RealityKitパーティクルエフェクト
- 廃棄後に各国の法律情報・罰則を表示
- 195カ国完全制覇エンディング

---

## 動作環境

- デバイス: Apple Vision Pro
- OS: visionOS 2.0以上

---

## 技術スタック

| 用途 | 技術 |
|---|---|
| UI | SwiftUI |
| 地図 | MapKit for visionOS |
| 3Dエフェクト | RealityKit パーティクル |
| 音響 | AVAudioEngine |
| 国旗SVG | [country-flags](https://github.com/hampusborgos/country-flags)（MITライセンス） |
| 各国法律データ | 自前JSONファイル |

---

## スクリーンショット

> Apple Vision Pro実機にて動作確認済み

---

## ライセンス

MIT License - 詳細は [LICENSE](LICENSE) を参照。

使用している国旗SVGは [country-flags](https://github.com/hampusborgos/country-flags)（MIT License）を利用しています。

---

## 免責事項

本アプリは教育・政治風刺を目的としたインタラクティブアート作品です。
各国の法律情報は参考情報であり、正確性を保証するものではありません。
