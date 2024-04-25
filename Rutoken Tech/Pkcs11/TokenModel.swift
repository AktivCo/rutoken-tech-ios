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
