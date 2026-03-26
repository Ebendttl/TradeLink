;; purchase-nft.clar
;; NFT Receipt & Ownership Contract (SIP-009)
;; Part of the TradeLink Protocol

;; ----------------------------
;; SIP-009 Trait
;; ----------------------------
(use-trait sip-009-trait 'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9.nft-trait.nft-trait)

;; ----------------------------
;; Constants & Errors
;; ----------------------------
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u500))
(define-constant ERR-TOKEN-NOT-FOUND (err u501))

(define-non-fungible-token purchase-receipt uint)

;; ----------------------------
;; Data Maps
;; ----------------------------

;; Receipt metadata
(define-map receipt-metadata
  { token-id: uint }
  { sale-id: uint,
    item-id: uint,
    buyer: principal,
    timestamp: uint })

(define-data-var last-token-id uint u0)

;; ----------------------------
;; SIP-009 Public Functions
;; ----------------------------

(define-read-only (get-last-token-id)
  (ok (var-get last-token-id)))

(define-read-only (get-token-uri (token-id uint))
  (ok none)) ;; In production: (ok (some "ipfs://..."))

(define-read-only (get-owner (token-id uint))
  (ok (nft-get-owner? purchase-receipt token-id)))

(define-public (transfer (token-id uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender sender) ERR-NOT-AUTHORIZED)
    (nft-transfer? purchase-receipt token-id sender recipient)))

;; ----------------------------
;; Custom Public Functions
;; ----------------------------

;; Mint receipt (TradeLink only)
(define-public (mint-receipt (recipient principal) (sale-id uint) (item-id uint))
  (let ((token-id (+ (var-get last-token-id) u1)))
    (begin
      ;; In production: (asserts! (is-eq tx-sender TRADELINK-CONTRACT) ERR-NOT-AUTHORIZED)
      (try! (nft-mint? purchase-receipt token-id recipient))
      (map-insert receipt-metadata { token-id: token-id }
        { sale-id: sale-id,
          item-id: item-id,
          buyer: recipient,
          timestamp: block-height })
      (var-set last-token-id token-id)
      (ok token-id))))

(define-read-only (get-receipt-data (token-id uint))
  (map-get? receipt-metadata { token-id: token-id }))
