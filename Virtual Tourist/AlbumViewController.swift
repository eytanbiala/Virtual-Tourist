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

typealias ChangeBlock = () -> ()


class AlbumViewController: UIViewController {

    var pin: Pin?
    var coordinate: CLLocationCoordinate2D?
    var map: MKMapView?

    var albumView: AlbumCollectionView?

    var flickrPage: Int = 1


    lazy var downloadedURLs: Set<String> = {
        return Set<String>()
    }()

    lazy var newCollectionButton : UIBarButtonItem = {
        let button = UIBarButtonItem(title: "New Collection", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(newCollectionTapped))
        return button
    }()

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

        title = String(format: "%.2f, %.2f", (coordinate?.latitude)!, (coordinate?.longitude)!)

        navigationController?.navigationBarHidden = false
        navigationController?.navigationBar.translucent = false

        navigationController?.toolbarHidden = false

        let space = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)

        setToolbarItems([space, newCollectionButton, space], animated: true)

        let mapHeight : CGFloat = view.bounds.size.height * 0.25
        let collectionViewHeight = view.bounds.size.height - mapHeight - (self.navigationController?.navigationBar.frame.size.height)! - UIApplication.sharedApplication().statusBarFrame.size.height - (self.navigationController?.toolbar.frame.size.height)!

        map = MKMapView(frame: CGRect(origin: CGPointZero, size: CGSize(width: view.bounds.size.width, height: mapHeight)))

        let annotation = Annotation(title: "\(coordinate?.latitude), \(coordinate?.longitude)", coordinate: coordinate!)
        map?.addAnnotation(annotation)

        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 90, height: 90)
        layout.minimumLineSpacing = 1.0
        layout.minimumInteritemSpacing = 1.0
        let frame = CGRect(origin: CGPoint(x: 0, y: mapHeight), size: CGSize(width: view.bounds.size.width, height: collectionViewHeight))
        albumView = AlbumCollectionView(frame: frame, collectionViewLayout: layout)
        albumView?.contentInset = UIEdgeInsets(top: 1, left: 2, bottom: 2, right: 2)
        albumView!.pin = pin
        albumView!.coordinate = coordinate

        view.addSubview(map!)
        view.addSubview(albumView!)

        downloadFromFlickr()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        let region = MKCoordinateRegion(center: coordinate!, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
        map?.setRegion(region, animated: animated)
    }

    func downloadFromFlickr() {
        self.newCollectionButton.enabled = false
        self.downloadedURLs.removeAll()

        albumView?.pin = nil
        albumView?.pin = pin

        if let lat = coordinate?.latitude, long = coordinate?.longitude {

            self.albumView?.setLoading(true)

            FlickrClient.photosSearch(lat, longitude: long, page:  flickrPage, completion: { (error, result) -> (Void) in
                guard error == nil && result != nil else {
                    return
                }

                guard let photos = result!["photos"] as? [String: AnyObject],
                    let photoList = photos["photo"] as? [[String: AnyObject]],
                    let pages = photos["pages"] as? Int
                    else {
                        return
                }

                self.flickrPage += 1

                if photoList.count == 0 {
                    self.albumView?.setLoading(false)
                }

                if let pinIn = self.pin, ctx = CoreDataStack.sharedInstance?.context {

                    for photo in photoList {
                        let flickr = FlickrPhoto(dictionary: photo)

                        Photo.addPhoto(pinIn, url: flickr.url(), context: ctx)
                        CoreDataStack.sharedInstance?.save()

                        ImageLoader.sharedInstance.loadImage(flickr.url(), completion: { (url, image, error) -> (Void) in

                            if let ctx2 = CoreDataStack.sharedInstance?.context {
                                if let data = image {
                                    Photo.updateImage(url.absoluteString, imageData: data, context: ctx2)
                                    CoreDataStack.sharedInstance?.save()
                                }

                                self.downloadedURLs.insert(url.absoluteString)

                                if self.downloadedURLs.count == photoList.count{

                                    self.albumView?.setLoading(false)

                                    if self.flickrPage <= pages {
                                        dispatch_async(dispatch_get_main_queue(), {
                                            self.newCollectionButton.enabled = true
                                        })
                                    }
                                }
                            }
                        });
                    }
                }
            })
        }
    }

    func newCollectionTapped() {
        CoreDataStack.sharedInstance?.performBackgroundBatchOperation({ (workerContext) in
            do {
                let pin = try workerContext.existingObjectWithID((self.pin)!.objectID) as! Pin
                Photo.deleteAll(pin, context: workerContext)
            } catch {

            }

            }, completion: { (Void) in
                CoreDataStack.sharedInstance?.save()
                self.downloadFromFlickr()
        })
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
            } else {
                fetchedResultsController = nil
            }
        }
    }

    var coordinate: CLLocationCoordinate2D?

    lazy var objectChanges : [ChangeBlock] = {
        return [ChangeBlock]()
    }()

    lazy var sectionChanges : [ChangeBlock] = {
        return [ChangeBlock]()
    }()

    lazy var emptyView : UILabel = {
        let label = UILabel()
        label.text = "No photos"
        label.textAlignment = .Center
        return label
    }()

    func setLoading(loading: Bool) {
        if loading {
            emptyView.text = "Loading"
        } else {
            emptyView.text = "No photos"
        }
    }

    convenience init() {
        self.init(frame: CGRectZero, collectionViewLayout: UICollectionViewLayout())
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)

        self.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: "photo")

        self.delegate = self
        self.dataSource = self

        self.backgroundColor = UIColor.whiteColor()
    }

    func controllerWillChangeContent(controller: NSFetchedResultsController) {

        objectChanges.removeAll()
        sectionChanges.removeAll()
    }

    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {

        switch type {
        case .Insert:
            sectionChanges.append({
                self.insertSections(NSIndexSet(index: sectionIndex))
            })
        case .Delete:
            sectionChanges.append({
                self.deleteSections(NSIndexSet(index: sectionIndex))
            })
        default:
            break
        }
    }

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {

        switch type {
        case .Insert:
            objectChanges.append({
                self.insertItemsAtIndexPaths([newIndexPath!])
            })
        case .Delete:
            objectChanges.append({
                self.deleteItemsAtIndexPaths([indexPath!])
            })
        case .Update:
            objectChanges.append({
                self.reloadItemsAtIndexPaths([indexPath!])
            })
        case .Move:
            objectChanges.append({
                self.moveItemAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
            })
        }
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {

        let secChanges = sectionChanges
        let objChanges = objectChanges

        self.performBatchUpdates({
            for block in secChanges {
                block()
            }

            for block in objChanges {
                block()
            }
            }, completion: nil)

        sectionChanges.removeAll()
        objectChanges.removeAll()
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let count = fetchedResultsController?.fetchedObjects?.count {
            if (count == 0) {
                collectionView.backgroundView = emptyView
                emptyView.frame = collectionView.bounds
            } else {
                collectionView.backgroundView = nil
            }
            return count
        }
        return 0
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("photo", forIndexPath: indexPath)


        for subview in cell.contentView.subviews {
            subview.removeFromSuperview()
        }

        if let object = fetchedResultsController?.objectAtIndexPath(indexPath) as? Photo {

            if let data = object.image {
                cell.contentView.backgroundColor = UIColor.clearColor()
                let imageView = UIImageView(frame: cell.contentView.bounds)
                imageView.contentMode = UIViewContentMode.ScaleAspectFit
                imageView.image = UIImage(data: data)
                cell.contentView.addSubview(imageView)
            } else {
                cell.contentView.backgroundColor = UIColor.lightGrayColor()
                let loader = UIActivityIndicatorView(frame: CGRect(origin: CGPointZero, size: CGSize(width: 44.0, height: 44.0)))
                loader.center = cell.contentView.center
                loader.startAnimating()
                cell.contentView.addSubview(loader)
            }
        }

        return cell
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if let ctx = CoreDataStack.sharedInstance?.context, photo = fetchedResultsController?.objectAtIndexPath(indexPath) as? Photo {
            ctx.deleteObject(photo)
            CoreDataStack.sharedInstance?.save()
        }
    }

}