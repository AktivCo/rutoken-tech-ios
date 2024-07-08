//
//  OnSetQrCodeTimer.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 08.07.2024.
//

import Foundation

import TinyAsyncRedux


class OnSetQrCodeTimer: Middleware {
    private var timer: Timer?
    private let timerInterval: Double = 0.01
    private let maxTime: Double = 120.0

    func handle(action: AppAction) -> AsyncStream<AppAction>? {
        switch action {
        case .generateQrCode: break
        case .invalidateQrCodeTimer:
            timer?.invalidate()
            return nil
        default: return nil
        }

        return AsyncStream<AppAction> { continuation in
            Task {
                await MainActor.run {
                    let startTime = DispatchTime.now().uptimeNanoseconds
                    timer = Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: true) { [unowned self] _ in
                        let currentTime = DispatchTime.now().uptimeNanoseconds
                        let diff = Double(currentTime - startTime) / 1_000_000_000
                        let percentage = diff / maxTime
                        guard maxTime > diff else {
                            continuation.yield(.updateQrCodeCountdown(.expired))
                            continuation.finish()
                            timer?.invalidate()
                            timer = nil
                            return
                        }
                        continuation.yield(.updateQrCodeCountdown(.countdown(Int(maxTime - diff), percentage)))
                    }
                }
            }
        }
    }
}
