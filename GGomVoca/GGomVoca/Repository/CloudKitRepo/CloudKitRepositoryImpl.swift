//
//  CloudKitRepositoryImpl.swift
//  GGomVoca
//
//  Created by JeongMin Ko on 2023/02/01.
//

import Foundation
import CloudKit
import Combine
class CloudKitRepositoryImpl : CloudKitRepository {

    //기본 싱글톤 인스턴스를 통해 얻은 private Cloud 데이터베이스 컨테이너
    let database = CKContainer.default().privateCloudDatabase
    //MARK:  VocaList Cloud와 Coredata 동기화
    func syncVocaData() -> AnyPublisher<[Vocabulary], FirstPartyRepoError> {
        let predicate =  NSPredicate(value: true)
        //let query = CKQuery(recordType: Vocabulary.recordType, predicate: predicate)
        let query = CKQuery(recordType: "Vocabulary", predicate: predicate)
        var vocaList = [Vocabulary]()
        return Future<[Vocabulary], FirstPartyRepoError>{[weak self]observer in
            self?.database.perform(query, inZoneWith: nil) { (records, error) in
                if let error = error {
                    print("Error fetching vocabulary: \(error.localizedDescription)")
                    observer(.failure(FirstPartyRepoError.notFoundDataFromCloudKit))
                    return
                }
                
                //MARK:  Cloud와 CoreData에서 fetch한 각 Vocabulary의 버전 체크
                records?.forEach{ record in
                    let cloudVocaId = record["id"] as? String
                    let cloudVocaUpdatedAt = record.modificationDate
                    
                    if let coreDataVocabulary = PracticePersistence.shared.fetchVocabularyFromCoreData(withID: cloudVocaId ?? ""){
                        //MARK: Coredata가 최신인 경우.
                        if coreDataVocabulary.updatedAt ?? "" > "\(cloudVocaUpdatedAt)"{
                            vocaList.append(coreDataVocabulary)
                        }else if coreDataVocabulary.updatedAt ?? "" < "\(cloudVocaUpdatedAt)"{
                            //MARK: Cloud가 최신인 경우
                            //기존 Voca 제거
                            PracticePersistence.shared.deleteVocabularyFromCoreData(withID: cloudVocaId ?? "")
                            PracticePersistence.shared.saveContext()
                            //Cloud 버전으로 New Vocabulary 생성
                            if let cloudVocabulary = Vocabulary.from(ckRecord: record){
                                vocaList.append(cloudVocabulary)
                            }
                        }
                        
                    }else{
                        //MARK: Coredata는 없고 Cloud만 존재하는 경우
                        //Cloud 버전으로 New Vocabulary 생성
                        if let cloudVocabulary = Vocabulary.from(ckRecord: record){
                            vocaList.append(cloudVocabulary)
                        }
                    }
                }
                
                PracticePersistence.shared.saveContext()
                observer(.success(vocaList))
            }
            
        }.eraseToAnyPublisher()
        
    }
    
    //MARK:  WordList Cloud와 Coredata 동기화
    func syncVocaData(voca : Vocabulary) -> AnyPublisher<[Word], FirstPartyRepoError> {
        let query = CKQuery(recordType: "Word", predicate: NSPredicate(format: "recordID == %@", voca.ckRecord.recordID))
        return Future<[Word], FirstPartyRepoError>{[weak self] observer in
            self?.database.perform(query, inZoneWith: nil) { (records, error) in
                if let error = error {
                    print("Error retrieving word record: \(error)")
                    observer(.failure(FirstPartyRepoError.notFoundDataFromCloudKit))
                } else if let records = records, records.count > 0 {
                    let wordRecord = records[0]
                    let name = wordRecord["name"] as? String
                    let definition = wordRecord["definition"] as? String
                   
                    print("Word: \(name ?? ""), Definition: \(definition ?? "")")
                } else {
                    print("No records found")
                }
                observer(.success([Word]()))
            }
            
        }.eraseToAnyPublisher()
    }
    
    
    
    //MARK: Post New Voca CloudKit
    func postVocaData(vocabulary: Vocabulary) -> AnyPublisher<Vocabulary, FirstPartyRepoError> {
        let record = vocabulary.ckRecord
        return Future<Vocabulary, FirstPartyRepoError>{[weak self]observer in
            self?.database.save(record){(CKRecord, error) in
                if let error = error{
                    print("ERROR save Vocabulary : \(error.localizedDescription)")
                    observer(.failure(FirstPartyRepoError.notFoundDataFromCloudKit))
                    return
                }
                print("ckRecord: \(String(describing: CKRecord))")
                PracticePersistence.shared.saveContext()
                observer(.success(vocabulary))
            }
        }.eraseToAnyPublisher()
        
    }
    
    //MARK: Post New Word CloudKit
    func postWordData(word : Word,vocabulary: Vocabulary) -> AnyPublisher<Vocabulary, FirstPartyRepoError> {
        let vocaRecord = vocabulary.ckRecord
        let wordRecord = word.ckRecord(vocaOfWord: vocabulary)
        
        return Future<Vocabulary, FirstPartyRepoError>{[weak self]observer in
            let saveOperation = CKModifyRecordsOperation(recordsToSave: [vocaRecord, wordRecord], recordIDsToDelete: nil)
            //handle the results of the operation. It provides the saved records, deleted records (if any), and any error that might have occurred.
            saveOperation.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
                if let error = error {
                    print("Error saving records: \(error)")
                    observer(.failure(FirstPartyRepoError.notFoundDataFromCloudKit))
                } else {
                    print("Records saved successfully")
                    // records to the CloudKit
                    self?.database.add(saveOperation)
                    observer(.success(vocabulary))
                }
            }
         
           
        }.eraseToAnyPublisher()
        
    }
    
    //MARK: Update New Word CloudKit
    func updateVocaData(vocabulary: Vocabulary) -> AnyPublisher<String, FirstPartyRepoError> {
        //동일한 레코드 가 데이터베이스에 이미 존재하는 경우 기존 레코드가 새 데이터로 업데이트됩니다.
        //레코드가 없으면 새 레코드가 생성됩니다.
        let record = vocabulary.ckRecord
        return Future<String, FirstPartyRepoError>{[weak self]observer in
            self?.database.save(record){(CKRecord, error) in
                if let error = error{
                    print("ERROR save Vocabulary : \(error.localizedDescription)")
                    observer(.failure(FirstPartyRepoError.notFoundDataFromCloudKit))
                    return
                }
                print("ckRecord: \(String(describing: CKRecord))")
                PracticePersistence.shared.saveContext()
                observer(.success("Cloud update complete"))
            }
        }.eraseToAnyPublisher()
    }
    
    //코어데이터에 저장 후 실행
    //MARK: Update Word CloudKit
    func updateWordData(word : Word,vocabulary: Vocabulary) -> AnyPublisher<Vocabulary, FirstPartyRepoError> {
        let vocaRecord = vocabulary.ckRecord
        let wordRecord = word.ckRecord(vocaOfWord: vocabulary)
        
        return Future<Vocabulary, FirstPartyRepoError>{[weak self]observer in
            let saveOperation = CKModifyRecordsOperation(recordsToSave: [vocaRecord, wordRecord], recordIDsToDelete: nil)
            //handle the results of the operation. It provides the saved records, deleted records (if any), and any error that might have occurred.
            saveOperation.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
                if let error = error {
                    print("Error saving records: \(error)")
                    observer(.failure(FirstPartyRepoError.notFoundDataFromCloudKit))
                } else {
                    print("Records saved successfully")
                    // records to the CloudKit
                    self?.database.add(saveOperation)
                    observer(.success(vocabulary))
                }
            }
         
           
        }.eraseToAnyPublisher()
        
    }
    
    
    
    func deleteVocaData(record: CKRecord) -> AnyPublisher<String, FirstPartyRepoError> {
      
        return Future<String, FirstPartyRepoError>{[weak self] observer in
            self?.database.delete(withRecordID: record.recordID) { (recordID, error) -> Void in
                guard let _ = error else {
                    print("ERROR delete Vocabulary : \(String(describing: error?.localizedDescription))")
                    observer(.failure(FirstPartyRepoError.notFoundDataFromCloudKit))
                  return
                }
                
                observer(.success("Cloud 데이터 삭제 완료"))
              }
            
        }.eraseToAnyPublisher()
         
    }
    
    //코어데이터 삭제전 먼저 실행 필요
    //MARK: delete Word CloudKit
    func deleteWordData(word : Word,vocabulary: Vocabulary) -> AnyPublisher<String, FirstPartyRepoError> {
        let vocaRecord = vocabulary.ckRecord
        let wordRecord = word.ckRecord(vocaOfWord: vocabulary)
        
        return Future<String, FirstPartyRepoError>{[weak self]observer in
            
            self?.database.delete(withRecordID: wordRecord.recordID){ (recordID, error) in
                guard let _ = error else {
                     
                    observer(.failure(FirstPartyRepoError.notFoundDataFromCloudKit))
                      return
                    }
                observer(.success("Cloud에서 삭제되었습니다."))
            
            }
        }.eraseToAnyPublisher()
         
    }
    
   
    
  
}
