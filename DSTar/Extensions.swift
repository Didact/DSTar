//
//  Extensions.swift
//  DSTar
//
//  Created by dakota on 2/7/17.
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

extension Data {
    func asString() -> String? {
        return String(data: self, encoding: .utf8)
    }
}
