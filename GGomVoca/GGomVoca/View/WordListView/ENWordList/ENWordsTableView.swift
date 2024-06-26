//
//  ENWordsTableView.swift
//  GGomVoca
//
//  Created by do hee kim on 2023/01/18.
//

import SwiftUI

struct ENWordsTableView: View {
    // MARK: SuperView Properties
    @ObservedObject var viewModel: ENWordListViewModel
    @ObservedObject var speechSynthesizer: SpeechSynthesizer
    
    var selectedSegment: ProfileSection
    @Binding var unmaskedWords: [Word.ID]
    
    // MARK: View Properties
    /// - 단어 수정 관련 State
    @State var editWord: Bool = false
    @State var editingWord: Word = Word()
    
    /// - 단어 리스트 편집 관련 State
    @Binding var isSelectionMode: Bool
    @Binding var multiSelection: Set<Word>
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header
            HStack {
                if isSelectionMode {
                    Image(systemName: "circle")
                        .foregroundColor(.clear)
                        .font(.title2)
                        .padding(.vertical, -10)
                }
                Text("단어")
                    .headerText()
                Text("뜻")
                    .headerText()
            }
            .animation(.default, value: isSelectionMode)
            .padding(.horizontal, 20)
            .background {
                Rectangle()
                    .fill(Color("fourseason"))
                    .frame(height: 30)
            }
            
            // MARK: - Content
            List($viewModel.words, id: \.self, selection: $multiSelection) { $word in
                HStack {
                    // 단어
                    Text(word.word ?? "")
                        .listCellText(isSelectionMode: isSelectionMode)
                        .opacity((selectedSegment == .wordTest && !unmaskedWords.contains(word.id)) ? 0 : 1)
                    VLine()
                    // 뜻
                    Text(word.meaning!.joined(separator: ", "))
                        .listCellText(isSelectionMode: isSelectionMode)
                        .opacity((selectedSegment == .meaningTest && !unmaskedWords.contains(word.id)) ? 0 : 1)
                }
                .eachDeviceFontSize()
                .frame(minHeight: 40)
                .alignmentGuide(.listRowSeparatorLeading) { d in
                    d[.leading]
                }
                .overlay {
                    if !isSelectionMode {
                        Color.clear
                            .frame(width: UIScreen.main.bounds.width)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedSegment != .normal {
                                    /// - 편집모드가 아닐때는 단어를 가렸다가 보였다가 할 수 있도록
                                    if unmaskedWords.contains(word.id) {
                                        if let tmpIndex = unmaskedWords.firstIndex(of: word.id) {
                                            unmaskedWords.remove(at: tmpIndex)
                                        }
                                    } else {
                                        unmaskedWords.append(word.id)
                                    }
                                }
                            }
                    }
                }
                .swipeActions(allowsFullSwipe: false) {
                    Button(role: .destructive){
                        viewModel.deleteWord(word: word)
                    }label: {
                        Label("Delete", systemImage: "trash.fill")
                    }
                }
                .contextMenu {
                    if selectedSegment == .normal {
                        Button {
                            editingWord = word
                            editWord.toggle()
                        } label: {
                            Label("수정하기", systemImage: "gearshape.fill")
                        }
                        Button {
                            speechSynthesizer.speakWordAndMeaning(word, to: "en-US", .single)
                        } label: {
                            Label("단어 듣기", systemImage: "mic.fill")
                        }
                    }
                }
            } // List
            .listStyle(.plain)
            .environment(\.editMode, .constant(self.isSelectionMode ? EditMode.active : EditMode.inactive))
            .animation(.default, value: isSelectionMode)
            // MARK: 단어 편집 시트
            .sheet(isPresented: $editWord) {
                ENEditWordView(viewModel: viewModel, editWord: $editWord, editingWord: $editingWord)
                    .presentationDetents([.medium])
            }
            .onDisappear {
                speechSynthesizer.stopSpeaking()
            }
        }
    }
}

//struct ENWordsTableView_Previews: PreviewProvider {
//    static var previews: some View {
//        ENWordsTableView(selectedSegment: .constant(.normal), selectedWord: .constant([]), filteredWords: .constant(FRWords), isSelectionMode: .constant(false), multiSelection: .constant(Set<String>()), nationality: .FR)
//    }
//}
