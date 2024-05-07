//
//  DocumentListView.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 22.03.2024.
//

import SwiftUI
import TinyAsyncRedux


struct DocumentListView: View {
    let documents: [BankDocument]
    var body: some View {
        let docsDictionary = Dictionary(grouping: documents, by: { $0.paymentTime })
        ForEach(docsDictionary.keys.sorted(by: { $0 > $1 }), id: \.timeIntervalSince1970) { key in
            VStack(alignment: .leading, spacing: 0) {
                if let documents = docsDictionary[key] {
                    Text(key.getString(as: "d MMMM yyyy"))
                        .textCase(.uppercase)
                        .font(.footnote)
                        .foregroundStyle(Color.RtColors.rtLabelSecondary)
                        .padding(.bottom, 7)
                        .padding(.leading, 12)
                    VStack(spacing: 12) {
                        ForEach(documents) { doc in
                            DocumentListItem(document: doc)
                        }
                    }
                }
            }
            .padding(.top, 6)
            .padding(.bottom, 12)
        }
    }
}


struct DocumentListView_Previews: PreviewProvider {
    static var previews: some View {
        let date = Date(timeIntervalSince1970: 1720000000)
        let documents = [
            BankDocument(
                name: "Платежное поручение №121", action: .verify, amount: 14500,
                companyName: "ОАО “Нефтегаз”", paymentTime: date),
            BankDocument(
                name: "Платежное поручение №121", action: .decrypt, amount: 29345,
                companyName: "ОАО “Нефтегаз”", paymentTime: date),
            BankDocument(
                name: "Платежное поручение №121", action: .verify, amount: 356000,
                companyName: "ОАО “Нефтегаз”",
                paymentTime: Calendar.current.date(byAdding: .day, value: -2, to: date)!),
            BankDocument(
                name: "Платежное поручение №121", action: .decrypt, amount: 1500,
                companyName: "ОАО “Нефтегаз”",
                paymentTime: Calendar.current.date(byAdding: .day, value: -2, to: date)!)
        ]
        VStack(spacing: 0) {
            DocumentListView(documents: documents)
        }
        .background(Color.RtColors.rtSurfaceSecondary)
    }
}
