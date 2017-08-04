//
//  Preferences.swift
//  Crypt
//
//  Created by Joel Rennich on 7/11/17.
//  Copyright © 2017 Graham Gilbert. All rights reserved.
//

import Foundation

/// A convenience name for `UserDefaults.standard`
let defaults = UserDefaults.standard

/// The preference keys for the crypt defaults domain.
///
/// Use these keys, rather than raw strings.
enum Preferences {
  static let fileLogging = "FileLogging"
  static let logPath = "LogPath"
  static let outputPath = "OutputPath"
  static let keyRotateDays = "KeyRotateDays"
  static let removePlist = "RemovePlist"
}
