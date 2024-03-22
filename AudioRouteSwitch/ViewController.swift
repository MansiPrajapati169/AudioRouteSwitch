//
//  ViewController.swift
//  AudioRouteSwitch
//
//  Created by Mansi Prajapati on 01/03/24.
//

import UIKit
import AVFAudio

class ViewController: UIViewController {
    
    @IBOutlet weak var btnStartStopRecord: UIButton!
    @IBOutlet weak var lblTranscript: UILabel!
    @IBOutlet weak var transcriptView: UIView!
    
    private var speechRecognitionHelper = SpeechRegognitionHelper()
    private var startRecording = true
    private var routeChange = false
    private var previousString = R.string.localizable.emptyString()
    private var isSessionStarted = false
    private var isTextEmpty = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    // MARK: - deinit
    deinit {
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.routeChangeNotification, object: nil)
    }
    
    func setupView() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleRouteChange), name: AVAudioSession.routeChangeNotification, object: nil)
        AudioUserDefault.sharedInstance.transcriptString = R.string.localizable.emptyString()
        speechRecognitionHelper.speechRegognitionDelegate = self
        lblTranscript.text = Constant.startSession
        btnStartStopRecord.layer.cornerRadius = Constant.cornerRadius
    }
    
    @objc func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        switch reason {
        case .newDeviceAvailable:
            print("Reason: User has plugged in audio device")
            manageSession()
        case .oldDeviceUnavailable:
            print("Reason: Audio device is no longer available")
           manageSession()
        default:
            break
        }
    }
    
    func manageSession() {
        isSessionStarted = false
        self.speechRecognitionHelper.cancelRecording()
        self.routeChange = true
        print("route change:: \(String(describing: lblTranscript.text)) userdefault:: \(String(describing: AudioUserDefault.sharedInstance.transcriptString))")
        if !isTextEmpty {
            AudioUserDefault.sharedInstance.transcriptString = self.lblTranscript.text
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Constant.sessionReset) {
            do {
                try self.speechRecognitionHelper.startSession()
                self.isSessionStarted = true
                print("session started")
            } catch {
                print("Error in starting session")
            }
        }
    }
    
    @IBAction func startRecording(_ sender: UIButton) {
        AudioUserDefault.sharedInstance.transcriptString = nil
        if startRecording {
            isTextEmpty = true
            DispatchQueue.main.asyncAfter(deadline: .now() + Constant.sessionReset) {
                do {
                    try self.speechRecognitionHelper.startSession()
                    self.updateView(true)
                } catch {
                    print("error starting new session")
                }
            }
        } else {
            speechRecognitionHelper.cancelRecording()
            updateView()
        }
        startRecording = !startRecording
    }
    
    private func updateView(_ isSessionStarted: Bool = false) {
        self.btnStartStopRecord.setTitle(isSessionStarted ? Constant.stopRecording : Constant.startRecording, for: .normal)
        self.lblTranscript.text = isSessionStarted ? Constant.startSpeaking : Constant.startSession
    }
}

extension ViewController: SpeechRegognitionDelegate {
    
    func speechRecognizing(text: String) {
        let str = AudioUserDefault.sharedInstance.transcriptString
        if let str, routeChange == true {
            print("str:: \(str) text:: \(text) label:: \(String(describing: lblTranscript.text))")
            lblTranscript.text = isSessionStarted ? R.string.localizable.transcriptString(str, text) : str
        } else if startRecording {
            lblTranscript.text = Constant.startSession
        } else if !text.isEmpty {
            isTextEmpty = false
            print("lblTransctipt:: \(String(describing:lblTranscript.text)) texts:: \(text))")
            lblTranscript.text = text
        }
    }
}
