//
//  ViewController.swift
//  StepCounter
//
//  Created by ios dev 4 on 15/11/17.
//  Copyright © 2017 ios dev 4. All rights reserved.
//

import UIKit
import HealthKit

class ViewController: UIViewController, UITableViewDataSource {
    
    @IBOutlet weak fileprivate var tableView: UITableView!
    
    @IBOutlet weak fileprivate var activityIndicator: UIActivityIndicatorView!
    
    fileprivate let stepCellIdentifier = "stepCell"
    fileprivate let totalStepsCellIdentifier = "totalStepsCell"
    
    fileprivate let healthKitManager = HealthKitManager.sharedInstance
    
    fileprivate var steps = [HKQuantitySample]()
    
    fileprivate let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getSteps()
//        activityIndicator.startAnimating()
//        requestHealthKitAuthorization()
    }
    
    // MARK: TableView Data Source
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return steps.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: stepCellIdentifier)! as UITableViewCell
        
        let step = steps[indexPath.row]
        let numberOfSteps = Int(step.quantity.doubleValue(for: healthKitManager.stepsUnit))
        
        cell.textLabel?.text = "\(numberOfSteps) steps"
        cell.detailTextLabel?.text = dateFormatter.string(from: step.endDate)
        
        return cell
    }
    
   
    
}




private extension ViewController {
    
    func requestHealthKitAuthorization() {
        let dataTypesToRead = NSSet(objects: healthKitManager.stepsCount as Any)
        healthKitManager.healthStore?.requestAuthorization(toShare: nil, read: dataTypesToRead as? Set<HKObjectType>, completion: { [unowned self] (success, error) in
            if success {
//                self.queryStepsSum()
//                self.querySteps()
                self.getSteps()
            } else {
                print(error.debugDescription)
            }
        })
    }
    
    
    func getSteps(){
        let endDate = NSDate()
//        let startDate = Calendar.current.dateByAddingUnit(.CalendarUnitMonth, value: -1, toDate: endDate, options: nil)
//        let startDate =   Calendar.current.date(byAdding:CalendarUnit, value: -1, to: endDate,options:nil)

        let startDate = Date().yesterday
        
        let weightSampleType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate as Date, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: weightSampleType!, predicate: predicate, limit: 0, sortDescriptors: nil, resultsHandler: {
            (query, results, error) in
            if results == nil {
                print("There was an error running the query: \(error)")
            }
            DispatchQueue.main.async {
                var dailyAVG:Double = 0
                for steps in results as! [HKQuantitySample]
                {
                    // add values to dailyAVG
                    dailyAVG += steps.quantity.doubleValue(for: HKUnit.count())
                    print("Daily avfg = \(dailyAVG)")
                    print( "steps =\( steps)")
                }
            }
        })
healthKitManager.healthStore?.execute(query)
    
        
    }

    
    func queryStepsSum() {
        let sumOption = HKStatisticsOptions.cumulativeSum
        let statisticsSumQuery = HKStatisticsQuery(quantityType: healthKitManager.stepsCount!, quantitySamplePredicate: nil, options: sumOption) { [unowned self] (query, result, error) in
            if let sumQuantity = result?.sumQuantity() {
                let headerView = self.tableView.dequeueReusableCell(withIdentifier: self.totalStepsCellIdentifier)! as UITableViewCell
                
                let numberOfSteps = Int(sumQuantity.doubleValue(for: self.healthKitManager.stepsUnit))
                headerView.textLabel?.text = "\(numberOfSteps) total"
                self.tableView.tableHeaderView = headerView
            }
            self.activityIndicator.stopAnimating()
            
        }
        healthKitManager.healthStore?.execute(statisticsSumQuery)
    }
    
    func querySteps() {
        let sampleQuery = HKSampleQuery(sampleType: healthKitManager.stepsCount!,
                                        predicate: nil,
                                        limit: 100,
                                        sortDescriptors: nil)
        { [unowned self] (query, results, error) in
            if let results = results as? [HKQuantitySample] {
                self.steps = results
                self.tableView.reloadData()
            }
            self.activityIndicator.stopAnimating()
        }
        
        healthKitManager.healthStore?.execute(sampleQuery)
}
}
extension Date {
    var yesterday: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: noon)!
    }
    var tomorrow: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: noon)!
    }
    var noon: Date {
        return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: self)!
    }
    var month: Int {
        return Calendar.current.component(.month,  from: self)
    }
    var isLastDayOfMonth: Bool {
        return tomorrow.month != month
    }
}
    
    

