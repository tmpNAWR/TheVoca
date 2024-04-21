//
//  UserManager.swift
//  GGomVoca
//
//  Created by JeongMin Ko on 2023/01/17.
//

import SwiftUI
import Combine

final class UserManager {
    static let shared = UserManager()
    
    private init() {}
    
    let valueChanged = NotificationCenter.default.publisher(for: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: NSUbiquitousKeyValueStore.default).receive(on: RunLoop.main)
    
    @UbiquitousStorage(key: .pinnedVocabularyIDs,   defaultValue: []) var pinnedVocabularyIDs  : [String]
    @UbiquitousStorage(key: .koreanVocabularyIDs,   defaultValue: []) var koreanVocabularyIDs  : [String]
    @UbiquitousStorage(key: .englishVocabularyIDs,  defaultValue: []) var englishVocabularyIDs : [String]
    @UbiquitousStorage(key: .japanishVocabularyIDs, defaultValue: []) var japanishVocabularyIDs: [String]
    @UbiquitousStorage(key: .frenchVocabularyIDs,   defaultValue: []) var frenchVocabularyIDs  : [String]
    
    func sync() {
        NSUbiquitousKeyValueStore().synchronize()
        
        print("고정", pinnedVocabularyIDs)
        print("한국", koreanVocabularyIDs)
        print("영어", englishVocabularyIDs)
        print("일본", japanishVocabularyIDs)
        print("프랑스", frenchVocabularyIDs)
    }
    
    /// 단어장 추가
    static func addVocabulary(id: String, nationality: String) {
        switch nationality {
        case Nationality.KO.rawValue:
            shared.koreanVocabularyIDs.append(id)
        case Nationality.EN.rawValue:
            shared.englishVocabularyIDs.append(id)
        case Nationality.JA.rawValue:
            shared.japanishVocabularyIDs.append(id)
        case Nationality.FR.rawValue:
            shared.frenchVocabularyIDs.append(id)
        default:
            break
        }
    }
    
    /// 단어장 삭제
    static func deleteVocabulary(id: String) {
        if let index = shared.pinnedVocabularyIDs.firstIndex(of: id) {
            shared.pinnedVocabularyIDs.remove(at: index)
        } else if let index = shared.koreanVocabularyIDs.firstIndex(of: id) {
            shared.koreanVocabularyIDs.remove(at: index)
        } else if let index = shared.englishVocabularyIDs.firstIndex(of: id) {
            shared.englishVocabularyIDs.remove(at: index)
        } else if let index = shared.japanishVocabularyIDs.firstIndex(of: id) {
            shared.japanishVocabularyIDs.remove(at: index)
        } else if let index = shared.frenchVocabularyIDs.firstIndex(of: id) {
            shared.frenchVocabularyIDs.remove(at: index)
        }
    }
    
    /// EditMode에서 단어장 삭제
    static func editModeDeleteVocabulary(at offset: IndexSet.Element, in group: String) -> String {
        var result = ""
        
        switch group {
        case "pinned":
            result = UserManager.shared.pinnedVocabularyIDs.remove(at: offset)
        case "korean":
            result = UserManager.shared.koreanVocabularyIDs.remove(at: offset)
        case "english":
            result = UserManager.shared.englishVocabularyIDs.remove(at: offset)
        case "japanish":
            result = UserManager.shared.japanishVocabularyIDs.remove(at: offset)
        case "french":
            result = UserManager.shared.frenchVocabularyIDs.remove(at: offset)
        default:
            break
        }
        
        return result
    }
    
    /// 단어장 고정
    static func pinnedVocabulary(id: String, nationality: String) {
        if let index = shared.pinnedVocabularyIDs.firstIndex(of: id) {
            shared.pinnedVocabularyIDs.remove(at: index)
            addVocabulary(id: id, nationality: nationality)
            return
        }
        
        shared.pinnedVocabularyIDs.append(id)
        
        if let index = shared.koreanVocabularyIDs.firstIndex(of: id) {
            shared.koreanVocabularyIDs.remove(at: index)
        } else if let index = shared.englishVocabularyIDs.firstIndex(of: id) {
            shared.englishVocabularyIDs.remove(at: index)
        } else if let index = shared.japanishVocabularyIDs.firstIndex(of: id) {
            shared.japanishVocabularyIDs.remove(at: index)
        } else if let index = shared.frenchVocabularyIDs.firstIndex(of: id) {
            shared.frenchVocabularyIDs.remove(at: index)
        }
    }
    
    /// 유비쿼터스 초기화
    static func initializeData() {
        shared.pinnedVocabularyIDs = []
        shared.koreanVocabularyIDs = []
        shared.englishVocabularyIDs = []
        shared.japanishVocabularyIDs = []
        shared.frenchVocabularyIDs = []
    }
}
