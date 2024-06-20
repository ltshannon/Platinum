//
//  Extensions.swift
//  SwipeAction
//
//  Created by Larry Shannon on 2/27/24.
//

import Foundation
import SwiftUI

public extension String {
    //Common
    static var empty: String { "" }
    static var space: String { " " }
    static var comma: String { "," }
    static var newline: String { "\n" }
    
    //Debug
    static var success: String { "🎉" }
    static var test: String { "🧪" }
    static var notice: String { "⚠️" }
    static var warning: String { "🚧" }
    static var fatal: String { "☢️" }
    static var reentry: String { "⛔️" }
    static var stop: String { "🛑" }
    static var boom: String { "💥" }
    static var sync: String { "🚦" }
    static var key: String { "🗝" }
    static var bell: String { "🔔" }
    
    var isNotEmpty: Bool {
        !isEmpty
    }
}

extension UIColor {
    static var accentColor: UIColor {
        UIColor(named: "AccentColor") ?? .blue
    }
}

extension Font {
    static let buttonText: Font = Font.system(size: 19, weight: .regular).leading(.loose)
}
