;; TradeLink: Decentralized Marketplace Protocol (v2 Hardened)
;; Description: Production-grade modular marketplace with security hardening.

;; ----------------------------
;; Traits
;; ----------------------------
(use-trait payment-trait .payment-trait.payment-trait)
(use-trait escrow-trait .escrow-trait.escrow-trait)
(use-trait reputation-trait .reputation-trait.reputation-trait)

;; ----------------------------
;; Constants & Errors
;; ----------------------------
(define-data-var owner principal tx-sender)
(define-data-var next-item-id uint u1)
(define-data-var next-sale-id uint u1)
(define-data-var platform-fee-percentage uint u5)

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ITEM-NOT-FOUND (err u101))
(define-constant ERR-ITEM-UNAVAILABLE (err u102))
(define-constant ERR-ACCESS-DENIED (err u103))
(define-constant ERR-REPUTATION-LOW (err u104))
(define-constant ERR-PAUSED (err u105))

;; ----------------------------
;; Data Maps
;; ----------------------------
(define-map items
  { item-id: uint }
  { seller: principal, name: (string-ascii 256), description: (string-ascii 1024),
    price: uint, sold: bool, category: (string-ascii 128), image-url: (string-ascii 2048),
    quantity: uint })

(define-map sales
  { sale-id: uint }
  { item-id: uint, buyer: principal, sale-price: uint, sale-time: uint,
    refunded: bool })

;; ----------------------------
;; Internal Helpers
;; ----------------------------
(define-private (check-not-paused (module-name (string-ascii 32)))
  (asserts! (not (contract-call? .circuit-breaker is-paused module-name)) ERR-PAUSED))

;; ----------------------------
;; Item Management
;; ----------------------------
(define-public (add-item (name (string-ascii 256)) (description (string-ascii 1024)) (price uint)
                          (category (string-ascii 128)) (image-url (string-ascii 2048)) (quantity uint))
  (begin
    ;; 1. Security Checklist
    (try! (check-not-paused "marketplace"))
    (asserts! (not (unwrap-panic (contract-call? .access-control is-blacklisted tx-sender))) ERR-ACCESS-DENIED)
    
    ;; 2. Protocol Guard Validation
    (try! (contract-call? .protocol-guard validate-listing price quantity))
    
    (let ((new-id (var-get next-item-id)))
      (map-insert items { item-id: new-id }
                  { seller: tx-sender, name: name, description: description, price: price,
                    sold: false, category: category, image-url: image-url, quantity: quantity })
      (var-set next-item-id (+ new-id u1))
      
      ;; 3. Standardized Event Logging
      (try! (contract-call? .event-registry log-listing new-id tx-sender price category))
      
      (ok new-id))))

;; ----------------------------
;; Sales Implementation (Hardened)
;; ----------------------------
(define-public (buy-item (item-id uint) (payment-p <payment-trait>) (escrow-p <escrow-trait>))
  (let ((item (unwrap! (map-get? items { item-id: item-id }) ERR-ITEM-NOT-FOUND))
        (buyer tx-sender)
        (seller (get seller item))
        (price (get price item))
        (payment-addr (contract-of payment-p))
        (escrow-addr (contract-of escrow-p)))
    (begin
      ;; 1. Security Checklist
      (try! (check-not-paused "marketplace"))
      (asserts! (not (unwrap-panic (contract-call? .access-control is-blacklisted buyer))) ERR-ACCESS-DENIED)
      
      ;; 2. Dynamic Contract Registry Check (Ensuring we use authorized modules)
      (asserts! (is-eq (some payment-addr) (contract-call? .contract-registry get-contract-address "payment-processor")) ERR-NOT-AUTHORIZED)
      (asserts! (is-eq (some escrow-addr) (contract-call? .contract-registry get-contract-address "escrow-manager")) ERR-NOT-AUTHORIZED)

      ;; 3. Advanced Reputation Check
      (asserts! (>= (unwrap-panic (contract-call? .reputation-oracle get-score seller)) u300) ERR-REPUTATION-LOW)

      (if (and (is-eq (get sold item) false) (> (get quantity item) u0))
        (let ((platform-fee (/ (* price (var-get platform-fee-percentage)) u100))
              (seller-amount (- price platform-fee))
              (sale-id (var-get next-sale-id))
              (expiry (contract-call? .time-utils get-expiry u1440))) ;; 10 days approx
          (begin
            ;; 4. Payment & Treasury Routing
            (try! (contract-call? payment-p lock-funds price (as-contract tx-sender)))
            (try! (contract-call? .treasury-vault deposit-fees platform-fee))
            
            ;; 5. Advanced Escrow with Time Utils
            (try! (contract-call? escrow-p create-escrow seller (var-get owner) seller-amount expiry (list price)))
            
            ;; 6. State Update
            (map-set items { item-id: item-id }
                    (merge item { quantity: (- (get quantity item) u1), 
                                 sold: (is-eq (- (get quantity item) u1) u0) }))
            
            (map-insert sales { sale-id: sale-id }
                              { item-id: item-id, buyer: buyer, sale-price: price, 
                                sale-time: (contract-call? .time-utils get-now), refunded: false })
            
            (var-set next-sale-id (+ sale-id u1))

            ;; 7. Post-Sale Services
            (try! (contract-call? .purchase-nft mint-receipt buyer sale-id item-id))
            (try! (contract-call? .event-registry log-sale sale-id item-id buyer seller price))
            (try! (contract-call? .market-analytics record-purchase seller price (get category item)))
            (try! (contract-call? .loyalty-rewards award-points buyer u10))
            
            (ok sale-id)))
        ERR-ITEM-UNAVAILABLE))))

;; ----------------------------
;; Dispute Redirection
;; ----------------------------
(define-public (open-dispute (sale-id uint) (reason (string-ascii 256)))
  (begin
    (try! (check-not-paused "governance"))
    ;; Delegate to Escrow Manager and DAO
    (try! (contract-call? .escrow-manager dispute-escrow sale-id))
    (try! (contract-call? .marketplace-dao submit-dispute-proposal sale-id reason))
    (try! (contract-call? .event-registry log-dispute sale-id tx-sender reason))
    (ok true)))

;; ----------------------------
;; Admin
;; ----------------------------
(define-public (set-platform-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender (var-get owner)) ERR-NOT-AUTHORIZED)
    (ok (var-set platform-fee-percentage new-fee))))

(define-public (withdraw-collected-fees (recipient principal))
  (begin
    (asserts! (is-eq tx-sender (var-get owner)) ERR-NOT-AUTHORIZED)
    (contract-call? .treasury-vault withdraw-all recipient)))
