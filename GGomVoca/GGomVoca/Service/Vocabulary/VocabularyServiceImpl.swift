//
//  VocabularyServiceImpl.swift
//  GGomVoca
//
//  Created by JeongMin Ko on 2023/02/01.
//

import Foundation
import Combine

final class VocabularyServiceImpl: VocabularyService {
    // Repository
    private let coreDataRepo: CoreDataRepository
    private let cloudDataRepo: CloudKitRepository
    
    init(coreDataRepo: CoreDataRepository, cloudDataRepo: CloudKitRepository) {
        self.coreDataRepo = coreDataRepo
        self.cloudDataRepo = cloudDataRepo
    }
    
    /// 데이터를 디스크에 저장
    func saveContext() {
        coreDataRepo.saveContext()
    }
    
    /// 단어장 리스트 불러오기
    func fetchVocabularyList() -> AnyPublisher<[Vocabulary], RepositoryError> {
        let publisher = self.coreDataRepo.fetchVocaListData() //cloudDataRepo.syncVocaData() //cloud DB와 coreData DB 동기화
           .eraseToAnyPublisher()
        return publisher
    }
    
    /// 단어장 추가하기
    func postVocaData(vocaName: String, nationality: String) -> AnyPublisher<Vocabulary, RepositoryError> {
        //Create New Voca at CoreData -> Create New Voca Cloud
        let publisher = coreDataRepo.postVocaData(vocaName: vocaName, nationality: nationality)
            //.flatMap{ voca in self.cloudDataRepo.postVocaData(vocabulary: voca)}
           .eraseToAnyPublisher()
       return publisher
    }
    
    /// 단어장 고정 상태 업데이트
    // TODO: Publisher 반환타입 수정
    func updatePinnedVoca(id: UUID) -> AnyPublisher<String, RepositoryError> {
        return coreDataRepo.updatePinnedVoca(id: id)
    }
    
    /// 단어장 삭제
    // TODO: Publisher 반환타입 수정
    func deletedVocaData(id: UUID) -> AnyPublisher<String, RepositoryError> {
        //Delete Voca at CoreData -> Delete Voca Cloud
        let publisher = coreDataRepo.deletedVocaData(id: id) // cloudDataRepo.deleteVocaData(record: voca!.ckRecord)
           .eraseToAnyPublisher()
       return publisher
    }
}
