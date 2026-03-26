;; event-registry.clar
;; Event Standardization & Logging Contract
;; Enables clean off-chain indexing for the protocol

;; ----------------------------
;; Constants & Errors
;; ----------------------------
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u1000))

;; ----------------------------
;; Public Logging Functions
;; ----------------------------

;; Log a new item listing
(define-public (log-listing (item-id uint) (seller principal) (price uint) (category (string-ascii 128)))
  (begin
    ;; In production: (asserts! (is-authorized-module) ERR-NOT-AUTHORIZED)
    (print { event: "listing", data: { item-id: item-id, seller: seller, price: price, category: category, timestamp: block-height } })
    (ok true)))

;; Log a sale
(define-public (log-sale (sale-id uint) (item-id uint) (buyer principal) (seller principal) (amount uint))
  (begin
    ;; In production: (asserts! (is-authorized-module) ERR-NOT-AUTHORIZED)
    (print { event: "sale", data: { sale-id: sale-id, item-id: item-id, buyer: buyer, seller: seller, amount: amount, timestamp: block-height } })
    (ok true)))

;; Log a dispute
(define-public (log-dispute (sale-id uint) (proposer principal) (reason (string-ascii 256)))
  (begin
    ;; In production: (asserts! (is-authorized-module) ERR-NOT-AUTHORIZED)
    (print { event: "dispute-opened", data: { sale-id: sale-id, proposer: proposer, reason: reason, timestamp: block-height } })
    (ok true)))

;; Log an escrow update
(define-public (log-escrow-update (escrow-id uint) (status uint) (milestone-index (optional uint)))
  (begin
    ;; In production: (asserts! (is-authorized-module) ERR-NOT-AUTHORIZED)
    (print { event: "escrow-update", data: { escrow-id: escrow-id, status: status, milestone: milestone-index, timestamp: block-height } })
    (ok true)))

;; Log a reward issuance
(define-public (log-reward-issued (user principal) (points uint) (total-points uint))
  (begin
    ;; In production: (asserts! (is-authorized-module) ERR-NOT-AUTHORIZED)
    (print { event: "reward-issued", data: { user: user, points: points, total: total-points, timestamp: block-height } })
    (ok true)))
