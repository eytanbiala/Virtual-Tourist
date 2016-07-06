//
//  Pin.swift
//  Virtual Tourist
//
//  Created by Eytan Biala on 6/17/16.
//  Copyright © 2016 Udacity. All rights reserved.
//

import Foundation
import CoreData

class Pin: NSManagedObject {

    class func entity(context: NSManagedObjectContext) -> NSEntityDescription? {
        return NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)
    }

    class func fetchRequest() -> NSFetchRequest {
        return NSFetchRequest(entityName: "Pin")
    }

    class func addPin(latitude: Double, longitude: Double, context: NSManagedObjectContext) -> Pin {
        let pin = Pin(entity: self.entity(context)!, insertIntoManagedObjectContext: context)
        pin.latitude = latitude
        pin.longitude = longitude
        context.insertObject(pin)
        return pin
    }

    class func getPin(latitude: Double, longitude: Double, context: NSManagedObjectContext) -> Pin? {

        let fetch = fetchRequest()
        fetch.predicate = NSPredicate(format: "latitude = %@ AND longitude = %@", argumentArray: [latitude, longitude])

        var pins = [Pin]()
        do {
            pins = try context.executeFetchRequest(fetch) as! [Pin]
        } catch let error as NSError {
            print("Fetch failed: \(error.localizedDescription)")
        }

        return pins.first
    }

    class func getAllPins(context: NSManagedObjectContext) -> [Pin] {

        let fetch = fetchRequest()

        var pins = [Pin]()
        do {
            pins = try context.executeFetchRequest(fetch) as! [Pin]
        } catch let error as NSError {
            print("Fetch failed: \(error.localizedDescription)")
        }
        
        return pins
    }
    
}
