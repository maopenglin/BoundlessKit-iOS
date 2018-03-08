import XCTest
@testable import BoundlessKit
@testable import BoundlessKit_Example

class Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
    }
    
    override func tearDown() {
        
        super.tearDown()
    }
    
//    func testSimple() {
//        let bk = BoundlessKit()
//        bk.launch(arguements: Helper.versionMappings)
//        
//        sleep(1)
//        
//        print("Got:\(bk.reinforce(actionID: "action1"))")
//        
//        sleep(2)
//    }
//    
//    func testswizzleTest() {
//        let sut = UIViewController()
//        let action = ObjectSelectorAction.init(target: sut, selector: #selector(sut.viewDidAppear(_:)), parameter: nil)
//        let swizzle = InstanceMethodSwizzle.init(actionID: action.name)!
//        swizzle.register()
//        
//        sleep(1)
//        sut.viewDidAppear(true)
//        sleep(1)
//    }
    
    func testSwizzleNotification() {
        let sut = MockViewController()
        
        let selectorInstance = InstanceSelector(type(of: sut), #selector(sut.printSomething))
        
        InstanceSelectorNotificationCenter.default.addObserver(sut, selector: #selector(sut.received(notification:)), name: selectorInstance?.notification, object: nil)
        
        sut.printSomething()
        
        XCTAssert(sut.didReceiveNotification)
    }
}
