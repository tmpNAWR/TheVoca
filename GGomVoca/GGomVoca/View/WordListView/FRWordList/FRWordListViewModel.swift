//
//  FRFRWordListViewModel.swift
//  GGomVoca
//
//  Created by Roen White on 2023/01/25.
//

import Foundation
import Combine

final class FRWordListViewModel: ObservableObject {
    //MARK: Service
    private let service: WordListService
    private var bag: Set<AnyCancellable> = Set<AnyCancellable>()
    
    init(service: WordListService) {
        self.service = service
    }
    
    @Published var words: [Word] = []
    
    // MARK: Vocabulary Properties
    var selectedVocabulary: Vocabulary = Vocabulary()
    let nationality: String = Nationality.FR.rawValue
    
    // MARK: 일치하는 id의 단어장 불러오기 Updated
    func getVocabulary(vocabularyID: Vocabulary.ID) {
        service.getVocabularyFromId(vocabularyID: vocabularyID)
            .sink { _ in
            } receiveValue: { [unowned self] voca in
                selectedVocabulary = voca
                
                guard let allWords = voca.words?.allObjects as? [Word] else { return }
                let filteredWords = allWords.filter { $0.deletedAt == "" || $0.deletedAt == nil }
                words = filteredWords.sorted { ($0.createdAt ?? "0") < ($1.createdAt ?? "0") }
            }
            .store(in: &bag)
    }
    
    // MARK: 단어 삭제하기 Updated
    func deleteWord(word: Word) {
        service.deleteWord(word: word)
            .sink { _ in
            } receiveValue: { [unowned self] _ in
                service.saveContext()
                getVocabulary(vocabularyID: selectedVocabulary.id)
            }
            .store(in: &bag)
    }
    
    // MARK: 단어 수정하기 Updated
    func updateWord(editWord: Word, word: String, meaning: [String], option: String = "") {
        service.updateWord(editWord: editWord, word: word, meaning: meaning, option: option)
            .sink { _ in
            } receiveValue: { [unowned self] value in
                service.saveContext()
                getVocabulary(vocabularyID: selectedVocabulary.id)
            }
            .store(in: &bag)
    }
    
    // MARK: 단어 추가하기 Updated
    func addNewWord(word: String, meaning: [String], option: String = "") {
        service.postWordData(word: word, meaning: meaning, option: option, voca: selectedVocabulary)
            .sink { _ in
            } receiveValue: { [unowned self] word in
                getVocabulary(vocabularyID: selectedVocabulary.id)
            }
            .store(in: &bag)
    }
    
    /// 단어장의 word 배열이 비어있을 때 나타낼 Empty 메세지의 다국어 처리
    // TODO: Vocabulary 구조체 자체의 property로 넣을 수 없을지?
    func getEmptyWord() -> String {
        return switch nationality {
        case Nationality.KO.rawValue:
            "비어 있는"
        case Nationality.EN.rawValue:
            "Empty"
        case Nationality.JA.rawValue:
            "空っぽの"
        case Nationality.FR.rawValue:
            "Vide"
        case "CH":
            "空"
        case "DE":
            "Geleert"
        case "ES":
            "Vacío"
        case "IT":
            "Vida"
        default :
            " "
        }
    }
    
    // MARK: Build Data For CSV
    func buildDataForCSV() -> String {
        var fullText = "word,option,meaning\n"
        
        for word in words where word.deletedAt == nil {
            var meaningString = word.meaning!.joined(separator: ",")
            
            if let meanings = word.meaning, meanings.count > 1 {
                meaningString = meaningString.reformForCSV
            }
            
            let aLine = "\(String(describing: word.word ?? "")),\(String(describing: word.option ?? "")),\(meaningString)"
            
            fullText += aLine + "\n"
        }
        
        return fullText
    }
}
