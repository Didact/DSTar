//
//  Header.swift
//  DSTar
//
//  Created by dakota on 1/23/17.
//  Copyright © 2017 Dakota Smith. All rights reserved.
//

import Foundation

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
    
    static func from(data: MutableRandomAccessSlice<Data>) -> Header? {
        return Header.from(data: Data(data))
    }
}

struct File {
    let header: Header
    let contents: Data
}

extension File {
    static func from(data: Data) -> File? {
        guard let header = Header.from(data: data[0..<512]) else {
            return nil
        }
        let content = Data(data[512..<(512 + header.size)])
        return File(header: header, contents: content)
    }
}

struct Archive {
    let files: [File]
}

extension Archive {
    static func from(data: Data) -> Archive? {
        var startIndex = 0
        var files = [File]()
        
        let blocks = stride(from: 0, to: data.count, by: 512).map({data[$0..<$0+512]})
        
        while startIndex < blocks.count {
            guard blocks[startIndex].contains(where: {$0 != 0}) else {
                break
            }
            let header = Header.from(data: blocks[startIndex])!
            let count = (header.size / 512) + 1
            let contents = blocks[startIndex+1..<(startIndex+1 + count)].joined().prefix(header.size)
            files.append(File(header: header, contents: Data(contents)))
            startIndex += count + 1
        }
        
        return Archive(files: files)
    }
}
