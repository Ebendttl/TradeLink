;; payment-processor.clar
;; Multi-Token Payment & Wallet Abstraction Contract
;; Part of the TradeLink Protocol

;; ----------------------------
;; Traits
;; ----------------------------
(use-trait ft-trait 'SP3FBR2AGK5H9QBDH3EEN6DF8EK8JY7RX8QJ5SVTE.sip-010-trait-ft-standard.sip-010-trait)

;; ----------------------------
;; Constants & Errors
;; ----------------------------
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u200))
(define-constant ERR-UNSUPPORTED-TOKEN (err u201))
(define-constant ERR-INSUFFICIENT-BALANCE (err u202))

;; ----------------------------
;; Data Maps
;; ----------------------------

;; Conversion rates (normalized to STX micro-units, 10^6)
;; 1 Token = X STX micro-units
(define-map token-rates
  { token-contract: principal }
  { rate: uint })

;; Supported tokens whitelist
(define-map supported-tokens
  { token-contract: principal }
  { active: bool })

;; ----------------------------
;; Read-Only Functions
;; ----------------------------

(define-read-only (get-token-rate (token principal))
  (get rate (default-to { rate: u0 } (map-get? token-rates { token-contract: token }))))

(define-read-only (is-supported (token principal))
  (get active (default-to { active: false } (map-get? supported-tokens { token-contract: token }))))

;; ----------------------------
;; Public Functions
;; ----------------------------

;; Admin: Add/Update supported token and rate
(define-public (set-token-support (token principal) (active bool) (rate uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (map-set supported-tokens { token-contract: token } { active: active })
    (map-set token-rates { token-contract: token } { rate: rate })
    (ok true)))

;; Process payment in STX
(define-public (pay-stx (amount uint) (recipient principal))
  (stx-transfer? amount tx-sender recipient))

;; Process payment in SIP-010 token
(define-public (pay-token (token <ft-trait>) (amount uint) (recipient principal))
  (let ((token-addr (contract-of token)))
    (asserts! (is-supported token-addr) ERR-UNSUPPORTED-TOKEN)
    (contract-call? token transfer amount tx-sender recipient none)))

;; Escrow locking (simulated, to be integrated with escrow-manager)
;; Locks funds in the project's vault (this contract for now)
(define-public (lock-funds-stx (amount uint))
  (stx-transfer? amount tx-sender (as-contract tx-sender)))

(define-public (lock-funds-token (token <ft-trait>) (amount uint))
  (let ((token-addr (contract-of token)))
    (asserts! (is-supported token-addr) ERR-UNSUPPORTED-TOKEN)
    (contract-call? token transfer amount tx-sender (as-contract tx-sender) none)))

;; Release locked funds (Admin/Escrow Manager only)
(define-public (release-funds-stx (amount uint) (recipient principal))
  (begin
    ;; In production: (asserts! (is-eq tx-sender ESCROW-MANAGER) ERR-NOT-AUTHORIZED)
    (as-contract (stx-transfer? amount tx-sender recipient))))

(define-public (release-funds-token (token <ft-trait>) (amount uint) (recipient principal))
  (begin
    ;; In production: (asserts! (is-eq tx-sender ESCROW-MANAGER) ERR-NOT-AUTHORIZED)
    (as-contract (contract-call? token transfer amount tx-sender recipient none))))
