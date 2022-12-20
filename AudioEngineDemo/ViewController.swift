//
//  ViewController.swift
//  AudioEngineDemo
//
//  Created by Murphy on 2022/12/20.
//

import UIKit
import AVFAudio
import SnapKit
import RxCocoa


class ViewController: UIViewController {
    
    // 音频引擎
    var audioEngine = AVAudioEngine()
    // 播放节点
    var enginePlayer = AVAudioPlayerNode()
    // 变声单元：调节音高
    let pitchEffect = AVAudioUnitTimePitch()
    // 混响单元
    let reverbEffect = AVAudioUnitReverb()
    // 调节音频播放速度单元
    let rateEffect = AVAudioUnitVarispeed()
    // 调节音量单元
    let volumeEffect = AVAudioUnitEQ()
    // 音频输入文件
    var engineAudioFile: AVAudioFile!
    
    let playerNode = AVAudioPlayerNode()
    let playerNode2 = AVAudioPlayerNode()

    // 录音
    var audioRecorder:AVAudioRecorder?
    
    var audioPlayer: AVAudioPlayer?
    
    // 保存 url
    var audioFileUrl:URL?
    
    
    lazy var recorderButton = {
        let button = UIButton.init(type: .custom)
        button.setTitle("录制", for: .normal)
        button.setTitle("停止", for: .selected)
        button.backgroundColor = .red
        return button
    }()
    
    lazy var playButton = {
        let button = UIButton.init(type: .custom)
        button.setTitle("背景音1", for: .normal)
        button.setTitle("停止", for: .selected)
        button.backgroundColor = .gray
        return button
    }()
    
    lazy var enginePlayButton = {
        let button = UIButton.init(type: .custom)
        button.setTitle("背景音2", for: .normal)
        button.setTitle("停止", for: .selected)
        button.backgroundColor = .blue
        return button
    }()
    
    lazy var pitchSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = -2400
        slider.maximumValue = 2400
        slider.value = 0;
        return slider
    }()
    // MARK: life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = .white
        
        
        // 配置录音
        setSessionPlayAndRecord()
        setupAudioRecorder()
        // 配置播放
//        setupAudioEngine()
        setupMixerAudioEngine()
        
        createUI()
        bindSignal()
    }
    
    // MARK: UI
    func createUI() {
        view.addSubview(recorderButton)
        view.addSubview(playButton)
        view.addSubview(enginePlayButton)
        view.addSubview(pitchSlider)
        recorderButton.snp.makeConstraints { make in
            make.left.equalTo(30)
            make.top.equalTo(additionalSafeAreaInsets.top).offset(50)
            make.width.equalTo(100)
            make.height.equalTo(50)
        }
        
        playButton.snp.makeConstraints { make in
            make.left.equalTo(recorderButton)
            make.width.height.equalTo(recorderButton)
            make.top.equalTo(recorderButton.snp_bottomMargin).offset(50)
        }
        
        enginePlayButton.snp.makeConstraints { make in
            make.left.width.height.equalTo(recorderButton)
            make.top.equalTo(playButton.snp_bottomMargin).offset(50)
        }
        
        pitchSlider.snp.makeConstraints { make in
            make.left.equalTo(30)
            make.right.equalTo(-30)
            make.top.equalTo(enginePlayButton.snp_bottomMargin)
        }
        
    }
    
    func bindSignal() {
        
        _ = recorderButton.rx.tap.subscribe(onNext: { [weak self] sender  in
            guard let self = self else {
                return
            }
            self.recorderButton.isSelected = !self.recorderButton.isSelected
            
            if self.recorderButton.isSelected {
                self.audioRecorder?.record()
            } else {
                self.audioRecorder?.stop()
            }
        })
        
        _ = playButton.rx.tap.subscribe(onNext: { [weak self] in
            guard let self = self else {
                return
            }
            
            
            self.playButton.isSelected = !self.playButton.isSelected
            
            if self.playButton.isSelected {
//                self.setupAudioPlayer()
//                self.audioPlayer?.play()
                do {
                    
                    guard let fileUrl = Bundle.main.url(forResource: "光年之外", withExtension: "mp3") else {
                        return
                    }
                    
                    // 读取文件，获取文件中 pcm 数据
                    let audioFile = try AVAudioFile(forReading: fileUrl)
                    
                    let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: AVAudioFrameCount(audioFile.length))
                    
                    guard let speechBuffer = buffer else {
                        return
                    }
                    
                    audioFile.framePosition = 0
                    try audioFile.read(into: speechBuffer)
                    
                    audioFile.framePosition = 0
                    self.audioEngine.attach(self.playerNode2)
                    self.audioEngine.connect(self.playerNode2, to: self.audioEngine.mainMixerNode, format: speechBuffer.format)
                    
                    self.playerNode2.scheduleBuffer(speechBuffer, at: nil, options: .loops)
                    self.playerNode2.play()
                    
                } catch {
                    
                }

            } else {
//                self.audioPlayer?.stop()
                self.audioEngine .detach(self.playerNode2)
            }
        })
        
        _ = enginePlayButton.rx.tap.subscribe(onNext:  { [weak self] in
            guard let self = self else {
                return
            }
                
                self.enginePlayButton.isSelected = !self.enginePlayButton.isSelected
                if self.enginePlayButton.isSelected {
                    do {
                        
                        guard let fileUrl = Bundle.main.url(forResource: "消愁", withExtension: "mp3") else {
                            return
                        }
                        
                        // 读取文件，获取文件中 pcm 数据
                        let audioFile = try AVAudioFile(forReading: fileUrl)
                        
                        let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: AVAudioFrameCount(audioFile.length))
                        
                        guard let speechBuffer = buffer else {
                            return
                        }
                        
                        audioFile.framePosition = 0
                        try audioFile.read(into: speechBuffer)
                        
                        audioFile.framePosition = 0
                        self.audioEngine.attach(self.playerNode)
                        self.audioEngine.connect(self.playerNode, to: self.audioEngine.mainMixerNode, format: speechBuffer.format)
                        
                        self.playerNode.scheduleBuffer(speechBuffer, at: nil, options: .loops)
                        
//                        self.playerNode.scheduleFile(audioFile, at: nil, completionHandler: nil)
                        self.playerNode.play()
                        
                        
                } catch {
                    
                }
            } else {
//                self.enginePlayer.stop()
                self.audioEngine .detach(self.playerNode)
                
            }

        })
        
        _ = pitchSlider.rx.controlEvent(.valueChanged).subscribe(onNext:  { [weak self] in
            guard let self = self else {
                return
            }
            self.pitchEffect.pitch = self.pitchSlider.value
//            print(self.pitchSlider.value)
        })
    }

    // MARK: private
    private func setupAudioRecorder() {
        let url = createFileUrl()
        audioFileUrl = url
        
        let recordSettings:[String: Any] = [
            // 设置录制音频的格式
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue,
            AVEncoderBitRateKey: 32000,
            // 每个采样点的通道数
            AVNumberOfChannelsKey: 2,
            // 设置录制音频的采样率
            AVSampleRateKey: 44100.0,

        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: recordSettings)
            audioRecorder?.delegate = self
            // 需要监听声波
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()

        } catch {
            audioRecorder = nil
            print("\(#function) - \(error)")
        }
    }
    
    private func setSessionPlayAndRecord() {
        // 获取当前应用的音频会话
        let session = AVAudioSession.sharedInstance()
        do {
            // 设置音频类别
            try session.setCategory(AVAudioSession.Category.playAndRecord, options: AVAudioSession.CategoryOptions.defaultToSpeaker)
        } catch {
            print("\(#function) - \(error)")
        }
        
        do {
            try session.setActive(true)
        } catch {
            print("\(#function) setActive - \(error)")
        }
    }
    
    private func setSessionPlayBack() {
        // 获取当前应用的音频会话
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, options: .defaultToSpeaker)
        } catch {
            print("\(#function) - \(error)")
        }
        
        do {
            try session.setActive(true)
        } catch {
            print("\(#function) setActive - \(error)")
        }

    }
    
    private func setupAudioPlayer() {
        guard let fileUrl = audioFileUrl else {
            return
        }
        do {
            try audioPlayer = AVAudioPlayer(contentsOf: fileUrl)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
        } catch {
            print("\(#function) - \(error)")
            self.playButton.isSelected = false
        }
    }
    
    // 配置一个混音引擎
    private func setupMixerAudioEngine() {
        do {
            let input = audioEngine.inputNode
            let mainMixer = audioEngine.mainMixerNode
            let output = audioEngine.outputNode
            
            
            // 开始回声抑制
            try input.setVoiceProcessingEnabled(true)
            
            // 建立音频处理链
            audioEngine.connect(input, to: mainMixer, format: input.outputFormat(forBus: 1))
            audioEngine.connect(mainMixer, to: output, format: mainMixer.outputFormat(forBus: 0))
            
            // 启动引擎
            try audioEngine.start()
            
        } catch {
            print("\(#function) - \(error)")
        }
    }
    
    // 配置，功能初始化
    private func setupAudioEngine() {
        // 单音
        let format = audioEngine.inputNode.inputFormat(forBus: 0)
        // 添加功能
        audioEngine.attach(enginePlayer)
        audioEngine.attach(pitchEffect)
        audioEngine.attach(reverbEffect)
        audioEngine.attach(rateEffect)
        audioEngine.attach(volumeEffect)
        
        // 连接功能
        audioEngine.connect(enginePlayer, to: pitchEffect, format: format)
        audioEngine.connect(pitchEffect, to: reverbEffect, format: format)
        audioEngine.connect(reverbEffect, to: rateEffect, format: format)
        audioEngine.connect(rateEffect, to: volumeEffect, format: format)
        audioEngine.connect(rateEffect, to: audioEngine.mainMixerNode, format: format)
        
        // 选择混响效果为大房间
        reverbEffect.loadFactoryPreset(AVAudioUnitReverbPreset.smallRoom)
        
        do {
            // 开始引擎
            try audioEngine.start()
        } catch {
            print("Error starting AVAudioEngine.\(error)")
        }
        
    }
    
    private func play() {
        guard let fileURL = audioFileUrl else {
            return
        }
        var playFlag = true
        
        do {
            // 用 URL 初始化 AVAudioFile
            // AVAudioFile 加载音频数据，形成数据缓冲区，方便 AVAudioEngine 使用
            
            engineAudioFile = try AVAudioFile(forReading: fileURL)
            
            // 音高
            pitchEffect.pitch = 0
            reverbEffect.wetDryMix = 50
            rateEffect.rate = 1
            volumeEffect.globalGain = 0
        } catch {
            engineAudioFile = nil
            playFlag = false
            print("Error loading AVAudioFile.\(error)")
        }
        
        if playFlag {
            enginePlayer.scheduleFile(engineAudioFile, at: nil, completionHandler: nil)
            enginePlayer.play()
        }
        
    }
    
    private func getURLForMemo() -> URL? {
        
        return URL.init(string: "")
    }
    
    private func createFileUrl() -> URL {
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        let fileName = "recording-\(format.string(from: Date())).WAV"
        
        var doc = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

        let path = "\(doc.path())audioFiles"
        
        if !FileManager.default.fileExists(atPath: path) {
            do {
                try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
            } catch {
                print("create \(doc.absoluteString) 目录失败, error = \(error)")
            }
        }
        doc.append(component: "audioFiles")
        doc.append(component: fileName)
//        doc.appendPathComponent(fileName)
        return doc
    }
}

// MARK: AVAudioRecorderDelegate
extension ViewController: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print("录制完成")
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("\(#function) - \(String(describing: error?.localizedDescription))")
    }
    
}

// MARK: AVAudioPlayerDelegate
extension ViewController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("播放完成")
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("\(#function) - \(String(describing: error?.localizedDescription))")
    }
}
