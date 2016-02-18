//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Hyun on 2015. 11. 30..
//  Copyright © 2015년 wook2. All rights reserved.
//

import Foundation

// Define constants
let BASE_URL = "https://api.flickr.com/services/rest/"
let METHOD_NAME = "flickr.photos.search"
let EXTRAS = "url_m"
let SAFE_SEARCH = "1"
let PER_PAGE = "21"
let DATA_FORMAT = "json"
let NO_JSON_CALLBACK = "1"
let TOTAL_PAGE = 4000

let BOUNDING_BOX_HALF_WIDTH = 1.0
let BOUNDING_BOX_HALF_HEIGHT = 1.0
let LAT_MIN = -90.0
let LAT_MAX = 90.0
let LON_MIN = -180.0
let LON_MAX = 180.0


class FlickrClient : NSObject {
    
    // MARK : - Properties 
    var session : NSURLSession
    
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    func taskForResource( methodArguments:[String:AnyObject], completionHandler:(result:AnyObject!, error:NSError?)->Void)->NSURLSessionDataTask {
        
        // Initialize rul
        let urlString =  BASE_URL + FlickrClient.escapedParameters(methodArguments)
        let url = NSURL(string:urlString)!
        let request = NSURLRequest(URL: url)
        
        // Initialize task for getting data
        let task = session.dataTaskWithRequest(request) { (data,response, downloadError) in
            
            if let error = downloadError {
                completionHandler(result:nil, error: error)
            } else {
                print("Step 3 - taskForResource's completionHandler is invoked.")
                FlickrClient.parseJSONWithCompletionHandler(data!, completionHandler:completionHandler)
            }
        }
        
        task.resume()
        
        return task
    }
    
    func taskForImage(imageURL: String, completionHandler: (imageData: NSData?, error: NSError?) ->  Void) -> NSURLSessionTask {
        
        let url = NSURL(string:imageURL)!
        
        let task = session.dataTaskWithURL(url) {data, response, downloadError in
            
            if let error = downloadError {
                //let newError = TheMovieDB.errorForData(data, response: response, error: error)
                completionHandler(imageData: nil, error: error)
            } else {
                completionHandler(imageData: data, error: nil)
            }
        }
        
        task.resume()
        
        return task
    }
    
    // MARK : - Shared Instance 
    class func sharedInstance()-> FlickrClient {
        
        struct Singleton {
            static var sharedInstance  = FlickrClient()
        }
        
        return Singleton.sharedInstance
    }
    
    class func parseJSONWithCompletionHandler(data:NSData, completionHandler: (result:AnyObject!, error:NSError?)->Void ) {
        
        var parsingError : NSError? = nil
        
        let parsedResult : AnyObject?
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
        } catch let error as NSError {
            parsingError = error
            parsedResult = nil
        }
        
        if let error = parsingError {
            completionHandler(result: nil, error: error)
        } else {
            print("Step 4 - parseJSONWithCompletionHandler is invoked.")
            completionHandler(result:parsedResult, error: nil)
        }
    }
    

    /* Helper function: Given a dictionary of parameters, convert to a string for a url */
    class func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
    
    // MARK: - Shared Image Cache
    
    struct Caches {
        static let imageCache = ImageCache()
    }

}