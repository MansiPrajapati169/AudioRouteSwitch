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
    private var audioEngine = AVAudioEngine()
    weak var speechRegognitionDelegate: SpeechRegognitionDelegate?
    
    // MARK: - functions
    func startSession() throws {
        if let recognitionTask = speechRecognitionTask {
            recognitionTask.cancel()
        }
        self.speechRecognitionTask = nil
        setAudioSessionCategory(.record)
        speechRecognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = speechRecognitionRequest else { return }
        engineSetup()
        recognitionRequest.shouldReportPartialResults = true
        speechRecognitionTask = speechRecognizer?.recognitionTask(
            with: recognitionRequest) { [weak self] result, error in
                guard let self else { return }
                guard let result else { return }
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    speechRegognitionDelegate?.speechRecognizing(text: result.bestTranscription.formattedString.lowercased())
                }
                guard self.audioEngine.isRunning else { return }
                if error != nil {
                    cancelRecording()
                }
            }
    }
    
    private func engineSetup() {
        audioEngine = AVAudioEngine()
        let inputNode = audioEngine.inputNode
        let bus = 0
        let recordingFormat = inputNode.outputFormat(forBus: bus)
        let outputFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: AVAudioSession.sharedInstance().sampleRate, channels: 1, interleaved: true)
        guard let outputFormat, let converter = AVAudioConverter(from: recordingFormat, to: outputFormat)  else {
            return
        }
        inputNode.installTap(onBus: bus, bufferSize: Constant.bufferSize, format: recordingFormat) { [weak self] (buffer, _) -> Void in
            guard let self else { return }
            var newBufferAvailable = true
            let inputCallback: AVAudioConverterInputBlock = { _, outStatus in
                if newBufferAvailable {
                    outStatus.pointee = .haveData
                    newBufferAvailable = false
                    return buffer
                } else {
                    outStatus.pointee = .noDataNow
                    return nil
                }
            }
            let outputSampleRate = AVAudioFrameCount(outputFormat.sampleRate)
            let bufferSampleRate = AVAudioFrameCount(buffer.format.sampleRate)
            let convertedBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: outputSampleRate * buffer.frameLength / bufferSampleRate)!
            var error: NSError?
            let status = converter.convert(to: convertedBuffer, error: &error, withInputFrom: inputCallback)
            if status == .error {
                if let err = error {
                    print("Error in starting session \(String(describing: err))")
                }
                return
            }
            self.speechRecognitionRequest?.append(convertedBuffer)
        }
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("Error in starting session")
        }
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
