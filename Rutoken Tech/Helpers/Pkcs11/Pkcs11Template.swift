//
//  Pkcs11Template.swift
//  Rutoken Tech
//
//  Created by Андрей Трифонов on 2024-07-10.
//

import Foundation


class Pkcs11Template {
    static func makeCertBaseTemplate() -> Pkcs11Template {
        return Pkcs11Template()
            .add(attr: .classObject, value: CKO_CERTIFICATE)
            .add(attr: .token, value: true)
            .add(attr: .certType, value: CKC_X_509)
    }

    static func makePubKeyBaseTemplate() -> Pkcs11Template {
        return Pkcs11Template()
            .add(attr: .classObject, value: CKO_PUBLIC_KEY)
            .add(attr: .token, value: true)
            .add(attr: .privateness, value: false)
    }

    static func makePrivKeyBaseTemplate() -> Pkcs11Template {
        return Pkcs11Template()
            .add(attr: .classObject, value: CKO_PRIVATE_KEY)
            .add(attr: .token, value: true)
            .add(attr: .privateness, value: true)
    }

    private var boolAttrs: [Pkcs11BoolAttribute: Bool] = [:]
    private var ulongAttrs: [Pkcs11CkUlongAttribute: UInt] = [:]
    private var dataAttrs: [Pkcs11DataAttribute: Data?] = [:]

    private var pointers: [WrappedPointer<UnsafeMutableRawPointer>] = []

    @discardableResult
    func add(attr: Pkcs11BoolAttribute, value: Bool) -> Pkcs11Template {
        boolAttrs[attr] = value
        return self
    }

    @discardableResult
    func add(attr: Pkcs11CkUlongAttribute, value: CK_ULONG) -> Pkcs11Template {
        ulongAttrs[attr] = value
        return self
    }

    @discardableResult
    func add(attr: Pkcs11DataAttribute, value: Data? = nil) -> Pkcs11Template {
        dataAttrs[attr] = value
        return self
    }

    func withCkTemplate<ResultType>(_ closure: (inout [CK_ATTRIBUTE]) throws -> ResultType) throws -> ResultType {
        var attributes = [CK_ATTRIBUTE]()

        for (attr, value) in boolAttrs {
            let memory = memoryFor(attr: attr, withValue: value)
            pointers.append(memory)
            let ckAttr = CK_ATTRIBUTE(type: attr.type, pValue: memory.pointer, ulValueLen: CK_ULONG(MemoryLayout<CK_BBOOL>.size))
            attributes.append(ckAttr)
        }

        for (attr, value) in ulongAttrs {
            let memory = memoryFor(attr: attr, withValue: value)
            pointers.append(memory)
            let ckAttr = CK_ATTRIBUTE(type: attr.type, pValue: memory.pointer, ulValueLen: CK_ULONG(MemoryLayout<CK_ULONG>.size))
            attributes.append(ckAttr)
        }

        for (attr, value) in dataAttrs {
            let ckAttr: CK_ATTRIBUTE
            if let value {
                let memory = memoryFor(attr: attr, withValue: value)
                pointers.append(memory)
                ckAttr = CK_ATTRIBUTE(type: attr.type, pValue: memory.pointer, ulValueLen: CK_ULONG(value.count))
            } else {
                ckAttr = CK_ATTRIBUTE(type: attr.type, pValue: nil, ulValueLen: 0)
            }
            attributes.append(ckAttr)
        }

        return try closure(&attributes)
    }

    private func memoryFor(attr: Pkcs11BoolAttribute, withValue value: Bool) -> WrappedPointer<UnsafeMutableRawPointer> {
        return WrappedPointer<UnsafeMutableRawPointer>({
            let ptr = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<CK_BBOOL>.size, alignment: 1)
            ptr.storeBytes(of: value ? CK_BBOOL(CK_TRUE) : CK_BBOOL(CK_FALSE), as: CK_BBOOL.self)

            return ptr
        }, {
            $0.deallocate()
        })
    }

    private func memoryFor(attr: Pkcs11CkUlongAttribute, withValue value: UInt) -> WrappedPointer<UnsafeMutableRawPointer> {
        return WrappedPointer<UnsafeMutableRawPointer>({
            let ptr = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<CK_ULONG>.size, alignment: 1)
            ptr.storeBytes(of: CK_ULONG(value), as: CK_ULONG.self)

            return ptr
        }, {
            $0.deallocate()
        })
    }

    private func memoryFor(attr: Pkcs11DataAttribute, withValue value: Data) -> WrappedPointer<UnsafeMutableRawPointer> {
        return WrappedPointer<UnsafeMutableRawPointer>({
            value.withUnsafeBytes { bytes in
                let ptr = UnsafeMutableRawPointer.allocate(byteCount: bytes.count, alignment: 1)
                ptr.copyMemory(from: bytes.baseAddress!, byteCount: bytes.count)
                return ptr
            }
        }, {
            $0.deallocate()
        })
    }
}
