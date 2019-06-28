// https://github.com/Quick/Quick

import Quick
import Nimble
@testable import SCKeychainManager

class SCKeychainManagerSpec: QuickSpec {
    override func spec() {
        describe("SCKeychainManager") {
            context("can be used with default parameters") {
                let manager = SCKeychainManager.standard
                it("must be non-nil") {
                    expect(manager).notTo(beNil())
                }
                
                it("must have the main bundle identifier as serviceName") {
                    expect(manager.serviceName).to(be(Bundle.main.bundleIdentifier))
                }
                
                it("can set multiple items at once") {
                    try! manager.securely() //unlock is required and no iCloud sync
                        .set("eaceto", forKey: "username")
                        .set("my-secret-password", forKey: "password")
                        .set(true, forKey: "validated")
                        .apply()
                }
                
                it ("can get items") {
                    try! manager.securely().set("eaceto", forKey: "username").apply()
                    
                    let username = manager.string(forKey: "username")
                    expect("eaceto").to(be(username))
                }
                
                it("can remove them") {
                    try! manager.securely()
                        .set("my-secret-password", forKey: "password")
                        .set(true, forKey: "validated")
                        .set(0, forKey: "userId")
                        .apply()
                    
                    var password = manager.string(forKey: "password")
                    var validated = manager.bool(forKey: "validated")
                    var userId = manager.integer(forKey: "userId")
                    
                    expect(password).to(equal("my-secret-password"))
                    expect(validated).to(equal(true))
                    expect(userId).to(equal(0))
                    
                    try! manager.securely()
                        .removeObject(forKey: "password")
                        .removeObject(forKey: "validated")
                        .removeObject(forKey: "userId")
                        .apply()
                    
                    
                    password = manager.string(forKey: "password")
                    validated = manager.bool(forKey: "validated")
                    userId = manager.integer(forKey: "userId")
                    
                    expect(password).to(beNil())
                    expect(validated).to(beNil())
                    expect(userId).to(beNil())
                }
            }
        }
    }
}
