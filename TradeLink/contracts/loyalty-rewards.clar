;; loyalty-rewards.clar
;; Loyalty & Incentives Contract
;; Part of the TradeLink Protocol

;; ----------------------------
;; Constants & Errors
;; ----------------------------
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u700))

;; Constants for tiers
(define-constant TIER-SILVER-THRESHOLD u1000)
(define-constant TIER-GOLD-THRESHOLD u5000)

;; ----------------------------
;; Data Maps
;; ----------------------------

;; User points and tier data
(define-map user-rewards
  { user: principal }
  { points: uint,
    total-earned: uint,
    tier: uint })

;; ----------------------------
;; Read-Only Functions
;; ----------------------------

(define-read-only (get-user-rewards (user principal))
  (default-to { points: u0, total-earned: u0, tier: u0 } (map-get? user-rewards { user: user })))

(define-read-only (get-tier (user principal))
  (get tier (get-user-rewards user)))

;; ----------------------------
;; Public Functions
;; ----------------------------

;; Award points for activity (TradeLink or other protocol contracts only)
(define-public (award-points (user principal) (amount uint))
  (let ((current-rewards (get-user-rewards user))
        (new-points (+ (get points current-rewards) amount))
        (new-total (+ (get total-earned current-rewards) amount)))
    (begin
      ;; In production: (asserts! (is-authorized-caller) ERR-NOT-AUTHORIZED)
      (let ((new-tier (calculate-tier new-total)))
        (ok (map-set user-rewards { user: user }
          { points: new-points,
            total-earned: new-total,
            tier: new-tier }))))))

;; Redeem points for benefits (logic placeholder)
(define-public (redeem-points (amount uint))
  (let ((current-rewards (get-user-rewards tx-sender)))
    (begin
      (asserts! (>= (get points current-rewards) amount) ERR-NOT-AUTHORIZED)
      (ok (map-set user-rewards { user: tx-sender }
        (merge current-rewards { points: (- (get points current-rewards) amount) }))))))

;; ----------------------------
;; Private Functions
;; ----------------------------

(define-private (calculate-tier (total-earned uint))
  (if (>= total-earned TIER-GOLD-THRESHOLD)
    u2 ;; Gold
    (if (>= total-earned TIER-SILVER-THRESHOLD)
      u1 ;; Silver
      u0))) ;; Bronze
