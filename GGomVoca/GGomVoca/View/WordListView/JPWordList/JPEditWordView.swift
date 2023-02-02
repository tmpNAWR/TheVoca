//
//  JPEditWordView.swift
//  GGomVoca
//
//  Created by tae on 2022/12/21.
//

import SwiftUI

//단어 수정 뷰
struct JPEditWordView: View {
    // MARK: Data Properties
    var viewModel: JPWordListViewModel
    
    // MARK: Super View Properties
    @Binding var editWord: Bool
    @Binding var editingWord: Word
    
    // MARK: View Properties
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
    private var meaning: [String] {
        [inputMeaning.trimmingCharacters(in: .whitespaces)]
    }
    
    // 입력값이 공백일 때 경고메세지 출력 조건
    @State private var isWordEmpty: Bool = false
    @State private var isMeaningEmpty: Bool = false

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("단어를 입력하세요.", text: $inputWord, axis: .vertical)
                        .textInputAutocapitalization(.never)
                } header: {
                    HStack {
                        Text("단어")
                        if isWordEmpty {
                            Text("\(Image(systemName: "exclamationmark.circle")) 필수 입력 항목입니다.")
                        }
                    }
                }
                
                Section(header: Text("발음")) {
                    TextField("발음을 입력하세요.", text: $inputOption, axis: .vertical)
                        .textInputAutocapitalization(.never)
                }
                
                Section {
                    TextField("뜻을 입력하세요.", text: $inputMeaning, axis: .vertical)
                        .textInputAutocapitalization(.never)
                } header: {
                    HStack {
                        Text("뜻")
                        if isMeaningEmpty {
                            Text("\(Image(systemName: "exclamationmark.circle")) 필수 입력 항목입니다.")
                        }
                    }
                }
            }
            .navigationTitle("단어 수정")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                inputWord = editingWord.word!
                inputOption = editingWord.option ?? ""
                inputMeaning = editingWord.meaning![0]
            }
            .toolbar {
                // 취소 버튼
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소", role: .cancel) { editWord.toggle() }
                }
                // 변경 내용 저장 버튼
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("변경") {
                        word.isEmpty ? (isWordEmpty = true) : (isWordEmpty = false)
                        meaning.isEmpty ? (isMeaningEmpty = true) : (isMeaningEmpty = false)
                        
                        if !isWordEmpty && !isMeaningEmpty {
                            viewModel.updateWord(editWord: editingWord, word: word, meaning: meaning, option: option)

                            editWord.toggle()
                        }
                    }
                }
            }
        }
    }
}
