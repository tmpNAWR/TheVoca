//
//  Array.swift
//  GGomVoca
//
//  Created by tae on 2023/02/03.
//

import Foundation

extension Array where Element: Comparable {
    func containsSameElements(as other: [Element]) -> Result {
        /// 개수가 똑같으면, 완전히 같은 값들만 가져야 한다.
        if self.count == other.count && self.sorted() == other.sorted() {
            return .right
        }
        
        /// 개수가 다르다면, 입력된 값들이 정답에 전부 포함되어야 한다.
        for i in other.indices where self.contains(other[i]) {
            /// 하나라도 정답이 있을 경우, 정답 처리가 된다.
            return .half
        }
        
        return .wrong
    }
}

extension Array: RawRepresentable where Element: Codable {
    /// NSUbiquitousKeyValueStore에 Array를 담기 위한 extension
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode([Element].self, from: data)
        else {
            return nil
        }
        self = result
    }

    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return result
    }
}
