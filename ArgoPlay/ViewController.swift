//
//  ViewController.swift
//  ArgoPlay
//
//  Created by Khan Thompson on 7/01/2016.
//  Copyright © 2016 Darkpond. All rights reserved.
//

import Tyro
import Swiftz
import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        Stuff.download(withSuccess: outputId, andErrorHandler: outputError)
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func outputId(rthing: RListing) {
        dispatch_async(dispatch_get_main_queue()) {
            rthing.children.forEach({thing in print("\(thing.data)")})
        }
    }
    
    func outputError(error: JSONError) {
        dispatch_async(dispatch_get_main_queue()) {
            print("error")
        }

    }
}