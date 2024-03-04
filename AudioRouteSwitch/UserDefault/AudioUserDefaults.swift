//
//  BAUserDefaults.swift
//  PastryAppPOC
//
//  Created by Mansi Prajapati on 07/02/24.
//

import Foundation

class AudioUserDefaults<T: Any> {
    private var key = ""
    private var objectInUserDefaults: T? {
        set {
            if let value = newValue {
                UserDefaults.standard.set(value, forKey: key)
            }
            else {
                UserDefaults.standard.removeObject(forKey: key )
            }
            UserDefaults.standard.synchronize()
        }
        
        get {
            return UserDefaults.standard.object(forKey: key) as? T
        }
    }
    
    func getObject<AnyValue :Any>(forKey key: String) -> AnyValue? {
        self.key = key
        return objectInUserDefaults as? AnyValue
    }
    
    func setObject(_ t: T?, key: String) {
        self.key = key
        objectInUserDefaults = t
    }
}
