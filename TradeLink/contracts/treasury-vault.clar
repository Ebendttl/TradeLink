;; treasury-vault.clar
;; Funds Vault / Treasury Contract
;; Centralizes protocol fund management and fee collection

;; ----------------------------
;; Constants & Errors
;; ----------------------------
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u1200))
(define-constant ERR-INSUFFICIENT-FUNDS (err u1201))

;; ----------------------------
;; Data Variables
;; ----------------------------
(define-data-var total-fees-collected uint u0)

;; ----------------------------
;; Read-Only Functions
;; ----------------------------

(define-read-only (get-balance)
  (stx-get-balance (as-contract tx-sender)))

(define-read-only (get-fees-stats)
  (var-get total-fees-collected))

;; ----------------------------
;; Public Functions
;; ----------------------------

;; Deposit platform fees (Protocol contracts only)
(define-public (deposit-fees (amount uint))
  (begin
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (var-set total-fees-collected (+ (var-get total-fees-collected) amount))
    (ok true)))

;; Withdraw funds (Admin only, potentially Multi-sig)
(define-public (withdraw-funds (amount uint) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (<= amount (get-balance)) ERR-INSUFFICIENT-FUNDS)
    (as-contract (stx-transfer? amount tx-sender recipient))))

;; Withdraw all funds (Emergency)
(define-public (withdraw-all (recipient principal))
  (let ((current-balance (get-balance)))
    (begin
      (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
      (as-contract (stx-transfer? current-balance tx-sender recipient)))))
