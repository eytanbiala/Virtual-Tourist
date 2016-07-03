//
//  AlbumViewController.swift
//  Virtual Tourist
//
//  Created by Eytan Biala on 6/27/16.
//  Copyright © 2016 Udacity. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import CoreLocation
import MapKit

class AlbumViewController: UIViewController {

    var pin: Pin?
    var coordinate: CLLocationCoordinate2D?

    convenience init() {
        self.init(nibName:nil, bundle:nil)
    }

    convenience init(pin: Pin, coordinate: CLLocationCoordinate2D) {
        self.init()
        self.pin = pin
        self.coordinate = coordinate
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBarHidden = false
        navigationController?.navigationBar.translucent = false

        let mapHeight : CGFloat = view.bounds.size.height * 0.25
        let collectionViewHeight = view.bounds.size.height - mapHeight

        let map = MKMapView(frame: CGRect(origin: CGPointZero, size: CGSize(width: view.bounds.size.width, height: mapHeight)))

        let layout = UICollectionViewLayout()
        let frame = CGRect(origin: CGPoint(x: 0, y: mapHeight), size: CGSize(width: view.bounds.size.width, height: collectionViewHeight))
        let collectionView = AlbumCollectionView(frame: frame, collectionViewLayout: layout)
        collectionView.pin = pin
        collectionView.coordinate = coordinate

        view.addSubview(map)
        view.addSubview(collectionView)

        if let lat = coordinate?.latitude, long = coordinate?.longitude {
            FlickrClient.photosSearch(lat, longitude: long, completion: { (error, result) -> (Void) in
                guard error == nil && result != nil else {
                    return
                }

                guard let photos = result!["photos"] as? [String: AnyObject],
                    let photoList = photos["photo"] as? [[String: AnyObject]]
                    else {
                        return
                }

                if let photoPin = self.pin, context = CoreDataStack.sharedInstance?.context {
                    for photo in photoList {
                        let flickr = FlickrPhoto(dictionary: photo)

                        Photo.addPhoto(photoPin, url: flickr.url(), context: context)
                    }
                }
            })
        }
    }

}

class AlbumCollectionView: UICollectionView, UICollectionViewDelegate, UICollectionViewDataSource, NSFetchedResultsControllerDelegate {

    private var fetchedResultsController: NSFetchedResultsController?

    var pin: Pin? {
        didSet {
            if pin != nil {
                let fetch = NSFetchRequest(entityName: "Photo")
                fetch.predicate = NSPredicate(format: "pin = %@", argumentArray: [pin!])
                let desc = NSSortDescriptor(key: "url", ascending: true)
                fetch.sortDescriptors = [desc]
                if let context = CoreDataStack.sharedInstance?.context {
                    fetchedResultsController = NSFetchedResultsController(fetchRequest: fetch, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
                    fetchedResultsController!.delegate = self
                    do {
                        try fetchedResultsController?.performFetch()
                    } catch let fetchError as NSError {
                        print(fetchError)
                    }
                }
            }
        }
    }

    var coordinate: CLLocationCoordinate2D?

    convenience init() {
        self.init(frame: CGRectZero, collectionViewLayout: UICollectionViewLayout())
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)

        self.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: "album")
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        print("didChange")
    }

    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        print("willChange")
    }

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        print("didChangeObject")
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let count = fetchedResultsController?.fetchedObjects?.count {
            return count
        }
        return 0
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        return UICollectionViewCell()
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        // TODO: Delete image
    }
    
}