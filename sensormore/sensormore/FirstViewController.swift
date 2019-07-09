//
//  FirstViewController.swift
//  sensormore
//
//  Created by Adrian Wong on 2019-07-09.
//  Copyright © 2019 Wiivv. All rights reserved.
//

import UIKit
import Charts
import CoreMotion

class FirstViewController: UIViewController, ChartViewDelegate, CoreMotionManagerCallback {
    
    @IBOutlet var chartView: LineChartView!
    
    var shouldHideData: Bool = false
    
    let MAX_NUM_OF_DATA_POINT = 50
    var coreMotionManager : CoreMotionManager?
    var accelerateX: [ChartDataEntry] = []
    var accelerateY: [ChartDataEntry] = []
    var accelerateZ: [ChartDataEntry] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        coreMotionManager = CoreMotionManager()
        coreMotionManager?.manCallBack = self
        
        chartView.delegate = self
        
        chartView.chartDescription?.enabled = false
        
        chartView.dragEnabled = true
        chartView.setScaleEnabled(true)
        chartView.pinchZoomEnabled = false
        chartView.highlightPerDragEnabled = true
        
        chartView.backgroundColor = .white
        
        chartView.legend.enabled = false
        
        let xAxis = chartView.xAxis
        xAxis.labelPosition = .topInside
        xAxis.labelFont = .systemFont(ofSize: 10, weight: .light)
        xAxis.labelTextColor = UIColor(red: 255/255, green: 192/255, blue: 56/255, alpha: 1)
        xAxis.drawAxisLineEnabled = false
        xAxis.drawGridLinesEnabled = true
        xAxis.centerAxisLabelsEnabled = true
        xAxis.granularity = 3600
        xAxis.valueFormatter = DateValueFormatter()
        
        let leftAxis = chartView.leftAxis
        leftAxis.labelPosition = .insideChart
        leftAxis.labelFont = .systemFont(ofSize: 12, weight: .light)
        leftAxis.drawGridLinesEnabled = true
        leftAxis.granularityEnabled = true
        leftAxis.axisMinimum = -5
        leftAxis.axisMaximum = 5
        leftAxis.yOffset = -9
        leftAxis.labelTextColor = UIColor(red: 255/255, green: 192/255, blue: 56/255, alpha: 1)

        chartView.rightAxis.enabled = false
        
        chartView.legend.form = .line
        
        chartView.animate(xAxisDuration: 2.5)
        
        updateChartData()
    }

    func updateChartData() {
        if self.shouldHideData {
            chartView.data = nil
            return
        }
        
        self.setDataCount(MAX_NUM_OF_DATA_POINT)
    }
    
    func setDataCount(_ count: Int) {
        let data = LineChartData()
        
        let set1 = LineChartDataSet(entries: accelerateX, label: "DataSet 1")
        set1.axisDependency = .left
        set1.setColor(UIColor(red: 51/255, green: 181/255, blue: 229/255, alpha: 1))
        set1.lineWidth = 1.5
        set1.drawCirclesEnabled = false
        set1.drawValuesEnabled = false
        set1.fillAlpha = 0.26
        set1.fillColor = UIColor(red: 51/255, green: 181/255, blue: 229/255, alpha: 1)
        set1.highlightColor = UIColor(red: 244/255, green: 117/255, blue: 117/255, alpha: 1)
        set1.drawCircleHoleEnabled = false
        data.addDataSet(set1)
        
        let set2 = LineChartDataSet(entries: accelerateY, label: "DataSet 2")
        set2.axisDependency = .left
        set2.setColor(UIColor(red: 0/255, green: 255/255, blue: 0/255, alpha: 1))
        set2.lineWidth = 1.5
        set2.drawCirclesEnabled = false
        set2.drawValuesEnabled = false
        set2.fillAlpha = 0.26
        set2.fillColor = UIColor(red: 0/255, green: 255/255, blue: 0/255, alpha: 1)
        set2.highlightColor = UIColor(red: 0/255, green: 255/255, blue: 0/255, alpha: 1)
        set2.drawCircleHoleEnabled = false
        data.addDataSet(set2)
        
        let set3 = LineChartDataSet(entries: accelerateZ, label: "DataSet 3")
        set3.axisDependency = .left
        set3.setColor(UIColor(red: 255/255, green: 0/255, blue: 0/255, alpha: 1))
        set3.lineWidth = 1.5
        set3.drawCirclesEnabled = false
        set3.drawValuesEnabled = false
        set3.fillAlpha = 0.26
        set3.fillColor = UIColor(red: 255/255, green: 0/255, blue: 0/255, alpha: 1)
        set3.highlightColor = UIColor(red: 255/255, green: 0/255, blue: 0/255, alpha: 1)
        set3.drawCircleHoleEnabled = false
        data.addDataSet(set3)
        
        data.setValueTextColor(.white)
        data.setValueFont(.systemFont(ofSize: 9, weight: .light))
        
        chartView.data = data
    }
    
    func onAccelerometerUpdate(_ data: CMAcceleration) {
        if accelerateX.count > MAX_NUM_OF_DATA_POINT {
            accelerateX.removeFirst()
        }
        if accelerateY.count > MAX_NUM_OF_DATA_POINT {
            accelerateY.removeFirst()
        }
        if accelerateZ.count > MAX_NUM_OF_DATA_POINT {
            accelerateZ.removeFirst()
        }
        
        let now = Date().timeIntervalSince1970
        accelerateX.append(ChartDataEntry(x: now, y: data.x))
        accelerateY.append(ChartDataEntry(x: now, y: data.y))
        accelerateZ.append(ChartDataEntry(x: now, y: data.z))
        
        updateChartData()
    }
}

