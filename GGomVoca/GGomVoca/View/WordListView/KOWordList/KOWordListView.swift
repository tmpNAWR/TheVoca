//
//  KOWordListView.swift
//  GGomVoca
//
//  Created by do hee kim on 2023/01/18.
//

import SwiftUI

struct KOWordListView: View {
    // MARK: Data Properties
    var vocabularyID: Vocabulary.ID

    @StateObject var viewModel: KOWordListViewModel = DependencyManager.shared.resolve(KOWordListViewModel.self)!
  
    // MARK: View Properties
    /// - onAppear 될 때 viewModel에서 값 할당
    @State private var navigationTitle: String = ""
    @State private var emptyMessage: String = ""
    @State private var unmaskedWords: [Word.ID] = [] // segment에 따라 Word.ID가 배열에 있으면 보임, 없으면 안보임
    @State private var sort: Int = 0


    


    // MARK: UIKit Menu
    @State var isImportVoca: Bool = false
    @State var isCheckResult: Bool = false
    @State var selectedSegment: ProfileSection = .normal
    @State var selectedOrder: String = "사전순"
    
    /// - 단어 추가 버튼 관련 State
    @State var addNewWord: Bool = false
    
    /// - 단어장 내보내기 관련 State
    @State var isExport: Bool = false
    
    /// - 단어장 편집모드 관련 State
    @State var isSelectionMode: Bool = false
    @State private var multiSelection: Set<Word> = Set<Word>()
    // 단어 여러 개 삭제 시 확인 메시지
    @State var confirmationDialog: Bool = false // iPhone
    @State var removeAlert: Bool = false // iPad
    
    /// - 단어 시험모드 관련 State
    @State private var isTestMode: Bool = false
    
    // 전체 발음 듣기 관련 State
    @State private var isSpeech = false
    
    /// 단어 듣기 관련 프로퍼티
    private var selectedWords: [Word] {
        var array = [Word]()
        
        self.multiSelection.forEach { word in
            array.append(word)
        }
        
        return array
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            if viewModel.words.isEmpty {
                VStack(spacing: 10) {
                    EmptyWordListView(lang: viewModel.nationality)
                }
                .foregroundColor(.gray)
                .verticalAlignSetting(.center)
            } else {
                KOWordsTableView(viewModel: viewModel, selectedSegment: selectedSegment, unmaskedWords: $unmaskedWords, isSelectionMode: $isSelectionMode, multiSelection: $multiSelection)
                    .padding(.top, 15)
            }
            
            if !multiSelection.isEmpty && isSelectionMode {
                VStack(spacing: 0) {
                    Rectangle()
                        .foregroundColor(Color("toolbardivider"))
                        .frame(height: 1)
                    
                    HStack {
                        // TODO: 단어장 이동 버튼; sheet가 올라오고 단어장 목록이 나옴
                        Button {
                            
                        } label: {
                            Image(systemName: "folder")
                        }
                        .padding()
                        
                        Spacer()
                        
                        Button("선택한 단어 듣기") {
                            SpeechSynthesizer.shared.speakWordsAndMeanings(selectedWords, to: "kr-KO")
                        }
                        
                        Spacer()
                        
                        // TODO: 삭제하기 전에 OO개의 단어를 삭제할거냐고 확인하기 confirmationDialog...
                        Button(role: .destructive) {
                            if UIDevice.current.model == "iPhone" {
                                confirmationDialog.toggle()
                            } else if UIDevice.current.model == "iPad" {
                                removeAlert.toggle()
                            }
                        } label: {
                            Image(systemName: "trash")
                        }
                        .padding()
                    }
                    .background(Color("toolbarbackground"))
                }
            }
        }
        .navigationTitle(isSelectionMode ? "선택된 단어 \(multiSelection.count)개" : navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.getVocabulary(vocabularyID: vocabularyID)
            navigationTitle = viewModel.selectedVocabulary.name ?? ""
            emptyMessage = viewModel.getEmptyWord()
        }
        // 시험 모드 시트
        .fullScreenCover(isPresented: $isTestMode, content: {
            TestModeSelectView(isTestMode: $isTestMode, vocabularyID: vocabularyID)
        })
        // 단어 여러 개 삭제 여부 (iPhone)
        .confirmationDialog("단어 삭제", isPresented: $confirmationDialog, actions: {
            Button(role: .destructive) {
                for word in multiSelection {
                    viewModel.deleteWord(word: word)
                }
                multiSelection.removeAll()
                confirmationDialog.toggle()
                isSelectionMode.toggle()
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("\(multiSelection.count)개의 단어 삭제")
                }
            }
        })
        // 단어 여러 개 삭제 여부 (iPad)
        .alert("\(multiSelection.count)개의 단어를 삭제하시겠습니까?", isPresented: $removeAlert, actions: {
            Button(role: .cancel) {
                removeAlert.toggle()
            } label: {
                Text("Cancle")
            }
            
            Button(role: .destructive) {
                for word in multiSelection {
                    viewModel.deleteWord(word: word)
                }
                multiSelection.removeAll()
                removeAlert.toggle()
                isSelectionMode.toggle()
            } label: {
                Text("OK")
            }
            
        })
        // 새 단어 추가 시트
        .sheet(isPresented: $addNewWord) {
            KOAddNewWordView(viewModel: viewModel)
                .presentationDetents([.height(CGFloat(500))])
        }
        // 단어장 내보내기
        .fileExporter(isPresented: $isExport, document: CSVFile(initialText: viewModel.buildDataForCSV() ?? ""), contentType: .commaSeparatedText, defaultFilename: "\(navigationTitle)") { result in
            switch result {
            case .success(let url):
                print("Saved to \(url)")
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
        .toolbar {
            // TODO: 편집모드에 따른 toolbar State 분기
            if !isSelectionMode, isSpeech { // 전체 발음 듣기 모드
                ToolbarItem {
                    Button("취소", role: .cancel) {
                        isSpeech.toggle()
                        SpeechSynthesizer.shared.stopSpeaking()
                    }
                }
            } else if isSelectionMode, !isSpeech {  // 편집 모드
                ToolbarItem {
                    Button("취소", role: .cancel) {
                        isSelectionMode.toggle()
                        multiSelection.removeAll()
                        SpeechSynthesizer.shared.stopSpeaking()
                    }
                }
            } else {
                //                ToolbarItem {
                //                    VStack(alignment: .center) {
                //                        Text("\(viewModel.words.count)")
                //                            .foregroundColor(.gray)
                //                    }
                //                }
                // + 버튼
                ToolbarItem {
                    Button {
                        addNewWord.toggle()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                
                
                // 햄버거 버튼
                ToolbarItem {
                    CustomMenu(currentMode: $selectedSegment, orderMode: $selectedOrder, speakOn: $isSpeech, testOn: $isTestMode, editOn: $isSelectionMode, isImportVoca: $isImportVoca, isExportVoca: $isExport, isCheckResult: $isCheckResult)
                        .onChange(of: selectedSegment) { _ in
                            unmaskedWords = []
                        }
                        .onChange(of: selectedOrder) { value in
                            switch value {
                            case "랜덤 정렬":
                            viewModel.words.shuffle()
                            case "사전순 정렬":
                            viewModel.words.shuffle()
                            default:
                            viewModel.words.shuffle()
                            }
                        }
                        .onChange(of: isSpeech) { value in
                            if value {
                              SpeechSynthesizer.shared.speakWordsAndMeanings(viewModel.words, to: "en-US")
                            }
                        }
                }
            }
        }
        .onDisappear {
            SpeechSynthesizer.shared.stopSpeaking()
        }
        
    }
}
