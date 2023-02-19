//
//  MonetaryCounterTests.swift
//  MonetaryCounterView_Tests
//
//  Created by Davide Ceresola on 22/02/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import XCTest
import MonetaryCounterView

class MonetaryCounterTests: MonetaryCounterBaseTests {
    
    func testIncrementFromZero() {
        
        let number: NSDecimalNumber = 1000.32
        counterView.number = number
        expectedResult(number)
        
    }
    
    func testIncrementAndReturnToZero() {
        
        let number: NSDecimalNumber = 1000.32
        counterView.number = number
        expectedResult(number)
        
        let finalNumber: NSDecimalNumber = .zero
        counterView.number = finalNumber
        expectedResult(finalNumber)
        
    }
    
    func testIncrementAndNegative() {
        
        let number: NSDecimalNumber = 1000.32
        counterView.number = number
        expectedResult(number)
        
        let finalNumber: NSDecimalNumber = -20.42
        counterView.number = finalNumber
        expectedResult(finalNumber)
        
    }
    
    func testIncrementNegative() {
        
        let number: NSDecimalNumber = -42.47
        counterView.number = number
        expectedResult(number)
        
        counterView.number = -142.47
        
        let finalNumber: NSDecimalNumber = -42.47
        counterView.number = finalNumber
        expectedResult(finalNumber)
        
    }
    
    func testIncrementNegativeAddingZero() {
        
        let number: NSDecimalNumber = -99
        counterView.number = number
        expectedResult(number)
        
        let finalNumber: NSDecimalNumber = -100.01
        counterView.number = finalNumber
        expectedResult(finalNumber)
        
    }
    
}
