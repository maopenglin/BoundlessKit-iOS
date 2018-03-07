import XCTest
@testable import BoundlessKit

class Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
    }
    
    override func tearDown() {
        
        super.tearDown()
    }
    
    func simpleTest() {
        let bk = BoundlessKit()
        bk.launch(arguements: Helper.versionMappings)
        
        sleep(1)
        
        print("Got:\(bk.reinforce(actionID: "action1"))")
        
        sleep(2)
    }
    
    func swizzleTest() {
        let sut = UIViewController()
        let action = InstanceMethodAction.init(target: sut, selector: #selector(sut.viewDidAppear(_:)), parameter: nil)
        let swizzle = InstanceMethodSwizzle.init(actionID: action.name)!
        swizzle.register()
        
        sleep(1)
        sut.viewDidAppear(true)
        sleep(1)
        XCTAssert(false)
    }
}
