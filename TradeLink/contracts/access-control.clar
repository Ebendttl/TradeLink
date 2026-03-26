;; access-control.clar
;; Access Control & Moderation Contract
;; Part of the TradeLink Protocol

;; ----------------------------
;; Constants & Errors
;; ----------------------------
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u800))
(define-constant ERR-USER-NOT-FOUND (err u801))

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

(define-read-only (is-moderator (user principal))
  (get active (default-to { active: false } (map-get? moderators { user: user }))))

;; ----------------------------
;; Public Functions
;; ----------------------------

;; Admin: Add/Remove moderator
(define-public (set-moderator (user principal) (active bool))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (ok (map-set moderators { user: user } { active: active }))))

;; Flag a user (Moderators only)
(define-public (flag-user (user principal) (reason (string-ascii 256)))
  (let ((current-flags (get flag-count (default-to { active: false, reason: "", flag-count: u0 } (map-get? blacklist { user: user })))))
    (begin
      (asserts! (or (is-moderator tx-sender) (is-eq tx-sender CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)
      (map-set blacklist { user: user }
        { active: (>= (+ current-flags u1) u5), ;; Auto-blacklist after 5 flags
          reason: reason,
          flag-count: (+ current-flags u1) })
      (ok true))))

;; Blacklist a user (Admin only)
(define-public (blacklist-user (user principal) (reason (string-ascii 256)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (ok (map-set blacklist { user: user }
      { active: true,
        reason: reason,
        flag-count: u999 }))))

;; Un-blacklist a user (Admin only)
(define-public (unblacklist-user (user principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (ok (map-delete blacklist { user: user }))))
