//
//  ImageDownloader.swift
//  Virtual Tourist
//
//  Created by Eytan Biala on 6/28/16.
//  Copyright © 2016 Udacity. All rights reserved.
//

import Foundation
import UIKit

typealias ImageLoadCompletion = (url: NSURL, image: UIImage?, error: NSError?) -> (Void)

class ImageLoadOperation : NSOperation {

    var imageURL : NSURL!
    var imageLoadCompletion: ImageLoadCompletion!

    init(url: NSURL, completion: ImageLoadCompletion) {
        super.init()
        self.name = url.absoluteString
        imageURL = url
        imageLoadCompletion = completion
    }

    override var asynchronous: Bool {
        return true
    }

    override func main() {
        let request = NSURLRequest(URL:  imageURL)
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) { data, response, error in
            guard error == nil && data != nil else {
                dispatch_async(dispatch_get_main_queue(), {
                    self.imageLoadCompletion?(url: self.imageURL, image: nil, error: error)
                })
                return
            }

            if let image = UIImage(data: data!) {
                dispatch_async(dispatch_get_main_queue(), {
                    self.imageLoadCompletion?(url: self.imageURL, image: image, error: nil)
                })
            } else {
                dispatch_async(dispatch_get_main_queue(), {
                    self.imageLoadCompletion?(url: self.imageURL, image: nil, error: nil)
                })
            }
        }
        task.resume()
    }
}

class ImageLoader {

    private lazy var queue: NSOperationQueue = {
        let queue = NSOperationQueue()
        queue.maxConcurrentOperationCount = 25
        queue.name = "ImageLoader"
        queue.qualityOfService = .Utility
        return queue
    }()

    let sharedInstance = ImageLoader()

    func loadImage(imageURL: String, completion: ImageLoadCompletion) {

        if let url = NSURL(string: imageURL) {
            let operation = ImageLoadOperation(url: url, completion: completion)
            queue.addOperation(operation)
        }
    }
}

