//
//  SCKeychainManager.swift
//  SCKeychainManager
//
//  Created by Kimi on 25/06/2019.
//

import UIKit

public enum SCKeychainManagerError : Error {
    case invalidKey(String)
    case invalidValueForKey(String)
    case errorSettingKey(String)
    case errorUpdatingKey(String)
    case errorRemovingKey(String)
    
}

open class SCKeychainManager: NSObject {
    
    public static let standard = SCKeychainManager()
    
    public static let defaultAuthenticationAllowableReuseDuration = 10
    public var authenticationAllowableReuseDuration = defaultAuthenticationAllowableReuseDuration
    
    private(set) var serviceName : String
    private(set) var accessGroup : String?
    
    private override convenience init() {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            fatalError("Bundle.main.bundleIdentifier is nil")
        }
        
        self.init(serviceName: bundleIdentifier, accessGroup: nil)
    }
    
    init(serviceName : String, accessGroup : String?) {
        self.serviceName = serviceName
        self.accessGroup = accessGroup
    }
    
    public func securely() -> SCKeychainOperationBuilder {
        return SCKeychainOperationBuilder(self, securely: true)
    }
}

extension SCKeychainManager {
    internal func apply(operations : [SCKeychainOperation], with options : SCKeychainOperationBuilderOptions) throws {
        for operation in operations {
            switch operation.type {
            case .set:
                guard let value = operation.value else {
                    throw SCKeychainManagerError.invalidValueForKey("Could not set value 'nil' for key: \(operation.key)")
                }
                try set(value, forKey : operation.key, with: options)
                break
            case .remove:
                try removeValue(forKey : operation.key)
                break
            case .get:
                
                break
                
            }
        }
    }
    
    internal func set(_ value : Data, forKey defaultName : String, with options : SCKeychainOperationBuilderOptions) throws {
        var query: [CFString : Any] = createTypedQuery(type: kSecClassGenericPassword, with: options)
        
        guard let dataKey = defaultName.data(using: String.Encoding.utf8) else {
            throw SCKeychainManagerError.invalidKey("Invalid key: \(defaultName)")
        }
        
        query[kSecAttrGeneric] = dataKey
        query[kSecAttrAccount] = dataKey
        query[kSecValueData] = value
        
        let cfQuery = query as CFDictionary
        var status: OSStatus = SecItemAdd(cfQuery, nil)
        
        if status != errSecSuccess && status != errSecDuplicateItem {
            var msg = "Error code: \(status)"
            if #available(iOS 11.3, *) {
                if let errorMsg = SecCopyErrorMessageString(status, nil) as String? {
                    msg = errorMsg
                }
            }
            throw SCKeychainManagerError.errorSettingKey(msg)
        } else if status == errSecDuplicateItem {
            status = SecItemUpdate(cfQuery, [kSecValueData:value] as CFDictionary)
            
            if status != errSecSuccess {
                var msg = "Error code: \(status)"
                if #available(iOS 11.3, *) {
                    if let errorMsg = SecCopyErrorMessageString(status, nil) as String? {
                        msg = errorMsg
                    }
                }
                throw SCKeychainManagerError.errorUpdatingKey("Error updating key: \(defaultName). \(msg)")
            }
        }
    }
    
    internal func removeValue(forKey defaultName : String) throws {
        var query: [CFString : Any] = createTypedQuery(type: kSecClassGenericPassword, with: nil)
        
        guard let dataKey = defaultName.data(using: String.Encoding.utf8) else {
            throw SCKeychainManagerError.invalidKey("Invalid key: \(defaultName)")
        }
        
        query[kSecAttrGeneric] = dataKey
        query[kSecAttrAccount] = dataKey
        
        let status: OSStatus = SecItemDelete(query as CFDictionary)
        
        if status != errSecSuccess { // }&& status != errSecItemNotFound {
            var msg = "Error code: \(status)"
            if #available(iOS 11.3, *) {
                if let errorMsg = SecCopyErrorMessageString(status, nil) as String? {
                    msg = errorMsg
                }
            }
            throw SCKeychainManagerError.errorRemovingKey("Error updating key: \(defaultName). \(msg)")
        }
    }
}

// getters
public extension SCKeychainManager {
    func rsaPublicKey(identifiedBy indentifier : String) -> SecKey? {
        let query = createRSAPublicKeyTypedQuery(indentifier)
        
        var dataRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataRef)
        
        if status == errSecSuccess, let ref = dataRef {
            return (ref as! SecKey)
            
        }
        
        return nil
    }
    
    func string(forKey defaultName : String) -> String? {
        if let storedData = try? data(forKey: defaultName) {
            return String(data: storedData, encoding: .utf8) as String?
        }
        return nil
    }

    func integer(forKey defaultName : String) -> Int? {
        if let storedData = try? data(forKey: defaultName) {
            return SCKeychainOperationValueConverter.integer(from: storedData)
        }
        return nil
    }
    
    func bool(forKey defaultName : String) -> Bool? {
        if let storedData = try? data(forKey: defaultName) {
            return SCKeychainOperationValueConverter.bool(from: storedData)
        }
        return nil
    }
    
    internal func data(forKey defaultName : String) throws -> Data? {
        var query: [CFString : Any] = createTypedQuery(type: kSecClassGenericPassword, with: nil)
        
        guard let dataKey = defaultName.data(using: String.Encoding.utf8) else {
            throw SCKeychainManagerError.invalidKey("Invalid key: \(defaultName)")
        }
        
        query[kSecAttrGeneric] = dataKey
        query[kSecAttrAccount] = dataKey
        query[kSecMatchLimit] = kSecMatchLimitOne
        query[kSecReturnData] = kCFBooleanTrue
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        return status == noErr ? result as? Data : nil
    }
}

// Keychain query dictionary builder
extension SCKeychainManager {
    
    func createRSAPublicKeyTypedQuery(_ identifier : String) -> [CFString : Any] {
        let keyIdentifier = "\(self.serviceName).\(identifier)"
        let query = [
            kSecClass: kSecClassKey,
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrApplicationTag: keyIdentifier,
            kSecAttrKeyClass: kSecAttrKeyClassPublic,
            kSecReturnData: true
        ] as [CFString : Any]
        
        return query
    }
    
    func createTypedQuery(type : CFString, with options : SCKeychainOperationBuilderOptions?) -> [CFString : Any] {
        var query: [CFString : Any] = [kSecClass : type]
        query[kSecAttrService] = serviceName

        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup] = accessGroup
        }

        guard let options = options else {
            return query
        }
        
        if options.onlyInForeground {
            if options.icloudSync  {
                /*
                 @constant kSecAttrAccessibleWhenUnlocked Item data can only be accessed
                 while the device is unlocked. This is recommended for items that only
                 need be accesible while the application is in the foreground.  Items
                 with this attribute will migrate to a new device when using encrypted
                 backups.
                */
               query[kSecAttrAccessible] = kSecAttrAccessibleWhenUnlocked
            } else {
                /*
                 @constant kSecAttrAccessibleWhenUnlockedThisDeviceOnly Item data can only
                 be accessed while the device is unlocked. This is recommended for items
                 that only need be accesible while the application is in the foreground.
                 Items with this attribute will never migrate to a new device, so after
                 a backup is restored to a new device, these items will be missing.
                */
               query[kSecAttrAccessible] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            }
            
        } else {
            if options.icloudSync  {
                /*
                 @constant kSecAttrAccessibleAfterFirstUnlock Item data can only be
                 accessed once the device has been unlocked after a restart.  This is
                 recommended for items that need to be accesible by background
                 applications. Items with this attribute will migrate to a new device
                 when using encrypted backups.
                */
                query[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlock
            } else {
                /*
                 @constant kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly Item data can
                 only be accessed once the device has been unlocked after a restart.
                 This is recommended for items that need to be accessible by background
                 applications. Items with this attribute will never migrate to a new
                 device, so after a backup is restored to a new device these items will
                 be missing.
                */
                query[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            }
        }

        return query
    }
}
