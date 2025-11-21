import CoreData

/// Core Data 持久化控制器
/// 負責設定 Core Data Stack 並提供 viewContext
struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        // 建立預覽資料
        for i in 0..<5 {
            let newItem = WorkSession(context: viewContext)
            newItem.id = UUID()
            newItem.taskName = "測試工作項目 \(i)"
            newItem.startTime = Date()
            newItem.focusDuration = 1500 // 25 分鐘
            newItem.createdAt = Date()
        }
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        // 使用 Code-based Model 定義，不需要 .xcdatamodeld 檔案
        let model = PersistenceController.makeManagedObjectModel()
        
        // 使用自訂名稱 "WorkPulse" 初始化 Container
        container = NSPersistentContainer(name: "WorkPulse", managedObjectModel: model)
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // 在開發階段，如果 Core Data 結構改變導致無法讀取，這裡會崩潰
                // 實際發布時應該要做 Migration 處理
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        // 自動合併來自父 Context 的變更 (如果有使用 background context)
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    /// 刪除所有資料
    func deleteAllData() {
        let context = container.viewContext
        let entities = container.managedObjectModel.entities
        
        performBackgroundTask { backgroundContext in
            for entity in entities {
                guard let name = entity.name else { continue }
                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: name)
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                
                do {
                    try backgroundContext.execute(deleteRequest)
                    try backgroundContext.save()
                } catch {
                    print("刪除實體 \(name) 失敗: \(error)")
                }
            }
            
            // 通知主線程更新 UI
            DispatchQueue.main.async {
                context.reset()
                NotificationCenter.default.post(name: NSNotification.Name("DataDidReset"), object: nil)
            }
        }
    }
    
    /// 在背景執行 Core Data 操作
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask(block)
    }
    
    // MARK: - Code-based Core Data Model Definition
    
    /// 程式碼定義 Core Data Model
    /// 包含 WorkSession 與 BreakEvent 兩個 Entity
    static func makeManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        
        // --- Entity: WorkSession ---
        let workSessionEntity = NSEntityDescription()
        workSessionEntity.name = "WorkSession"
        workSessionEntity.managedObjectClassName = NSStringFromClass(WorkSession.self)
        
        // Attributes
        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .UUIDAttributeType
        idAttr.isOptional = false
        
        let taskNameAttr = NSAttributeDescription()
        taskNameAttr.name = "taskName"
        taskNameAttr.attributeType = .stringAttributeType
        taskNameAttr.isOptional = false
        taskNameAttr.defaultValue = "未命名工作"
        
        let startTimeAttr = NSAttributeDescription()
        startTimeAttr.name = "startTime"
        startTimeAttr.attributeType = .dateAttributeType
        startTimeAttr.isOptional = false
        
        let endTimeAttr = NSAttributeDescription()
        endTimeAttr.name = "endTime"
        endTimeAttr.attributeType = .dateAttributeType
        endTimeAttr.isOptional = true
        
        let focusDurationAttr = NSAttributeDescription()
        focusDurationAttr.name = "focusDuration"
        focusDurationAttr.attributeType = .doubleAttributeType
        focusDurationAttr.isOptional = false
        focusDurationAttr.defaultValue = 0.0
        
        let breakDurationAttr = NSAttributeDescription()
        breakDurationAttr.name = "breakDuration"
        breakDurationAttr.attributeType = .doubleAttributeType
        breakDurationAttr.isOptional = false
        breakDurationAttr.defaultValue = 0.0
        
        let createdAtAttr = NSAttributeDescription()
        createdAtAttr.name = "createdAt"
        createdAtAttr.attributeType = .dateAttributeType
        createdAtAttr.isOptional = false
        
        workSessionEntity.properties = [idAttr, taskNameAttr, startTimeAttr, endTimeAttr, focusDurationAttr, breakDurationAttr, createdAtAttr]
        
        // --- Entity: BreakEvent ---
        let breakEventEntity = NSEntityDescription()
        breakEventEntity.name = "BreakEvent"
        breakEventEntity.managedObjectClassName = NSStringFromClass(BreakEvent.self)
        
        // Attributes
        let breakIdAttr = NSAttributeDescription()
        breakIdAttr.name = "id"
        breakIdAttr.attributeType = .UUIDAttributeType
        breakIdAttr.isOptional = false
        
        let typeAttr = NSAttributeDescription()
        typeAttr.name = "type"
        typeAttr.attributeType = .stringAttributeType
        typeAttr.isOptional = false
        
        let breakStartTimeAttr = NSAttributeDescription()
        breakStartTimeAttr.name = "startTime"
        breakStartTimeAttr.attributeType = .dateAttributeType
        breakStartTimeAttr.isOptional = false
        
        let breakEndTimeAttr = NSAttributeDescription()
        breakEndTimeAttr.name = "endTime"
        breakEndTimeAttr.attributeType = .dateAttributeType
        breakEndTimeAttr.isOptional = true
        
        let durationAttr = NSAttributeDescription()
        durationAttr.name = "duration"
        durationAttr.attributeType = .doubleAttributeType
        durationAttr.isOptional = false
        durationAttr.defaultValue = 0.0
        
        breakEventEntity.properties = [breakIdAttr, typeAttr, breakStartTimeAttr, breakEndTimeAttr, durationAttr]
        
        // --- Relationships ---
        
        // WorkSession (One) -> BreakEvent (Many)
        let breakEventsRel = NSRelationshipDescription()
        breakEventsRel.name = "breakEvents"
        breakEventsRel.destinationEntity = breakEventEntity
        breakEventsRel.minCount = 0
        breakEventsRel.maxCount = 0 // 0 means unlimited
        breakEventsRel.deleteRule = .cascadeDeleteRule // 刪除 Session 時一併刪除 BreakEvents
        
        // BreakEvent (Many) -> WorkSession (One)
        let workSessionRel = NSRelationshipDescription()
        workSessionRel.name = "workSession"
        workSessionRel.destinationEntity = workSessionEntity
        workSessionRel.minCount = 0
        workSessionRel.maxCount = 1
        workSessionRel.deleteRule = .nullifyDeleteRule
        
        // 設定 Inverse
        breakEventsRel.inverseRelationship = workSessionRel
        workSessionRel.inverseRelationship = breakEventsRel
        
        // 加入 Relationship 到 Properties
        workSessionEntity.properties.append(breakEventsRel)
        breakEventEntity.properties.append(workSessionRel)
        
        // 設定 Model
        model.entities = [workSessionEntity, breakEventEntity]
        
        return model
    }
}

// MARK: - NSManagedObject Subclasses

/// 工作紀錄實體
@objc(WorkSession)
public class WorkSession: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var taskName: String?
    @NSManaged public var startTime: Date?
    @NSManaged public var endTime: Date?
    @NSManaged public var focusDuration: Double
    @NSManaged public var breakDuration: Double
    @NSManaged public var createdAt: Date?
    @NSManaged public var breakEvents: NSSet?
}

extension WorkSession: Identifiable {
    // 方便 SwiftUI 使用的計算屬性
    public var unwrappedTaskName: String {
        taskName ?? "未命名工作"
    }
    
    public var unwrappedStartTime: Date {
        startTime ?? Date()
    }
    
    public var breakEventArray: [BreakEvent] {
        let set = breakEvents as? Set<BreakEvent> ?? []
        return set.sorted {
            ($0.startTime ?? Date()) < ($1.startTime ?? Date())
        }
    }
}

/// 休息事件實體
@objc(BreakEvent)
public class BreakEvent: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var type: String?
    @NSManaged public var startTime: Date?
    @NSManaged public var endTime: Date?
    @NSManaged public var duration: Double
    @NSManaged public var workSession: WorkSession?
}

extension BreakEvent: Identifiable {
    public var unwrappedType: String {
        type ?? "rest"
    }
    
    // 顯示用的類型名稱
    public var typeDisplayName: String {
        switch unwrappedType {
        case "toilet": return "🚽 上廁所"
        case "meal": return "🍚 買飯"
        case "rest": return "☕ 一般休息"
        default: return "☕ 休息"
        }
    }
}
