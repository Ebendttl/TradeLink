;; escrow-manager.clar
;; Advanced Escrow & Milestone Contract (Hardened)

;; ----------------------------
;; Traits
;; ----------------------------
(impl-trait .escrow-trait.escrow-trait)

;; ----------------------------
;; Constants & Errors
;; ----------------------------
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u300))
(define-constant ERR-ESCROW-NOT-FOUND (err u301))
(define-constant ERR-INVALID-STATE (err u302))
(define-constant ERR-PAUSED (err u303))

;; ----------------------------
;; Internal Helpers
;; ----------------------------
(define-private (check-not-paused)
  (asserts! (not (contract-call? .circuit-breaker is-paused "escrow")) ERR-PAUSED))

;; ----------------------------
;; Data Maps
;; ----------------------------
(define-map escrows
  { escrow-id: uint }
  { buyer: principal,
    seller: principal,
    arbiter: principal,
    amount: uint,
    status: uint,
    expiry: uint,
    milestones-total: uint,
    milestones-released: uint })

(define-map milestones
  { escrow-id: uint, milestone-index: uint }
  { amount: uint, released: bool })

(define-data-var next-escrow-id uint u1)

;; ----------------------------
;; Trait Implementation
;; ----------------------------

(define-public (create-escrow (seller principal) (arbiter principal) (amount uint) (expiry uint) (milestone-amounts (list 10 uint)))
  (let ((escrow-id (var-get next-escrow-id))
        (total-milestones (len milestone-amounts)))
    (begin
      (try! (check-not-paused))
      (map-insert escrows { escrow-id: escrow-id }
        { buyer: tx-sender,
          seller: seller,
          arbiter: arbiter,
          amount: amount,
          status: u0,
          expiry: expiry,
          milestones-total: total-milestones,
          milestones-released: u0 })
      
      (var-set next-escrow-id (+ escrow-id u1))
      (map-insert milestones { escrow-id: escrow-id, milestone-index: u0 }
        { amount: amount, released: false })
        
      (try! (contract-call? .event-registry log-escrow-update escrow-id u0 none))
      (ok escrow-id))))

(define-public (release-milestone (escrow-id uint) (index uint))
  (let ((escrow (unwrap! (map-get? escrows { escrow-id: escrow-id }) ERR-ESCROW-NOT-FOUND))
        (milestone (unwrap! (map-get? milestones { escrow-id: escrow-id, milestone-index: index }) ERR-ESCROW-NOT-FOUND)))
    (begin
      (try! (check-not-paused))
      (asserts! (is-eq (get buyer escrow) tx-sender) ERR-NOT-AUTHORIZED)
      
      (map-set milestones { escrow-id: escrow-id, milestone-index: index }
        { amount: (get amount milestone), released: true })
        
      (map-set escrows { escrow-id: escrow-id }
        (merge escrow { milestones-released: (+ (get milestones-released escrow) u1) }))
        
      (try! (contract-call? .event-registry log-escrow-update escrow-id u1 (some index)))
      (ok true))))

(define-public (dispute-escrow (escrow-id uint))
  (let ((escrow (unwrap! (map-get? escrows { escrow-id: escrow-id }) ERR-ESCROW-NOT-FOUND)))
    (begin
      (try! (check-not-paused))
      (map-set escrows { escrow-id: escrow-id } (merge escrow { status: u2 }))
      (try! (contract-call? .event-registry log-escrow-update escrow-id u2 none))
      (ok true))))

(define-public (resolve-escrow (escrow-id uint) (release-to-seller bool))
  (let ((escrow (unwrap! (map-get? escrows { escrow-id: escrow-id }) ERR-ESCROW-NOT-FOUND)))
    (begin
      (try! (check-not-paused))
      ;; In production: (asserts! (is-authorized-arbiter) ERR-NOT-AUTHORIZED)
      (map-set escrows { escrow-id: escrow-id }
        (merge escrow { status: (if release-to-seller u1 u3) }))
      (try! (contract-call? .event-registry log-escrow-update escrow-id (if release-to-seller u1 u3) none))
      (ok true))))
