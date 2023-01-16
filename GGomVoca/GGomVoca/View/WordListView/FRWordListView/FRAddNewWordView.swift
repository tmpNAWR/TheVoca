//
//  FRAddNewWordView.swift
//  GGomVoca
//
//  Created by Roen White on 2022/12/20.
//

import SwiftUI

struct FRAddNewWordView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    var vocabulary: Vocabulary
    
    @Binding var isShowingAddWordView: Bool
    @Binding var words: [Word]
    @Binding var filteredWords: [Word]
    
    @State private var isContinue: Bool = false
    
    @State private var inputWord: String = ""
    @State private var inputOption: String = ""
    @State private var inputMeaning: String = ""
    
    // 입력값 공백 제거
    private var word: String {
        inputWord.trimmingCharacters(in: .whitespaces)
    }
    private var option: String {
        inputOption.trimmingCharacters(in: .whitespaces)
    }
    private var meaning: String {
        inputMeaning.trimmingCharacters(in: .whitespaces)
    }

    // 입력값이 공백일 때 경고메세지 출력 조건
    @State private var isWordEmpty: Bool = false
    @State private var isMeaningEmpty: Bool = false
    
    // 추가 후 TextFeildFocus 이동
    @FocusState private var wordFocused: Bool
    
    var body: some View {
        NavigationStack {
            
            Form {
                Toggle("계속 이어서 입력하기", isOn: $isContinue)
                    .toggleStyle(.switch)
                
                Section(header: HStack {
                    Text("단어")
                    if isWordEmpty {
                        Text("\(Image(systemName: "exclamationmark.circle")) 필수 입력 항목입니다.")
                    }
                }) {
                    TextField("단어를 입력하세요.", text: $inputWord)
                        .textInputAutocapitalization(.never)
                        .focused($wordFocused)
                }
                
                Section(header: Text("성별")) {
                    Picker("성별", selection: $inputOption) {
                        Text("남성형").tag("m")
                        Text("여성형").tag("f")
                    }
                    .pickerStyle(.segmented)
                }
                    
                Section(header: HStack {
                    Text("뜻")
                    if isMeaningEmpty {
                        Text("\(Image(systemName: "exclamationmark.circle")) 필수 입력 항목입니다.")
                    }
                }) {
                    TextField("뜻을 입력하세요.", text: $inputMeaning)
                        .textInputAutocapitalization(.never)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("새 단어 추가")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        isShowingAddWordView = false
                    } label: {
                        Text("취소").foregroundColor(.red)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        word.isEmpty ? (isWordEmpty = true) : (isWordEmpty = false)
                        meaning.isEmpty ? (isMeaningEmpty = true) : (isMeaningEmpty = false)
                        
                        if !word.isEmpty && !meaning.isEmpty {
                            addNewWord(vocabulary: vocabulary, word: word, meaning: meaning, option: option)
                            inputWord = ""
                            inputMeaning = ""
                            inputOption = ""
                            
                            if !isContinue {
                                isShowingAddWordView = false
                            }
                            wordFocused = true
                        }
                    } label: {
                        Text("추가")
                    }
                }
            }
        }
    }
    
    func addNewWord(vocabulary:Vocabulary, word: String, meaning: String, option: String = "") {
        let newWord = Word(context: viewContext)
        newWord.id = UUID()
        newWord.word = word
        newWord.meaning = meaning
        newWord.option = option
        newWord.vocabulary = vocabulary
        newWord.vocabularyID = vocabulary.id
        
        saveContext()
        words = vocabulary.words?.allObjects as! [Word]
        filteredWords = words.filter({ $0.deletedAt == "" || $0.deletedAt == nil })
        
    }
    
    // MARK: saveContext
    func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Error saving managed object context: \(error)")
        }
    }
}

//struct AddNewWordView_Previews: PreviewProvider {
//    static var previews: some View {
//        NavigationStack {
//            AddNewWordView(vocabulary: , isShowingAddWordView: .constant(true))
//        }
//    }
//}

