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
    
    static func fetchRequest() -> NSFetchRequest<T>?
    static func add(container: NSPersistentContainer, _ addHandler:(T)->()) -> Bool
    func update(predicate: NSPredicate, container: NSPersistentContainer, _ updateHandler:((T)->())?) -> Bool
}

public extension WZDataManagerDelegate {
    
    static func fetchRequest() -> NSFetchRequest<T>? {
        if let name = T.description().components(separatedBy: ".").last {
            return NSFetchRequest<T>(entityName: name)
        }
        return nil
    }
    
    @discardableResult
    static func add(container: NSPersistentContainer, _ addHandler: (T) -> ()) -> Bool {
        let obj = T(context: container.viewContext)
        addHandler(obj)
        return container.saveContext()
    }
    
    @discardableResult
    func update(predicate: NSPredicate, container: NSPersistentContainer, _ updateHandler:((T)->())?) -> Bool {
        let context = container.viewContext
        guard let request = Self.fetchRequest() else { return false }
        request.predicate = predicate
        if let result = (try? context.fetch(request)), result.count > 0 {
            updateHandler?(result.first!)
            return container.saveContext()
        }
        return false
    }
}


open class WZDataManager {
    
    open var name: String { "WZNoteSwift" }
    
    public static var shared = WZDataManager()
    
    public lazy var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: name)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    @discardableResult
    func saveContext(_ p: NSPersistentContainer = WZDataManager.shared.container) -> Bool {
        return p.saveContext()
    }
    
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

public extension WZDataManager {
    /// viewContext
    var context: NSManagedObjectContext { container.viewContext }
}
