//
//  FileStorageTests.swift
//  GrowthBook-IOS
//
//  Created by Vitalii Budnik on 1/23/25.
//

import Foundation
import XCTest

@testable import GrowthBook

fileprivate struct StoredValue: Codable, Equatable {
    var value: Int
    init(value: Int = 42) {
        self.value = value
    }
}

fileprivate class StoredValueClass: Codable, Equatable {
    static func == (lhs: StoredValueClass, rhs: StoredValueClass) -> Bool {
        lhs.value == rhs.value
    }
    
    var value: Int
    init(value: Int = 42) {
        self.value = value
    }
}

class FileStorageTests: XCTestCase {
    typealias SUT = FileStorage
    let fileURL: URL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(UUID().uuidString).json")

    override func setUp() {
        super.setUp()
        try? FileManager.default.removeItem(at: fileURL)
    }

    override func tearDown() {
        super.tearDown()
        try? FileManager.default.removeItem(at: fileURL)
    }

    func testUpdateValue() throws {
        let storedValue: StoredValue = .init()

        let sut: SUT<StoredValue> = SUT<StoredValue>(fileURL: fileURL)

        try XCTAssertNil(sut.value())

        try sut.updateValue(storedValue)

        try XCTAssertEqual(sut.value(), storedValue)
    }

    func testGetValue() throws {
        let storedValue: StoredValue = .init()
        let storedData: Data = try JSONEncoder().encode(storedValue)
        try storedData.write(to: fileURL)

        let sut: SUT<StoredValue> = SUT<StoredValue>(fileURL: fileURL)

        try XCTAssertEqual(sut.value(), storedValue)
    }

    func testGetValueMalformedData() throws {
        let storedData: Data = try JSONEncoder().encode(["storedValue"])
        try storedData.write(to: fileURL)

        let sut: SUT<StoredValue> = SUT<StoredValue>(fileURL: fileURL)

        try XCTAssertNil(sut.value())
        XCTAssertNil(try? sut.getRawData())
    }

    func testReset() throws {
        let storedValue: StoredValue = .init()
        let storedData: Data = try JSONEncoder().encode(storedValue)
        try storedData.write(to: fileURL)

        let sut: SUT<StoredValue> = SUT<StoredValue>(fileURL: fileURL)
        try XCTAssertNotNil(sut.value())
        try XCTAssertNotNil(sut.getRawData())

        try sut.reset()

        try XCTAssertNil(sut.value())
        do {
            _ = try sut.getRawData()
            XCTFail("Data must be nil")
        } catch SDKError.failedToLoadData {
        } catch {
            XCTFail("Expected SDKError.failedToLoadData, got \(error)")
        }

        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
    }

    func testSetData() throws {
        let storedValue: StoredValue = .init()
        let storedData: Data = try JSONEncoder().encode(storedValue)

        let sut: SUT<StoredValue> = SUT<StoredValue>(fileURL: fileURL)
        try XCTAssertNil(sut.value())
        XCTAssertNil(try? sut.getRawData())

        try sut.setRawData(storedData)

        try XCTAssertEqual(sut.getRawData(), storedData)
        try XCTAssertEqual(sut.value(), storedValue)
    }

    func testGetData() throws {
        let storedValue: StoredValue = .init()
        let storedData: Data = try JSONEncoder().encode(storedValue)
        try storedData.write(to: fileURL)

        let sut: SUT<StoredValue> = SUT<StoredValue>(fileURL: fileURL)

        try XCTAssertEqual(sut.getRawData(), storedData)
    }

    func testDeinit() throws {
        let storedValue: WeakChecker<StoredValueClass> = WeakChecker(StoredValueClass())

        let sut: WeakChecker<SUT<StoredValueClass>> = WeakChecker(SUT(fileURL: fileURL))

        try sut.object.updateValue(storedValue.object)

        // WHEN
        storedValue.removeLink()
        storedValue.assertNotNil()
        
        sut.removeLink()

        // THEN
        sut.assertNil()
        storedValue.assertNil()
    }
}
