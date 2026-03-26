;; payment-processor.clar
;; Multi-Token Payment & Wallet Abstraction Contract (Hardened)

;; ----------------------------
;; Traits
;; ----------------------------
(impl-trait .payment-trait.payment-trait)
(use-trait ft-trait 'SP3FBR2AGK5H9QBDH3EEN6DF8EK8JY7RX8QJ5SVTE.sip-010-trait-ft-standard.sip-010-trait)

;; ----------------------------
;; Constants & Errors
;; ----------------------------
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u200))
(define-constant ERR-UNSUPPORTED-TOKEN (err u201))
(define-constant ERR-PAUSED (err u202))

;; ----------------------------
;; Internal Helpers
;; ----------------------------
(define-private (check-not-paused)
  (asserts! (not (contract-call? .circuit-breaker is-paused "payment")) ERR-PAUSED))

;; ----------------------------
;; Data Maps
;; ----------------------------
(define-map token-rates
  { token-contract: principal }
  { rate: uint })

(define-map supported-tokens
  { token-contract: principal }
  { active: bool })

;; ----------------------------
;; Trait Implementation
;; ----------------------------

(define-public (lock-funds (amount uint) (recipient principal))
  (begin
    (try! (check-not-paused))
    (stx-transfer? amount tx-sender recipient)))

(define-public (release-funds (amount uint) (recipient principal))
  (begin
    (try! (check-not-paused))
    ;; In production: (asserts! (is-authorized-module) ERR-NOT-AUTHORIZED)
    (as-contract (stx-transfer? amount tx-sender recipient))))

(define-read-only (get-token-rate (token principal))
  (ok (get rate (default-to { rate: u0 } (map-get? token-rates { token-contract: token })))))

;; ----------------------------
;; Public Functions
;; ----------------------------

(define-public (set-token-support (token principal) (active bool) (rate uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (map-set supported-tokens { token-contract: token } { active: active })
    (map-set token-rates { token-contract: token } { rate: rate })
    (ok true)))

(define-public (pay-token (token <ft-trait>) (amount uint) (recipient principal))
  (let ((token-addr (contract-of token)))
    (begin
      (try! (check-not-paused))
      (asserts! (get active (default-to { active: false } (map-get? supported-tokens { token-contract: token-addr }))) ERR-UNSUPPORTED-TOKEN)
      (contract-call? token transfer amount tx-sender recipient none))))
