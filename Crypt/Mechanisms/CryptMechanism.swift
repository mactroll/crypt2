/*
  Crypt

  Copyright 2016 The Crypt Project.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

import Foundation
import Security

class CryptMechanism: NSObject {  
  // This NSString will be used as the domain for the inter-mechanism context data
  let contextCryptDomain : NSString = "com.grahamgilbert.crypt"
  
  // Define a pointer to the MechanismRecord. This will be used to get and set
  // all the inter-mechanism data. It is also used to allow or deny the login.
  var mechanism:UnsafePointer<MechanismRecord>
  
  // init the class with a MechanismRecord
  init(mechanism:UnsafePointer<MechanismRecord>) {
    NSLog("Crypt:MechanismInvoke:Check:[+] initWithMechanismRecord");
    self.mechanism = mechanism
  }
  
  var username: NSString? {
    get {
      var value : UnsafePointer<AuthorizationValue>? = nil
      var flags = AuthorizationContextFlags()
      var err: OSStatus = noErr
      err = self.mechanism.pointee.fPlugin.pointee.fCallbacks.pointee.GetContextValue(
        mechanism.pointee.fEngine, kAuthorizationEnvironmentUsername, &flags, &value)
      if err != errSecSuccess {
        return nil
      }
      guard let username = NSString.init(bytes: value!.pointee.data,
        length: value!.pointee.length, encoding: String.Encoding.utf8.rawValue)
        else { return nil }
      
      return username.replacingOccurrences(of: "\0", with: "") as NSString
    }
  }
  
  var password: NSString? {
    get {
      var value : UnsafePointer<AuthorizationValue>? = nil
      var flags = AuthorizationContextFlags()
      var err: OSStatus = noErr
      err = self.mechanism.pointee.fPlugin.pointee.fCallbacks.pointee.GetContextValue(
        mechanism.pointee.fEngine, kAuthorizationEnvironmentPassword, &flags, &value)
      if err != errSecSuccess {
        return nil
      }
      guard let pass = NSString.init(bytes: value!.pointee.data,
        length: value!.pointee.length, encoding: String.Encoding.utf8.rawValue)
        else { return nil }
      
      return pass.replacingOccurrences(of: "\0", with: "") as NSString
    }
  }
  
  var uid: uid_t {
    get {
      var value : UnsafePointer<AuthorizationValue>? = nil
      var flags = AuthorizationContextFlags()
      var uid : uid_t = 0
      if (self.mechanism.pointee.fPlugin.pointee.fCallbacks.pointee.GetContextValue(
              mechanism.pointee.fEngine, ("uid" as NSString).utf8String!, &flags, &value)
              == errSecSuccess) {
        let uidData = Data.init(bytes: value!.pointee.data, count: MemoryLayout<uid_t>.size) //UnsafePointer<UInt8>(value!.pointee.data)
          (uidData as NSData).getBytes(&uid, length: MemoryLayout<uid_t>.size)
            }
      return uid
    }
  }
  
  func setBoolHintValue(_ encryptionWasEnabled : NSNumber) -> Bool {
    // Try and unwrap the optional NSData returned from archivedDataWithRootObject
    // This can be decoded on the other side with unarchiveObjectWithData
    guard let data : Data = NSKeyedArchiver.archivedData(withRootObject: encryptionWasEnabled)
      else {
        logger.logit(.base, message: "Crypt:MechanismInvoke:Check:setHintValue:[+] Failed to unwrap data");
        return false
    }
    
    // Fill the AuthorizationValue struct with our data
    var value = AuthorizationValue(length: data.count,
      data: UnsafeMutableRawPointer(mutating: (data as NSData).bytes.bindMemory(to: Void.self, capacity: data.count)))
    
    // Use the MechanismRecord SetHintValue callback to set the
    // inter-mechanism context data
    let err : OSStatus = self.mechanism.pointee.fPlugin.pointee.fCallbacks.pointee.SetHintValue(
      self.mechanism.pointee.fEngine, contextCryptDomain.utf8String!, &value)
    
    return (err == errSecSuccess)
  }
  
  // This is how we get the inter-mechanism context data
  func getBoolHintValue() -> Bool {
    var value : UnsafePointer<AuthorizationValue>? = nil
    var err: OSStatus = noErr
    err = self.mechanism.pointee.fPlugin.pointee.fCallbacks.pointee.GetHintValue(mechanism.pointee.fEngine, contextCryptDomain.utf8String!, &value)
    if err != errSecSuccess {
      logger.logit(.base, message: "couldn't retrieve hint value")
      return false
    }
    let outputdata = Data.init(bytes: value!.pointee.data, count: value!.pointee.length) //UnsafePointer<UInt8>(value!.pointee.data)
    guard let boolHint = NSKeyedUnarchiver.unarchiveObject(with: outputdata)
      else {
        logger.logit(.base, message: "couldn't unpack hint value")
        return false
    }
    
    return (boolHint as AnyObject).boolValue
  }
  
  // Allow the login. End of the mechanism
  func allowLogin() -> OSStatus {
    logger.logit(.base, message: "Crypt:MechanismInvoke:Check:[+] Done. Thanks and have a lovely day.");
    var err: OSStatus = noErr
    err = self.mechanism.pointee.fPlugin.pointee.fCallbacks.pointee.SetResult(
      mechanism.pointee.fEngine, AuthorizationResult.allow)
    logger.logit(.base, message: "Crypt:MechanismInvoke:Check:[+] [\(Int(err))]");
    return err
  }
}
