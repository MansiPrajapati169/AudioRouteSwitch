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
            case .newDeviceAvailable, .oldDeviceUnavailable:
                isSessionStarted = false
                self.speechRecognitionHelper.cancelRecording()
                self.routeChange = true
                print("route change:: \(String(describing: lblTranscript.text)) userdefault:: \(String(describing: AudioUserDefault.sharedInstance.transcriptString))")
                AudioUserDefault.sharedInstance.transcriptString = self.lblTranscript.text
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    do {
                        try self.speechRecognitionHelper.startSession()
                        self.isSessionStarted = true
                        print("session started")
                    } catch {
                        print("Error in starting session")
                    }
                }
            default: break
            }
    }
    
    @IBAction func startRecording(_ sender: UIButton) {
        if startRecording {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                do {
                    AudioUserDefault.sharedInstance.transcriptString = R.string.localizable.emptyString()
                    try self.speechRecognitionHelper.startSession()
                    self.btnStartStopRecord.setTitle(Constant.stopRecording, for: .normal)
                    self.lblTranscript.text = Constant.startSpeaking
                } catch {
                    print("error starting new session")
                }
            }
        } else {
            speechRecognitionHelper.cancelRecording()
            btnStartStopRecord.setTitle(Constant.startRecording, for: .normal)
        }
        self.startRecording = !startRecording
    }
}

extension ViewController: SpeechRegognitionDelegate {
    
    func speechRecognizing(text: String) {
        let str = AudioUserDefault.sharedInstance.transcriptString
        if let str, str != R.string.localizable.emptyString(), routeChange == true {
            print("str:: \(str) text:: \(text) label:: \(String(describing: lblTranscript.text))")
            lblTranscript.text = isSessionStarted ? R.string.localizable.transcriptString(str, text) : str
        } else if startRecording {
            lblTranscript.text = Constant.startSession
        } else if !text.isEmpty {
            print("lblTransctipt:: \(String(describing:lblTranscript.text)) texts:: \(text))")
            lblTranscript.text = text
        }
    }
}
