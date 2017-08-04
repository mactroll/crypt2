//
//  Logger.swift
//  Crypt
//
//  Created by Joel Rennich on 7/30/17.
//  Copyright © 2017 Graham Gilbert All rights reserved.
//
import Foundation
import os.log
import Dispatch


// quick class to log to a file and/or the OS
/// A singleton `Logger` instance for the app to use.
let logger = Logger()

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
  let logFile = OSLog(subsystem: "com.grahamgilbert.crypt", category: "Crypt")
  var file = true
  var path: String = defaults.string(forKey: Preferences.logPath) ?? "/var/log/crypt.log"
  
  // methodology inspired by https://github.com/emaloney/CleanroomLogger
  
  var fileObject: UnsafeMutablePointer<FILE>?
  let newlines: [Character] = ["\n", "\r"]

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
    
    // check to see if file logging has been turned off
    
    if !defaults.bool(forKey: Preferences.fileLogging ) {
      file = false
    }
    
    openFile()
  }
  
  deinit {
    
    // be nice and close the file
    
    fclose(fileObject)

  }
  
  func logit(_ level: LogLevel, message: String) {
    
    if (level.rawValue <= loglevel.rawValue) {
      
      NSLog("level: \(level) - " + message)
      
      if file {
        var addNewline = true
        
        if message.characters.count > 0 {
          let lastChar = message.characters[message.characters.index(before: message.characters.endIndex)]
          addNewline = !newlines.contains(lastChar)
        }
        
        fputs(message, fileObject)
        
        if addNewline {
          fputc(0x0A, fileObject)
        }
        
        fflush(fileObject)
      
      }
    }
  }
  
  private func openFile() {
    let f = fopen(path, "a")
    guard f != nil else {
      // error getting the file handle
      NSLog("Error getting log file handle for Cyrpt.")
      file = false
      return
    }
    
    fileObject = f
  }
}
