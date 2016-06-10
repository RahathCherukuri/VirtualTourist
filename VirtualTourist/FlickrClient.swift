//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Rahath cherukuri on 4/25/16.
//  Copyright © 2016 Rahath cherukuri. All rights reserved.
//

import Foundation

class FlickrClient {
    
    
    var session: NSURLSession
    
    private init() {
        session = NSURLSession.sharedSession()
    }
    
    // MARK: GET
    func taskForGETMethod(method: String, parameters: [String : AnyObject], completionHandler: (result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask {
        
        /* 1. Set the parameters */
        let mutableParameters = parameters
        
        /* 2/3. Build the URL and configure the request */
        let urlString = BASE_URL + FlickrClient.escapedParameters(mutableParameters)
        
        let url = NSURL(string: urlString)!
        let request = NSMutableURLRequest(URL: url)
        
        /* 4. Make the request */
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            if let _ = error {
                completionHandler(result: nil, error: error)
            } else {
                /* GUARD: Was there any data returned? */
                guard let data = data else {
                    completionHandler(result: nil, error: error)
                    return
                }
                
                /* 5/6. Parse the data and use the data (happens in completion handler) */
                FlickrClient.parseJSONWithCompletionHandler(data, completionHandler: completionHandler)
            }
        }
        
        /* 7. Start the request */
        task.resume()
        
        return task
    }
    
    func taskForImage(imageURL: NSURL, completionHandler: (result: NSData?, error: NSError?)-> Void) -> NSURLSessionDataTask {
        let request = NSMutableURLRequest(URL: imageURL)
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            if let _ = error {
                completionHandler(result: nil, error: error)
            } else {
                /* GUARD: Was there any data returned? */
                guard let data = data else {
                    completionHandler(result: nil, error: error)
                    return
                }
                completionHandler(result: data, error: nil)
            }
        }
        task.resume()
        
        return task
    }
    
    // MARK: Helpers
    
    /* Helper: Given raw JSON, return a usable Foundation object */
    class func parseJSONWithCompletionHandler(data: NSData, completionHandler: (result: AnyObject!, error: NSError?) -> Void) {
        
        var parsedResult: AnyObject!
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            completionHandler(result: nil, error: NSError(domain: "parseJSONWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        
        completionHandler(result: parsedResult, error: nil)
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
    
    // MARK: Shared Instance
    
    static let sharedInstance = FlickrClient()
    
    // MARK: - Shared Image Cache
    
    struct Caches {
        static let imageCache = ImageCache()
    }

}
