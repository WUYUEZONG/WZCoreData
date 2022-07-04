//
//  DataManager.swift
//  WZNoteSwift
//
//  Created by August on 2022/5/28.
//

import Foundation
import CoreData


public protocol WZDataManagerDelegate {
    
    associatedtype T: NSManagedObject
    
    static func fetchRequest(predicate: NSPredicate?, _ sortDescriptors: [NSSortDescriptor]?) -> NSFetchRequest<T>?
    static func add<Container: NSPersistentContainer>(container: Container, _ addHandler:(T)->()) -> Bool
    static func update<Container: NSPersistentContainer>(predicate: NSPredicate, container: Container, _ updateHandler:((T)->())?) -> Bool
    static func delete<Container: NSPersistentContainer>(predicate: NSPredicate, container: Container) -> Bool
}

public extension WZDataManagerDelegate {
    
    static func fetchRequest(predicate: NSPredicate? = nil, _ sortDescriptors: [NSSortDescriptor]? = nil) -> NSFetchRequest<T>? {
        if let name = T.description().components(separatedBy: ".").last {
            let request = NSFetchRequest<T>(entityName: name)
            request.sortDescriptors = sortDescriptors
            request.predicate = predicate
            return request
        }
        return nil
    }
    
    @discardableResult
    static func add<Container: NSPersistentContainer>(container: Container, _ addHandler:(T)->()) -> Bool {
        let obj = T(context: container.viewContext)
        addHandler(obj)
        return container.saveContext()
    }
    
    @discardableResult
    static func update<Container: NSPersistentContainer>(predicate: NSPredicate, container: Container, _ updateHandler:((T)->())?) -> Bool {
        let context = container.viewContext
        guard let request = Self.fetchRequest(predicate: predicate) else { return false }
        if let result = (try? context.fetch(request)) {
            if result.isEmpty {
                debugPrint("更新-查询数据为空")
                return false
            }
            for item in result {
                updateHandler?(item)
            }
            return context.saveContext()
        }
        return false
    }
    
    @discardableResult
    static func delete<Container: NSPersistentContainer>(predicate: NSPredicate, container: Container) -> Bool {
        let context = container.viewContext
        guard let request = Self.fetchRequest(predicate: predicate) else { return false }
        if let result = (try? context.fetch(request)) {
            if result.isEmpty {
                debugPrint("删除-查询数据为空")
                return true
            }
            for item in result {
                context.delete(item)
            }
            return context.saveContext()
        }
        return false
    }
}

/// 重写 `name` 属性换成自己的表名
open class WZDataManager {
    
    public init() {}
    
    open var name: String { "" }
    
    open lazy var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: name)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    @discardableResult
    func saveContext(_ p: NSPersistentContainer) -> Bool {
        return p.saveContext()
    }
    
    /// viewContext
    open var context: NSManagedObjectContext { container.viewContext }
    
}




public extension NSPersistentContainer {
    
    @discardableResult
    func saveContext () -> Bool {
        return saveContext(viewContext)
    }
    
    @discardableResult
    func saveContext(_ context: NSManagedObjectContext) -> Bool {
        return context.saveContext()
    }
}

public extension NSManagedObjectContext {
    
    @discardableResult
    func saveContext() -> Bool {
        var success = true
        if hasChanges {
            do {
                try save()
            } catch {
                success = false
            }
        }
        return success
    }
}

