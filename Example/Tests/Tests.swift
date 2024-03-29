// https://github.com/Quick/Quick

import Quick
import Nimble
@testable import SCKeychainManager

class SCKeychainManagerSpec: QuickSpec {
    
    func generateRSAKeyPair(with identifier : String, _ completion : @escaping (_ created : Bool) -> Void) {
        let tag = "\(Bundle.main.bundleIdentifier ?? "").\(identifier)"
        let privateKeySpec: [CFString : Any] = [
            kSecAttrIsPermanent: true,
            kSecAttrApplicationTag: tag
        ]
        
        let publicKeyParams: [CFString : Any] = [
            kSecAttrIsPermanent: true,
            kSecAttrApplicationTag: tag
        ]
        
        let keyPairParams: [CFString: Any] = [
            kSecPublicKeyAttrs: publicKeyParams,
            kSecPrivateKeyAttrs: privateKeySpec,
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits: 4096,
        ]
        
        // private / public key generation takes a lot of time, so this operation must be perform in another thread.
        DispatchQueue.global().async {
            var publicKey : SecKey?
            var privateKey : SecKey?
            
            let status = SecKeyGeneratePair(keyPairParams as CFDictionary, &publicKey, &privateKey)
            
            if status != errSecSuccess {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            DispatchQueue.main.async {
                completion(true)
            }
        }
    }
    
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
                
                it("can get a RSA Public Key") {
                    waitUntil(timeout: 30) { done in
                        let identifier = "test_public_key_1"
                        self.generateRSAKeyPair(with: identifier) { created in
                            expect(created).to(equal(true))
                            
                            let publicKey = manager.rsaPublicKey(identifiedBy: identifier)
                            expect(publicKey).notTo(beNil())
                            done()
                        }
                    }
                }
            }
        }
    }
}
