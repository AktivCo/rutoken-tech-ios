//
//  ScreenBrightnessController.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 19.07.2024.
//

import Foundation
import SwiftUI


class ScreenBrightnessController {
    private var timer: Timer?
    static var shared: ScreenBrightnessController = ScreenBrightnessController()

    private init() {}

    func setBrightness(to value: CGFloat, duration: TimeInterval = 0.3, ticksPerSecond: Double = 120) {
        timer?.invalidate()
        let startingBrightness = UIScreen.main.brightness
        let delta = value - startingBrightness
        let totalTicks = Int(ticksPerSecond * duration)
        let changePerTick = delta / CGFloat(totalTicks)
        let delayBetweenTicks = 1 / ticksPerSecond

        var i = 1
        timer = Timer.scheduledTimer(withTimeInterval: delayBetweenTicks, repeats: true) { _ in
            i += 1
            if i < totalTicks {
                DispatchQueue.main.async {
                    UIScreen.main.brightness = max(min(startingBrightness + (changePerTick * CGFloat(i)), 1), 0)
                }
            } else {
                self.timer?.invalidate()
            }
        }
    }
}
