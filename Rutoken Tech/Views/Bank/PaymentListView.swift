//
//  PaymentListView.swift
//  Rutoken Tech
//
//  Created by Никита Девятых on 29.02.2024.
//

import SwiftUI

import RtUiComponents
import TinyAsyncRedux


struct PaymentListView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @EnvironmentObject private var store: Store<AppState, AppAction>
    @State private var docsType: DocType = .income
    @State private var isArchivedDocsShown = true

    var body: some View {
        VStack(spacing: 0) {
            CustomNavBar(left: {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    backButton
                        .padding(.leading, 11)
                        .padding(.vertical, 9)
                }
            }, center: {
                Picker("", selection: $docsType) {
                    ForEach(DocType.allCases, id: \.self) {
                        Text($0.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 186)
            }, right: {
                Button {
                    store.send(.resetDocuments)
                } label: {
                    resetButton
                        .padding(.trailing, 20)
                        .padding(.vertical, 9)
                }
                .disabled(store.state.bankDocumentListState.isLoading)
            })
            .frame(height: 44)
            mainView
                .frame(maxWidth: 642)
                .padding(.horizontal, 20)
            Spacer()
        }
        .background(Color.RtColors.rtSurfaceSecondary)
    }

    private var backButton: some View {
        HStack(spacing: 8) {
            Image(systemName: "chevron.backward")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 19)
            Text("Назад")
        }
        .foregroundStyle(Color.RtColors.rtColorsSecondary)
    }

    private var resetButton: some View {
        Image(systemName: "gobackward.minus")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: 24)
            .foregroundStyle(Color.RtColors.rtColorsSecondary)
    }

    private var mainView: some View {
        let notArchived = store.state.bankDocumentListState.documents.filter({
            $0.direction == docsType && !$0.inArchive
        })
        let archived = store.state.bankDocumentListState.documents.filter({
            $0.direction == docsType && $0.inArchive
        })
        return VStack(alignment: .leading, spacing: 0) {
            HeaderTitleView(title: "Платежи")
            if store.state.bankDocumentListState.isLoading {
                documentsLoadingView
            } else {
                ScrollView(showsIndicators: false) {
                    DocumentListView(documents: notArchived)
                    if !archived.isEmpty {
                        archiveDocumentListView(archived)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func archiveDocumentListView(_ archived: [BankDocument]) -> some View {
        HStack {
            Text("Архив")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.leading, 12)
            Spacer()
            Button {
                isArchivedDocsShown.toggle()
            } label: {
                Image(systemName: isArchivedDocsShown
                      ? "chevron.down"
                      : "chevron.up")
                .frame(width: 24, height: 24)
            }
        }
        if isArchivedDocsShown {
            DocumentListView(documents: archived)
        }
    }

    private var documentsLoadingView: some View {
        VStack(spacing: 0) {
            Spacer()
            RtLoadingIndicator(.big)
                .padding(.bottom, 12)
            Text("Сброс данных...")
                .font(.subheadline)
                .foregroundStyle(Color.RtColors.rtLabelSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}


struct PaymentListView_Previews: PreviewProvider {
    static var previews: some View {
        let date = Date(timeIntervalSince1970: 1720000000)
        var archivedDocument = BankDocument(
            name: "Платежное поручение №121", action: .decrypt, amount: 1500,
            companyName: "ОАО “Нефтегаз”",
            paymentDay: Calendar.current.date(byAdding: .day, value: -2, to: date)!)
        var _ = archivedDocument.inArchive = true
        let docListState = BankDocumentListState(documents: [
            BankDocument(
                name: "Платежное поручение №121", action: .verify, amount: 14500,
                companyName: "ОАО “Нефтегаз”", paymentDay: date),
            BankDocument(
                name: "Платежное поручение №121", action: .decrypt, amount: 29345,
                companyName: "ОАО “Нефтегаз”", paymentDay: date),
            BankDocument(
                name: "Платежное поручение №121", action: .verify, amount: 356000,
                companyName: "ОАО “Нефтегаз”", paymentDay: Calendar.current.date(byAdding: .day, value: -2, to: date)!),
            archivedDocument,
            BankDocument(
                name: "Платежное поручение №121", action: .sign, amount: 14500,
                companyName: "ОАО “Нефтегаз”", paymentDay: date),
            BankDocument(
                name: "Платежное поручение №121", action: .encrypt, amount: 29345,
                companyName: "ОАО “Нефтегаз”", paymentDay: Calendar.current.date(byAdding: .day, value: -3, to: date)!),
            BankDocument(
                name: "Платежное поручение №121", action: .sign, amount: 356000,
                companyName: "ОАО “Нефтегаз”", paymentDay: Calendar.current.date(byAdding: .day, value: -4, to: date)!),
            BankDocument(
                name: "Платежное поручение №121", action: .encrypt, amount: 1500,
                companyName: "ОАО “Нефтегаз”", paymentDay: Calendar.current.date(byAdding: .day, value: -2, to: date)!)
        ])
        let store = Store(initialState: AppState(bankDocumentListState: docListState), reducer: AppReducer(), middlewares: [])
        PaymentListView()
            .environmentObject(store)

        let state = AppState(bankDocumentListState: BankDocumentListState(isLoading: true))
        PaymentListView()
            .environmentObject(Store(initialState: state, reducer: AppReducer(), middlewares: []))
    }
}