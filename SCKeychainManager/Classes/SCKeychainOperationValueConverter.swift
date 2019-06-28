//
//  SCKeychainOperationValueConverter.swift
//  SCKeychainManager
//
//  Created by Kimi on 28/06/2019.
//

import Foundation

internal enum SCKeychainOperationValueConverterError : Error {
    case unsupportedValueType
    case couldNotEncodeValue
}

internal class SCKeychainOperationValueConverter {

    static func data(with value : Any) throws -> Data {
        var data : Data?
        switch  value {
        case let str as String:
            data = str.data(using: .utf8)
            break
        case let bool as Bool:
            let int = Int(bool ? 1 : 0)
            data = Data(from: int)
            break
        case let int as Int:
            data = Data(from: int)
        default:
            throw SCKeychainOperationValueConverterError.unsupportedValueType
        }
        
        if let data = data {
            return data
        }
        throw SCKeychainOperationValueConverterError.couldNotEncodeValue
    }
    
    static func bool(from data : Data) -> Bool? {
        if let value = integer(from: data) {
            return value != 0
        }
        return nil
    }
    
    static func integer(from data : Data) -> Int? {
        return data.to(type: Int.self)
    }
}

extension Data {
    
    init<T>(from value: T) {
        self = Swift.withUnsafeBytes(of: value) { Data($0) }
    }
    
    func to<T>(type: T.Type) -> T? where T: ExpressibleByIntegerLiteral {
        var value: T = 0
        guard count >= MemoryLayout.size(ofValue: value) else { return nil }
        _ = Swift.withUnsafeMutableBytes(of: &value, { copyBytes(to: $0)} )
        return value
    }
}
