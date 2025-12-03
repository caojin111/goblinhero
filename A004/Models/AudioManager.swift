//
//  AudioManager.swift
//  A004
//
//  音频管理器 - 管理音乐和音效
//

import Foundation
import AVFoundation

class AudioManager: ObservableObject {
    static let shared = AudioManager()
    
    @Published var isMusicEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(isMusicEnabled, forKey: "isMusicEnabled")
            if !isMusicEnabled {
                stopMusic()
            } else {
                playMusic()
            }
        }
    }
    
    @Published var isSoundEffectsEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(isSoundEffectsEnabled, forKey: "isSoundEffectsEnabled")
        }
    }
    
    private var backgroundMusicPlayer: AVAudioPlayer?
    private var soundEffectPlayers: [String: AVAudioPlayer] = [:]
    
    private init() {
        loadSettings()
    }
    
    /// 加载设置
    private func loadSettings() {
        isMusicEnabled = UserDefaults.standard.object(forKey: "isMusicEnabled") as? Bool ?? true
        isSoundEffectsEnabled = UserDefaults.standard.object(forKey: "isSoundEffectsEnabled") as? Bool ?? true
    }
    
    /// 播放背景音乐
    func playMusic() {
        guard isMusicEnabled else { return }
        
        // 这里可以添加实际的音乐文件播放逻辑
        // 例如：播放 Bundle 中的音乐文件
        // if let url = Bundle.main.url(forResource: "background_music", withExtension: "mp3") {
        //     backgroundMusicPlayer = try? AVAudioPlayer(contentsOf: url)
        //     backgroundMusicPlayer?.numberOfLoops = -1 // 循环播放
        //     backgroundMusicPlayer?.play()
        // }
        
        print("🎵 [音频] 背景音乐播放")
    }
    
    /// 停止背景音乐
    func stopMusic() {
        backgroundMusicPlayer?.stop()
        backgroundMusicPlayer = nil
        print("🎵 [音频] 背景音乐停止")
    }
    
    /// 播放音效
    func playSoundEffect(_ name: String) {
        guard isSoundEffectsEnabled else { return }
        
        // 这里可以添加实际的音效文件播放逻辑
        // 例如：播放 Bundle 中的音效文件
        // if let url = Bundle.main.url(forResource: name, withExtension: "mp3") {
        //     let player = try? AVAudioPlayer(contentsOf: url)
        //     player?.play()
        //     soundEffectPlayers[name] = player
        // }
        
        print("🔊 [音频] 播放音效: \(name)")
    }
    
    /// 停止所有音效
    func stopAllSoundEffects() {
        soundEffectPlayers.values.forEach { $0.stop() }
        soundEffectPlayers.removeAll()
    }
}

