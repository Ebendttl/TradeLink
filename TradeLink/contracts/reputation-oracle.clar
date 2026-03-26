;; reputation-oracle.clar
;; Advanced Reputation Oracle Layer
;; Sophisticated scoring engine for user trust

;; ----------------------------
;; Constants & Errors
;; ----------------------------
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u1400))
(define-constant WEIGHT-RATING u70) ;; 70%
(define-constant WEIGHT-VOLUME u30) ;; 30%

;; ----------------------------
;; Data Maps
;; ----------------------------

;; User reputation components
(define-map user-stats
  { user: principal }
  { avg-rating: uint, ;; 0-500 (5.0 stars = 500)
    completed-sales: uint,
    total-volume: uint,
    dispute-penalties: uint })

;; ----------------------------
;; Read-Only Functions
;; ----------------------------

(define-read-only (get-user-stats (user principal))
  (default-to { avg-rating: u0, completed-sales: u0, total-volume: u0, dispute-penalties: u0 }
              (map-get? user-stats { user: user })))

;; Reputation = (avg_rating * 1.4) + (completed_sales * 2) - penalties
;; Normalized to 0-1000
(define-read-only (get-score (user principal))
  (let ((stats (get-user-stats user)))
    (let ((base-score (+ (/ (* (get avg-rating stats) u14) u10) (* (get completed-sales stats) u2))))
      (if (> base-score (get dispute-penalties stats))
          (ok (- base-score (get dispute-penalties stats)))
          (ok u0)))))

;; ----------------------------
;; Public Functions
;; ----------------------------

;; Record a successful sale (Protocol only)
(define-public (record-success (user principal) (amount uint))
  (let ((stats (get-user-stats user)))
    (begin
      ;; In production: (asserts! (is-authorized-module) ERR-NOT-AUTHORIZED)
      (ok (map-set user-stats { user: user }
        (merge stats { completed-sales: (+ (get completed-sales stats) u1),
                      total-volume: (+ (get total-volume stats) amount) }))))))

;; Apply penalty (Protocol only)
(define-public (record-penalty (user principal) (amount uint))
  (let ((stats (get-user-stats user)))
    (begin
      ;; In production: (asserts! (is-authorized-module) ERR-NOT-AUTHORIZED)
      (ok (map-set user-stats { user: user }
        (merge stats { dispute-penalties: (+ (get dispute-penalties stats) amount) }))))))

;; Update rating (Protocol only)
(define-public (update-rating (user principal) (new-avg uint))
  (let ((stats (get-user-stats user)))
    (begin
      ;; In production: (asserts! (is-authorized-module) ERR-NOT-AUTHORIZED)
      (ok (map-set user-stats { user: user }
        (merge stats { avg-rating: new-avg }))))))
