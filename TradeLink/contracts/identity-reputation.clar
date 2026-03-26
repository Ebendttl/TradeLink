;; identity-reputation.clar
;; Decentralized Identity & Reputation Contract
;; Part of the TradeLink Protocol

;; ----------------------------
;; Constants & Errors
;; ----------------------------
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-PROFILE-NOT-FOUND (err u101))
(define-constant ERR-INVALID-USERNAME (err u102))

;; ----------------------------
;; Data Maps
;; ----------------------------

;; Profile data: username, metadata-uri (IPFS/Arweave), verification status
(define-map profiles
  { user: principal }
  { username: (string-ascii 48),
    metadata-uri: (string-ascii 256),
    verified: bool,
    kyc-status: bool })

;; Reputation data: score (0-1000), total-ratings, sum-of-ratings
(define-map reputation
  { user: principal }
  { score: uint,
    total-ratings: uint,
    rating-sum: uint })

;; ----------------------------
;; Read-Only Functions
;; ----------------------------

(define-read-only (get-profile (user principal))
  (map-get? profiles { user: user }))

(define-read-only (get-reputation (user principal))
  (default-to 
    { score: u0, total-ratings: u0, rating-sum: u0 }
    (map-get? reputation { user: user })))

(define-read-only (is-verified (user principal))
  (get verified (default-to { verified: false } (map-get? profiles { user: user }))))

;; ----------------------------
;; Public Functions
;; ----------------------------

;; Initialize/Update profile
(define-public (set-profile (username (string-ascii 48)) (metadata-uri (string-ascii 256)))
  (let ((current-profile (map-get? profiles { user: tx-sender })))
    (ok (map-set profiles
      { user: tx-sender }
      { username: username,
        metadata-uri: metadata-uri,
        verified: (default-to false (get verified current-profile)),
        kyc-status: (default-to false (get kyc-status current-profile)) }))))

;; Admin function to set verification status
(define-public (set-verification-status (user principal) (status bool) (kyc bool))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (let ((current-profile (unwrap! (map-get? profiles { user: user }) ERR-PROFILE-NOT-FOUND)))
      (ok (map-set profiles
        { user: user }
        (merge current-profile { verified: status, kyc-status: kyc }))))))

;; Called by TradeLink to update reputation after a sale/rating
;; Restrict to TradeLink contract in production
(define-public (add-rating (user principal) (rating uint))
  (begin
    ;; In production: (asserts! (is-eq tx-sender TRADELINK-CONTRACT) ERR-NOT-AUTHORIZED)
    (asserts! (<= rating u5) (err u103))
    (let ((current-rep (get-reputation user))
          (new-total (+ (get total-ratings current-rep) u1))
          (new-sum (+ (get rating-sum current-rep) rating))
          ;; Normalized score: (sum * 200) / total (gives 0-1000 range for 1-5 stars)
          (new-score (/ (* new-sum u200) new-total)))
      (ok (map-set reputation
        { user: user }
        { score: new-score,
          total-ratings: new-total,
          rating-sum: new-sum })))))
