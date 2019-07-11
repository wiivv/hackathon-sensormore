//
//  CoreDataManager.swift
//  sensormore
//
//  Created by Adrian Wong on 2019-07-09.
//  Copyright © 2019 Wiivv. All rights reserved.
//

import Foundation
import CoreData
import Sync

class CoreDataManager {
    static let sharedManager = CoreDataManager()
    
    private var dataStack: DataStack?
    
//    lazy var persistentContainer: NSPersistentContainer = {
//        let container = NSPersistentContainer(name: "SensorModel")
//        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
//            if let error = error as NSError? {
//                fatalError("Unresolved error \(error), \(error.userInfo)")
//            }
//        })
//        return container
//    }()
    
    init(){
        dataStack = DataStack(modelName: "SensorModel", bundle: Bundle.main, storeType: .sqLite, storeName: "WiivvSensorModel")
    }
    
    func saveContext () {
        guard let context = dataStack?.mainContext else {
            return
        }
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate.
                // You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func exportToAppFileSharing() {
    }
    
    func insertAccelerometerData(_ x:Double, y:Double, z:Double) -> Accelerometer? {
        guard let managedContext = dataStack?.mainContext else {
            return nil
        }
        
        let entity = NSEntityDescription.entity(forEntityName: "Accelerometer", in: managedContext)!
     
        let accelerometer = NSManagedObject(entity: entity, insertInto: managedContext)
        
        let now = Date().timeIntervalSince1970
        accelerometer.setValue(now, forKey: "timestamp")
        accelerometer.setValue(x, forKey: "x")
        accelerometer.setValue(y, forKey: "y")
        accelerometer.setValue(z, forKey: "z")
        
        do {
            try managedContext.save()
            return accelerometer as? Accelerometer
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
            return nil
        }

    }
    
    func fetchAccelerometerDatas() -> [Accelerometer]?{
        guard let managedContext = dataStack?.mainContext else {
            return nil
        }
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Accelerometer")
    
        do {
            let accelerometers = try managedContext.fetch(fetchRequest)
            return accelerometers as? [Accelerometer]
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
            return nil
        }
    }
    
}
