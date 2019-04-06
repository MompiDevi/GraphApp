//
//  ViewController.swift
//  iOSInterviewTest
//
//  Created by N. Mompi Devi on 26/02/19.
//  Copyright © 2019 momiv. All rights reserved.
//

import UIKit
import SocketIO
import FMDB
import UserNotifications
import Charts
class ViewController: UIViewController, ChartViewDelegate {
    var manager:SocketManager?
    let databaseFileName = "database.sqlite"
    var prevData:Int = 0
    var pathToDatabase: String!
    struct DataStruct {
        var data:Int
        var date:String
    }
    
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var chart: LineChartView!
    var database: FMDatabase!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let documentsDirectory = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString) as String
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { (granted, error) in
            if granted {
                print("yes")
            } else {
                print("No")
            }
        }
        chart.delegate = self
        pathToDatabase = documentsDirectory.appending("/\(databaseFileName)")
        let working = createDatabase()
        connect()
        
    }

    func sendNotifications(){
        let content = UNMutableNotificationContent()
        content.title = "Test"
        content.subtitle = "Test Subtitle"
        content.body = "Body"
        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "sound.wav"))
        content.categoryIdentifier = "banner"
        let uuidString = UUID().uuidString
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    func connect(){
         manager = SocketManager(socketURL: URL(string: "http://ios-test.us-east-1.elasticbeanstalk.com/")!, config: [.log(true), .compress])
        let socket = manager!.socket(forNamespace: "/random")

        socket.on(clientEvent: .connect) {data, ack in
            print("socket connected")
        }
        let socketConnectionStatus = socket.status
        switch socketConnectionStatus {
        case SocketIOStatus.connected:
            print("socket connected")
        case SocketIOStatus.connecting:
            print("socket connecting")
        case SocketIOStatus.disconnected:
            print("socket disconnected")
        case SocketIOStatus.notConnected:
            print("socket not connected")
        }
        socket.on("capture") {data, ack in
            let newData:Int = data[0] as! Int
            let date = Date()
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: date)
            let minutes = calendar.component(.minute, from: date)
            let seconds = calendar.component(.second, from: date)
            let time = String(describing: "\(hour):\(minutes):\(seconds)")
            print("Data:\(data[0]), \(time)")
            self.addData(data: newData, date: time)
            let dataReceived:[DataStruct] = self.getData()
            self.updateChart(data: dataReceived)
            if(newData ==  self.prevData){
                self.sendNotifications()
            }
            self.prevData = newData
        }
        
        socket.connect()
    }
    func createDatabase() -> Bool {
        var created = false
        
        if !FileManager.default.fileExists(atPath: pathToDatabase) {
            database = FMDatabase(path: pathToDatabase!)
            
            if database != nil {
                if database.open() {
                    let createMoviesTableQuery = "create table Database (data integer, date string)"
                    
                    do {
                        try database.executeUpdate(createMoviesTableQuery, values: nil)
                        created = true
                    }
                    catch {
                        print("Could not create table.")
                        print(error.localizedDescription)
                    }
                    
                    database.close()
                }
                else {
                    print("Could not open the database.")
                }
            }
        }
        
        return created
    }
    
    func addData(data: Int, date: String ) {
        database = FMDatabase(path: pathToDatabase!)
        
        if database != nil {
            if database.open() {
                let insertMoviesTableQuery = "insert into Database (data,date) values (\(data), '\(date)')"
                
                do {
                    try database.executeUpdate(insertMoviesTableQuery, values: nil)
                    
                }
                catch {
                    print("Could not insert table.")
                    print(error.localizedDescription)
                }
                
                database.close()
            }
            else {
                print("Could not open the database.")
            }
        }
    }
    
    func getData() -> [DataStruct] {
        var dataFetched:DataStruct?
         var dataFetchedArray:[DataStruct]?
        database = FMDatabase(path: pathToDatabase!)
        
        if database != nil {
            // Open the database.
            if database.open() {
                let selectMoviesTableQuery = "select * from database"
                
                do {
                    let results = try database.executeQuery(selectMoviesTableQuery, values: nil)
                    while results.next() {
                        dataFetched = DataStruct(data: Int(results.int(forColumn: "data")), date: String(describing: results.string(forColumn: "date")!))
                        if dataFetchedArray == nil {
                            dataFetchedArray = [DataStruct]()
                        }
                        dataFetchedArray?.append(dataFetched!)

                    }
                }
                catch {
                    print("Could not insert table.")
                    print(error.localizedDescription)
                }
                database.close()
            }
            else {
                print("Could not open the database.")
            }
        }
        return dataFetchedArray!
    }
    
    private func updateChart(data: [DataStruct]) {
        chart.noDataText = "You need to provide data for the chart."
        countLabel.text = "Number of Random Numbers Stored:  \(data.count)"
        var chartEntry = [ChartDataEntry]()
        
        for i in 0..<data.count {
            let value = ChartDataEntry(x:  Double(i), y:Double(data[i].data))
            chartEntry.append(value)
        }
        
        let line = LineChartDataSet(entries: chartEntry, label: "Random Numbers")
        line.mode = .cubicBezier
        line.setColor(UIColor.green, alpha: 0.6)
        line.fill = Fill.init(CGColor: UIColor.orange.cgColor)

        line.drawFilledEnabled = true
        let newData = LineChartData()
        newData.addDataSet(line)
        newData.setDrawValues(true)
        chart.setVisibleXRangeMaximum(Double(10))
        chart.moveViewToX(Double(data.count - 10))
        let limit = ChartLimitLine(limit: 7.0, label: "Target")
        
        chart.rightAxis.addLimitLine(limit)
        chart.data = newData
        chart.chartDescription?.text = "Random Numbers"
    }
}

