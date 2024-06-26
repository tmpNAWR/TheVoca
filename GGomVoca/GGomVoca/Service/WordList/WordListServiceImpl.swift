//
//  WordServiceImpl.swift
//  GGomVoca
//
//  Created by JeongMin Ko on 2023/02/06.
//

import Foundation
import Combine

final class WordListServiceImpl: WordListService {
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
    
    /// 일치하는 id의 단어장 불러오기
    func getVocabularyFromId(vocabularyID: Vocabulary.ID) -> AnyPublisher<Vocabulary, RepositoryError> {
        return coreDataRepo.getVocabularyFromID(vocabularyID: vocabularyID!)
    }
    
    /// 일치하는 id의 단어장 단어리스트 불러오기
    //TODO: Cloud Fetch
    func fetchWordList(vocabulary: Vocabulary) -> AnyPublisher<[Word], RepositoryError> {
        return coreDataRepo.getWordListFromVoca(voca: vocabulary)
    }
    
    /// 단어 추가하기
    //TODO: Cloud Fetch
    func postWordData(word: String, meaning: [String], option: String, voca: Vocabulary) -> AnyPublisher<Word, RepositoryError> {
        return coreDataRepo.addNewWord(word: word, meaning: meaning, option: option, voca: voca)
    }
    
    /// 단어 수정하기
    //TODO: Publisher 반환타입 수정
    func updateWord(editWord: Word, word: String, meaning: [String], option: String = "") -> AnyPublisher<Word, RepositoryError> {
        return coreDataRepo.updateWord(editWord: editWord, word: word, meaning: meaning, option: option)
    }
    
    /// 단어 삭제하기
    func deleteWord(word: Word) -> AnyPublisher<String, RepositoryError> {
        return coreDataRepo.deleteWord(word: word)
    }
}
