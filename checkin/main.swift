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
  case SkipUsers, RecoveryKey, PostRunCommand
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
   Return a preference. Since this uses CFPreferencesCopyAppValue,
   Preferences can be defined several places. Precedence is:
   - MCX
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

func escrowKey() {
  
}

func server_initiated_rotation(output: String) {
  
}

func using_recovery_key() {
  
}

func post_run_command() {
  if let run_command = pref(pref_name: .PostRunCommand) as? String,
     let output_plist = pref(pref_name: .OutputPath) as? String,
     FileManager.default.fileExists(atPath: run_command) {
    logging("Running post run command: \(run_command)")
    logging(cliTask(run_command))
  }
}

func get_recovery_key(key_location: String) -> String {
  if let url = URL(string: key_location),
     let plistData = try? Data.init(contentsOf: url) {
    
  }
  logging("Unable to open key location file")
  return ""
}

func rotate_invalid_key(plist_path: String) {
  
}

func validate_key(current_key: String) {
  
}

func rotate_key(current_key: String, plist: String) {
  
}

func get_enabled_user() -> String {
  var nonusers = pref(pref_name: .SkipUsers) as? [String] ?? [String]()
}

func rotate_if_used(key_path: String) {
  
}

// here we go do the actual running
