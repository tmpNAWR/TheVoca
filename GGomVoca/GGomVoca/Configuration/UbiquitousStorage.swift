//
//  UbiquitousStore.swift
//  GGomVoca
//
//  Created by Roen White on 2023/02/07.
//

import Foundation

// MARK: NSUbiquitousKeyValueStore를 마치 @AppStorage처럼 쓸 수 있게 해주는 프로퍼티래퍼
@propertyWrapper
struct UbiquitousStorage<T> {
    private let key: String
    private let defaultValue: T
    
    init(key: UbiquitousStorageItem, defaultValue: T) {
        self.key = key.rawValue
        self.defaultValue = defaultValue
    }
    
    var wrappedValue: T {
        get {
            NSUbiquitousKeyValueStore().object(forKey: key) as? T ?? defaultValue
        }
        set {
            NSUbiquitousKeyValueStore().set(newValue, forKey: key)
            NSUbiquitousKeyValueStore().synchronize()
        }
    }
}
