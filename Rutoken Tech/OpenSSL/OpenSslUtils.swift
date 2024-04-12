//
//  OpenSslUtils.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 19.03.2024.
//

import Foundation


func bioToData(_ bio: OpaquePointer) -> Data? {
    let len = BIO_ctrl(bio, BIO_CTRL_PENDING, 0, nil)

    guard let wrappedPointer = WrappedPointer({
        UnsafeMutableRawBufferPointer.allocate(byteCount: Int(len), alignment: 1)
    }, { $0.deallocate() }),
        let bytes = wrappedPointer.pointer.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
        return nil
    }

    var accumulated: Int32 = 0
    var bytesRead: Int32 = 0
    repeat {
        bytesRead = BIO_read(bio, bytes.advanced(by: Int(bytesRead)), Int32(wrappedPointer.pointer.count) - accumulated)
        accumulated += bytesRead

        guard bytesRead >= -1 else {
            return nil
        }
    } while bytesRead > 0

    return Data(bytes: bytes, count: len)
}

func bioToString(_ bio: OpaquePointer) -> String? {
    guard let data = bioToData(bio) else {
        return nil
    }

    return String(data: data, encoding: .utf8)
}

func dataToBio(_ data: Data) -> WrappedPointer<OpaquePointer>? {
    data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> WrappedPointer<OpaquePointer>? in
        WrappedPointer({
            guard let bytes = ptr.baseAddress?.assumingMemoryBound(to: UInt8.self),
                  let bio = BIO_new(BIO_s_mem()) else {
                return nil
            }

            var accumulated: Int32 = 0
            var bytesWritten: Int32 = 0
            repeat {
                bytesWritten = BIO_write(bio, bytes.advanced(by: Int(bytesWritten)), Int32(ptr.count) - accumulated)
                accumulated += bytesWritten

                guard bytesWritten >= 0 else {
                    return nil
                }
            } while bytesWritten > 0

            return bio
        }, BIO_free)
    }
}

func stringToBio(_ str: String) -> WrappedPointer<OpaquePointer>? {
    guard let data = str.data(using: .utf8) else {
        return nil
    }

    return dataToBio(data)
}

func wrapKey(_ data: Data) -> WrappedPointer<OpaquePointer>? {
    return WrappedPointer<OpaquePointer>({
        guard let bio = dataToBio(data) else { return nil }
        return PEM_read_bio_PrivateKey(bio.pointer, nil, nil, nil)
    }, EVP_PKEY_free)
}

func x509DerToPem(_ bio: OpaquePointer) -> String? {
    guard let wrappedBio = WrappedPointer({ BIO_new(BIO_s_mem()) }, BIO_free),
          PEM_write_bio_X509(wrappedBio.pointer, bio) == 1 else {
        return nil
    }
    return bioToString(wrappedBio.pointer)
}
