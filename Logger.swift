//
//  Logger.swift
//  Crypt
//
//  Created by Joel Rennich on 7/30/17.
//  Copyright © 2017 Graham Gilbert All rights reserved.
//
import Foundation


// quick class to log to a file and/or the OS
/// A singleton `Logger` instance for the app to use.
let logger = Logger()

import Foundation
import os.log

/// The individual logging levels to use when logging in NoMAD
///
/// - base: General errors
/// - info: Positive info
/// - notice: Nice to know issues that may, or may not, cause issues
/// - debug: Lots of verbose logging
enum LogLevel: Int {
  
  /// General errors
  case base = 0
  
  /// Positive info
  case info = 1
  
  /// Nice to know issues that may, or may not, cause issues
  case notice = 2
  
  /// Lots of verbose logging
  case debug = 3
}


class Logger {
  
  /// Set to a level from `LogLevel` enum to control what gets logged.
  var loglevel: LogLevel = .base
  var file = true
  var path: String = defaults.string(forKey: Preferences.logPath) ?? "/var/log/crypt.log"
  var handle: FileHandle? = nil
  
  /// Init method simply check to see if Verbose logging is enabled or not for the Logger object.
  init() {
    if (defaults.bool(forKey: "Verbose") == true) {
      loglevel = .debug
      logit(.debug, message: "Debug logging enabled")
    } else if (CommandLine.arguments.contains("-v")) {
      loglevel = .debug
      logit(.debug, message: "Debug logging enabled via flag")
    } else {
      loglevel = .base
    }
    
    getFileHandle()
  }
  
  func logit(_ level: LogLevel, message: String) {
    
    if (level.rawValue <= loglevel.rawValue) {
      
      NSLog("level: \(level) - " + message)
      
      if file {
          try handle?.write(message.data(using: String.Encoding.utf8)!)
      }
    }
  }
  
  private func getFileHandle() {
    let fm = FileManager.default
    
    // create the log file if it doesn't already exist
    if !fm.fileExists(atPath: path) {
      do {
        fm.createFile(atPath: path, contents: nil, attributes: nil)
      } catch {
        // couldn't create a file, lets set logging off and return
        file = false
        return
      }
    }
    let handle = FileHandle(forWritingAtPath: path)
    handle?.seekToEndOfFile()
  }
  
}
