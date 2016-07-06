//
//  Photo.swift
//  Virtual Tourist
//
//  Created by Eytan Biala on 6/17/16.
//  Copyright © 2016 Udacity. All rights reserved.
//

import Foundation
import CoreData

class Photo: NSManagedObject {

    class func entity(context: NSManagedObjectContext) -> NSEntityDescription? {
        return NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)
    }

    class func fetchRequest() -> NSFetchRequest {
        return NSFetchRequest(entityName: "Photo")
    }

    class func fetchedResultsController(pin: Pin, context: NSManagedObjectContext) -> NSFetchedResultsController {
        let fr = fetchRequest()
        fr.predicate = NSPredicate(format: "pin == %@", pin)
        let frc = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: "\(pin.latitude),\(pin.longitude)")
        return frc
    }

    class func addPhoto(pin: Pin, url: String, context: NSManagedObjectContext) -> Photo {
        var photo = existingPhoto(pin, url: url, context: context)
        if photo == nil {
            photo = Photo(entity: self.entity(context)!, insertIntoManagedObjectContext: context)
        }

        photo!.pin = pin
        photo!.url = url
        return photo!
    }

    class func existingPhoto(pin: Pin, url: String, context: NSManagedObjectContext) -> Photo? {
        let fr = fetchRequest()
        fr.predicate = NSPredicate(format: "url == %@ AND pin == %@", url, pin)

        var photos = [Photo]()
        do {
            photos = try context.executeFetchRequest(fr) as! [Photo]
        } catch let error as NSError {
            print("Fetch failed: \(error.localizedDescription)")
        }

        return photos.first
    }

    class func updateImage(url: String, imageData: NSData, context: NSManagedObjectContext) -> Photo? {
        let fr = fetchRequest()
        fr.predicate = NSPredicate(format: "url == %@", url)

        var photos = [Photo]()
        do {
            photos = try context.executeFetchRequest(fr) as! [Photo]
        } catch let error as NSError {
            print("Fetch failed: \(error.localizedDescription)")
        }

        if let photo = photos.first {
            photo.image = imageData
        }

        return nil
    }

    class func deleteAll(pin: Pin, context: NSManagedObjectContext) {
        let fr = fetchRequest()
        fr.predicate = NSPredicate(format: "pin == %@", pin)

        var photos = [Photo]()
        do {
            photos = try context.executeFetchRequest(fr) as! [Photo]
        } catch let error as NSError {
            print("Fetch failed: \(error.localizedDescription)")
        }

        for photo in photos {
            context.deleteObject(photo)
        }
    }
}
