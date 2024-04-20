//
//  TestServiceImpl.swift
//  GGomVoca
//
//  Created by JeongMin Ko on 2023/02/13.
//

import Foundation
import Combine

final class WordTestServiceImpl: WordTestService {
    //Repository
    private let coreDataRepo: CoreDataRepository
    private let cloudDataRepo: CloudKitRepository
    
    init(coreDataRepo: CoreDataRepository, cloudDataRepo: CloudKitRepository) {
        self.coreDataRepo = coreDataRepo
        self.cloudDataRepo = cloudDataRepo
    }
    
    /// 디스크에 저장.
    func saveContext() {
        coreDataRepo.saveContext()
    }
    
    /// 일치하는 id의 단어장 불러오기
    func getVocabularyFromId(vocabularyID: Vocabulary.ID) -> AnyPublisher<Vocabulary, RepositoryError> {
        return coreDataRepo.getVocabularyFromID(vocabularyID: vocabularyID!)
    }
    
    /// 일치하는 id의 단어장 단어리스트 불러오기
    // TODO: Cloud Fetch
    func fetchWordList(vocabulary: Vocabulary) -> AnyPublisher<[Word], RepositoryError> {
        return coreDataRepo.getWordListFromVoca(voca: vocabulary)
    }
    
    /// - Core Data에 시험결과 저장
//    func testResult() {
//       
//    }
}
