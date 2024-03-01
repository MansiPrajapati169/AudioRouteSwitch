//
//  ViewController.swift
//  AudioRouteSwitch
//
//  Created by Mansi Prajapati on 01/03/24.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var btnStartStopRecord: UIButton!
    @IBOutlet weak var lblTranscript: UILabel!
    @IBOutlet weak var transcriptView: UIView!
    
    private var speechRecognitionHelper = SpeechRegognitionHelper()
    private var startRecording = true
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    func setupView() {
        speechRecognitionHelper.speechRegognitionDelegate = self
        lblTranscript.text = Constant.startSession
        btnStartStopRecord.layer.cornerRadius = Constant.cornerRadius
    }
    
    @IBAction func startRecording(_ sender: UIButton) {
        if startRecording {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                do {
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
        if startRecording {
            lblTranscript.text = Constant.startSession
        } else if !text.isEmpty {
            lblTranscript.text = text
        }
    }
}
