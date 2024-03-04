//
//  Constant.swift
//  AudioRouteSwitch
//
//  Created by Mansi Prajapati on 01/03/24.
//

import Foundation
import AVFAudio

struct Constant {
    static let cornerRadius: CGFloat = 20
    static let locale = "en-US"
    static let bufferSize: AVAudioFrameCount = 1024
    static let startSession = "Click on start recording"
    static let startSpeaking = "Speak something...."
    static let stopRecording = "Stop Recording"
    static let startRecording = "Start Recording"
    static let transcript = "transcript"
    static let sessionReset = 0.3
}
