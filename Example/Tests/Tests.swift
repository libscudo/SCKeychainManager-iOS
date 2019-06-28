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
                
                it("can save multiple items securely") {
                    manager.securely() //unlock is required and no iCloud sync
                        //or .insecurely()
                        .set("a string", forKey: "key1")
                        .set("another string", forKey: "Key2")
                        .set(true, forKey: "boolKey")
                        .allowSinchronization() // override iCloud sync
                        .apply()
                }
            }
        }
    }
}
