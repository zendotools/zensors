//
//  Zensor.swift
//  darling-nikki
//
//  Created by Douglas Purdy on 1/24/20.
//  Copyright © 2020 Zendo Tools. All rights reserved.
//

import Foundation
import CoreBluetooth
import FirebaseDatabase

public class Zensor : Identifiable, ObservableObject
{
    var batt : UInt8 = 0
    
    public var id : UUID
    public var name : String
    var startDate = Date()
    
    @Published public var hrv : String = "0.0"
    @Published public var hr : String = "0.0"
    @Published public var duration : String = "0"
    @Published public var progress : String = "true/0"
    @Published public var isMeditating : Bool = false
    @Published public var level : Int = 0
    @Published public var samples = [Float]()
    
    init(id: UUID, name: String, hr: Float, batt: UInt8) {
        
        self.id = id
        self.name = String(name.suffix(12))
        self.hr = hr.description
        self.batt = batt
    }
    
    func update(hr: Float) {
        
        self.samples.append(hr)
        
        self.hr = hr.description
         
        self.duration = self.getDuration().description

        if (self.samples.count > 10)
        {
            self.hrv = self.getHRV().description
            
            self.isMeditating = getMeditativeState()
            
            self.level = getLevel()
                        
            self.progress = self.getProgress()
            
            self.publish()
        }
    }
    
    func getLevel() -> Int {
        
        var retval = 0
        
        if(self.isMeditating)
        {
            retval = self.level + 1
        }
        
        return retval
    }
    
    func getMeditativeState() -> Bool
    {
        var retval = false
        
        if (self.samples.count > 10)
        {
            let min = self.samples.min()
            let max = self.samples.max()
            
            let range = max! - min!
            
            if range > 3
            {
                retval = true
            }
            
            self.samples.removeAll()
            
        }
        
        return retval
    }
    
    func getDuration() -> Int
    {
        let startDate = self.startDate
        
        let seconds = abs(startDate.seconds(from: Date()))
        
        return seconds
    }
    
    func getProgress() -> String
    {
        progress = "\(self.isMeditating)/\(self.level)"
    
        return progress
    }
    
    func getUpdate() -> [String : String]
    {
        return ["duration": self.duration, "hr" : self.hr, "hrv" : self.hrv, "meditating": self.isMeditating.description , "level": self.level.description, "progress" : self.progress]
    }
    
    func getHRV() -> Float
    {
        return self.standardDeviation(self.samples)
    }
    
    func standardDeviation(_ arr : [Float]) -> Float
    {
        let rrIntervals = arr.map
        {
            (beat) -> Float in
            
            return 1000 / beat
        }
        
        let length = Float(rrIntervals.count)
        
        let avg = rrIntervals.reduce(0, +) / length
        
        let sumOfSquaredAvgDiff = rrIntervals.map
        {pow($0 - avg, 2.0)}.reduce(0, {$0 + $1})
        
        return sqrt(sumOfSquaredAvgDiff / length)
        
    }
    
    func publish()
    {
        let database = Database.database().reference()
        let players = database.child("players")
        
        let key = players.child(self.name)
        
        key.setValue(self.getUpdate())
        {
            (error, ref) in
            
            if let error = error
            {
                print("Data could not be saved: \(error).")
                
                return
            }
            
        }
        
    }
}

open class Zensors : NSObject, CBCentralManagerDelegate, ObservableObject {
    
    let centralQueue: DispatchQueue = DispatchQueue(label: "tools.sunyata.zendo", attributes: .concurrent)
    
    var centralManager: CBCentralManager!
    
    @Published public var current: [Zensor] = []
    
    override init()
    {
        super.init()
        
        centralManager = CBCentralManager(delegate: self, queue: centralQueue)
    }
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager)
    {
        switch central.state
        {
        case .poweredOn:
            
            centralManager.scanForPeripherals(withServices: nil, options: nil)
            
        case .poweredOff:
            
            print("Bluetooth status is POWERED OFF")
            
        case .unknown, .resetting, .unsupported, .unauthorized: break
            
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber)
    {
        
        var bytes=[UInt8](repeating:0, count:16)
        var hr_bytes=[UInt8](repeating:0, count:4)
        var batt_byte=[UInt8](repeating:0, count:1)
        
        if let payload: NSData = advertisementData["kCBAdvDataManufacturerData"] as? NSData
        {
            if let name = peripheral.name
            {
                if name.lowercased().contains("movesense")
                {
                    payload.getBytes(&bytes,length:15)
                    
                    var hr:Float = 0
                    var batt:UInt8 = 0
                    
                    for i in 7...10 {
                        hr_bytes[i-7]=bytes[i]
                    }
                    
                    batt_byte[0]=bytes[14]
                    
                    memcpy(&hr,&hr_bytes,4)
                    memcpy(&batt,&batt_byte,1)
                    
                    if (hr != 0)
                    {
                        DispatchQueue.main.async
                            {
                                if let zensor  = self.current.first(where: { $0.id == peripheral.identifier })
                                {
                                    zensor.update(hr: hr)
                                }
                                else
                                {
                                    let zensor = Zensor(id: peripheral.identifier , name: peripheral.name ?? "unknown", hr: hr, batt: batt)
                                    self.current.append(zensor)
                                }
                        }
                    }
                }
            }
        }
    }
}
