//
//  PaymentViewModel.swift
//  KickIn
//
//  Created by 서준일 on 01/07/26.
//

import Foundation
import Combine
import OSLog
import iamport_ios

final class PaymentViewModel: ObservableObject {
    @Published var validationResponse: PaymentValidationResponseDTO?
    @Published var errorMessage: String?
    var onValidationSuccess: (() -> Void)?
    var onPaymentFailure: ((String) -> Void)?
    var onPaymentCancelled: (() -> Void)?

    private let networkService = NetworkServiceFactory.shared.makeNetworkService()
    private let pendingValidationKey = "pending_payment_validation_imp_uids"

    func retryPendingValidations() {
        let pending = loadPendingImpUids()
        guard !pending.isEmpty else { return }

        Task {
            for impUid in pending {
                await validateReceipt(impUid: impUid)
            }
        }
    }

    func handleIamportResponse(_ response: IamportResponse?) {
        if response?.success == false {
            let message = response?.error_msg ?? "결제에 실패했습니다."
            if isCancellationMessage(message) {
                Task { @MainActor in
                    self.onPaymentCancelled?()
                }
            } else {
                Task { @MainActor in
                    self.onPaymentFailure?(message)
                }
            }
            return
        }

        guard let impUid = response?.imp_uid, !impUid.isEmpty else {
            Logger.network.error("❌ Missing imp_uid from Iamport response")
            Task { @MainActor in
                let message = "결제 응답을 확인할 수 없습니다."
                self.errorMessage = message
                self.onPaymentFailure?(message)
            }
            return
        }

        addPendingImpUid(impUid)

        Task {
            await validateReceipt(impUid: impUid)
        }
    }

    private func validateReceipt(impUid: String) async {
        do {
            let response: PaymentValidationResponseDTO = try await networkService.request(
                PaymentRouter.validateReceipt(PaymentValidationRequestDTO(impUid: impUid))
            )

            await MainActor.run {
                self.validationResponse = response
                self.onValidationSuccess?()
            }

            removePendingImpUid(impUid)
            Logger.network.info("✅ Validated receipt for imp_uid: \(impUid)")
        } catch let error as NetworkError {
            Logger.network.error("❌ Failed to validate receipt: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.onPaymentFailure?(error.localizedDescription)
            }
        } catch {
            Logger.network.error("❌ Unknown error validating receipt: \(error.localizedDescription)")
            await MainActor.run {
                let message = "결제 검증에 실패했습니다."
                self.errorMessage = message
                self.onPaymentFailure?(message)
            }
        }
    }

    private func loadPendingImpUids() -> [String] {
        UserDefaults.standard.stringArray(forKey: pendingValidationKey) ?? []
    }

    private func savePendingImpUids(_ values: [String]) {
        UserDefaults.standard.set(values, forKey: pendingValidationKey)
    }

    private func addPendingImpUid(_ impUid: String) {
        var pending = loadPendingImpUids()
        guard !pending.contains(impUid) else { return }
        pending.append(impUid)
        savePendingImpUids(pending)
    }

    private func removePendingImpUid(_ impUid: String) {
        var pending = loadPendingImpUids()
        pending.removeAll { $0 == impUid }
        savePendingImpUids(pending)
    }

    private func isCancellationMessage(_ message: String) -> Bool {
        let lowercased = message.lowercased()
        return message.contains("취소") || lowercased.contains("cancel")
    }
}
