//
//  CertView.swift
//  Rutoken Tech
//
//  Created by Vova Badyaev on 19.02.2024.
//

import SwiftUI


struct CertView: View {
    let cert: CertViewData

    func infoField(for title: String, with value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(Color.RtColors.rtLabelSecondary)
                .frame(height: 20, alignment: .top)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(Color.RtColors.rtLabelPrimary)
                .frame(height: 20, alignment: .bottom)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(cert.certInfo.name)
                .font(.headline)
                .foregroundStyle(Color.RtColors.rtLabelPrimary)
                .opacity(cert.causeOfInvalid != nil ? 0.4 : 1)
            VStack(alignment: .leading, spacing: 8) {
                infoField(for: "Должность", with: cert.certInfo.jobTitle)
                infoField(for: "Организация", with: cert.certInfo.companyName)
                infoField(for: "Алгоритм", with: cert.certInfo.keyAlgo.description)
                infoField(for: "Сертификат истекает", with: cert.certInfo.expiryDate.getString(as: "dd.MM.YYYY"))
            }
            .opacity(cert.causeOfInvalid != nil ? 0.4 : 1)
            .frame(maxHeight: 200)
            if let reason = cert.causeOfInvalid {
                Text(reason.rawValue)
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(Color.RtColors.rtColorsSystemRed)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#if DEBUG
struct CertView_Previews: PreviewProvider {
    static var previews: some View {
        let cert = CertViewData()
        let invalidCert = CertViewData(reason: .alreadyExist)

        ZStack {
            Color.RtColors.rtSurfaceSecondary
                .ignoresSafeArea()
            VStack(spacing: 12) {
                CertView(cert: cert)
                CertView(cert: invalidCert)
            }
            .padding(20)
        }
    }
}
#endif
