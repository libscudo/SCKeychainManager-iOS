//
//  SCKeychainItemOperationBuilder.swift
//  SCKeychainManager
//
//  Created by Kimi on 25/06/2019.
//

import UIKit

internal class SCKeychainOperation {
    let type : SCKeychainOperationType
    let value : Data?
    let key : String
    
    init(type : SCKeychainOperationType, value: Data?, forKey defaultName: String) {
        self.type = type
        self.key = defaultName
        self.value = value
    }
}

extension SCKeychainOperation {
    func internalKey() -> String {
        return "\(type.rawValue)-\(key)"
    }
}

