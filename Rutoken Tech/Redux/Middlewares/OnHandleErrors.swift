//
//  OnHandleErrors.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 29.07.2024.
//

import TinyAsyncRedux


class OnHandleErrors: Middleware {
    func handle(action: AppAction) -> AsyncStream<AppAction>? {
        guard case let .handleError(error, actions) = action else {
            return nil
        }


        return AsyncStream<AppAction> { continuation in
            Task {
                defer {
                    continuation.finish()
                }

                if let error {
                    switch error {
                    case CryptoManagerError.nfcStopped:
                        break
                    case let CryptoManagerError.incorrectPin(attemptsLeft):
                        continuation.yield(.showPinInputError("Неверный PIN-код. Осталось попыток: \(attemptsLeft)"))
                    case let error as CryptoManagerError:
                        continuation.yield(.showAlert(AppAlert(from: error)))
                    default:
                        continuation.yield(.showAlert(.unknownError))
                    }
                }

                actions.forEach {
                    continuation.yield($0)
                }
            }
        }
    }
}
