//
//  PersistenceManager.swift
//  grokSwiftREST
//
//  Created by Christina Moulton on 2016-04-20.
//  Copyright © 2016 Teak Mobile Inc. All rights reserved.
//

import Foundation

enum Path: String {
  case Public = "Public"
  case Starred = "Starred"
  case MyGists = "MyGists"
}

class PersistenceManager {
  class private func documentsDirectory() -> NSString {
    let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory,
                                                    .UserDomainMask, true)
    let documentDirectory = paths[0] as NSString
    return documentDirectory
  }
  
  class func saveArray<T: NSCoding>(arrayToSave: [T], path: Path) {
    let file = documentsDirectory().stringByAppendingPathComponent(path.rawValue)
    NSKeyedArchiver.archiveRootObject(arrayToSave, toFile: file)
  }
  
  class func loadArray<T: NSCoding>(path: Path) -> [T]? {
    let file = documentsDirectory().stringByAppendingPathComponent(path.rawValue)
    let result = NSKeyedUnarchiver.unarchiveObjectWithFile(file)
    return result as? [T]
  }
}