;; loyalty-rewards.clar
;; Loyalty & Incentives Contract (Hardened)

;; ----------------------------
;; Constants & Errors
;; ----------------------------
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u700))
(define-constant ERR-PAUSED (err u701))

(define-constant TIER-SILVER-THRESHOLD u1000)
(define-constant TIER-GOLD-THRESHOLD u5000)

;; ----------------------------
;; Internal Helpers
;; ----------------------------
(define-private (check-not-paused)
  (asserts! (not (contract-call? .circuit-breaker is-paused "loyalty")) ERR-PAUSED))

;; ----------------------------
;; Data Maps
;; ----------------------------
(define-map user-rewards
  { user: principal }
  { points: uint,
    total-earned: uint,
    tier: uint })

;; ----------------------------
;; Public Functions
;; ----------------------------

(define-public (award-points (user principal) (amount uint))
  (let ((current-rewards (default-to { points: u0, total-earned: u0, tier: u0 }
                                    (map-get? user-rewards { user: user })))
        (new-points (+ (get points current-rewards) amount))
        (new-total (+ (get total-earned current-rewards) amount)))
    (begin
      (try! (check-not-paused))
      ;; In production: (asserts! (is-authorized-module) ERR-NOT-AUTHORIZED)
      (let ((new-tier (if (>= new-total TIER-GOLD-THRESHOLD) u2 
                         (if (>= new-total TIER-SILVER-THRESHOLD) u1 u0))))
        (map-set user-rewards { user: user }
          { points: new-points,
            total-earned: new-total,
            tier: new-tier })
        (try! (contract-call? .event-registry log-reward-issued user amount new-points))
        (ok true)))))

(define-public (redeem-points (amount uint))
  (let ((current-rewards (default-to { points: u0, total-earned: u0, tier: u0 }
                                    (map-get? user-rewards { user: tx-sender }))))
    (begin
      (try! (check-not-paused))
      (asserts! (>= (get points current-rewards) amount) ERR-NOT-AUTHORIZED)
      (ok (map-set user-rewards { user: tx-sender }
        (merge current-rewards { points: (- (get points current-rewards) amount) }))))))
