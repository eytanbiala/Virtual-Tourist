//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Eytan Biala on 6/16/16.
//  Copyright © 2016 Udacity. All rights reserved.
//

import UIKit
import MapKit

class Annotation: NSObject, MKAnnotation {

    var title: String?
    var coordinate: CLLocationCoordinate2D

    init(title: String, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.coordinate = coordinate
    }

}

class ViewController: UIViewController, MKMapViewDelegate {

    let annotations = [CLLocation:Annotation]()

    let map = MKMapView()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        map.frame = self.view.bounds
        map.delegate = self

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 1.0
        map.addGestureRecognizer(longPress)

        view.addSubview(map)

        navigationController?.navigationBarHidden = true
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        if let region = NSUserDefaults.standardUserDefaults().objectForKey("savedMapRegion") as? MKCoordinateRegion {
            map.region = region
        }

        if let center = NSUserDefaults.standardUserDefaults().objectForKey("savedMapZoom") as? CLLocationCoordinate2D {
            map.camera.centerCoordinate = center
        }

        if let context = CoreDataStack.sharedInstance?.context {
            let pins = Pin.getAllPins(context)
            for pin in pins {
                let annotation = Annotation(title: "\(pin.latitude), \(pin.longitude)", coordinate: CLLocationCoordinate2DMake(pin.latitude, pin.longitude))
                map.addAnnotation(annotation)
            }
        }
    }

    func handleLongPress(gesture: UILongPressGestureRecognizer) {
        if gesture.state != UIGestureRecognizerState.Began {
            return
        }

        let p = gesture.locationInView(map)
        let coordinate = map.convertPoint(p, toCoordinateFromView: map)

        if let context = CoreDataStack.sharedInstance?.context {
            Pin.addPin(coordinate.latitude, longitude: coordinate.longitude, context: context)
            CoreDataStack.sharedInstance?.save()
        }


        let annotation = Annotation(title: "Test: \(coordinate.latitude)", coordinate: coordinate)
        map.addAnnotation(annotation)
    }

    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveMapPosition()
    }

    func saveMapPosition() {
        let region = map.region
        let zoom = map.camera.centerCoordinate
        NSUserDefaults.standardUserDefaults().setObject(region as? AnyObject, forKey: "savedMapRegion")
        NSUserDefaults.standardUserDefaults().setObject(zoom as? AnyObject, forKey: "savedMapZoom")
    }

    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"

        if let pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView {
            pinView.annotation = annotation
            return pinView
        } else {
            let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView.animatesDrop = true
            pinView.pinTintColor = UIColor.redColor()
            pinView.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
            pinView.animatesDrop = true
            return pinView
        }
    }


    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {

        print(view.annotation?.coordinate)

        if let coord = view.annotation?.coordinate, context = CoreDataStack.sharedInstance?.context {
            if let pin = Pin.getPin(coord.latitude, longitude: coord.longitude, context: context) {

                let vc = AlbumViewController(pin: pin, coordinate: coord)
                navigationController?.pushViewController(vc, animated: true)
            }
        }

        mapView.deselectAnnotation(view.annotation, animated: true)
    }
}

