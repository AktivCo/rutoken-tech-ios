//
//  TokenModel.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 21.11.2023.
//

enum TokenModel: String {
    case rutoken2 = "Рутокен ЭЦП 2.0"
    case rutoken3 = "Рутокен ЭЦП 3.0"
    case rutoken3Nfc = "Рутокен ЭЦП 3.0 NFC"
}

extension TokenModel {
    init?(_ hardwareVersion: CK_VERSION, _ firmwareVersion: CK_VERSION, _ tokenClass: CK_ULONG, type: TokenType) {
        guard tokenClass == TOKEN_CLASS_ECP || tokenClass == TOKEN_CLASS_ECPDUAL else {
            return nil
        }

        let AA = hardwareVersion.major
        let BB = hardwareVersion.minor
        let CC = firmwareVersion.major
        let DD = firmwareVersion.minor

        switch (AA, BB, CC, DD) {
        case (_, _, 21, _),
             (_, _, 25, _),
             (20, _, 23...24, _),
             (20, _, 26, _),
             (54, _, 23, 2),
             (55, _, 24, _),
             (55, _, 27, _),
             (58, _, 27, _),
             (59, _, 26...27, _):
            self = .rutoken2
        case (54, _, 23, 0),
             (54, _, ..<20, _):
            return nil
        case (_, _, 30...31, _),
             (60, _, 28, _):
            self = type == .dual ? .rutoken3 : .rutoken3Nfc
        default:
            return nil
        }
    }
}
