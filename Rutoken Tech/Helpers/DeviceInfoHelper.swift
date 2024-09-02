//
//  DeviceInfoHelper.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 06.08.2024.
//

import UIKit

import RtMock


@RtMock
protocol DeviceInfoHelperProtocol {
    var isPhone: Bool { get }
}

class DeviceInfoHelper: DeviceInfoHelperProtocol {
    var isPhone: Bool {
        UIDevice.isPhone
    }
}
