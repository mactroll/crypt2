//
//  main.swift
//  checkin
//
//  Created by Joel Rennich on 12/9/20.
//  Copyright © 2020 Graham Gilbert. All rights reserved.
//

import Foundation

//
// 

//
// defaults and things
//

let kBundleID = "com.grahamgilbert.crypt"
let kLogFile = "/var/log/crypt.log"

enum PrefKeys: String {
  case RemovePlist, RotateUsedKey, OutputPath, ValidateKey, KeyEscrowInterval, AdditionalCurlOpts
  case SkipUsers, RecoveryKey, PostRunCommand, ServerURL
}

//
// Helper functions
//

func get_console_user() -> String {
  NSUserName()
}

func get_os_version(only_major_minor:Bool=true) -> String {
  let version = ProcessInfo.processInfo.operatingSystemVersion
  if only_major_minor {
    return "\(version.majorVersion).\(version.minorVersion)"
  } else {
    return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
  }
}

func set_pref(pref_name: String, pref_value: Any?) {
  guard let defaults = UserDefaults(suiteName: kBundleID) else { return }
  defaults.setValue(pref_value, forKey: pref_name)
}

func pref(pref_name: PrefKeys) -> Any? {
  
  /*
   Return a preference.
   Preferences can be defined several places. Precedence is:
   - MCX/Profiles
   - /var/root/Library/Preferences/com.grahamgilbert.crypt.plist
   - /Library/Preferences/com.grahamgilbert.crypt.plist
   - default_prefs defined here.
   */
  guard let defaults = UserDefaults(suiteName: kBundleID) else { return nil }
  return defaults.object(forKey: pref_name.rawValue)
}

func getMacName() -> String {
  Host.current().name ?? "UNKNOWN_COMPUTERNAME"
}

func logging(_ item: String) {
  guard let url = URL(string: kLogFile) else { return }
  try? item.appendLineToURL(fileURL: url)
}

func escrowKey() -> Bool{
  
  logging("Attempting to Escrow Key...")
  
  guard var server_url = pref(pref_name: .ServerURL) as? String else {
    logging("Unable to get Server URL failing")
    return false
  }
  
  logging("ServerURL Pref set to: \(server_url)...")
  
  if server_url.hasSuffix("/") {
    server_url = server_url + "checkin/"
  } else {
    server_url = server_url + "/checkin/"
  }
  
  let payload = [
    "SerialNumber": getSerial(),
    "RecoveryKey": "recoveryKey", // FIX ME
    "username": get_console_user(),
    "macname": getMacName()
  ]
  
  var args = ["--fail", "--silent", "--show-error", "--location"]
  

  cliTask("/usr/bin/curl", arguments: args, waitForTermination: true)

      mydata = urllib.parse.urlencode(mydata)
      config_file = build_curl_config_file({"url": theurl, "data": mydata})
      # --fail: Fail silently (no output at all) on server errors.
      # --silent: Silent mode. Don't show progress meter or error messages.
      # --show-error: When used with silent, it makes curl show an error message
      # if it fails.
      # --location: This option will make curl redo the request on the new
      # location if the server responds with a 3xx code.
      # --config: Specify which config file to read curl arguments from.
      # The config file is a text file in which command line arguments can be
      # written which then will be used as if they were written on the actual
      # command line.
      cmd = ["/usr/bin/curl", "--fail", "--silent", "--show-error", "--location"]
      if all([pref("AdditionalCurlOpts"), isinstance(pref("AdditionalCurlOpts"), list)]):
          for curl_opt in pref("AdditionalCurlOpts"):
              cmd.append(curl_opt)
      cmd.extend(["--config", "-"])
      task = subprocess.Popen(
          cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, stdin=subprocess.PIPE
      )
      (output, error) = task.communicate(input=config_file.encode())

      if task.returncode == 0:
          logging.info("Key escrow successful.")
          server_initiated_rotation(output)
          return True
      else:
          logging.error("Key escrow unsuccessful.")
          return False
  
}

func server_initiated_rotation(output: String) -> String {
  // Rotate the key if the server tells us to.
  // We need the old key to be present on disk and RotateUsedKey to be True
  
     try:
         json_output = json.loads(output)
     except ValueError:
         return ""

     if not pref("RotateUsedKey") or pref("RemovePlist"):
         # Don't do anything if we don't care about the good stuff
         return ""

     output_plist = pref("OutputPath")
     if not os.path.isfile(output_plist):
         # Need this to be here too (which it should, but you never know..)
         return ""

     if json_output.get("rotation_required", False):
         logging.info("Removing output plist for rotation at next login.")
         os.remove(output_plist)
  
}

/// Determines if the FV Recovery Key is currently in
/// - Returns: true if in use, false if not
func using_recovery_key() -> Bool {
  
  //Check if FileVault is currently unlocked using
  //the recovery key.
  
  if ProcessInfo.processInfo.operatingSystemVersion.majorVersion > 14 {
    logging("Checking if using a recovery key is unstable on 10.15+. Skipping.")
    return false
  }
  
  do {
    if try FDESetupRunner().run(arguments: ["usingrecoverykey"], userInfo: nil).contains("true") {
      logging("Detected Recovery Key use.")
      return true
    }
  } catch {
    logging("Error checking for using recovery key")
    return false
  }

  return false
}

func post_run_command() {
  if let run_command = pref(pref_name: .PostRunCommand) as? String,
     let output_plist = pref(pref_name: .OutputPath) as? String,
     FileManager.default.fileExists(atPath: run_command) {
    logging("Running post run command: \(run_command)")
    logging(cliTask(run_command))
  }
}

func get_recovery_key(key_location: String) -> String? {
  
  // first get the recovery key location
  
  var plistFormat = PropertyListSerialization.PropertyListFormat.xml
  if let url = URL(string: key_location),
     let plistData = try? Data.init(contentsOf: url),
     let plistDict = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: &plistFormat) as? [String:String] {
    return plistDict["RecoveryKey"]
  }
  
  logging("Unable to open key location file")
  return nil
}

func rotate_invalid_key(plist_path: String) -> Bool {
  //Will send the key (if present) for validation. If validation fails,
  //it will remove the plist so the key can be regenerated at next login.
  //Due to the bug that restricts the number of validations before reboot
  //in versions of macOS prior to 10.12.5, this will only run there.
  
  // a work around for https://github.com/grahamgilbert/crypt/issues/68
  if get_console_user() == "_mbsetupuser" || getConsoleUser() == "root" {
      logging("Skipping Validation, no user is logged in.")
      return true
  }
  
  if ProcessInfo.processInfo.operatingSystemVersion.majorVersion < 13 {
    logging("macOS version is too old to run reliably")
    return false
  }

  if FileManager.default.fileExists(atPath: plist_path) {
    if let recovery_key = get_recovery_key(key_location: plist_path) {
      if !validate_key(current_key: recovery_key) {
        logging("Stored recovery key is not valid, removing from disk")
        try? FileManager.default.removeItem(atPath: plist_path)
      } else {
        logging("Stored recovery key is valid")
        return true
      }
    } else {
      logging("Could not retrieve recovery key from plist.")
      return false
    }
  } else {
    logging("Recovery key is not present on disk")
    return false
  }
}

func validate_key(current_key: String) -> Bool {
  
  let fdeDict = ["Password": current_key]
  
  if let userInfo = try? PropertyListSerialization.data(fromPropertyList: fdeDict,
                                                  format: PropertyListSerialization.PropertyListFormat.xml,
                                                  options: 0) {
    do {
      if try FDESetupRunner().run(arguments: ["/usr/bin/fdesetup", "validaterecovery", "-inputplist"], userInfo: userInfo).contains("true") {
        return true
      }
    } catch {
      if let fdeError = error as? FDESetupError {
        switch fdeError {
        case .errorOnResult(let error):
          logging("Recovery Key could not be validated.")
          logging("Failed with Error: \(error)")
        default:
          logging("Recovery Key could not be validated.")
          logging("Failed with Error: unknown error")
        }
      }
      return false
    }
  }
  
  logging("Recovery Key could not be validated.")
  return false
}

func rotate_key(current_key: String, plist: String) {
  
}

func get_enabled_user() -> String {
  var nonusers = pref(pref_name: .SkipUsers) as? [String] ?? [String]()
}

func rotate_if_used(key_path: String) {
  
  if !using_recovery_key() {
    return
  }
  
  if !FileManager.default.fileExists(atPath: key_path) {
    logging("Could not locate \(key_path)")
    return
  }

  logging("Recovery Key has been used.. Attempting to Rotate.")
  if let current_key = get_recovery_key(key_location: key_path) {
    if validate_key(current_key: current_key) {
      rotate_key(current_key: current_key, plist: key_path)
    } else {
      logging("Our current key is not valid.")
    }
  }
}

// here we go do the actual running
