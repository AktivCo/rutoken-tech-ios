//
//  Pkcs11Date.swift
//  Rutoken Tech
//
//  Created by Андрей Трифонов on 2024-05-27.
//

import Foundation


struct Pkcs11Date {
    var date: CK_DATE

    init(date: Date) {
        let day = date.getString(as: "dd").createPointer()
        let month = date.getString(as: "MM").createPointer()
        let year = date.getString(as: "YYYY").createPointer()

        self.date = CK_DATE()

        memcpy(&(self.date.day), day.pointer, 2)
        memcpy(&(self.date.month), month.pointer, 2)
        memcpy(&(self.date.year), year.pointer, 4)
    }

    mutating func data() -> Data {
        return Data(bytes: &date, count: 8)
    }
}
