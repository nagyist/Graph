/*
 * Copyright (C) 2015 - 2016, Daniel Dahan and CosmicMind, Inc. <http://cosmicmind.io>.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *	*	Redistributions of source code must retain the above copyright notice, this
 *		list of conditions and the following disclaimer.
 *
 *	*	Redistributions in binary form must reproduce the above copyright notice,
 *		this list of conditions and the following disclaimer in the documentation
 *		and/or other materials provided with the distribution.
 *
 *	*	Neither the name of CosmicMind nor the names of its
 *		contributors may be used to endorse or promote products derived from
 *		this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import XCTest
@testable import Graph

class EntityThreadTests : XCTestCase, GraphEntityDelegate {
    var insertSaveExpectation: XCTestExpectation?
    var insertExpectation: XCTestExpectation?
    var insertPropertyExpectation: XCTestExpectation?
    var insertGroupExpectation: XCTestExpectation?
    var updateSaveExpectation: XCTestExpectation?
    var updatePropertyExpectation: XCTestExpectation?
    var deleteSaveExpectation: XCTestExpectation?
    var deleteExpectation: XCTestExpectation?
    var deletePropertyExpectation: XCTestExpectation?
    var deleteGroupExpectation: XCTestExpectation?
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testAll() {
        insertSaveExpectation = expectation(withDescription: "Test: Save did not pass.")
        insertExpectation = expectation(withDescription: "Test: Insert did not pass.")
        insertPropertyExpectation = expectation(withDescription: "Test: Insert property did not pass.")
        insertGroupExpectation = expectation(withDescription: "Test: Insert tag did not pass.")
        
        let q1 = DispatchQueue(label: "io.cosmicmind.graph.thread.1", attributes: DispatchQueueAttributes.serial)
        let q2 = DispatchQueue(label: "io.cosmicmind.graph.thread.2", attributes: DispatchQueueAttributes.serial)
        let q3 = DispatchQueue(label: "io.cosmicmind.graph.thread.3", attributes: DispatchQueueAttributes.serial)
        
        let graph = Graph()
        graph.delegate = self
        graph.watchForEntity(types: ["T"], tags: ["G"], properties: ["P"])
        
        let entity = Entity(type: "T")
        
        q1.async { [weak self] in
            entity["P"] = 111
            entity.add(tag: "G")
            
            graph.async { [weak self] (success: Bool, error: NSError?) in
                XCTAssertTrue(success, "\(error)")
                self?.insertSaveExpectation?.fulfill()
            }
        }
        
        waitForExpectations(withTimeout: 5, handler: nil)
        
        updateSaveExpectation = expectation(withDescription: "Test: Save did not pass.")
        updatePropertyExpectation = expectation(withDescription: "Test: Update did not pass.")
        
        q2.async { [weak self] in
            entity["P"] = 222
            
            graph.async { [weak self] (success: Bool, error: NSError?) in
                XCTAssertTrue(success, "\(error)")
                self?.updateSaveExpectation?.fulfill()
            }
        }
        
        waitForExpectations(withTimeout: 5, handler: nil)
        
        deleteSaveExpectation = expectation(withDescription: "Test: Save did not pass.")
        deleteExpectation = expectation(withDescription: "Test: Delete did not pass.")
        deletePropertyExpectation = expectation(withDescription: "Test: Delete property did not pass.")
        deleteGroupExpectation = expectation(withDescription: "Test: Delete tag did not pass.")
        
        q3.async { [weak self] in
            entity.delete()
            
            graph.async { [weak self] (success: Bool, error: NSError?) in
                XCTAssertTrue(success, "\(error)")
                self?.deleteSaveExpectation?.fulfill()
            }
        }
        
        waitForExpectations(withTimeout: 5, handler: nil)
    }
    
    func graph(graph: Graph, inserted entity: Entity, cloud: Bool) {
        XCTAssertEqual("T", entity.type)
        XCTAssertTrue(0 < entity.id.characters.count)
        XCTAssertEqual(111, entity["P"] as? Int)
        XCTAssertTrue(entity.has(tag: "G"))
        
        insertExpectation?.fulfill()
    }
    
    func graph(graph: Graph, deleted entity: Entity, cloud: Bool) {
        XCTAssertEqual("T", entity.type)
        XCTAssertTrue(0 < entity.id.characters.count)
        XCTAssertNil(entity["P"])
        XCTAssertFalse(entity.has(tag: "G"))
        
        deleteExpectation?.fulfill()
    }
    
    func graph(graph: Graph, entity: Entity, added tag: String, cloud: Bool) {
        XCTAssertEqual("T", entity.type)
        XCTAssertEqual("G", tag)
        XCTAssertTrue(entity.has(tag: tag))
        
        insertGroupExpectation?.fulfill()
    }
    
    func graph(graph: Graph, entity: Entity, removed tag: String, cloud: Bool) {
        XCTAssertEqual("T", entity.type)
        XCTAssertTrue(0 < entity.id.characters.count)
        XCTAssertEqual("G", tag)
        XCTAssertFalse(entity.has(tag: "G"))
        
        deleteGroupExpectation?.fulfill()
    }
    
    func graph(graph: Graph, entity: Entity, added property: String, with value: AnyObject, cloud: Bool) {
        XCTAssertEqual("T", entity.type)
        XCTAssertTrue(0 < entity.id.characters.count)
        XCTAssertEqual("P", property)
        XCTAssertEqual(111, value as? Int)
        XCTAssertEqual(value as? Int, entity[property] as? Int)
        
        insertPropertyExpectation?.fulfill()
    }
    
    func graph(graph: Graph, entity: Entity, updated property: String, with value: AnyObject, cloud: Bool) {
        XCTAssertEqual("T", entity.type)
        XCTAssertTrue(0 < entity.id.characters.count)
        XCTAssertEqual("P", property)
        XCTAssertEqual(222, value as? Int)
        XCTAssertEqual(value as? Int, entity[property] as? Int)
        
        updatePropertyExpectation?.fulfill()
    }
    
    func graph(graph: Graph, entity: Entity, removed property: String, with value: AnyObject, cloud: Bool) {
        XCTAssertEqual("T", entity.type)
        XCTAssertTrue(0 < entity.id.characters.count)
        XCTAssertEqual("P", property)
        XCTAssertEqual(222, value as? Int)
        XCTAssertNil(entity[property])
        
        deletePropertyExpectation?.fulfill()
    }
}
