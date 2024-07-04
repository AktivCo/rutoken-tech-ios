//
//  AppReducer.swift
//  Rutoken Tech
//
//  Created by Ivan Poderegin on 22.11.2023.
//

import Foundation
import SwiftUI

import TinyAsyncRedux


struct AppReducer: Reducer {
    func reduce(state: AppState, withAction action: AppAction) -> AppState {
        var newState = state
        switch action {
        case .appLoaded:
            break
        case let .showAlert(appAlert):
            newState.routingState.alert = appAlert.alertModel
        case .hideAlert:
            newState.routingState.alert = nil
        case let .showSheet(draggable, size, content):
            newState.routingState.sheet.isDraggable = draggable
            newState.routingState.sheet.size = size
            newState.routingState.sheet.content = AnyView(content)
            newState.routingState.sheet.isPresented = true
        case .hideSheet:
            newState.routingState.sheet.isPresented = false
        case .selectToken:
            break
        case let .tokenSelected(info, pin):
            newState.caConnectedTokenState.connectedToken = info
            newState.caConnectedTokenState.pin = pin
        case let .showPinInputError(errorText):
            newState.routingState.pinInputModel.errorDescription = errorText
        case .hidePinInputError:
            newState.routingState.pinInputModel.errorDescription = ""
        case .updateActionWithTokenButtonState(let state):
            newState.routingState.actionWithTokenButtonState = state
            newState.routingState.pinInputModel.buttonState = state
        case .generateKeyId:
            newState.caGenerateKeyPairState.key = KeyModel(ckaId: String.generateID(),
                                                           type: .gostR3410_2012_256)
        case .generateKeyPair:
            break
        case let .updateKeys(keys):
            newState.caGenerateCertState.keys = keys
        case .generateCert:
            break
        case .logout:
            // MARK: logout ca
            newState.caConnectedTokenState.connectedToken = nil
            newState.caConnectedTokenState.pin = nil
            newState.caConnectedTokenState.certs = []
            newState.caGenerateKeyPairState.key = nil
            newState.caGenerateCertState.keys = []

            // MARK: logout bank
            newState.bankDocumentListState.isLoading = false
            newState.bankCertListState.certs = []
            newState.bankSelectUserState.selectedUser = nil
            newState.bankSelectedDocumentState.docContent = nil
            newState.bankSelectedDocumentState.metadata = nil
            newState.bankSelectedDocumentState.urlsForShare = []
        case .openLink:
            break
        case .readCerts:
            break
        case let .updateBankCerts(certs):
            newState.bankCertListState.certs = certs
        case let .cacheCaCerts(certs):
            newState.caConnectedTokenState.certs = certs
        case .selectCert:
            break
        case let .updateUsers(users):
            newState.bankSelectUserState.userListModel.items = users
        case .deleteUser:
            break
        case .authUser:
            break
        case .prepareDocuments:
            break
        case let .selectUser(user):
            newState.bankSelectUserState.selectedUser = user
        case .savePin:
            break
        case let .updatePin(pin):
            newState.routingState.pinInputModel.pin = pin
        case .getPin:
            break
        case .deletePin:
            newState.routingState.pinInputModel.pin = ""
        case .resetDocuments:
            newState.bankDocumentListState.isLoading = true
        case .updateDocuments(let docs):
            newState.bankDocumentListState.isLoading = false
            newState.bankDocumentListState.documents = docs
            if let selectedDoc = state.bankSelectedDocumentState.metadata,
               let updatedDocument = newState.bankDocumentListState.documents.first(where: { $0.name == selectedDoc.name }) {
                newState.bankSelectedDocumentState.metadata = updatedDocument
            }
        case .signDocument:
            break
        case .cmsVerify:
            break
        case .encryptDocument:
            break
        case .decryptCms:
            break
        case .selectDocument:
            break
        case let .updateCurrentDoc(metadata, content):
            newState.bankSelectedDocumentState.metadata = metadata
            newState.bankSelectedDocumentState.docContent = content
        case let .updateUrlsForShare(urls):
            newState.bankSelectedDocumentState.urlsForShare = urls
        case .generateQrCode:
            break
        case .updateQrCode(let image):
            newState.vcrState.qrCode = image
        }
        return newState
    }
}
