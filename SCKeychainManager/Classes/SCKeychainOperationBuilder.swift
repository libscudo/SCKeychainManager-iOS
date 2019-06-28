//
//  SCKeychainOperationBuilder.swift
//  SCKeychainManager
//
//  Created by Kimi on 25/06/2019.
//

import UIKit

public enum SCKeychainOperationBuilderError : Error {
    case inconsistentOperations
}

internal class SCKeychainOperationBuilderOptions {
    var onlyInForeground = true
    var icloudSync = false
}

open class SCKeychainOperationBuilder {
    
    private let manager : SCKeychainManager
    
    private let options = SCKeychainOperationBuilderOptions()
    private var operations = [String : SCKeychainOperation]()
    
    init(_ manager : SCKeychainManager, securely : Bool) {
        self.manager = manager
        self.options.onlyInForeground = securely
    }
}

// Setters
public extension SCKeychainOperationBuilder {
    
    /*!
     -setString:forKey: set a String for the provided key. Value is persistently store after apply() is called.
     */
    func set(_ value: String, forKey defaultName: String) throws -> SCKeychainOperationBuilder {
        return try addingSetOperation(value, forKey: defaultName)
    }

    /*!
     -setBool:forKey: set a Bool for the provided key. Value is persistently store after apply() is called.
     */
    func set(_ value: Bool, forKey defaultName: String) throws -> SCKeychainOperationBuilder {
        return try addingSetOperation(value, forKey: defaultName)
    }
    
    /*!
     -setInteger:forKey: set an Int for the provided key. Value is persistently store after apply() is called.
     */
    func set(_ value: Int, forKey defaultName: String) throws -> SCKeychainOperationBuilder {
        return try addingSetOperation(value, forKey: defaultName)
    }
}


// Setters - private
private extension SCKeychainOperationBuilder {
    
    private func addingSetOperation(_ value: Any, forKey defaultName: String) throws -> SCKeychainOperationBuilder {
        do {
            let v = try SCKeychainOperationValueConverter.data(with: value)
            let operation = SCKeychainOperation(type: .set, value: v, forKey: defaultName)
            self.operations[operation.internalKey()] = operation
        } catch {
            throw error
        }
        return self
    }
    
}

// Remove
public extension SCKeychainOperationBuilder {
    /*!
     -removeObject:forKey: remove an object for the provided key. Object is removed after apply() is called.
     */
    func removeObject(forKey defaultName: String) throws -> SCKeychainOperationBuilder {
        let operation = SCKeychainOperation(type: .remove, value: nil, forKey: defaultName)
        self.operations[operation.internalKey()] = operation
        return self
    }
}

// Apply
extension SCKeychainOperationBuilder {
    func apply() throws {
        if hasInconsistentOperations() {
            throw SCKeychainOperationBuilderError.inconsistentOperations
        }
        try manager.apply(operations: operations.values.map( { return $0 }), with: self.options)
    }
    
    func hasInconsistentOperations() -> Bool {
        let writeOps = operations.values.filter({ return $0.type == .set || $0.type == .remove })
        let readOps = operations.values.filter({ return $0.type == .get })
        return writeOps.count > 0 && readOps.count > 0
    }

}
