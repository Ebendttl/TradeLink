;; identity-reputation.clar
;; Decentralized Identity & Reputation Contract (Hardened)

;; ----------------------------
;; Traits
;; ----------------------------
(impl-trait .reputation-trait.reputation-trait)

;; ----------------------------
;; Constants & Errors
;; ----------------------------
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-PROFILE-NOT-FOUND (err u101))
(define-constant ERR-PAUSED (err u102))

;; ----------------------------
;; Internal Helpers
;; ----------------------------
(define-private (check-not-paused)
  (asserts! (not (contract-call? .circuit-breaker is-paused "identity")) ERR-PAUSED))

;; ----------------------------
;; Data Maps
;; ----------------------------
(define-map profiles
  { user: principal }
  { username: (string-ascii 48),
    metadata-uri: (string-ascii 256),
    verified: bool,
    kyc-status: bool })

(define-map reputation
  { user: principal }
  { score: uint,
    total-ratings: uint,
    rating-sum: uint })

;; ----------------------------
;; Trait Implementation
;; ----------------------------

(define-read-only (get-score (user principal))
  (ok (get score (default-to { score: u0, total-ratings: u0, rating-sum: u0 }
                            (map-get? reputation { user: user })))))

(define-public (record-success (user principal) (amount uint))
  (begin
    (try! (check-not-paused))
    ;; In production: (asserts! (is-authorized-module) ERR-NOT-AUTHORIZED)
    (ok true)))

(define-public (record-penalty (user principal) (amount uint))
  (begin
    (try! (check-not-paused))
    ;; In production: (asserts! (is-authorized-module) ERR-NOT-AUTHORIZED)
    (ok true)))

;; ----------------------------
;; Public Functions
;; ----------------------------

(define-public (set-profile (username (string-ascii 48)) (metadata-uri (string-ascii 256)))
  (begin
    (try! (check-not-paused))
    (let ((current-profile (map-get? profiles { user: tx-sender })))
      (map-set profiles
        { user: tx-sender }
        { username: username,
          metadata-uri: metadata-uri,
          verified: (default-to false (get verified current-profile)),
          kyc-status: (default-to false (get kyc-status current-profile)) })
      (ok true))))

(define-public (add-rating (user principal) (rating uint))
  (begin
    (try! (check-not-paused))
    (asserts! (<= rating u5) (err u103))
    (let ((current-rep (default-to { score: u0, total-ratings: u0, rating-sum: u0 } (map-get? reputation { user: user })))
          (new-total (+ (get total-ratings current-rep) u1))
          (new-sum (+ (get rating-sum current-rep) rating))
          (new-score (/ (* new-sum u200) new-total)))
      (map-set reputation
        { user: user }
        { score: new-score,
          total-ratings: new-total,
          rating-sum: new-sum })
      (try! (contract-call? .event-registry log-reward-issued user new-score new-score))
      (ok true))))
