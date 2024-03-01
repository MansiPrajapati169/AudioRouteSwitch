//
//  SpeechHelper.swift
//  AudioRouteSwitch
//
//  Created by Mansi Prajapati on 01/03/24.
//

import Speech
 
protocol SpeechRegognitionDelegate: AnyObject {
    func speechRecognizing(text: String)
}

class SpeechRegognitionHelper {
    
    // MARK: - Variables
    private let speechRecognizer = SFSpeechRecognizer(locale:
                                                        Locale(identifier: Constant.locale))
    private var speechRecognitionRequest:
    SFSpeechAudioBufferRecognitionRequest?
    private var speechRecognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    weak var speechRegognitionDelegate: SpeechRegognitionDelegate?
    
    // MARK: - functions
    func startSession() throws {
        if let recognitionTask = speechRecognitionTask {
            recognitionTask.cancel()
            self.speechRecognitionTask = nil
        }
        
        setAudioSessionCategory(.playAndRecord)
        speechRecognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = speechRecognitionRequest else { return }
        let inputNode = audioEngine.inputNode
        recognitionRequest.shouldReportPartialResults = true
        speechRecognitionTask = speechRecognizer?.recognitionTask(
            with: recognitionRequest) { [weak self] result, error in
                guard let self else { return }
                guard let result else { return }
                print("Date \(Date())")
                print("result \(result.bestTranscription.formattedString.lowercased())")
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    speechRegognitionDelegate?.speechRecognizing(text: result.bestTranscription.formattedString.lowercased())
                }
                guard self.audioEngine.isRunning else { return }
                if error != nil {
                    self.audioEngine.stop()
                    inputNode.removeTap(onBus: .zero)
                    
                    self.speechRecognitionRequest = nil
                    self.speechRecognitionTask = nil
                }
            }
        
        let recordingFormat = inputNode.outputFormat(forBus: .zero)
        inputNode.installTap(onBus: .zero, bufferSize: Constant.bufferSize, format: recordingFormat) {
            (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.speechRecognitionRequest?.append(buffer)
        }
        audioEngine.prepare()
        try audioEngine.start()
    }
    
    func cancelRecording() {
        if audioEngine.isRunning {
            speechRecognitionRequest?.endAudio()
            audioEngine.stop()
            if audioEngine.inputNode.numberOfInputs > .zero {
                audioEngine.inputNode.removeTap(onBus: .zero)
            }
            speechRecognitionTask?.cancel()
            speechRecognitionTask = nil
            speechRecognitionRequest = nil
        }
    }
    
    func isAudioRunning() -> Bool {
        audioEngine.isRunning
    }

    static func checkPermissions(completion: @escaping (Bool, Bool) -> Void) {
        var speechAuthorized = false
        var microphoneAuthorized = false
        
        // Check speech recognition permission
        SFSpeechRecognizer.requestAuthorization { (speechAuthStatus) in
            switch speechAuthStatus {
            case .authorized:
                speechAuthorized = true
            case .denied, .restricted, .notDetermined:
                speechAuthorized = false
            default:
                speechAuthorized = false
            }
            
            // Check microphone permission
            switch AVAudioApplication.shared.recordPermission {
            case .granted:
                microphoneAuthorized = true
            case .denied, .undetermined:
                microphoneAuthorized = false
            default:
                microphoneAuthorized = false
            }
            completion(speechAuthorized, microphoneAuthorized)
        }
    }
}
