;; escrow-manager.clar
;; Advanced Escrow & Milestone Contract
;; Part of the TradeLink Protocol

;; ----------------------------
;; Constants & Errors
;; ----------------------------
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u300))
(define-constant ERR-ESCROW-NOT-FOUND (err u301))
(define-constant ERR-INVALID-STATE (err u302))
(define-constant ERR-ALREADY-RELEASED (err u303))
(define-constant ERR-TIME-LOCKED (err u304))

;; ----------------------------
;; Data Maps
;; ----------------------------

;; Escrow status: 0=Active, 1=Released, 2=Disputed, 3=Refunded
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
;; Read-Only Functions
;; ----------------------------

(define-read-only (get-escrow (escrow-id uint))
  (map-get? escrows { escrow-id: escrow-id }))

(define-read-only (get-milestone (escrow-id uint) (index uint))
  (map-get? milestones { escrow-id: escrow-id, milestone-index: index }))

;; ----------------------------
;; Public Functions
;; ----------------------------

;; Create a new escrow with milestones
(define-public (create-escrow (seller principal) (arbiter principal) (amount uint) (expiry uint) (milestone-amounts (list 10 uint)))
  (let ((escrow-id (var-get next-escrow-id))
        (total-milestones (len milestone-amounts)))
    (begin
      ;; Store main escrow data
      (map-insert escrows { escrow-id: escrow-id }
        { buyer: tx-sender,
          seller: seller,
          arbiter: arbiter,
          amount: amount,
          status: u0,
          expiry: expiry,
          milestones-total: total-milestones,
          milestones-released: u0 })
      
      ;; Increment global ID
      (var-set next-escrow-id (+ escrow-id u1))
      
      ;; Simplified: In a real scenario, we'd loop or use a more complex way to store milestones.
      ;; For now, let's assume milestone 0 is always created.
      (map-insert milestones { escrow-id: escrow-id, milestone-index: u0 }
        { amount: amount, released: false })
        
      (ok escrow-id))))

;; Release a milestone (Buyer only)
(define-public (release-milestone (escrow-id uint) (index uint))
  (let ((escrow (unwrap! (map-get? escrows { escrow-id: escrow-id }) ERR-ESCROW-NOT-FOUND))
        (milestone (unwrap! (map-get? milestones { escrow-id: escrow-id, milestone-index: index }) ERR-ESCROW-NOT-FOUND)))
    (begin
      (asserts! (is-eq (get buyer escrow) tx-sender) ERR-NOT-AUTHORIZED)
      (asserts! (not (get released milestone)) ERR-ALREADY-RELEASED)
      
      ;; Mark milestone as released
      (map-set milestones { escrow-id: escrow-id, milestone-index: index }
        { amount: (get amount milestone), released: true })
        
      ;; Update escrow released count
      (map-set escrows { escrow-id: escrow-id }
        (merge escrow { milestones-released: (+ (get milestones-released escrow) u1) }))
        
      ;; In production: Trigger payment-processor.release-funds-stx
      (ok true))))

;; Dispute an escrow (Buyer or Seller)
(define-public (dispute-escrow (escrow-id uint))
  (let ((escrow (unwrap! (map-get? escrows { escrow-id: escrow-id }) ERR-ESCROW-NOT-FOUND)))
    (begin
      (asserts! (or (is-eq (get buyer escrow) tx-sender) (is-eq (get seller escrow) tx-sender)) ERR-NOT-AUTHORIZED)
      (asserts! (is-eq (get status escrow) u0) ERR-INVALID-STATE)
      (ok (map-set escrows { escrow-id: escrow-id }
        (merge escrow { status: u2 }))))))

;; Resolve dispute (Arbiter only)
(define-public (resolve-escrow (escrow-id uint) (release-to-seller bool))
  (let ((escrow (unwrap! (map-get? escrows { escrow-id: escrow-id }) ERR-ESCROW-NOT-FOUND)))
    (begin
      (asserts! (is-eq (get arbiter escrow) tx-sender) ERR-NOT-AUTHORIZED)
      (asserts! (is-eq (get status escrow) u2) ERR-INVALID-STATE)
      (ok (map-set escrows { escrow-id: escrow-id }
        (merge escrow { status: (if release-to-seller u1 u3) }))))))

;; Sweep expired escrow (Seller only after expiry)
(define-public (sweep-expired (escrow-id uint))
  (let ((escrow (unwrap! (map-get? escrows { escrow-id: escrow-id }) ERR-ESCROW-NOT-FOUND)))
    (begin
      (asserts! (is-eq (get seller escrow) tx-sender) ERR-NOT-AUTHORIZED)
      (asserts! (> block-height (get expiry escrow)) ERR-TIME-LOCKED)
      (asserts! (is-eq (get status escrow) u0) ERR-INVALID-STATE)
      (ok (map-set escrows { escrow-id: escrow-id }
        (merge escrow { status: u1 }))))))
