;; access-control.clar
;; Access Control & Moderation Contract (Hardened)

;; ----------------------------
;; Constants & Errors
;; ----------------------------
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u800))
(define-constant ERR-PAUSED (err u801))

;; ----------------------------
;; Internal Helpers
;; ----------------------------
(define-private (check-not-paused)
  (asserts! (not (contract-call? .circuit-breaker is-paused "access")) ERR-PAUSED))

;; ----------------------------
;; Data Maps
;; ----------------------------

;; Blacklisted users
(define-map blacklist
  { user: principal }
  { active: bool,
    reason: (string-ascii 256),
    flag-count: uint })

;; Authorized moderators
(define-map moderators
  { user: principal }
  { active: bool })

;; ----------------------------
;; Read-Only Functions
;; ----------------------------

(define-read-only (is-blacklisted (user principal))
  (get active (default-to { active: false, reason: "", flag-count: u0 } (map-get? blacklist { user: user }))))

;; ----------------------------
;; Public Functions
;; ----------------------------

(define-public (set-moderator (user principal) (active bool))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (ok (map-set moderators { user: user } { active: active }))))

(define-public (flag-user (user principal) (reason (string-ascii 256)))
  (let ((current-flags (get flag-count (default-to { active: false, reason: "", flag-count: u0 } (map-get? blacklist { user: user })))))
    (begin
      (try! (check-not-paused))
      (asserts! (or (is-some (map-get? moderators { user: tx-sender })) (is-eq tx-sender CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)
      (map-set blacklist { user: user }
        { active: (>= (+ current-flags u1) u5),
          reason: reason,
          flag-count: (+ current-flags u1) })
      (ok true))))

(define-public (blacklist-user (user principal) (reason (string-ascii 256)))
  (begin
    (try! (check-not-paused))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (ok (map-set blacklist { user: user }
      { active: true,
        reason: reason,
        flag-count: u999 }))))
