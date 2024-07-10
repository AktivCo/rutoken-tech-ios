//
//  Pkcs11Constants.swift
//  Rutoken Tech
//
//  Created by Андрей Трифонов on 2024-07-10.
//

import Foundation


enum Pkcs11Constants {
    static let gostR3410_2012_256_paramset_B: [CK_BYTE] = [ 0x06, 0x09, 0x2A, 0x85, 0x03, 0x07, 0x01, 0x02, 0x01, 0x01, 0x02 ]
    static let gostR3411_2012_256_params_oid: [CK_BYTE] = [ 0x06, 0x08, 0x2a, 0x85, 0x03, 0x07, 0x01, 0x01, 0x02, 0x02 ]
    static let CK_CERTIFICATE_CATEGORY_TOKEN_USER: CK_ULONG = 1
}
