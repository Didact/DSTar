//
//  Header.swift
//  DSTar
//
//  Created by dakota on 1/23/17.
//  Copyright © 2017 Dakota Smith. All rights reserved.
//

import Foundation

struct Header {
    enum `Type` {
        case normal
    }
    let name: String
    let mode: UInt64
    let owner: UInt64
    let group: UInt64
    let size: UInt64
    let lastModified: Date
    let checksum: UInt64
    let type: Type
    let linkedName: String
}
