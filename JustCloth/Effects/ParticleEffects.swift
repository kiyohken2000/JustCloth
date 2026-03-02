// ParticleEffects.swift
// 廃棄エフェクト用のRealityKitパーティクル設定
// App Store審査対策：炎・破壊表現を避け、光の粒子で表現する

import RealityKit
import UIKit

// ParticleColorの型エイリアス（長い型名を省略）
private typealias PColor     = ParticleEmitterComponent.ParticleEmitter.ParticleColor
private typealias PColorVal  = ParticleEmitterComponent.ParticleEmitter.ParticleColor.ColorValue
private typealias PUIColor   = ParticleEmitterComponent.ParticleEmitter.Color

// 廃棄方法ごとのパーティクルエフェクトを生成するファクトリ
enum ParticleEffects {

    // 廃棄方法に応じたEntityを生成する
    static func makeEmitter(for method: DisposalMethod) -> Entity {
        switch method {
        case .incinerate: return makeIncinerateEmitter()
        case .cut:        return makeCutEmitter()
        case .recycle:    return makeRecycleEmitter()
        }
    }

    // MARK: - 焼却
    // 白→黄→橙の光がランダムに広がる（炎のような光の粒子）
    // メインの炎パーティクル＋灰のような微粒子の2層構成
    static func makeIncinerateEmitter() -> Entity {
        let root = Entity()

        // 層1：メイン炎パーティクル（白→橙→赤に変化する大粒子）
        var fire = ParticleEmitterComponent.Presets.magic
        fire.mainEmitter.birthRate = 600
        fire.speed = 0.4
        fire.mainEmitter.lifeSpan = 1.0
        fire.mainEmitter.size = 0.025
        fire.mainEmitter.sizeVariation = 0.015
        fire.mainEmitter.spreadingAngle = 0.6
        // 白→黄→橙と変化させて焔のような色合いに
        let fireStart = PColorVal.random(
            a: PUIColor.white,
            b: PUIColor(red: 1.0, green: 0.95, blue: 0.6, alpha: 1.0)
        )
        let fireEnd = PColorVal.random(
            a: PUIColor(red: 1.0, green: 0.5, blue: 0.1, alpha: 0.0),
            b: PUIColor(red: 1.0, green: 0.2, blue: 0.0, alpha: 0.0)
        )
        fire.mainEmitter.color = .evolving(start: fireStart, end: fireEnd)

        let fireEntity = Entity()
        fireEntity.components.set(fire)
        fireEntity.position = [0, 0, 0]
        root.addChild(fireEntity)

        // 層2：微細な輝き粒子（白→透明、高速・小さく）
        var spark = ParticleEmitterComponent.Presets.magic
        spark.mainEmitter.birthRate = 300
        spark.speed = 0.8
        spark.mainEmitter.lifeSpan = 0.5
        spark.mainEmitter.size = 0.008
        spark.mainEmitter.spreadingAngle = 1.2
        let sparkStart = PColorVal.single(PUIColor(red: 1.0, green: 0.98, blue: 0.85, alpha: 1.0))
        let sparkEnd   = PColorVal.single(PUIColor(red: 1.0, green: 0.8, blue: 0.3, alpha: 0.0))
        spark.mainEmitter.color = .evolving(start: sparkStart, end: sparkEnd)

        let sparkEntity = Entity()
        sparkEntity.components.set(spark)
        sparkEntity.position = [0, 0, 0]
        root.addChild(sparkEntity)

        return root
    }

    // MARK: - 裁断
    // 鋭く飛び散る白〜青白い光の粒子（ハサミの刃のイメージ）
    // 横方向に広がる線状の粒子＋細かい飛沫の2層構成
    static func makeCutEmitter() -> Entity {
        let root = Entity()

        // 層1：メインの飛沫（高速・広角に散る）
        var slash = ParticleEmitterComponent.Presets.impact
        slash.mainEmitter.birthRate = 800
        slash.speed = 1.2
        slash.mainEmitter.lifeSpan = 0.8
        slash.mainEmitter.size = 0.012
        slash.mainEmitter.sizeVariation = 0.006
        slash.mainEmitter.spreadingAngle = 1.8  // 広角に散らす
        let slashStart = PColorVal.random(
            a: PUIColor.white,
            b: PUIColor(red: 0.85, green: 0.95, blue: 1.0, alpha: 1.0)
        )
        let slashEnd = PColorVal.single(PUIColor(red: 0.5, green: 0.8, blue: 1.0, alpha: 0.0))
        slash.mainEmitter.color = .evolving(start: slashStart, end: slashEnd)

        let slashEntity = Entity()
        slashEntity.components.set(slash)
        slashEntity.position = [0, 0, 0]
        root.addChild(slashEntity)

        // 層2：細かい光の粒子（ゆっくり落ちる布くずのイメージ）
        var shred = ParticleEmitterComponent.Presets.magic
        shred.mainEmitter.birthRate = 200
        shred.speed = 0.2
        shred.mainEmitter.lifeSpan = 1.5
        shred.mainEmitter.size = 0.018
        shred.mainEmitter.sizeVariation = 0.008
        let shredStart = PColorVal.single(PUIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 0.9))
        let shredEnd   = PColorVal.single(PUIColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 0.0))
        shred.mainEmitter.color = .evolving(start: shredStart, end: shredEnd)

        let shredEntity = Entity()
        shredEntity.components.set(shred)
        shredEntity.position = [0, 0, 0]
        root.addChild(shredEntity)

        return root
    }

    // MARK: - リサイクル
    // 白→緑の粒子がゆっくり上昇しながら消える（循環・再生のイメージ）
    // 上昇する泡のような大粒子＋キラキラ小粒子の2層構成
    static func makeRecycleEmitter() -> Entity {
        let root = Entity()

        // 層1：上昇する光の泡（緑に変化）
        var bubble = ParticleEmitterComponent.Presets.magic
        bubble.mainEmitter.birthRate = 150
        bubble.speed = 0.25
        bubble.mainEmitter.lifeSpan = 2.0
        bubble.mainEmitter.size = 0.022
        bubble.mainEmitter.sizeVariation = 0.01
        bubble.mainEmitter.spreadingAngle = 0.4
        let bubbleStart = PColorVal.random(
            a: PUIColor.white,
            b: PUIColor(red: 0.8, green: 1.0, blue: 0.85, alpha: 1.0)
        )
        let bubbleEnd = PColorVal.random(
            a: PUIColor(red: 0.2, green: 0.9, blue: 0.4, alpha: 0.0),
            b: PUIColor(red: 0.1, green: 0.7, blue: 0.5, alpha: 0.0)
        )
        bubble.mainEmitter.color = .evolving(start: bubbleStart, end: bubbleEnd)

        let bubbleEntity = Entity()
        bubbleEntity.components.set(bubble)
        bubbleEntity.position = [0, 0, 0]
        root.addChild(bubbleEntity)

        // 層2：キラキラした小粒子（緑〜水色）
        var sparkle = ParticleEmitterComponent.Presets.magic
        sparkle.mainEmitter.birthRate = 250
        sparkle.speed = 0.5
        sparkle.mainEmitter.lifeSpan = 1.0
        sparkle.mainEmitter.size = 0.008
        sparkle.mainEmitter.spreadingAngle = 1.0
        let sparkleStart = PColorVal.single(PUIColor(red: 0.7, green: 1.0, blue: 0.8, alpha: 1.0))
        let sparkleEnd   = PColorVal.single(PUIColor(red: 0.3, green: 1.0, blue: 0.6, alpha: 0.0))
        sparkle.mainEmitter.color = .evolving(start: sparkleStart, end: sparkleEnd)

        let sparkleEntity = Entity()
        sparkleEntity.components.set(sparkle)
        sparkleEntity.position = [0, 0, 0]
        root.addChild(sparkleEntity)

        return root
    }
}
