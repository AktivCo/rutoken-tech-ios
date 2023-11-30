//
//  TokenType.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 22.11.2023.
//


enum TokenInterface {
    case usb
    case nfc
    case sc
}

extension TokenInterface {
    init?(_ value: CK_ULONG) {
        switch value {
        case CK_ULONG(INTERFACE_TYPE_NFC_TYPE_A), CK_ULONG(INTERFACE_TYPE_NFC_TYPE_B):
            self = .nfc
        case CK_ULONG(INTERFACE_TYPE_USB):
            self = .usb
        case CK_ULONG(INTERFACE_TYPE_ISO):
            self = .sc
        default:
            return nil
        }
    }
}

extension Sequence where Iterator.Element == TokenInterface {
    init(bits: CK_ULONG) where Self == [TokenInterface] {
        self = [INTERFACE_TYPE_ISO,
                INTERFACE_TYPE_NFC_TYPE_A,
                INTERFACE_TYPE_NFC_TYPE_B,
                INTERFACE_TYPE_USB]
                   .compactMap({
                       let mask = CK_ULONG($0)
                       guard bits & mask == mask else { return nil }
                       return TokenInterface(mask)
                   })
    }
}
