;; protocol-guard.clar
;; Protocol Guard & Validation Layer
;; Centralizes all critical validation logic for the protocol

;; ----------------------------
;; Constants & Errors
;; ----------------------------
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-PRICE-TOO-LOW (err u1100))
(define-constant ERR-PRICE-TOO-HIGH (err u1101))
(define-constant ERR-QTY-INVALID (err u1102))
(define-constant ERR-SPAM-DETECTED (err u1103))

(define-constant MIN-PRICE u100000) ;; 0.1 STX
(define-constant MAX-PRICE u1000000000000) ;; 1M STX
(define-constant MAX-QTY u10000)

;; ----------------------------
;; Read-Only Functions
;; ----------------------------

;; Validate listing parameters
(define-read-only (validate-listing (price uint) (quantity uint))
  (begin
    (asserts! (and (>= price MIN-PRICE) (<= price MAX-PRICE)) ERR-PRICE-TOO-LOW)
    (asserts! (and (> quantity u0) (<= quantity MAX-QTY)) ERR-QTY-INVALID)
    (ok true)))

;; Validate purchase parameters
(define-read-only (validate-purchase (item-price uint) (available-qty uint))
  (begin
    (asserts! (>= item-price MIN-PRICE) ERR-PRICE-TOO-LOW)
    (asserts! (> available-qty u0) ERR-QTY-INVALID)
    (ok true)))

;; Simple anti-spam: check listing frequency (placeholder)
(define-read-only (is-spamming (user principal))
  false)
