//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Eytan Biala on 6/17/16.
//  Copyright © 2016 Udacity. All rights reserved.
//

import Foundation
import UIKit

typealias FlickrClientResult = (error: NSError?, result: Dictionary<String, AnyObject>?) -> (Void)

let key = "9ab025685e5b8d9600042448a22e4f0c"

struct FlickrPhoto {
    // https://farm{farm-id}.staticflickr.com/{server-id}/{id}_{secret}_[mstzb].jpg

    let farm: String
    let server: String
    let photoId: String
    let secret: String

    init(dictionary: Dictionary<String, AnyObject>) {
        farm = (dictionary["farm"] as! NSNumber).stringValue
        server = dictionary["server"] as! String
        photoId = dictionary["id"] as! String
        secret = dictionary["secret"] as! String
    }

    func url() -> String {
        return "https://farm\(farm).staticflickr.com/\(server)/\(photoId)_\(secret)_q.jpg"
    }
}

class FlickrClient {

    private class func jsonFromResponseData(data: NSData) -> Dictionary<String, AnyObject>? {
        do {
            let jsonObject = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0))
            return jsonObject as? Dictionary<String, AnyObject>
        } catch let jsonError as NSError {
            print(jsonError.localizedDescription)
        }

        return nil
    }

    private class func flickrDataTaskWithCompletion(request: NSURLRequest, completion: FlickrClientResult?) {

        UIApplication.sharedApplication().networkActivityIndicatorVisible = true

        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) { data, response, error in

            UIApplication.sharedApplication().networkActivityIndicatorVisible = false

            guard error == nil && data != nil else {
                dispatch_async(dispatch_get_main_queue(), {
                    completion?(error: error, result: nil)
                })
                return
            }

            /* subset response data! */
            let json = jsonFromResponseData(data!)
            //print(json)
            dispatch_async(dispatch_get_main_queue(), {
                completion?(error: error, result: json)
            })
        }
        task.resume()
    }

    class func photosSearch(latitude: Double, longitude: Double, completion: FlickrClientResult) {
        let url = NSURL(string:"https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(key)&media=photos&format=json&nojsoncallback=1&lat=\(latitude)&lon=\(longitude)")
        let request = NSURLRequest(URL: url!)
        flickrDataTaskWithCompletion(request, completion: completion)
    }
}