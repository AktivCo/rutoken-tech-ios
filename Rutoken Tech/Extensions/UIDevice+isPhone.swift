//
//  UIDevice+isPhone.swift
//  Rutoken Tech
//
//  Created by Ivan Poderegin on 07.11.2023.
//

import UIKit


extension UIDevice {
    class var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
}
