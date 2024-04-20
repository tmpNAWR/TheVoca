//
//  CoredataRepositoryImpl.swift
//  GGomVoca
//
//  Created by JeongMin Ko on 2023/02/01.
//

import Foundation
import Combine
import CoreData

final class CoreDataRepositoryImpl: CoreDataRepository {
    // CloudKit database와 동기화하기 위해서는 NSPersistentCloudKitContainer로 변경
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    /// 데이터를 디스크에 저장하는 메서드
    func saveContext() {
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }

    /// 단어장 리스트 불러오기
    func fetchVocaListData() -> AnyPublisher<[Vocabulary], RepositoryError> {
        return Future<[Vocabulary], RepositoryError> { [unowned self] observer in
            let vocabularyFetch = Vocabulary.fetchRequest()
            
            do {
                let results = try context.fetch(vocabularyFetch) as [Vocabulary]
                observer(.success(results))
            } catch {
                observer(.failure(RepositoryError.coreDataRepositoryError(error: .notFoundDataFromCoreData)))
            }
        }.eraseToAnyPublisher()
    }
    
    /// 단어장 id로 불러오기
    func getVocabularyFromID(vocabularyID: UUID) -> AnyPublisher<Vocabulary, RepositoryError> {
        return Future<Vocabulary, RepositoryError> { [unowned self] observer in
            let vocabularyFetch = Vocabulary.fetchRequest()
            vocabularyFetch.predicate = NSPredicate(format: "id == %@", vocabularyID as CVarArg)
            
            do {
                let results = try context.fetch(vocabularyFetch) as [Vocabulary]
                let voca = results.first ?? Vocabulary()
                observer(.success(voca))
            } catch {
                observer(.failure(RepositoryError.coreDataRepositoryError(error: .notFoundDataFromCoreData)))
            }
        }.eraseToAnyPublisher()
    }
    
    /// 단어리스트 불러오기
    func getWordListFromVoca(voca: Vocabulary) -> AnyPublisher<[Word], RepositoryError> {
        return Future<[Word], RepositoryError> { observer in
            var words = [Word]()
            let allWords = voca.words?.allObjects as? [Word] ?? []
            words = allWords.filter { $0.deletedAt == "" || $0.deletedAt == nil }
            observer(.success(words))
        }.eraseToAnyPublisher()
    }
    
    /// 단어장 추가하기
    func postVocaData(vocaName: String, nationality: String) -> AnyPublisher<Vocabulary, RepositoryError> {
        return Future<Vocabulary, RepositoryError> { [unowned self] observer in
            let newVocabulary = Vocabulary(context: context)
            newVocabulary.id = UUID()
            newVocabulary.name = "\(vocaName)"
            newVocabulary.nationality = "\(nationality)"
            newVocabulary.createdAt = "\(Date())"
            newVocabulary.words = NSSet(array: [])
            newVocabulary.updatedAt = "\(Date())"
            
            saveContext()
            observer(.success(newVocabulary))
        }.eraseToAnyPublisher()
    }
    
    /// 단어 추가하기
    func addNewWord(word: String, meaning: [String], option: String, voca: Vocabulary) -> AnyPublisher<Word, RepositoryError> {
        return Future<Word, RepositoryError> { [unowned self] observer in
            let newWord = Word(context: context)
            newWord.vocabularyID = voca.id
            newWord.vocabulary = voca
            newWord.id = UUID()
            newWord.word = word
            newWord.meaning = meaning
            newWord.option = option
            newWord.createdAt = "\(Date())"

            saveContext()
            observer(.success(newWord))
        }.eraseToAnyPublisher()
    }
    
    /// 단어장 고정 상태 업데이트하기
    func updatePinnedVoca(id: UUID) -> AnyPublisher<String, RepositoryError> {
        return Future<String, RepositoryError> { [unowned self] observer in
            let vocabularyFetch = Vocabulary.fetchRequest()
            vocabularyFetch.predicate = NSPredicate(format: "id = %@", id as CVarArg)
            
            do {
                let results = try context.fetch(vocabularyFetch) as [Vocabulary]
                
                guard let objectUpdate = results.first else { return }
                objectUpdate.setValue(!objectUpdate.isPinned, forKey: "isPinned")
                observer(.success("\(objectUpdate)"))
            } catch {
                observer(.failure(RepositoryError.coreDataRepositoryError(error: .notFoundDataFromCoreData)))
            }
        }.eraseToAnyPublisher()
    }
    
    /// 단어 수정하기
    func updateWord(editWord: Word, word: String, meaning: [String], option: String) -> AnyPublisher<Word, RepositoryError> {
        return Future<Word, RepositoryError> { [unowned self] observer in
            editWord.word = word
            editWord.meaning = meaning
            editWord.option = option

            saveContext()
            observer(.success(editWord))
        }.eraseToAnyPublisher()
    }
    
    /// 단어장 삭제 후 반영 함수
    func deletedVocaData(id: UUID) -> AnyPublisher<String, RepositoryError> {
        return Future<String, RepositoryError> { [unowned self] observer in
            let vocabularyFetch = Vocabulary.fetchRequest()
            vocabularyFetch.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            
            do {
                let results = try context.fetch(vocabularyFetch) as [Vocabulary]
                
                guard let voca = results.first else { return }
                voca.deleatedAt = "\(Date())"
                observer(.success(""))
            } catch {
                observer(.failure(RepositoryError.coreDataRepositoryError(error: .notFoundDataFromCoreData)))
            }
        }.eraseToAnyPublisher()
    }
    
    /// 단어 삭제
    func deleteWord(word: Word) -> AnyPublisher<String, RepositoryError> {
        return Future<String, RepositoryError> { [unowned self] observer in
            word.deletedAt = "\(Date())"

            saveContext()
            observer(.success("로컬DB 단어 삭제 성공"))
        }.eraseToAnyPublisher()
    }
}
