//
//  Pkcs11KeyPair.swift
//  Rutoken Tech
//
//  Created by Андрей Трифонов on 2024-05-27.
//


struct Pkcs11KeyPair {
    let publicKey: Pkcs11ObjectProtocol
    let privateKey: Pkcs11ObjectProtocol

    var algorithm: Pkcs11KeyAlgorithm {
        .gostR3410_2012_256
    }
}
