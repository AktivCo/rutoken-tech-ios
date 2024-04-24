//
//  TokenModel.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 21.11.2023.
//

enum TokenModel: Equatable {
    case rutoken2_2000
    case rutoken2_2010
    case rutoken2_2100
    case rutoken2_2200
    case rutoken2_3000
    case rutoken2_4000
    case rutoken2_4400
    case rutoken2_4500
    case rutoken2_4900
    case rutoken2_8003
    case rutoken3_3200
    case rutoken3_3220
    case rutoken3Nfc_3100
    case rutoken3_3100
    case rutoken3NfcMf_3110
    case rutoken3Ble_8100
    case rutokenSelfIdentify(String)

    var rawValue: String {
        switch self {
        case .rutoken2_2000:
            return "Рутокен ЭЦП 2.0 (2000)"
        case .rutoken2_2010:
            return "Рутокен ЭЦП 2.0 (2010)"
        case .rutoken2_2100:
            return "Рутокен ЭЦП 2.0 (2100)"
        case .rutoken2_2200:
            return "Рутокен ЭЦП 2.0 (2200)"
        case .rutoken2_3000:
            return "Рутокен ЭЦП 2.0 (3000)"
        case .rutoken2_4000:
            return "Рутокен ЭЦП 2.0 (4000)"
        case .rutoken2_4400:
            return "Рутокен ЭЦП 2.0 (4400)"
        case .rutoken2_4500:
            return "Рутокен ЭЦП 2.0 (4500)"
        case .rutoken2_4900:
            return "Рутокен ЭЦП 2.0 (4900)"
        case .rutoken2_8003:
            return "Рутокен ЭЦП 2.0 (8003)"
        case .rutoken3_3200:
            return "Рутокен ЭЦП 3.0 (3200)"
        case .rutoken3_3220:
            return "Рутокен ЭЦП 3.0 (3220)"
        case .rutoken3Nfc_3100:
            return "Рутокен ЭЦП 3.0 NFC (3100)"
        case .rutoken3_3100:
            return "Рутокен ЭЦП 3.0 (3100)"
        case .rutoken3NfcMf_3110:
            return "Рутокен ЭЦП 3.0 NFC MF (3110)"
        case .rutoken3Ble_8100:
            return "Рутокен ЭЦП 3.0 Bluetooth (8100)"
        case .rutokenSelfIdentify(let model):
            return model
        }
    }
}

extension TokenModel {
    init?(_ hardwareVersion: CK_VERSION, _ firmwareVersion: CK_VERSION,
          _ extendedTokenInfo: CK_TOKEN_INFO_EXTENDED, supportedInterfaces: Set<TokenInterface>) {
        guard extendedTokenInfo.ulTokenClass == TOKEN_CLASS_ECP || extendedTokenInfo.ulTokenClass == TOKEN_CLASS_ECPDUAL else {
            return nil
        }

        let AA = hardwareVersion.major
        let BB = hardwareVersion.minor
        let CC = firmwareVersion.major
        let DD = firmwareVersion.minor
        let containsFlashDrive = extendedTokenInfo.flags & TOKEN_FLAGS_HAS_FLASH_DRIVE == 0 ? false : true
        let containsTouchButton = extendedTokenInfo.flags & TOKEN_FLAGS_HAS_BUTTON == 0 ? false : true

        switch (AA, BB, CC, DD, containsFlashDrive, containsTouchButton) {
        case (20, _, 23, _, false, false),
             (59, _, 26, _, false, false):
            self = .rutoken2_2000
        case (54, _, 23, 2, false, false):
            self = .rutoken2_2100
        case (20, _, 24, _, false, false):
            self = .rutoken2_2200
        case (20, _, 26, _, false, false),
             (59, _, 27, _, false, false):
            self = .rutoken2_3000
        case (55, _, 24, _, false, false):
            self = .rutoken2_4000
        case (55, _, 24, _, false, true):
            self = .rutoken2_4400
        case (55, _, 24, _, true, false),
             (59, _, 26, _, true, false),
             (55, _, 27, _, true, false),
             (58...59, _, 27, _, true, false):
            self = .rutoken2_4500
        case (55, _, 24, _, true, true),
             (55, _, 27, _, true, true),
             (59, _, 27, _, true, true):
            self = .rutoken2_4900
        case (_, _, 21, _, false, false),
             (_, _, 25, _, false, false):
            self = .rutoken2_8003
        case (59, _, 30, _, false, false):
            self = .rutoken3_3200
        case (65, _, 30, _, false, false):
            self = .rutoken3_3220
        case (60, _, 30, _, false, false),
             (60, _, 28, _, false, false):
            if supportedInterfaces.contains(.nfc) {
                self = .rutoken3Nfc_3100
            } else {
                self = .rutoken3_3100
            }
        case (60, _, 31, _, false, false):
            self = .rutoken3NfcMf_3110
        case (_, _, 30, _, false, false):
            self = .rutoken3Ble_8100
        case (_, _, 24, _, false, false):
            self = .rutoken2_2010
        default:
            return nil
        }
    }
}
