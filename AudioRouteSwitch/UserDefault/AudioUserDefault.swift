//
//  BAUserDefault.swift
//  PastryAppPOC
//
//  Created by Mansi Prajapati on 07/02/24.
//

import Foundation

class AudioUserDefault {
    static let sharedInstance = AudioUserDefault()
    
    var transcriptString: String? {
        set {
            AudioUserDefaults<String>().setObject(newValue, key: Constant.transcript)
        }
        get {
            return AudioUserDefaults<String>().getObject(forKey: Constant.transcript)
        }
    }
}
