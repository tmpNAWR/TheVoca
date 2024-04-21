//
//  CloudKitRepositoryImpl.swift
//  GGomVoca
//
//  Created by JeongMin Ko on 2023/02/01.
//

import Foundation
import CloudKit
import Combine

final class CloudKitRepositoryImpl: CloudKitRepository {
    /// 기본 싱글턴 인스턴스를 통해 얻은 private Cloud 데이터베이스 컨테이너
    private let database = CKContainer.default().privateCloudDatabase
    
    func syncVocaData() -> AnyPublisher<[Vocabulary], RepositoryError> {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Vocabulary", predicate: predicate)
        var vocaList = [Vocabulary]()
        
        return Future<[Vocabulary], RepositoryError> { [unowned self] observer in
            database.perform(query, inZoneWith: nil) { (records, error) in
                guard error != nil, let records else {
                    observer(.failure(RepositoryError.cloudRepositoryError(error: .failPostWordFromCloudKit)))
                    return
                }
                
                /// Cloud와 CoreData에서 fetch한 각 Vocabulary의 버전 체크
                records.forEach { record in
                    guard let cloudVocaId = record["id"] as? String, let cloudVocaUpdatedAt = record.modificationDate else {
                        observer(.failure(RepositoryError.cloudRepositoryError(error: .failUpdateVocaFromCloudData)))
                        return
                    }
                    
                    // CoreData에 단어장 존재 확인
                    guard let coreDataVocabulary = PersistenceController.shared.fetchVocabularyFromCoreData(withID: cloudVocaId) else {
                        /// Coredata는 없고 Cloud만 존재하는 경우 Cloud 버전으로 New Vocabulary 생성
                        guard let cloudVocabulary = Vocabulary.from(ckRecord: record) else { return }
                        vocaList.append(cloudVocabulary)
                        return
                    }
                    
                    // Vocabulary의 최신 버전 확인
                    guard let coreDataUpdatedAt = coreDataVocabulary.updatedAt, coreDataUpdatedAt < "\(cloudVocaUpdatedAt)" else {
                        /// CoreData가 최신이거나 두 데이터의 업데이트 시점이 동일한 경우
                        vocaList.append(coreDataVocabulary)
                        return
                    }
                    
                    /// Cloud가 최신인 경우 기존 Voca 제거 후 Cloud 버전으로 New Vocabulary 생성
                    PersistenceController.shared.deleteVocabularyFromCoreData(withID: cloudVocaId)
                    PersistenceController.shared.saveContext()

                    guard let cloudVocabulary = Vocabulary.from(ckRecord: record) else {
                        observer(.failure(.cloudRepositoryError(error: .failUpdateVocaFromCloudData)))
                        return
                    }
                    
                    vocaList.append(cloudVocabulary)
                }
                
                PersistenceController.shared.saveContext()
                observer(.success(vocaList))
            }
        }.eraseToAnyPublisher()
    }
        
    ///  WordList Cloud와 Coredata 동기화
    func syncVocaData(voca: Vocabulary) -> AnyPublisher<[Word], RepositoryError> {
        let query = CKQuery(recordType: "Word", predicate: NSPredicate(format: "recordID == %@", voca.ckRecord.recordID))
        
        return Future<[Word], RepositoryError> { [unowned self] observer in
            database.perform(query, inZoneWith: nil) { records, error in
                guard error != nil, let records else {
                    observer(.failure(RepositoryError.cloudRepositoryError(error: .failPostWordFromCloudKit)))
                    return
                }
                
                guard let wordRecord = records.first,
                      let _ = wordRecord["name"] as? String,
                      let _ = wordRecord["definition"] as? String else { return }
                
                observer(.success([Word]()))
            }
        }.eraseToAnyPublisher()
    }
    
    /// Post New Voca CloudKit
    func postVocaData(vocabulary: Vocabulary) -> AnyPublisher<Vocabulary, RepositoryError> {
        let record = vocabulary.ckRecord
        
        return Future<Vocabulary, RepositoryError> { [unowned self] observer in
            database.save(record) { _, error in
                guard error != nil else {
                    observer(.failure(RepositoryError.cloudRepositoryError(error: .failPostWordFromCloudKit)))
                    return
                }
                
                PersistenceController.shared.saveContext()
                observer(.success(vocabulary))
            }
        }.eraseToAnyPublisher()
    }
    
    /// Post New Word CloudKit
    func postWordData(word: Word,vocabulary: Vocabulary) -> AnyPublisher<Vocabulary, RepositoryError> {
        let vocaRecord = vocabulary.ckRecord
        let wordRecord = word.ckRecord(vocaOfWord: vocabulary)
        
        return Future<Vocabulary, RepositoryError> { observer in
            let saveOperation = CKModifyRecordsOperation(recordsToSave: [vocaRecord, wordRecord], recordIDsToDelete: nil)

            saveOperation.modifyRecordsResultBlock = { [unowned self] result in
                switch result {
                case .success:
                    database.add(saveOperation)
                    observer(.success(vocabulary))
                case .failure:
                    observer(.failure(RepositoryError.cloudRepositoryError(error: .failPostWordFromCloudKit)))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    /// Update New Word CloudKit
    func updateVocaData(vocabulary: Vocabulary) -> AnyPublisher<String, RepositoryError> {
        // 동일한 레코드 가 데이터베이스에 이미 존재하는 경우 기존 레코드가 새 데이터로 업데이트됩니다. 레코드가 없으면 새 레코드가 생성됩니다.
        let record = vocabulary.ckRecord
        
        return Future<String, RepositoryError> { [unowned self] observer in
            database.save(record) { _, error in
                guard error != nil else {
                    observer(.failure(RepositoryError.cloudRepositoryError(error: .failPostWordFromCloudKit)))
                    return
                }
                
                PersistenceController.shared.saveContext()
                observer(.success("Cloud update complete"))
            }
        }.eraseToAnyPublisher()
    }
    
    /// Update Word CloudKit : 코어데이터에 저장 후 실행
    func updateWordData(word: Word,vocabulary: Vocabulary) -> AnyPublisher<Vocabulary, RepositoryError> {
        let vocaRecord = vocabulary.ckRecord
        let wordRecord = word.ckRecord(vocaOfWord: vocabulary)
        
        return Future<Vocabulary, RepositoryError> { observer in
            let saveOperation = CKModifyRecordsOperation(recordsToSave: [vocaRecord, wordRecord], recordIDsToDelete: nil)
            
            saveOperation.modifyRecordsResultBlock = { [unowned self] result in
                switch result {
                case .success:
                    database.add(saveOperation)
                    observer(.success(vocabulary))
                case .failure:
                    observer(.failure(RepositoryError.cloudRepositoryError(error: .failPostWordFromCloudKit)))
                }
            }
        }.eraseToAnyPublisher()
        
    }
    
    func deleteVocaData(record: CKRecord) -> AnyPublisher<String, RepositoryError> {
        return Future<String, RepositoryError> { [unowned self] observer in
            database.delete(withRecordID: record.recordID) { recordID, error -> Void in
                guard error != nil else {
                    observer(.failure(RepositoryError.cloudRepositoryError(error: .failPostWordFromCloudKit)))
                    return
                }
                
                observer(.success("Cloud 데이터 삭제 완료"))
            }
        }.eraseToAnyPublisher()
    }
    
    /// delete Word CloudKit
    func deleteWordData(word: Word,vocabulary: Vocabulary) -> AnyPublisher<String, RepositoryError> {
        _ = vocabulary.ckRecord
        let wordRecord = word.ckRecord(vocaOfWord: vocabulary)
        
        return Future<String, RepositoryError> { [unowned self]observer in
            database.delete(withRecordID: wordRecord.recordID) { recordID, error in
                guard error != nil else {
                    observer(.failure(RepositoryError.cloudRepositoryError(error: .failPostWordFromCloudKit)))
                    return
                }
                
                observer(.success("Cloud에서 삭제되었습니다."))
            }
        }.eraseToAnyPublisher()
    }  
}
