//
//  SCPKIHelper.swift
//  SCPKIHelper
//
//  Created by Kimi on 28/06/2019.
//

import UIKit

public enum SCPKIError : Error {
    case itemAlreadyExistInKeychain(String)
    case keyNotFound(String)
    case couldNotCreateKeyPair(String)
}

open class SCPKIHelper : NSObject {

    public static let shared = SCPKIHelper()
    
    private(set) var serviceName : String
    
    private override convenience init() {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            fatalError("Bundle.main.bundleIdentifier is nil")
        }
        
        self.init(serviceName: bundleIdentifier)
    }
    
    init(serviceName : String) {
        self.serviceName = serviceName
    }
    
}

// Generate key pair
public extension SCPKIHelper {
    func generateKeyPair(with spec : SCPKIKeySpec, identifiedBy identifier: String, _ completion:  (@escaping (_ publicKey : SecKey?, _ privateKey : SecKey?, _ error: Error?) -> Void)) {
        
        let keyPairIdentifier = "\(self.serviceName).\(identifier)"
        let accessLevel = spec.accessOnlyWhenUnlocked ? kSecAttrAccessibleWhenUnlocked : kSecAttrAccessibleAfterFirstUnlock
        
        let privateKeyAccess = SecAccessControlCreateWithFlags(nil,
                                                               accessLevel,
                                                               [.userPresence, .privateKeyUsage],
                                                               nil)!
        
        let privateKeySpec: [CFString : Any] = [
            kSecAttrIsPermanent: spec.storeInKeychain,
            kSecAttrApplicationTag: keyPairIdentifier,
            kSecAttrAccessControl: privateKeyAccess
        ]
        
        let publicKeyParams: [CFString : Any] = [
            kSecAttrIsPermanent: spec.storeInKeychain,
            kSecAttrApplicationTag : keyPairIdentifier
        ]

        let keyPairParams: [CFString: Any] = [
            kSecPublicKeyAttrs: publicKeyParams,
            kSecPrivateKeyAttrs: privateKeySpec,
            kSecAttrKeyType: spec.keyType,
            kSecAttrKeySizeInBits: spec.sizeInBits,
        ]
        
        // private / public key generation takes a lot of time, so this operation must be perform in another thread.
        DispatchQueue.global().async {
            var publicKey : SecKey?
            var privateKey : SecKey?
            
            let status = SecKeyGeneratePair(keyPairParams as CFDictionary, &publicKey, &privateKey)
            
            if status != errSecSuccess {
                let defaultErrorMessage = "An unknown error ocurred while generating pair with code: \(status)"
                var error = SCPKIError.couldNotCreateKeyPair(defaultErrorMessage)
                
                switch (status) {
                    case errSecDuplicateItem: error = SCPKIError.itemAlreadyExistInKeychain("The item identified by '\(keyPairIdentifier)' already exist in the Keychain")
                    case errSecItemNotFound: error = SCPKIError.keyNotFound("The item identified by '\(keyPairIdentifier)' does not exist")
                    default: break
                }
                
                DispatchQueue.main.async {
                    completion(nil, nil, error)
                }
                return
            }
            
            DispatchQueue.main.async {
                completion(publicKey, privateKey, nil)
            }
        }
    }
}
