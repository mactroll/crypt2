//
//  FDESetupRunner.swift
//  checkin
//
//  Created by Joel Rennich on 12/9/20.
//  Copyright © 2020 Graham Gilbert. All rights reserved.
//

import Foundation

struct FDESetupRunner {
  
  func run(arguments: [String]) -> String {
    let inPipe = Pipe.init()
    let outPipe = Pipe.init()
    let errorPipe = Pipe.init()
    
    let task = Process.init()
    task.launchPath = "/usr/bin/fdesetup"
    task.arguments = arguments
    
    task.standardInput = inPipe
    task.standardOutput = outPipe
    task.standardError = errorPipe
    task.launch()
    inPipe.fileHandleForWriting.write(userInfo)
    inPipe.fileHandleForWriting.closeFile()
    task.waitUntilExit()
    
    let outputData = outPipe.fileHandleForReading.readDataToEndOfFile()
    outPipe.fileHandleForReading.closeFile()
    
    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
    let errorMessage = String(data: errorData, encoding: .utf8)
    errorPipe.fileHandleForReading.closeFile()
    
    return String(data: outputData, encoding: .utf8)
  }
}
