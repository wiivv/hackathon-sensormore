//
//  SecondViewController.swift
//  sensormore
//
//  Created by Adrian Wong on 2019-07-09.
//  Copyright © 2019 Wiivv. All rights reserved.
//

import UIKit
import HealthKit

class SecondViewController: UIViewController {
    
    let healthStore = HKHealthStore()
    
    @IBOutlet var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        if HKHealthStore.isHealthDataAvailable() {
            let readDataTypes : Set = [HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!,
                                       HKObjectType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.biologicalSex)!,
                                       HKObjectType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.dateOfBirth)!,
                                       HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)!]
            
            let writeDataTypes : Set = [HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!]
            
            textView.isEditable = false
            
            healthStore.requestAuthorization(toShare: writeDataTypes, read: readDataTypes) { (success, error) in
                if !success {
                    // Handle the error here.
                } else {
                    self.getTodaysSteps{ (steps) in
                        if steps == 0.0 {
                            self.textView.insertText("steps :: \(steps)" + "\n")
                        }
                        else {
                            DispatchQueue.main.async {
                                self.textView.insertText("steps :: \(steps)" + "\n")
                            }
                        }
                    }
                }
            }
        }
        
        testCharachteristic()
        testSampleQuery()
    }
    
    func getTodaysSteps(completion: @escaping (Double) -> Void) {
        let stepsQuantityType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepsQuantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else {
                completion(0.0)
                return
            }
            completion(sum.doubleValue(for: HKUnit.count()))
        }
        
        healthStore.execute(query)
    }
    
    // Fetches biologicalSex of the user, and date of birth.
    func testCharachteristic() {
        // Biological Sex
        if try! healthStore.biologicalSex().biologicalSex == HKBiologicalSex.female {
            self.textView.insertText("You are female" + "\n")
        } else if try! healthStore.biologicalSex().biologicalSex == HKBiologicalSex.male {
            self.textView.insertText("You are male" + "\n")
        } else if try! healthStore.biologicalSex().biologicalSex == HKBiologicalSex.other {
            self.textView.insertText("You are not categorised as male or female" + "\n")
        }
        
        // Date of Birth
        if #available(iOS 10.0, *) {
            let formatter = DateComponentsFormatter()
            formatter.unitsStyle = .full
            try! self.textView.insertText(formatter.string(from: healthStore.dateOfBirthComponents())! + "\n")
        } else {
            // Fallback on earlier versions
            do {
                let dateFormatter = DateFormatter()
                let dateOfBirth = try healthStore.dateOfBirth()
                self.textView.insertText(dateFormatter.string(from: dateOfBirth) + "\n")
            } catch let error {
                self.textView.insertText("There was a problem fetching your data: \(error)" + "\n")
            }
        }
    }
    
    // HKSampleQuery with a nil predicate
    func testSampleQuery() {
        // Simple Step count query with no predicate and no sort descriptors
        let sampleType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)
        let query = HKSampleQuery.init(sampleType: sampleType!,
                                       predicate: nil,
                                       limit: HKObjectQueryNoLimit,
                                       sortDescriptors: nil) { (query, results, error) in
                                       
                                        DispatchQueue.main.async { [weak self] in
                                            guard let fResults = results else {
                                                return
                                            }
                                            self?.textView.insertText((self?.printHeartRateInfo(fResults) ?? "") + "\n")
                                        }
        }
        
        healthStore.execute(query)
    }
    
    let heartRateUnit:HKUnit = HKUnit.count()
    
    private func printHeartRateInfo(_ results:[HKSample]) -> String
    {
        var outputString = ""
    
        for result in results
        {
            if let currData:HKQuantitySample = result as? HKQuantitySample
            {
                outputString.append(" Heart Rate: \(currData.quantity.doubleValue(for: heartRateUnit))")
//                outputString.append(" quantityType: \(currData.quantityType)")
//                outputString.append(" Start Date: \(currData.startDate)")
//                outputString.append("  End Date: \(currData.endDate)")
//                outputString.append(" Metadata: \(currData.metadata)")
//                outputString.append(" UUID: \(currData.uuid)")
//                outputString.append(" Source: \(currData.sourceRevision)")
//                outputString.append(" Device: \(currData.device)")
                outputString.append(" ,  ")
            }
        }
        
        return outputString
    }
    
    // HKSampleQuery with a predicate
    func testSampleQueryWithPredicate() {
        let sampleType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)
        
        let today = Date()
        let startDate = Calendar.current.date(byAdding: .month, value: -3, to: today)
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: today, options: HKQueryOptions.strictEndDate)
        
        let query = HKSampleQuery.init(sampleType: sampleType!,
                                       predicate: predicate,
                                       limit: HKObjectQueryNoLimit,
                                       sortDescriptors: nil) { (query, results, error) in
                                       
                                        DispatchQueue.main.async { [weak self] in
                                            guard let fResults = results else {
                                                return
                                            }
                                            self?.textView.insertText((self?.printHeartRateInfo(fResults) ?? "") + "\n")
                                        }
        }
        
        healthStore.execute(query)
    }
    
    // Sample query with a sort descriptor
    func testSampleQueryWithSortDescriptor() {
        let sampleType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)
        
        let today = Date()
        let startDate = Calendar.current.date(byAdding: .month, value: -3, to: today)
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: today, options: HKQueryOptions.strictEndDate)
        
        let query = HKSampleQuery.init(sampleType: sampleType!,
                                       predicate: predicate,
                                       limit: HKObjectQueryNoLimit,
                                       sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { (query, results, error) in
                                        
                                        DispatchQueue.main.async { [weak self] in
                                            guard let fResults = results else {
                                                return
                                            }
                                            self?.textView.insertText((self?.printHeartRateInfo(fResults) ?? "") + "\n")
                                        }
        }
        
        healthStore.execute(query)
    }
    
    func testAnchoredQuery() {
        guard let bodyMassType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            fatalError("*** Unable to get the body mass type ***")
        }
        
        var anchor = HKQueryAnchor.init(fromValue: 0)
        
        if UserDefaults.standard.object(forKey: "Anchor") != nil {
            let data = UserDefaults.standard.object(forKey: "Anchor") as! Data
            anchor = NSKeyedUnarchiver.unarchiveObject(with: data) as! HKQueryAnchor
        }
        
        let query = HKAnchoredObjectQuery(type: bodyMassType,
                                          predicate: nil,
                                          anchor: anchor,
                                          limit: HKObjectQueryNoLimit) { (query, samplesOrNil, deletedObjectsOrNil, newAnchor, errorOrNil) in
                                            guard let samples = samplesOrNil, let deletedObjects = deletedObjectsOrNil else {
                                                fatalError("*** An error occurred during the initial query: \(errorOrNil!.localizedDescription) ***")
                                            }
                                            
                                            anchor = newAnchor!
                                            let data : Data = NSKeyedArchiver.archivedData(withRootObject: newAnchor as Any)
                                            UserDefaults.standard.set(data, forKey: "Anchor")
                                            
                                            for bodyMassSample in samples {
                                                self.textView.insertText("Samples: \(bodyMassSample)" + "\n")
                                            }
                                            
                                            for deletedBodyMassSample in deletedObjects {
                                                self.textView.insertText("deleted: \(deletedBodyMassSample)" + "\n")
                                            }
                                            
                                            self.textView.insertText("Anchor: \(anchor)" + "\n")
        }
        
        query.updateHandler = { (query, samplesOrNil, deletedObjectsOrNil, newAnchor, errorOrNil) in
            
            guard let samples = samplesOrNil, let deletedObjects = deletedObjectsOrNil else {
                // Handle the error here.
                fatalError("*** An error occurred during an update: \(errorOrNil!.localizedDescription) ***")
            }
            
            anchor = newAnchor!
            let data : Data = NSKeyedArchiver.archivedData(withRootObject: newAnchor as Any)
            UserDefaults.standard.set(data, forKey: "Anchor")
            
            for bodyMassSample in samples {
                self.textView.insertText("samples: \(bodyMassSample)" + "\n")
            }
            
            for deletedBodyMassSample in deletedObjects {
                self.textView.insertText("deleted: \(deletedBodyMassSample)" + "\n")
            }
        }
        
        healthStore.execute(query)
    }
    
    func testStatisticsQueryCumulitive() {
        guard let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            fatalError("*** Unable to get the step count type ***")
        }
        
        let query = HKStatisticsQuery.init(quantityType: stepCountType,
                                           quantitySamplePredicate: nil,
                                           options: [HKStatisticsOptions.cumulativeSum, HKStatisticsOptions.separateBySource]) { (query, results, error) in
                                            self.textView.insertText("Total: \(results?.sumQuantity()?.doubleValue(for: HKUnit.count()))" + "\n")
                                            for source in (results?.sources)! {
                                                self.textView.insertText("Seperate Source: \(results?.sumQuantity(for: source)?.doubleValue(for: HKUnit.count()))" + "\n")
                                            }
        }
        
        healthStore.execute(query)
    }
    
    func testStatisticsQueryDiscrete() {
        guard let bodyMassType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            fatalError("*** Unable to get the body mass type ***")
        }
        
        let query = HKStatisticsQuery.init(quantityType: bodyMassType,
                                           quantitySamplePredicate: nil,
                                           options: [HKStatisticsOptions.discreteMax, HKStatisticsOptions.separateBySource]) { (query, results, error) in
                                            self.textView.insertText("Total: \(results?.maximumQuantity()?.doubleValue(for: HKUnit.pound()))" + "\n")
                                            for source in (results?.sources)! {
                                                self.textView.insertText("Seperate Source: \(results?.maximumQuantity(for: source)?.doubleValue(for: HKUnit.pound()))" + "\n")
                                            }
        }
        
        healthStore.execute(query)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

