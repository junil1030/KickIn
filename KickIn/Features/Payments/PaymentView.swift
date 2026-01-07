//
//  PaymentView.swift
//  KickIn
//
//  Created by 서준일 on 01/07/26.
//

import SwiftUI
import UIKit
import OSLog
import iamport_ios
import Then

struct PaymentView: UIViewControllerRepresentable {
    let paymentOrderInfo: PaymentOrderInfo
    let onValidationSuccess: (() -> Void)?
    let onPaymentFailure: ((String) -> Void)?
    let onPaymentCancelled: (() -> Void)?

    func makeUIViewController(context: Context) -> UIViewController {
        return PaymentViewController(
            paymentOrderInfo: paymentOrderInfo,
            onValidationSuccess: onValidationSuccess,
            onPaymentFailure: onPaymentFailure,
            onPaymentCancelled: onPaymentCancelled
        )
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

final class PaymentViewController: UIViewController {
    private let paymentOrderInfo: PaymentOrderInfo
    private var didRequestPayment = false
    private let viewModel = PaymentViewModel()
    private let onValidationSuccess: (() -> Void)?
    private let onPaymentFailure: ((String) -> Void)?
    private let onPaymentCancelled: (() -> Void)?

    init(
        paymentOrderInfo: PaymentOrderInfo,
        onValidationSuccess: (() -> Void)?,
        onPaymentFailure: ((String) -> Void)?,
        onPaymentCancelled: (() -> Void)?
    ) {
        self.paymentOrderInfo = paymentOrderInfo
        self.onValidationSuccess = onValidationSuccess
        self.onPaymentFailure = onPaymentFailure
        self.onPaymentCancelled = onPaymentCancelled
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        viewModel.onValidationSuccess = { [weak self] in
            self?.onValidationSuccess?()
        }
        viewModel.onPaymentFailure = { [weak self] message in
            self?.onPaymentFailure?(message)
        }
        viewModel.onPaymentCancelled = { [weak self] in
            self?.onPaymentCancelled?()
        }

        viewModel.retryPendingValidations()

        guard !didRequestPayment else { return }
        didRequestPayment = true
        requestIamportPayment()
    }

    // MARK: - Iamport Payment

    private func requestIamportPayment() {
        let userCode = Bundle.main.object(forInfoDictionaryKey: "iamport_user_code") as? String ?? ""
        guard !userCode.isEmpty else {
            Logger.ui.error("❌ Missing iamport_user_code in Info.plist")
            return
        }

        let payment = createPaymentData()

        Iamport.shared.payment(viewController: self,
                               userCode: userCode,
                               payment: payment) { [weak self] response in
            Logger.ui.info("✅ Iamport payment response: \(String(describing: response))")
            self?.viewModel.handleIamportResponse(response)
        }
    }

    private func createPaymentData() -> IamportPayment {
        return IamportPayment(
            pg: PG.html5_inicis.makePgRawName(pgId: "INIpayTest"),
            merchant_uid: paymentOrderInfo.orderCode,
            amount: "\(paymentOrderInfo.amount)").then {
                $0.pay_method = PayMethod.card.rawValue
                $0.name = paymentOrderInfo.title
                $0.buyer_name = paymentOrderInfo.buyerName
                $0.app_scheme = "KickIn"
            }
    }
}
