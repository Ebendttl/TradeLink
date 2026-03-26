;; circuit-breaker.clar
;; Emergency Stop / Circuit Breaker Contract
;; Provides a global and per-module pause mechanism for the protocol

;; ----------------------------
;; Constants & Errors
;; ----------------------------
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u1300))

;; ----------------------------
;; Data Variables
;; ----------------------------
(define-data-var global-paused bool false)

;; ----------------------------
;; Data Maps
;; ----------------------------

;; Pause status per contract name
(define-map paused-modules
  { name: (string-ascii 32) }
  { paused: bool })

;; ----------------------------
;; Read-Only Functions
;; ----------------------------

(define-read-only (is-paused (module-name (string-ascii 32)))
  (or (var-get global-paused)
      (get paused (default-to { paused: false } (map-get? paused-modules { name: module-name })))))

(define-read-only (is-global-paused)
  (var-get global-paused))

;; ----------------------------
;; Public Functions
;; ----------------------------

;; Admin: Toggle global pause
(define-public (set-global-pause (status bool))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (ok (var-set global-paused status))))

;; Admin: Toggle module-specific pause
(define-public (set-module-pause (name (string-ascii 32)) (status bool))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (ok (map-set paused-modules { name: name } { paused: status }))))
