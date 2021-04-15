//
//  Color+Extensions.swift
//  MyPay
//
//  Created by Rolando Rodriguez on 9/4/20.
//  Copyright © 2020 Rolando Rodriguez. All rights reserved.
//

import Foundation
import SwiftUI

#if os(iOS)
import UIKit.UIColor
#endif

public extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        
        let r = (rgbValue & 0xff0000) >> 16
        let g = (rgbValue & 0xff00) >> 8
        let b = rgbValue & 0xff
        
        self.init(red: Double(r) / 0xff, green: Double(g) / 0xff, blue: Double(b) / 0xff, opacity: 1)
        
    }
}

public extension Color {
    static var main: Color {
        self.init("main")
    }
    
    static var lightGrayText: Color {
        self.init("lightGrayText")
    }
    
    static var accent: Color {
        Color("accentColor")
    }
    
    static var solar: Color {
        Color("solar")
    }
}

#if os(iOS)
extension UIColor {
    public convenience init?(hex: String) {
        let r, g, b, a: CGFloat

        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])

            if hexColor.count == 8 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0

                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                    g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                    b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                    a = CGFloat(hexNumber & 0x000000ff) / 255

                    self.init(red: r, green: g, blue: b, alpha: a)
                    return
                }
            }
        }

        return nil
    }
}
#endif
