//
//  Photo+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by Eytan Biala on 6/17/16.
//  Copyright © 2016 Udacity. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Photo {

    @NSManaged var image: NSData?
    @NSManaged var url: NSString
    @NSManaged var pin: Pin?

}
