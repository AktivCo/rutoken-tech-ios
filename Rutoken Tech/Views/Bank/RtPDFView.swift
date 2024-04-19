//
//  RtPDFView.swift
//  Rutoken Tech
//
//  Created by Ivan Poderegin on 15.04.2024.
//

import PDFKit
import SwiftUI


struct RtPDFView: UIViewRepresentable {
    let pdf: PDFDocument

    func makeUIView(context: UIViewRepresentableContext<RtPDFView>) -> PDFView {
        let pdfView = PDFView()
        pdfView.pageBreakMargins = UIEdgeInsets(top: 0, left: UIDevice.isPhone ? 29 : 49,
                                                bottom: 0, right: UIDevice.isPhone ? 29 : 49)
        pdfView.pageShadowsEnabled = false
        pdfView.autoScales = true
        pdfView.document = pdf
        pdfView.backgroundColor = UIColor(Color.RtColors.rtSurfaceSecondary)
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: UIViewRepresentableContext<RtPDFView>) { }
}