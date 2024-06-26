//
//  VocabularyListView.swift
//  GGomVoca
//
//  Created by JeongMin Ko on 2022/12/20.
//

import SwiftUI

struct DisplaySplitView: View {
    @StateObject private var viewModel: DisplaySplitViewModel
    
    init(viewModel: DisplaySplitViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    // MARK: 단어장 ID 배열
    @State private var pinnedVocabularyIDs = [String]()
    @State private var koreanVocabularyIDs = [String]()
    @State private var englishVocabularyIDs = [String]()
    @State private var japanishVocabularyIDs = [String]()
    @State private var frenchVocabularyIDs = [String]()
    
    // MARK: View Properties
    @State private var splitViewVisibility: NavigationSplitViewVisibility = .all
    /// - NavigationSplitView 선택 단어장 Id
    @State private var selectedVocabulary: Vocabulary?
    /// - 개발자 뷰 show flag
    @State private var isShowingContributor: Bool = false
    /// - 정보(앱 버전, 라이선스) 뷰 show flag
    @State private var isShowingInformation: Bool = false
    /// - 단어장 추가 뷰 show flag
    @State private var isShowingAddVocabulary: Bool = false
    /// - EditMode
    @State private var editMode: EditMode = .inactive
    /// - Searching
    @State private var inputKeyword: String = ""
    
    private var keyword: String {
        inputKeyword.trimmingCharacters(in: .whitespaces).lowercased()
    }
    
    var body: some View {
        NavigationSplitView(columnVisibility: $splitViewVisibility) {
            sidebarView()
        } detail: {
            if let selectedVocabulary {
                NavigationStack {
                    switch Nationality(rawValue: selectedVocabulary.nationality ?? "") {
                    case .KO:
                        KOWordListView(vocabularyID: selectedVocabulary.id)
                            .id(selectedVocabulary.id)
                    case .EN :
                        ENWordListView(vocabularyID: selectedVocabulary.id)
                            .id(selectedVocabulary.id)
                    case .JA :
                        JPWordListView(vocabularyID: selectedVocabulary.id)
                            .id(selectedVocabulary.id)
                    case .FR :
                        FRWordListView(vocabularyID: selectedVocabulary.id)
                            .id(selectedVocabulary.id)
                    default:
                        WordListView(vocabularyID: selectedVocabulary.id)
                            .id(selectedVocabulary.id)
                    }
                }
            } else {
                notSelectedVocabularyView()
            }
        }
        .navigationSplitViewStyle(.automatic)
        .searchable(text: $inputKeyword, placement: .navigationBarDrawer, prompt: "등록한 단어 검색")
        .onAppear {
            viewModel.getVocabularyData()
            updateVocabularyIDs()
        }
        .refreshable {
            viewModel.getVocabularyData()
            updateVocabularyIDs()
        }
        .onReceive(UserManager.shared.valueChanged) { _ in
            updateVocabularyIDs()
        }
    }
    
    // MARK: VocabularyList의 상태에 따라 분기되는 Sidebar View 및 공통 수정자
    func sidebarView() -> some View {
        Group {
            if viewModel.vocabularyList.isEmpty {
                emptyVocabularyListView()
            } else {
                if !inputKeyword.isEmpty {
                    SearchingResultsInMyWordsView(selectedVocabulary: $selectedVocabulary, keyword: keyword)
                } else {
                    vocabularyListView()
                }
            }
        }
        .navigationBarTitle("단어장")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Section {
                        Button {
                            isShowingContributor.toggle()
                        } label: {
                            Text("개발자")
                            Image(systemName: "person")
                        }
                    }
                    
                    Section {
                        Link(destination: URL(string: "https://bit.ly/thevoca")!) {
                            Text("도움말 및 피드백")
                            Image(systemName: "list.bullet.clipboard")
                        }
                        Button {
                            isShowingInformation.toggle()
                        } label: {
                            Text("정보")
                            Image(systemName: "info.circle")
                        }
                    }
                } label: {
                    Image(systemName: "exclamationmark.circle")
                }
            }
            
            ToolbarItemGroup(placement: .bottomBar) {
                Spacer()
                Button {
                    isShowingAddVocabulary.toggle()
                } label: {
                    Image(systemName: "folder.badge.plus")
                }
                .disabled(editMode == .active)
            }
        }
        .sheet(isPresented: $isShowingContributor) {
            ContributorsView()
        }
        .sheet(isPresented: $isShowingInformation) {
            InformationView()
        }
        .sheet(isPresented: $isShowingAddVocabulary) {
            AddVocabularyView(addCompletion:{ name, nationality in
                viewModel.addVocabulary(name: name, nationality: nationality)})
            .presentationDetents([.height(CGFloat(270))])
        }
    }
    
    // MARK: VocabularyList가 비어있을 때 표시되는 sidebar View
    func emptyVocabularyListView() -> some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .center, spacing: 10) {
                    Text("단어장 없음").font(.title3)
                    Text("하단의 \(Image(systemName: "folder.badge.plus"))을 눌러 단어장을 생성하세요.")
                    Text("(혹은 아래로 잡아당겨 데이터 동기화)")
                }
                .foregroundColor(.gray)
                .padding()
                .padding(.bottom, 40)
                .horizontalAlignSetting(.center)
                .frame(minHeight: geometry.size.height)
            }
        }
    }
    
    // MARK: VocabularyList가 비어있지 않을 때 표시되는 sidebar view
    func vocabularyListView() -> some View {
        List(selection: $selectedVocabulary) {
            // MARK: 고정된 단어장
            if !pinnedVocabularyIDs.isEmpty {
                Section("고정된 단어장") {
                    ForEach(pinnedVocabularyIDs, id: \.self) { vocabularyID in
                        if let vocabulary = viewModel.getVocabulary(for: vocabularyID) {
                            VocabularyCell(
                                pinnedCompletion: { vocaId in
                                    viewModel.updateIsPinnedVocabulary(id: vocaId)
                                }, deleteCompletion: { vocaId in
                                    viewModel.deleteVocabulary(id: vocaId.uuidString)
                                }, selectedVocabulary: $selectedVocabulary, vocabulary: vocabulary, editMode: $editMode)
                        }
                    }
                    .onDelete { indexSet in
                        for offset in indexSet {
                            let deleted = UserManager.editModeDeleteVocabulary(at: offset, in: "pinned")
                            viewModel.deleteVocabulary(id: deleted)
                        }
                    }
                    .onMove { from, to in
                        UserManager.shared.pinnedVocabularyIDs.move(fromOffsets: from, toOffset: to)
                    }
                }
            }
            
            // MARK: 한국어
            if !koreanVocabularyIDs.isEmpty {
                Section("한국어") {
                    ForEach(koreanVocabularyIDs, id: \.self) { vocabularyID in
                        if let vocabulary = viewModel.getVocabulary(for: vocabularyID) {
                            VocabularyCell(
                                pinnedCompletion: { vocaId in
                                    viewModel.updateIsPinnedVocabulary(id: vocaId)
                                }, deleteCompletion: { vocaId in
                                    viewModel.deleteVocabulary(id: vocaId.uuidString)
                                }, selectedVocabulary: $selectedVocabulary, vocabulary: vocabulary, editMode: $editMode)
                        }
                    }
                    .onDelete { indexSet in
                        for offset in indexSet {
                            let deleted = UserManager.editModeDeleteVocabulary(at: offset, in: "korean")
                            viewModel.deleteVocabulary(id: deleted)
                        }
                    }
                    .onMove { from, to in
                        UserManager.shared.koreanVocabularyIDs.move(fromOffsets: from, toOffset: to)
                    }
                }
            }
            
            // MARK: 영어
            if !englishVocabularyIDs.isEmpty {
                Section("영어") {
                    ForEach(englishVocabularyIDs, id: \.self) { vocabularyID in
                        if let vocabulary = viewModel.getVocabulary(for: vocabularyID) {
                            VocabularyCell(
                                pinnedCompletion: { vocaId in
                                    viewModel.updateIsPinnedVocabulary(id: vocaId)
                                }, deleteCompletion: { vocaId in
                                    viewModel.deleteVocabulary(id: vocaId.uuidString)
                                }, selectedVocabulary: $selectedVocabulary, vocabulary: vocabulary, editMode: $editMode)
                        }
                    }
                    .onDelete { indexSet in
                        for offset in indexSet {
                            let deleted = UserManager.editModeDeleteVocabulary(at: offset, in: "english")
                            viewModel.deleteVocabulary(id: deleted)
                        }
                    }
                    .onMove { from, to in
                        UserManager.shared.englishVocabularyIDs.move(fromOffsets: from, toOffset: to)
                    }
                }
            }
            
            // MARK: 일본어
            if !japanishVocabularyIDs.isEmpty {
                Section("일본어") {
                    ForEach(japanishVocabularyIDs, id: \.self) { vocabularyID in
                        if let vocabulary = viewModel.getVocabulary(for: vocabularyID) {
                            VocabularyCell(
                                pinnedCompletion: { vocaId in
                                    viewModel.updateIsPinnedVocabulary(id: vocaId)
                                }, deleteCompletion: { vocaId in
                                    viewModel.deleteVocabulary(id: vocaId.uuidString)
                                }, selectedVocabulary: $selectedVocabulary, vocabulary: vocabulary, editMode: $editMode)
                        }
                    }
                    .onDelete { indexSet in
                        for offset in indexSet {
                            let deleted = UserManager.editModeDeleteVocabulary(at: offset, in: "japanish")
                            viewModel.deleteVocabulary(id: deleted)
                        }
                    }
                    .onMove { from, to in
                        UserManager.shared.japanishVocabularyIDs.move(fromOffsets: from, toOffset: to)
                    }
                }
            }
            
            // MARK: 프랑스어
            if !frenchVocabularyIDs.isEmpty {
                Section("프랑스어") {
                    ForEach(frenchVocabularyIDs, id: \.self) { vocabularyID in
                        if let vocabulary = viewModel.getVocabulary(for: vocabularyID) {
                            VocabularyCell(
                                pinnedCompletion: { vocaId in
                                    viewModel.updateIsPinnedVocabulary(id: vocaId)
                                }, deleteCompletion: { vocaId in
                                    viewModel.deleteVocabulary(id: vocaId.uuidString)
                                }, selectedVocabulary: $selectedVocabulary, vocabulary: vocabulary, editMode: $editMode)
                        }
                    }
                    .onDelete { indexSet in
                        for offset in indexSet {
                            let deleted = UserManager.editModeDeleteVocabulary(at: offset, in: "french")
                            viewModel.deleteVocabulary(id: deleted)
                        }
                    }
                    .onMove { from, to in
                        UserManager.shared.frenchVocabularyIDs.move(fromOffsets: from, toOffset: to)
                    }
                }
            }
        }
        .environment(\.editMode, $editMode)
        /// - environment로 editmode를 구현하면 기본으로 제공되는 editbutton과 다르게 애니메이션이 없음. 그래서 직접 구현
        .animation(.default, value: editMode)
        .toolbar {
            /// - 편집 모드
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    editMode = editMode == .inactive ? .active : .inactive
                } label: {
                    Text(editMode == .inactive ? "편집" : "완료")
                }
                .onDisappear {
                    editMode = .inactive
                }
            }
        }
    }
    
    // MARK: selectedVocabulary가 nil이면서 vocabularyList의 상태에 따라 분기되는 Detail View 및 공통 수정자
    func notSelectedVocabularyView() -> some View {
        Group {
            if viewModel.vocabularyList.isEmpty {
                emptyVocabularyListDetailView()
            } else {
                vocabularyListDetailView()
            }
        }
        .navigationTitle("") // 이게 없으면, 보고 있던 단어장을 삭제했을 때 그 삭제한 단어장 이름이 계속 남아있음
        .foregroundColor(.gray)
        .padding(.top, 15)
    }
    
    // MARK: VocabularyList가 비어있을 때 표시되는 detail View
    func emptyVocabularyListDetailView() -> some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "sidebar.left")
                    .font(.largeTitle)
                    .fontWeight(.light)
                Image(systemName: "arrow.right")
                Image(systemName: "folder.badge.plus")
                    .font(.largeTitle)
                    .fontWeight(.light)
                Image(systemName: "arrow.right")
                Image(systemName: "character.book.closed")
                    .font(.largeTitle)
                    .fontWeight(.light)
            }
            
            Text("왼쪽 사이드바에서 단어장을 추가하세요.")
        }
    }
    
    // MARK: VocabularyList가 비어있지 않을 때 표시되는 detail View
    func vocabularyListDetailView() -> some View {
        VStack(alignment:.leading, spacing: 10) {
            Text("왼쪽 사이드바에서 단어장을 선택하세요.")
                .font(.title2)
                .padding(.bottom, 10)
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "pin")
                    Text("단어장을 오른쪽(\(Image(systemName: "arrow.right")))으로 밀면 상단에 고정됩니다.")
                }
                HStack {
                    Image(systemName: "trash")
                    Text("단어장을 왼쪽(\(Image(systemName: "arrow.left")))으로 밀면 삭제할 수 있습니다.")
                }
                HStack {
                    Image(systemName: "pencil")
                    Text("단어장을 길게 누르면 단어장의 제목을 변경할 수 있습니다.")
                }
            }
        }
    }
}

extension DisplaySplitView {
    private func updateVocabularyIDs() {
        pinnedVocabularyIDs = UserManager.shared.pinnedVocabularyIDs
        koreanVocabularyIDs = UserManager.shared.koreanVocabularyIDs
        englishVocabularyIDs = UserManager.shared.englishVocabularyIDs
        japanishVocabularyIDs = UserManager.shared.japanishVocabularyIDs
        frenchVocabularyIDs = UserManager.shared.frenchVocabularyIDs
    }
}

//struct VocabularyListView_Previews: PreviewProvider {
//    static var previews: some View {
//        DisplaySplitView(viewModel: DisplaySplitViewModel(vocabularyList: [], service: VocabularyServiceImpl(coreDataRepo: CoreDataRepositoryImpl(context: PersistenceController.shared.container.viewContext), cloudDataRepo: CloudKitRepositoryImpl())))
//    }
//}
