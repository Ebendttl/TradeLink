;; marketplace-dao.clar
;; DAO Governance & Dispute Arbitration Contract (Hardened)

;; ----------------------------
;; Constants & Errors
;; ----------------------------
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u400))
(define-constant ERR-PROPOSAL-NOT-FOUND (err u401))
(define-constant ERR-VOTING-CLOSED (err u402))
(define-constant ERR-PAUSED (err u403))

(define-constant QUORUM u1000)
(define-constant VOTING-PERIOD u144) ;; ~24 hours

;; ----------------------------
;; Internal Helpers
;; ----------------------------
(define-private (check-not-paused)
  (asserts! (not (contract-call? .circuit-breaker is-paused "governance")) ERR-PAUSED))

;; ----------------------------
;; Data Maps
;; ----------------------------
(define-map proposals
  { proposal-id: uint }
  { sale-id: uint,
    proposer: principal,
    description: (string-ascii 256),
    votes-for: uint,
    votes-against: uint,
    end-block: uint,
    executed: bool })

(define-map user-votes
  { proposal-id: uint, voter: principal }
  { amount: uint })

(define-data-var next-proposal-id uint u1)

;; ----------------------------
;; Public Functions
;; ----------------------------

(define-public (submit-dispute-proposal (sale-id uint) (description (string-ascii 256)))
  (let ((proposal-id (var-get next-proposal-id)))
    (begin
      (try! (check-not-paused))
      (map-insert proposals { proposal-id: proposal-id }
        { sale-id: sale-id,
          proposer: tx-sender,
          description: description,
          votes-for: u0,
          votes-against: u0,
          end-block: (+ (contract-call? .time-utils get-now) VOTING-PERIOD),
          executed: false })
      (var-set next-proposal-id (+ proposal-id u1))
      (try! (contract-call? .event-registry log-dispute sale-id tx-sender description))
      (ok proposal-id))))

(define-public (vote (proposal-id uint) (vote-for bool))
  (let ((proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) ERR-PROPOSAL-NOT-FOUND))
        (voter-power (stx-get-balance tx-sender)))
    (begin
      (try! (check-not-paused))
      (asserts! (< (contract-call? .time-utils get-now) (get end-block proposal)) ERR-VOTING-CLOSED)
      
      (map-insert user-votes { proposal-id: proposal-id, voter: tx-sender } { amount: voter-power })
      
      (if vote-for
        (map-set proposals { proposal-id: proposal-id }
          (merge proposal { votes-for: (+ (get votes-for proposal) voter-power) }))
        (map-set proposals { proposal-id: proposal-id }
          (merge proposal { votes-against: (+ (get votes-against proposal) voter-power) })))
      (ok true))))

(define-public (execute-proposal (proposal-id uint))
  (let ((proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) ERR-PROPOSAL-NOT-FOUND)))
    (begin
      (try! (check-not-paused))
      (asserts! (>= (contract-call? .time-utils get-now) (get end-block proposal)) ERR-VOTING-CLOSED)
      
      (let ((passed (> (get votes-for proposal) (get votes-against proposal))))
        (map-set proposals { proposal-id: proposal-id } (merge proposal { executed: true }))
        (ok passed)))))
