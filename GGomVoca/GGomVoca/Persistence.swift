//
//  Persistence.swift
//  GGomVoca
//
//  Created by Roen White on 2022/12/19.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentCloudKitContainer // NSPersistentContainer
    
    init() {
        container = NSPersistentCloudKitContainer(name: "GGomVoca")
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        //NSManagedObjectContext. 스토어의 URL, 유형(예: SQLite), 마이그레이션 또는 버전 관리와 같은 옵션과 같은 스토어 구성 옵션을 제공
        //관리 개체 컨텍스트를 기본 영구 저장소에 연결하는 데 사용
        let description = NSPersistentStoreDescription()
        description.type = NSSQLiteStoreType
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.NAWR.GGomVoca")
        description.shouldInferMappingModelAutomatically = true
        description.shouldMigrateStoreAutomatically = true
        
        container.persistentStoreDescriptions = [description]
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    // MARK: 데이터를 디스크에 저장하는 메서드
    func saveContext() {
        let context = container.viewContext
        
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
    
    func fetchVocabularyFromCoreData(withID id: String) -> Vocabulary? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Vocabulary")
        let predicate = NSPredicate(format: "id == %@", id)
        
        fetchRequest.predicate = predicate
        
        do {
            let result = try self.container.viewContext.fetch(fetchRequest) as! [Vocabulary]
            return result.first
        } catch {
            return nil
        }
    }
    
    func deleteVocabularyFromCoreData(withID id: String) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Vocabulary")
        let predicate = NSPredicate(format: "id == %@", id)
        
        fetchRequest.predicate = predicate
        
        do {
            let result = try container.viewContext.fetch(fetchRequest) as! [Vocabulary]
            let vocabularyToDelete = result.first
            
            container.viewContext.delete(vocabularyToDelete!)
            
            try container.viewContext.save()
        } catch {
            print("Error deleting vocabulary from Core Data: \(error)")
        }
    }
    
    func refrechContext() {
        let context = container.viewContext
        context.refreshAllObjects()
    }

    //    func refrechContext() {
    //        let context = container.viewContext
    //        context.refreshAllObjects()
    //    }
}
