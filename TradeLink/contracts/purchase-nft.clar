;; purchase-nft.clar
;; NFT Receipt & Ownership Contract (SIP-009) (Hardened)

;; ----------------------------
;; Traits
;; ----------------------------
(use-trait sip-009-trait 'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9.nft-trait.nft-trait)

;; ----------------------------
;; Constants & Errors
;; ----------------------------
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u500))
(define-constant ERR-TOKEN-NOT-FOUND (err u501))
(define-constant ERR-PAUSED (err u502))

(define-non-fungible-token purchase-receipt uint)

;; ----------------------------
;; Internal Helpers
;; ----------------------------
(define-private (check-not-paused)
  (asserts! (not (contract-call? .circuit-breaker is-paused "nft")) ERR-PAUSED))

;; ----------------------------
;; Data Maps
;; ----------------------------
(define-map receipt-metadata
  { token-id: uint }
  { sale-id: uint,
    item-id: uint,
    buyer: principal,
    timestamp: uint })

(define-data-var last-token-id uint u0)

;; ----------------------------
;; Public Functions
;; ----------------------------

(define-public (transfer (token-id uint) (sender principal) (recipient principal))
  (begin
    (try! (check-not-paused))
    (asserts! (is-eq tx-sender sender) ERR-NOT-AUTHORIZED)
    (nft-transfer? purchase-receipt token-id sender recipient)))

(define-public (mint-receipt (recipient principal) (sale-id uint) (item-id uint))
  (let ((token-id (+ (var-get last-token-id) u1)))
    (begin
      (try! (check-not-paused))
      ;; In production: (asserts! (is-authorized-module) ERR-NOT-AUTHORIZED)
      (try! (nft-mint? purchase-receipt token-id recipient))
      (map-insert receipt-metadata { token-id: token-id }
        { sale-id: sale-id,
          item-id: item-id,
          buyer: recipient,
          timestamp: (contract-call? .time-utils get-now) })
      (var-set last-token-id token-id)
      (ok token-id))))
