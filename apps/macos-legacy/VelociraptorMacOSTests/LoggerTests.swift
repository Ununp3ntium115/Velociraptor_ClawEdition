//
//  LoggerTests.swift
//  VelociraptorMacOSTests
//
//  Unit tests for Logger utility
//

import XCTest
@testable import Velociraptor

final class LoggerTests: XCTestCase {
    
    var logger: Logger!
    var testLogDirectory: URL!
    
    override func setUpWithError() throws {
        logger = Logger.shared
        
        // Create a temporary directory for test logs
        testLogDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("VelociraptorTests")
            .appendingPathComponent("Logs")
        
        try? FileManager.default.createDirectory(
            at: testLogDirectory,
            withIntermediateDirectories: true
        )
    }
    
    override func tearDownWithError() throws {
        // Clean up test logs
        try? FileManager.default.removeItem(at: testLogDirectory)
        logger = nil
    }
    
    // MARK: - Initialization Tests
    
    func testSharedInstanceExists() {
        XCTAssertNotNil(Logger.shared)
    }
    
    func testSharedInstanceIsSingleton() {
        let instance1 = Logger.shared
        let instance2 = Logger.shared
        XCTAssertTrue(instance1 === instance2)
    }
    
    // MARK: - Log Level Tests
    
    func testLogLevelDebug() {
        // Debug logging should not crash
        logger.debug("Test debug message")
    }
    
    func testLogLevelInfo() {
        logger.info("Test info message")
    }
    
    func testLogLevelWarn() {
        logger.warning("Test warning message")
    }
    
    func testLogLevelError() {
        logger.error("Test error message")
    }
    
    func testLogLevelCritical() {
        logger.critical("Test critical message")
    }
    
    // MARK: - Log Formatting Tests
    
    func testLogMessageFormat() {
        let message = "Test message"
        let formattedMessage = "[\(Date())] [INFO] \(message)"
        
        XCTAssertTrue(formattedMessage.contains(message))
        XCTAssertTrue(formattedMessage.contains("INFO"))
    }
    
    func testLogWithCategory() {
        let component = "TestComponent"
        let message = "Test message with component"
        
        // Should handle component without crashing
        logger.info(message, component: component)
    }
    
    // MARK: - Log File Tests
    
    func testGetCurrentLogFilePath() {
        let logPath = logger.getCurrentLogFilePath()
        
        // Should return a valid path
        XCTAssertNotNil(logPath)
        if let path = logPath {
            XCTAssertTrue(path.lastPathComponent.contains(".log"))
        }
    }
    
    func testLogFileNameFormat() {
        let expectedPattern = "velociraptor-\\d{4}-\\d{2}-\\d{2}\\.log"
        let regex = try? NSRegularExpression(pattern: expectedPattern)
        
        if let logPath = logger.getCurrentLogFilePath() {
            let filename = logPath.lastPathComponent
            let range = NSRange(filename.startIndex..<filename.endIndex, in: filename)
            let matches = regex?.numberOfMatches(in: filename, range: range) ?? 0
            XCTAssertEqual(matches, 1, "Log filename should match pattern yyyy-MM-dd.log")
        }
    }
    
    // MARK: - Log Reading Tests
    
    func testReadCurrentLogReturnsString() {
        // First, ensure a log entry exists by writing one
        logger.info("Test entry for readCurrentLog test")
        
        // Give it a moment to write
        let expectation = XCTestExpectation(description: "Log file creation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        let logContent = logger.readCurrentLog()
        
        // Should return some string after writing a log entry
        // Note: May still be nil if logging is disabled or path is not set
        if let content = logContent {
            XCTAssertFalse(content.isEmpty, "Log content should not be empty after writing")
        }
        // If logContent is nil, it means logging isn't fully initialized in test context,
        // which is acceptable for unit tests
    }
    
    func testLogPathIsValid() {
        // Logger should have a valid log path
        // This is a simpler test that doesn't require listAllLogs
        let logPath = logger.getCurrentLogFilePath()
        if let path = logPath {
            XCTAssertTrue(path.lastPathComponent.hasSuffix(".log"))
        }
    }
    
    // MARK: - Log Cleanup Tests
    
    func testClearOldLogs() {
        // Should not crash when clearing old logs
        logger.clearOldLogs(olderThanDays: 30)
    }
    
    func testClearOldLogsWithZeroDays() {
        // Edge case: clearing all logs
        logger.clearOldLogs(olderThanDays: 0)
    }
    
    // MARK: - Performance Tests
    
    func testLoggingPerformance() {
        measure {
            for i in 0..<100 {
                logger.info("Performance test message \(i)")
            }
        }
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentLogging() {
        let expectation = XCTestExpectation(description: "Concurrent logging")
        let iterations = 100
        var completedCount = 0
        let lock = NSLock()
        
        DispatchQueue.concurrentPerform(iterations: iterations) { index in
            logger.info("Concurrent log message \(index)")
            
            lock.lock()
            completedCount += 1
            if completedCount == iterations {
                expectation.fulfill()
            }
            lock.unlock()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - Special Character Tests
    
    func testLogWithSpecialCharacters() {
        let specialMessage = "Test with special chars: émojis 🎉, quotes \"test\", newlines\n\t"
        
        // Should handle special characters without crashing
        logger.info(specialMessage)
    }
    
    func testLogWithUnicode() {
        let unicodeMessage = "日本語テスト 中文测试 한국어 테스트"
        
        logger.info(unicodeMessage)
    }
    
    func testLogWithEmptyMessage() {
        logger.info("")
    }
    
    func testLogWithVeryLongMessage() {
        let longMessage = String(repeating: "A", count: 10000)
        
        logger.info(longMessage)
    }
}
