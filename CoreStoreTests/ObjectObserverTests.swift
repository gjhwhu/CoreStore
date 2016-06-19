//
//  ObjectObserverTests.swift
//  CoreStore
//
//  Copyright © 2016 John Rommel Estropia
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import XCTest

@testable
import CoreStore


#if os(iOS) || os(watchOS) || os(tvOS)

// MARK: - ObjectObserverTests

class ObjectObserverTests: BaseTestDataTestCase {
    
    @objc
    dynamic func test_ThatObjectObservers_CanReceiveUpdateNotifications() {
        
        self.prepareStack { (stack) in
            
            self.prepareTestDataForStack(stack)
            
            guard let object = stack.fetchOne(
                From(TestEntity1),
                Where("testEntityID", isEqualTo: 101)) else {
                    
                    XCTFail()
                    return
            }
            let observer = TestObjectObserver()
            let monitor = stack.monitorObject(object)
            monitor.addObserver(observer)
            
            XCTAssertEqual(monitor.object, object)
            XCTAssertFalse(monitor.isObjectDeleted)
            
            var events = 0
            
            let willUpdateExpectation = self.expectationForNotification(
                "objectMonitor:willUpdateObject:",
                object: observer,
                handler: { (note) -> Bool in
                    
                    XCTAssertEqual(events, 0)
                    XCTAssertEqual(
                        (note.userInfo ?? [:]),
                        ["object": object] as NSDictionary
                    )
                    defer {
                        
                        events += 1
                    }
                    return events == 0
                }
            )
            let didUpdateExpectation = self.expectationForNotification(
                "objectMonitor:didUpdateObject:changedPersistentKeys:",
                object: observer,
                handler: { (note) -> Bool in
                    
                    XCTAssertEqual(events, 1)
                    XCTAssertEqual(
                        (note.userInfo ?? [:]),
                        [
                            "object": object,
                            "changedPersistentKeys": Set(
                                [
                                    "testNumber",
                                    "testString"
                                ]
                            )
                        ] as NSDictionary
                    )
                    let object = note.userInfo?["object"] as? TestEntity1
                    XCTAssertEqual(object?.testNumber, NSNumber(integer: 10))
                    XCTAssertEqual(object?.testString, "nil:TestEntity1:10")
                    
                    defer {
                        
                        events += 1
                    }
                    return events == 1
                }
            )
            let saveExpectation = self.expectationWithDescription("save")
            stack.beginAsynchronous { (transaction) in
                
                guard let object = transaction.edit(object) else {
                    
                    XCTFail()
                    return
                }
                object.testNumber = NSNumber(integer: 10)
                object.testString = "nil:TestEntity1:10"
                
                transaction.commit { (result) in
                    
                    switch result {
                        
                    case .Success(let hasChanges):
                        XCTAssertTrue(hasChanges)
                        saveExpectation.fulfill()
                        
                    case .Failure:
                        XCTFail()
                    }
                }
            }
            self.waitAndCheckExpectations()
        }
    }
    
    @objc
    dynamic func test_ThatObjectObservers_CanReceiveDeleteNotifications() {
        
        self.prepareStack { (stack) in
            
            self.prepareTestDataForStack(stack)
            
            guard let object = stack.fetchOne(
                From(TestEntity1),
                Where("testEntityID", isEqualTo: 101)) else {
                    
                    XCTFail()
                    return
            }
            let observer = TestObjectObserver()
            let monitor = stack.monitorObject(object)
            monitor.addObserver(observer)
            
            XCTAssertEqual(monitor.object, object)
            XCTAssertFalse(monitor.isObjectDeleted)
            
            var events = 0
            
            let didDeleteExpectation = self.expectationForNotification(
                "objectMonitor:didDeleteObject:",
                object: observer,
                handler: { (note) -> Bool in
                    
                    XCTAssertEqual(events, 0)
                    XCTAssertEqual(
                        (note.userInfo ?? [:]),
                        ["object": object] as NSDictionary
                    )
                    defer {
                        
                        events += 1
                    }
                    return events == 0
                }
            )
            let saveExpectation = self.expectationWithDescription("save")
            stack.beginAsynchronous { (transaction) in
                
                guard let object = transaction.edit(object) else {
                    
                    XCTFail()
                    return
                }
                transaction.delete(object)
                
                transaction.commit { (result) in
                    
                    switch result {
                        
                    case .Success(let hasChanges):
                        XCTAssertTrue(hasChanges)
                        XCTAssertTrue(monitor.isObjectDeleted)
                        saveExpectation.fulfill()
                        
                    case .Failure:
                        XCTFail()
                    }
                }
            }
            self.waitAndCheckExpectations()
        }
    }
}


// MARK: TestObjectObserver

class TestObjectObserver: ObjectObserver {
    
    typealias ObjectEntityType = TestEntity1
    
    func objectMonitor(monitor: ObjectMonitor<TestEntity1>, willUpdateObject object: TestEntity1) {
        
        NSNotificationCenter.defaultCenter().postNotificationName(
            "objectMonitor:willUpdateObject:",
            object: self,
            userInfo: [
                "object": object
            ]
        )
    }
    
    func objectMonitor(monitor: ObjectMonitor<TestEntity1>, didUpdateObject object: TestEntity1, changedPersistentKeys: Set<KeyPath>) {
        
        NSNotificationCenter.defaultCenter().postNotificationName(
            "objectMonitor:didUpdateObject:changedPersistentKeys:",
            object: self,
            userInfo: [
                "object": object,
                "changedPersistentKeys": changedPersistentKeys
            ]
        )
    }
    
    func objectMonitor(monitor: ObjectMonitor<TestEntity1>, didDeleteObject object: TestEntity1) {
        
        NSNotificationCenter.defaultCenter().postNotificationName(
            "objectMonitor:didDeleteObject:",
            object: self,
            userInfo: [
                "object": object
            ]
        )
    }
}

#endif