//
//  FRWordListViewModel.swift
//  GGomVoca
//
//  Created by Roen White on 2023/01/18.
//

import Foundation

class FRWordListViewModel: ObservableObject {
    // MARK: CoreData ViewContext
    var viewContext = PersistenceController.shared.container.viewContext
    var coreDataRepository = CoredataRepository()
    
    // MARK: View properties
    var selectedVocabulary: Vocabulary = Vocabulary()

    @Published var words: [Word] = []
    
    // MARK: 일치하는 id의 단어장 불러오기
    func getVocabulary(vocabularyID: Vocabulary.ID) {
        selectedVocabulary = coreDataRepository.getVocabularyFromID(vocabularyID: vocabularyID ?? UUID())
        let allWords = selectedVocabulary.words?.allObjects as? [Word] ?? []
        words = allWords.filter { $0.deletedAt == "" || $0.deletedAt == nil }
    }
    

    // MARK: 단어 삭제하기
    func deleteWord(word: Word) {
        word.deletedAt = "\(Date())"
        if let tempIndex = words.firstIndex(of: word) {
            words.remove(at: tempIndex)
        }
    }
    
    // MARK: 단어 수정하기
    func updateWord(editWord: Word, word: String, meaning: String, option: String = "") {
        guard let tempIndex = words.firstIndex(of: editWord) else { return }

        editWord.word = word
        editWord.meaning = meaning
        editWord.option = option
        
        saveContext()
        
        words[tempIndex] = editWord
    }
    
    // MARK: 단어 추가하기
    func addNewWord(vocabulary: Vocabulary, word: String, meaning: String, option: String = "") {
        let newWord = Word(context: viewContext)
        newWord.vocabularyID = vocabulary.id
        newWord.vocabulary = vocabulary
        newWord.id = UUID()
        newWord.word = word
        newWord.meaning = meaning
        newWord.option = option
        
        saveContext()
        
        words.append(newWord)
    }
    
    // MARK: saveContext
    func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Error saving managed object context: \(error)")
        }
    }
    
    func getEmptyWord(vocabularyID: Vocabulary.ID) -> String {
        selectedVocabulary = coreDataRepository.getVocabularyFromID(vocabularyID: vocabularyID ?? UUID())
        let na = selectedVocabulary.nationality ?? "KO"
        print("getEmptyWord", na)
        var emptyMsg: String {
            get {
                switch na {
                case "CH":
                    return "空"
                case "DE":
                    return "Geleert"
                case "EN":
                    return "Empty"
                case "ES":
                    return "Vacío"
                case "FR":
                    return "Vide"
                case "IT":
                    return "Vida"
                case "KO":
                    return "비어있는"
                case "JA":
                    return "空"
                default :
                    return " "
                }
            }
        }
        return emptyMsg
    }
    
    // MARK: buildDataForCSV
    func buildDataForCSV(vocabularyID: Vocabulary.ID) -> String? {
        
        // 1. find the vocabulary by id
        let voca = coreDataRepository.getVocabularyFromID(vocabularyID: vocabularyID ?? UUID())
        var fullText = "word,option,meaning\n"
        var aLine = ""
        for target in voca.words ?? [] {
            aLine = ""
            if (target as AnyObject).deletedAt! == nil {
                if target is Word {
                    aLine = "\(String(describing: (target as AnyObject).word! ?? "")),\(String(describing: (target as AnyObject).option! ?? "")),\(String(describing: (target as AnyObject).meaning! ?? ""))"
                }
                fullText += aLine + "\n"
            }
        }
        print("CSV En construction\n")     // For test
        print(fullText)
        print("***")
        return fullText
    }

}
