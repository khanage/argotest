//
//  Reddit.swift
//  ArgoPlay
//
//  Created by Khan Thompson on 7/01/2016.
//  Copyright © 2016 Darkpond. All rights reserved.
//

import Foundation
import UIKit
import Swiftz
import Tyro
import BrightFutures
import Result

class RThing {
    var id: String?
    var name: String?
    var kind: String
    var data: JSONValue?
    
    
    init(id: String?, name: String?, kind: String, data: JSONValue?){
        self.id = id
        self.name = name
        self.kind = kind
        self.data = data
    }
}

extension RThing : FromJSON {
    static func fromJSON(j:JSONValue) -> Either<JSONError, RThing> {
        let id: String?? = j <?? "id"
        let name: String?? = j <?? "name"
        let kind: String? = j <? "kind"
        let data: JSONValue?? = j <?? "data"
        
        return (curry(RThing.init)
            <^> id
            <*> name
            <*> kind
            <*> data
        ).toEither(.Custom("Failed to create thing"))
    }
}

class RListing {
    var kind: String
    var before: String?
    var after: String?
    var modhash: String?
    var children: [RThing]
    
    init( kind: String
        , before: String?
        , after: String?
        , modhash: String?
        , children: [RThing]
        )
    {
        self.kind = kind
        self.before = before
        self.after = after
        self.modhash = modhash
        self.children = children
    }
}

extension RListing : FromJSON {
    static func fromJSON(j:JSONValue) -> Either<JSONError, RListing> {
        let kind: String? = j <? "kind"
        let before: String?? = j <?? "data" <> "before"
        let after: String?? = j <?? "data" <> "after"
        let modhash: String? = j <? "data" <> "modhash"
        let children: [RThing]? = try? j <! "data" <> "children"
    
        return (curry(RListing.init)
          <^> kind
          <*> before
          <*> after
          <*> modhash
          <*> children).toEither(.Custom("Could not create listing"))
    }
}

func downloadAsString(url: NSURL) -> Future<NSData, NSError> {
    let sessionConfiguration =
        NSURLSessionConfiguration.defaultSessionConfiguration()
    let session: NSURLSession =
        NSURLSession(configuration: sessionConfiguration)
    let (task, future) =
        session.dataTaskWithURL(url)
    
    task.resume()
    
    let runner: (NSData?, NSURLResponse?) -> Result<NSData, NSError> =
        { (data, _) in
            switch data {
            case .Some(let result):
                return Result(value: result)
            case .None:
                return Result(error: NSError(domain: "Downloading", code: 0, userInfo: nil))
            }
        }
    
    return future.flatMap(runner)
}

class Stuff {
    
    static func tuple2<A,B>(a: A) -> B -> (A,B) {
        return { b in (a, b) }
    }
    
    static func downloadStuff
        ( first: String
        , second: String)
        -> Future<(NSData,NSData), NSError>
    {
        let vals =
            tuple2
                <^> downloadAsString(NSURL(string: first)!)
                <*> downloadAsString(NSURL(string: second)!)
        
        return vals
    }
    
    static func download
        ( withSuccess           success: RListing -> Void
        , andErrorHandler errorCallback: JSONError -> Void)
        -> Void {
        
        let url = NSURL(string: "https://api.reddit.com/hot?count=1")
                        
        let download: Future<JSONValue,NSError> =
            downloadAsString(url!)
            .map { data in JSONValue.decode(data)! }

        download.map { jsonVal in
            switch RListing.fromJSON(jsonVal) {
            case let .Left(error):
                errorCallback(error)
            case let .Right(listing):
                success(listing)
            }
        }
    }
}
