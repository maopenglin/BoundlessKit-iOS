import XCTest
@testable import BoundlessKit

class Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
    }
    
    override func tearDown() {
        
        super.tearDown()
    }
    
    func test() {
        let bk = BoundlessKit()
        bk.launch(arguements: Helper.versionMappings)
        
        sleep(1)
        
        print("Got:\(bk.reinforce(actionID: "action1"))")
        
        sleep(2)
    }
}
