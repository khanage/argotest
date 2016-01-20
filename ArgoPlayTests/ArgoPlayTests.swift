//
//  ArgoPlayTests.swift
//  ArgoPlayTests
//
//  Created by Khan Thompson on 7/01/2016.
//  Copyright © 2016 Darkpond. All rights reserved.
//

import XCTest
import BrightFutures
// Not importing leads to "Operator is not a
// know binary operator".
import Swiftz

@testable import ArgoPlay

class ArgoPlayTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testPreliftedFunc() {
        let f = future({ _ in { x in x + 1 } })
        let fa = future(2)
        
        let futureApplicative = f <*> fa
        
        futureApplicative
            .forced()
        
        XCTAssert((futureApplicative.value!) == 3)
    }
    
    func testDelay() {
        Trickiness.delay(seconds: 3).forced()
        
        XCTAssert(true)
    }
    
    func testApplicativesAreAsync() {        
        let delayTimeInSeconds: UInt32 =
            3
        
        let firstDelay =
            Trickiness.delay(seconds: delayTimeInSeconds)
        
        let nextDelay =
            Trickiness.delay(seconds: delayTimeInSeconds)
        
        let futureApplicative: Future<Int,NoError> =
            alwaysThree
                <^> firstDelay
                <*> nextDelay
        
        futureApplicative
            .forced()
        
        XCTAssert(true, "Timed out - this should be parallel")
    }
    
    func alwaysThree<A,B>(_:A) -> B -> Int {
        return { _ in 3 }
    }
}
