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
                // 如果之前有保存的音乐，恢复播放
                if let fileName = currentMusicFileName {
                    print("🎵 [音频] 音乐开关已开启，恢复播放: \(fileName).\(currentMusicFileExtension)")
                    playBackgroundMusic(fileName: fileName, fileExtension: currentMusicFileExtension)
                }
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
    private var currentMusicFileName: String? = nil // 保存当前应该播放的音乐文件名
    private var currentMusicFileExtension: String = "mp3" // 保存当前音乐文件扩展名
    
    private init() {
        loadSettings()
        // 配置音频会话
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ [音频] 音频会话配置失败: \(error)")
        }
    }
    
    /// 加载设置
    private func loadSettings() {
        isMusicEnabled = UserDefaults.standard.object(forKey: "isMusicEnabled") as? Bool ?? true
        isSoundEffectsEnabled = UserDefaults.standard.object(forKey: "isSoundEffectsEnabled") as? Bool ?? true
    }
    
    /// 播放背景音乐（通用方法，已废弃，使用 playBackgroundMusic）
    func playMusic() {
        // 保持兼容性，但不执行任何操作
        print("🎵 [音频] playMusic() 已废弃，请使用 playBackgroundMusic(fileName:)")
    }
    
    /// 播放指定的背景音乐（循环播放）
    func playBackgroundMusic(fileName: String, fileExtension: String = "mp3") {
        // 保存当前应该播放的音乐信息（即使音乐被关闭，也保存以便恢复）
        currentMusicFileName = fileName
        currentMusicFileExtension = fileExtension
        
        guard isMusicEnabled else {
            print("🎵 [音频] 音乐已关闭，保存音乐信息: \(fileName).\(fileExtension)")
            return
        }
        
        // 如果正在播放相同的音乐，不重复播放
        if let currentPlayer = backgroundMusicPlayer,
           let currentUrl = currentPlayer.url,
           currentUrl.lastPathComponent == "\(fileName).\(fileExtension)" {
            print("🎵 [音频] 背景音乐已在播放: \(fileName)")
            return
        }
        
        // 停止当前音乐
        stopMusic()
        
        // 加载并播放新音乐
        if let url = Bundle.main.url(forResource: fileName, withExtension: fileExtension) {
            do {
                backgroundMusicPlayer = try AVAudioPlayer(contentsOf: url)
                backgroundMusicPlayer?.numberOfLoops = -1 // 循环播放
                // homepage.mp3 音量减少 50%（从0.7变为0.35）
                if fileName == "homepage" {
                    backgroundMusicPlayer?.volume = 0.35 // 50%音量
                } else {
                    backgroundMusicPlayer?.volume = 0.7 // 其他音乐正常音量
                }
                backgroundMusicPlayer?.play()
                print("🎵 [音频] 开始播放背景音乐: \(fileName).\(fileExtension), 音量: \(backgroundMusicPlayer?.volume ?? 0)")
            } catch {
                print("❌ [音频] 播放背景音乐失败: \(error)")
            }
        } else {
            print("⚠️ [音频] 找不到音频文件: \(fileName).\(fileExtension)")
        }
    }
    
    /// 停止背景音乐
    func stopMusic() {
        backgroundMusicPlayer?.stop()
        backgroundMusicPlayer = nil
        print("🎵 [音频] 背景音乐停止")
    }
    
    /// 播放音效
    func playSoundEffect(_ name: String, fileExtension: String = "wav") {
        guard isSoundEffectsEnabled else { return }
        
        if let url = Bundle.main.url(forResource: name, withExtension: fileExtension) {
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                // letter.wav需要更响：使用两个播放器叠加播放，近似放大两倍（单个播放器最大1.0）
                if name == "letter" {
                    player.volume = 1.0
                    player.play()
                    soundEffectPlayers[name] = player
                    
                    // 额外叠加一个播放器提高响度
                    let boostPlayer = try AVAudioPlayer(contentsOf: url)
                    boostPlayer.volume = 1.0
                    boostPlayer.play()
                    soundEffectPlayers["\(name)_boost"] = boostPlayer
                    
                    print("🔊 [音频] 播放音效: \(name).\(fileExtension)，双播放器叠加提升音量")
                } else {
                    player.volume = 1.0 // 其他音效正常音量
                    player.play()
                    soundEffectPlayers[name] = player
                    print("🔊 [音频] 播放音效: \(name).\(fileExtension), 音量: \(player.volume)")
                }
            } catch {
                print("❌ [音频] 播放音效失败: \(error)")
            }
        } else {
            print("⚠️ [音频] 找不到音效文件: \(name).\(fileExtension)")
        }
    }
    
    /// 停止特定音效
    func stopSoundEffect(_ name: String) {
        if let player = soundEffectPlayers[name] {
            player.stop()
            soundEffectPlayers.removeValue(forKey: name)
            print("🔇 [音频] 停止音效: \(name)")
        }
    }
    
    /// 停止所有音效
    func stopAllSoundEffects() {
        soundEffectPlayers.values.forEach { $0.stop() }
        soundEffectPlayers.removeAll()
    }
}

