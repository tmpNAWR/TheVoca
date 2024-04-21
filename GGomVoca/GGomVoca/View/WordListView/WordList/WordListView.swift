//
//  WordListView.swift
//  GGomVoca
//
//  Created by do hee kim on 2023/01/18.
//

import SwiftUI

struct WordListView: View {
    // MARK: Data Properties
    private let vocabularyID: Vocabulary.ID
    
    init(vocabularyID: Vocabulary.ID) {
        self.vocabularyID = vocabularyID
    }
    
    @StateObject private var viewModel: WordListViewModel = DependencyManager.shared.resolve(WordListViewModel.self)!
    @StateObject private var speechSynthesizer = SpeechSynthesizer()
    
    // MARK: View Properties
    /// - onAppear 될 때 viewModel에서 값 할당
    @State private var navigationTitle: String = ""
    @State private var emptyMessage: String = ""
    @State private var unmaskedWords: [Word.ID] = [] // segment에 따라 Word.ID가 배열에 있으면 보임, 없으면 안보임
    @State private var isVocaEmpty: Bool = false
    
    // MARK: Meatball Menu
    /// 보기모드
    @State private var selectedSegment: ProfileSection = .normal
    /// - 단어 시험모드 관련 State
    @State private var isTestMode: Bool = false
    /// 시험 결과 보기 뷰 띄우기
    @State private var isCheckResult: Bool = false
    /// 단어장 가져오기 뷰 띄우기
    @State private var isImportVoca: Bool = false
    /// - 단어장 내보내기 뷰 띄우기
    @State private var isExport: Bool = false
    /// 단어 정렬 조건
    @State private var selectedOrder: Order = .byRegistered
    /// 전체 단어듣기
    @State private var speakOn: Bool = false
    
    /// - 단어 추가 버튼 관련 State
    @State private var addNewWord: Bool = false
    
    /// - 단어장 편집모드 관련 State
    @State private var isSelectionMode: Bool = false
    @State private var multiSelection: Set<Word> = Set<Word>()
    /// 단어 여러 개 삭제 시 확인 메시지
    @State var confirmationDialog: Bool = false // iPhone
    @State var removeAlert: Bool = false // iPad
    
    /// 전체 발음 듣기 관련 State
    @State private var isSpeech = false
    
    /// 단어 듣기 관련 프로퍼티
    private var selectedWords: [Word] {
        return Array(multiSelection)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.words.isEmpty {
                    VStack(spacing: 10) {
                        EmptyWordListView(lang: viewModel.nationality)
                    }
                    .foregroundColor(.gray)
                    .verticalAlignSetting(.center)
                } else {
                    WordsTableView(viewModel: viewModel, speechSynthesizer: speechSynthesizer, selectedSegment: selectedSegment, unmaskedWords: $unmaskedWords, isSelectionMode: $isSelectionMode, multiSelection: $multiSelection)
                        .padding(.top, 15)
                }
                
            }
            .navigationTitle(isSelectionMode ? "선택된 단어 \(multiSelection.count)개" : navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $isImportVoca) {
                ImportCSVFileView(vocabulary: viewModel.selectedVocabulary)
                    .onDisappear {
                        viewModel.getVocabulary(vocabularyID: vocabularyID)
                    }
            }
            .navigationDestination(isPresented: $isCheckResult) {
                MyNoteView(words: viewModel.words)
            }
            .onAppear {
                viewModel.getVocabulary(vocabularyID: vocabularyID)
                navigationTitle = viewModel.selectedVocabulary.name ?? ""
                isVocaEmpty = viewModel.words.isEmpty
                emptyMessage = viewModel.getEmptyWord()
            }
            // 시험 모드 시트
            .fullScreenCover(isPresented: $isTestMode) {
                if viewModel.words.isEmpty {
                    EmptyTestModeView()
                } else {
                    TestScopeSelectView(isTestMode: $isTestMode, vocabularyID: vocabularyID)
                }
            }
            // 단어 여러 개 삭제 여부 (iPhone)
            .confirmationDialog("단어 삭제", isPresented: $confirmationDialog) {
                Button(role: .destructive) {
                    multiSelection.forEach { word in viewModel.deleteWord(word: word) }
                    multiSelection.removeAll()
                    confirmationDialog.toggle()
                    isSelectionMode.toggle()
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("\(multiSelection.count)개의 단어 삭제")
                    }
                }
            }
            // 단어 여러 개 삭제 여부 (iPad)
            .alert("\(multiSelection.count)개의 단어를 삭제하시겠습니까?", isPresented: $removeAlert) {
                Button(role: .cancel) {
                    removeAlert.toggle()
                } label: {
                    Text("Cancel")
                }
                
                Button(role: .destructive) {
                    multiSelection.forEach { word in viewModel.deleteWord(word: word) }
                    multiSelection.removeAll()
                    removeAlert.toggle()
                    isSelectionMode.toggle()
                } label: {
                    Text("OK")
                }
            }
            // 새 단어 추가 시트
            .sheet(isPresented: $addNewWord) {
                AddNewWordView(viewModel: viewModel)
                    .presentationDetents([.height(CGFloat(500))])
            }
            // 단어장 내보내기
            .fileExporter(isPresented: $isExport, document: CSVFile(initialText: viewModel.buildDataForCSV()), contentType: .commaSeparatedText, defaultFilename: "\(navigationTitle)") { result in
                switch result {
                case .success(let url):
                    print("Saved to \(url)")
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
            .toolbar {
                // TODO: 편집모드에 따른 toolbar State 분기
                if !isSelectionMode, speechSynthesizer.isPlaying { // 전체 발음 듣기 모드
                    ToolbarItem {
                        Button(role: .cancel) {
                            speechSynthesizer.stopSpeaking()
                        } label: {
                            Image(systemName: "square.fill")
                        }
                    }
                } else if isSelectionMode {  // 편집 모드
                    ToolbarItem {
                        Button("취소", role: .cancel) {
                            isSelectionMode.toggle()
                            multiSelection.removeAll()
                            speechSynthesizer.stopSpeaking()
                        }
                    }
                    
                    ToolbarItemGroup(placement: .bottomBar) {
                        Button("선택한 단어 듣기") {
                            speechSynthesizer.speakWordsAndMeanings(selectedWords, to: "en-US")
                        }
                        .disabled(multiSelection.isEmpty)
                        
                        Button(role: .destructive) {
                            if UIDevice.current.model == "iPhone" {
                                confirmationDialog.toggle()
                            } else if UIDevice.current.model == "iPad" {
                                removeAlert.toggle()
                            }
                        } label: {
                            Image(systemName: "trash")
                        }
                        .disabled(multiSelection.isEmpty)
                    }
                    
                } else {
                    // MARK: 새 단어 추가 버튼
                    ToolbarItemGroup(placement: .bottomBar) {
                        Button {
                            addNewWord.toggle()
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("새 단어 추가")
                            }
                        }
                        
                        Spacer()
                    }
                    
                    // MARK: 미트볼 버튼
                    ToolbarItem {
                        Menu("Menu", systemImage: "ellipsis.circle") {
                            Section {
                                Picker(selection: $selectedSegment) {
                                    ForEach(ProfileSection.allCases, id: \.self) { option in
                                        Text(option.rawValue.localized)
                                    }
                                } label: {
                                    Button(action: {}) {
                                        Text("보기 모드".localized)
                                        Text(selectedSegment.rawValue)
                                        Image(systemName: "eye.fill")
                                    }
                                }
                                .pickerStyle(.menu)
                                .disabled(isVocaEmpty)
                                
                                Button {
                                    isTestMode.toggle()
                                } label: {
                                    Text("시험 보기".localized)
                                    Image(systemName: "square.and.pencil")
                                }
                                .disabled(isVocaEmpty)
                                
                                Button {
                                    isCheckResult.toggle()
                                } label: {
                                    Text("시험 결과 보기".localized)
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                }
                                .disabled(isVocaEmpty)
                            }
                            
                            Section {
                                Picker(selection: $selectedOrder) {
                                    ForEach(Order.allCases, id: \.self) { option in
                                        Text(option.rawValue.localized)
                                    }
                                } label: {
                                    Button(action: {}) {
                                        Text("정렬".localized)
                                        Text(selectedOrder.rawValue)
                                        Image(systemName: "arrow.up.arrow.down")
                                    }
                                }
                                .pickerStyle(.menu)
                                .disabled(isVocaEmpty)
                                
                                Button {
                                    isSelectionMode.toggle()
                                } label: {
                                    Text("단어 선택하기".localized)
                                    Image(systemName: "checkmark.circle")
                                }
                                .disabled(isVocaEmpty)
                                
                                Button {
                                    isImportVoca.toggle()
                                } label: {
                                    Text("단어장 가져오기".localized)
                                    Image(systemName: "square.and.arrow.down")
                                }
                                
                                Button {
                                    isExport.toggle()
                                } label: {
                                    Text("단어장 내보내기".localized)
                                    Image(systemName: "square.and.arrow.up")
                                }
                                .disabled(isVocaEmpty)
                            }
                            
                            Button {
                                speakOn.toggle()
                            } label: {
                                Text("전체 단어 듣기".localized)
                                Image(systemName: "speaker.wave.3")
                            }
                            .disabled(isVocaEmpty)
                        }
                        .onChange(of: selectedSegment) { _ in
                            unmaskedWords = []
                        }
                        .onChange(of: selectedOrder) { value in
                            switch value {
                            case .byRandom:
                                viewModel.words.shuffle()
                            case .byAlphabetic:
                                viewModel.words.sort { $0.word! < $1.word! }
                            case .byRegistered:
                                viewModel.words.sort { ($0.createdAt ?? "0") < ($1.createdAt ?? "0") }
                            }
                        }
                        .onChange(of: speakOn) { value in
                            guard speakOn else { return }
                            speechSynthesizer.speakWordsAndMeanings(viewModel.words, to: "en-US")
                            speakOn.toggle()
                        }
                    }
                }
            }
            .onDisappear {
                speechSynthesizer.stopSpeaking()
            }
            .onChange(of: viewModel.words.isEmpty) { value in
                isVocaEmpty = value
            }
        }
    }
}
