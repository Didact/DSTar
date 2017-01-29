//
//  Header.swift
//  DSTar
//
//  Created by dakota on 1/23/17.
//  Copyright © 2017 Dakota Smith. All rights reserved.
//

import Foundation

extension FileManager {
    static let documentsDirectory: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
}

extension CharacterSet {
    static var whitespacesAndNulls: CharacterSet {
        var c = CharacterSet.whitespaces
        c.insert(charactersIn: "\0")
        return c
    }
}

precedencegroup PowerPrecedence { higherThan: MultiplicationPrecedence }
infix operator ** : PowerPrecedence
func **(lhs: Int, rhs: Int) -> Int {
    if rhs == 0 { return 1 }
    if rhs == 1 {return lhs }
    return Int(pow(Double(lhs), Double(rhs)))
}

prefix func !<T>(lhs: @escaping (T) -> Bool) -> (T) -> Bool {
    return {!lhs($0)}
}

extension Collection {
    func prefix(while predicate: @escaping (Self.Iterator.Element) -> Bool) -> Self.SubSequence {
        let index = self.index(where: !predicate) ?? self.endIndex
        return self.prefix(upTo: index)
    }
    func drop(while predicate: @escaping (Self.Iterator.Element) -> Bool) -> Self.SubSequence {
        let index = self.index(where: !predicate).map(self.index(after:)) ?? self.startIndex
        return self[index..<self.endIndex]
    }
}

extension String {
    func trimmingNulls() -> String {
        return String(self.characters.prefix(while: {$0 != Character("\0")}))
    }
}

struct Permissions {
    struct Level: OptionSet {
        
        let rawValue: Int
        
        static let read = Level(rawValue: 4)
        static let write = Level(rawValue: 2)
        static let execute = Level(rawValue: 1)
        
        init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }
    
    let user: Level
    let group: Level
    let other: Level
    
    init(octal: Int) {
        self.user = Level(rawValue: (octal / 8**2 % 8))
        self.group = Level(rawValue: (octal / 8**1 % 8))
        self.other = Level(rawValue: (octal / 8**0 % 8))
    }
    
}

public struct Header {
    
    let name: String
    let mode: Permissions
    let owner: Int
    let group: Int
    let size: Int
    let lastModified: Date
    let checksum: Int
    let type: UInt8
    let linkedName: String
}

extension Header {
    static func from(data: Data) -> Header? {
        
        guard data.count == 512 else {
            return nil
        }
    
        // fuck swift not having substrings
        
        let rawName = data[0..<100]
        let rawMode = data[100..<108]
        let rawOwner = data[108..<116]
        let rawGroup = data[116..<124]
        let rawSize = data[124..<136]
        let rawModified = data[136..<148]
        let rawChecksum = data[148..<156]
        let rawType = data[156]
        let rawLinked = data[157..<257]
        
        let name = String(data: Data(rawName), encoding: .ascii)!.trimmingNulls()
        let mode = Permissions(octal: Int(String(data: Data(rawMode), encoding: .ascii)!.trimmingCharacters(in: .whitespacesAndNulls), radix: 8)!)
        let owner = Int(String(data: Data(rawOwner), encoding: .ascii)!.trimmingCharacters(in: .whitespacesAndNulls))!
        let group = Int(String(data: Data(rawGroup), encoding: .ascii)!.trimmingCharacters(in: .whitespacesAndNulls))!
        
        let size = Int(String(data: Data(rawSize), encoding: .ascii)!.trimmingCharacters(in: .whitespacesAndNulls), radix: 8)!
        let lastModified = Date(timeIntervalSince1970: TimeInterval(Int(String(data: Data(rawModified), encoding: .ascii)!.trimmingCharacters(in: .whitespacesAndNulls), radix: 8)!))
        
        let checksum = Int(String(data: Data(rawChecksum), encoding: .ascii)!.trimmingCharacters(in: .whitespacesAndNulls), radix: 8)!
        
        let type = rawType
        
        let linkedName = String(data: Data(rawLinked), encoding: .ascii)!.trimmingCharacters(in: .whitespacesAndNulls)
        
        return Header(name: name, mode: mode, owner: owner, group: group, size: size, lastModified: lastModified, checksum: checksum, type: type, linkedName: linkedName)
    }
}

struct File {
    let header: Header
    let contets: Data
}
