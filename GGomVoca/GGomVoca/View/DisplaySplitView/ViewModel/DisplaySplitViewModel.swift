//
//  VocabularyListViewModel.swift
//  GGomVoca
//
//  Created by JeongMin Ko on 2022/12/20.
//

import Foundation
import SwiftUI
import Combine

final class DisplaySplitViewModel: ObservableObject {
    // MARK: Service
    private let service: VocabularyService
    private var bag: Set<AnyCancellable> = Set<AnyCancellable>()
    
    init(vocabularyList: [Vocabulary], service: VocabularyService) {
        self.vocabularyList = vocabularyList
        self.service = service
    }
    
    // MARK: Published Properties
    @Published var vocabularyList: [Vocabulary] = [] // all vocabularies
    
    /// Get Vocabulary Lists
    func getVocabularyData() {
        service.fetchVocabularyList()
            .sink { _ in
            } receiveValue: { [unowned self] vocaList in
                vocabularyList = vocaList.filter{ $0.deleatedAt == nil }
                if vocaList.isEmpty { UserManager.initializeData() }
            }
            .store(in: &bag)
    }
    
    /// Post 단어장 추가
    func addVocabulary(name: String, nationality: String) {
        service.postVocaData(vocaName: "\(name)", nationality: "\(nationality)")
            .sink { _ in
            } receiveValue: { [unowned self] value in
                service.saveContext()
                getVocabularyData()
                
                //context에 저장 -> 전체 단어장 배열 다시 불러오기 -> 다음 유비쿼터스에 추가
                UserManager.addVocabulary(id: value.id!.uuidString, nationality: "\(value.nationality ?? "")")
            }
            .store(in: &bag)
    }
    
    /// 즐겨찾기 업데이트
    func updateIsPinnedVocabulary(id: UUID) {
        service.updatePinnedVoca(id: id)
            .sink { _ in
            } receiveValue: { [unowned self] _ in
                service.saveContext()
                getVocabularyData()
            }
            .store(in: &bag)
    }
    
    /// Vocabualry.ID로 해당 단어장을 찾아오는 메서드
    func getVocabulary(for vocaId: String) -> Vocabulary? {
        guard let vocaIndex = vocabularyList.firstIndex(where: { $0.id?.uuidString ?? "" == vocaId }) else { return nil }
        return vocabularyList[vocaIndex]
    }
    
    /// 단어장 삭제 함수
    func deleteVocabulary(id: String) {
        guard let uuid = UUID(uuidString: id) else { return }
        
        service.deletedVocaData(id: uuid)
            .sink { _ in
            } receiveValue: { [unowned self] _ in
                service.saveContext() //저장
                getVocabularyData() //불러오기
            }
            .store(in: &bag)
    }
}
