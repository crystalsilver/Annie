//
//  AnnieTests.swift
//  AnnieTests
//
//  Created by skyline on 15/1/6.
//  Copyright (c) 2015年 skyline. All rights reserved.
//

import Cocoa
import XCTest
//import Annie

class AnnieTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func getTestCaseFromFile(name:String) -> (expectOutput:String, realOutput :String) {
        var input:NSString?
        var output: NSString?
        if let url1 = NSBundle(forClass: self.dynamicType).URLForResource(name, withExtension: "text") {
            input = try? NSString(contentsOfURL: url1, encoding: NSUTF8StringEncoding)
        }
        if let url2 = NSBundle(forClass: self.dynamicType).URLForResource(name, withExtension: "html") {
            output = try? NSString(contentsOfURL: url2, encoding: NSUTF8StringEncoding)
        }
        return (trimWhitespace(String(output!)),trimWhitespace(markdown(String(input!))))
    }
    
    
    func testAmpAndAnglesEncodeing() {
        let test = getTestCaseFromFile("amps_and_angles_encoding")
        XCTAssertEqual(test.realOutput, test.expectOutput)
    }
    
    func testAutoEmail() {
        let test = getTestCaseFromFile("auto_email")
        XCTAssertEqual(test.realOutput, test.expectOutput)
    }
    
    func testAutoLinks() {
        let test = getTestCaseFromFile("auto_links")
        XCTAssertEqual(test.realOutput, test.expectOutput)
    }
    
    func testBackSlashEscapes() {
        let test = getTestCaseFromFile("backslash_escapes")
        XCTAssertEqual(test.realOutput, test.expectOutput)
    }
    
    func testCodeBlocks() {
        let test = getTestCaseFromFile("code_blocks")
        XCTAssertEqual(test.realOutput, test.expectOutput)
    }

    func testCodeSpan() {
        let test = getTestCaseFromFile("code_spans")
        XCTAssertEqual(test.realOutput, test.expectOutput)
    }
    

    func testHeaders() {
        let test = getTestCaseFromFile("headers")
        XCTAssertEqual(test.realOutput, test.expectOutput)
    }
    
    func testHorizontalRules() {
        let test = getTestCaseFromFile("horizontal_rules")
        XCTAssertEqual(test.realOutput, test.expectOutput)
    }

    func testNestedBlockQuotes() {
        let test = getTestCaseFromFile("nested_blockquotes")
        XCTAssertEqual(test.realOutput, test.expectOutput)
    }

    func testStrongAndEm() {
        let test = getTestCaseFromFile("strong_and_em_together")
        XCTAssertEqual(test.realOutput, test.expectOutput)
    }
    
    func testTidyness() {
        let test = getTestCaseFromFile("tidyness")
        XCTAssertEqual(test.realOutput, test.expectOutput)
    }
}
