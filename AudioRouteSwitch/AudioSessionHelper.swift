//
//  AudioSessionHelper.swift
//  AudioRouteSwitch
//
//  Created by Mansi Prajapati on 01/03/24.
//

import AVFoundation

func isBluetoothDeviceConnected(audioSession: AVAudioSession) -> Bool {
    let bluetoothPortTypes: Set<AVAudioSession.Port> = [.bluetoothA2DP, .bluetoothLE, .bluetoothHFP, .headphones]
    for output in audioSession.currentRoute.outputs {
        if bluetoothPortTypes.contains(output.portType) {
            return true
        }
    }
    return false
}

func setAudioSessionCategory(_ categoery: AVAudioSession.Category) {
    let audioSession = AVAudioSession.sharedInstance()
    do {
        try? audioSession.setCategory(AVAudioSession.Category.playAndRecord, mode: .default, options: [.allowBluetooth, .defaultToSpeaker])
        if isBluetoothDeviceConnected(audioSession: audioSession) {
            try audioSession.overrideOutputAudioPort(.none)
        } else {
            try audioSession.overrideOutputAudioPort(.speaker)
        }
        try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    } catch {
        print("Error setting up audio session: \(error.localizedDescription)")
    }
}
