;; TradeLink: Decentralized Marketplace Protocol (v2 Modular)
;; Description: Evolved into a composable protocol layer with 8 integration modules.

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
;; Read-Only Functions
;; ----------------------------
(define-read-only (get-item (item-id uint))
  (map-get? items { item-id: item-id }))

;; ----------------------------
;; Item Management
;; ----------------------------
(define-public (add-item (name (string-ascii 256)) (description (string-ascii 1024)) (price uint)
                          (category (string-ascii 128)) (image-url (string-ascii 2048)) (quantity uint))
  (begin
    ;; 1. Access Control Check
    (asserts! (not (unwrap-panic (contract-call? .access-control is-blacklisted tx-sender))) ERR-ACCESS-DENIED)
    
    (asserts! (>= quantity u1) (err u200))
    (let ((new-id (var-get next-item-id)))
      (map-insert items { item-id: new-id }
                  { seller: tx-sender, name: name, description: description, price: price,
                    sold: false, category: category, image-url: image-url, quantity: quantity })
      (var-set next-item-id (+ new-id u1))
      (ok new-id))))

;; ----------------------------
;; Sales Implementation
;; ----------------------------
(define-public (buy-item (item-id uint))
  (let ((item (unwrap! (map-get? items { item-id: item-id }) ERR-ITEM-NOT-FOUND))
        (buyer tx-sender)
        (seller (get seller item))
        (price (get price item)))
    (begin
      ;; 1. Access Control & Reputation Checks
      (asserts! (not (unwrap-panic (contract-call? .access-control is-blacklisted buyer))) ERR-ACCESS-DENIED)
      ;; Optional: Check seller reputation for high-value items
      (if (> price u1000000000) ;; > 1000 STX example
          (asserts! (>= (get score (contract-call? .identity-reputation get-reputation seller)) u500) ERR-REPUTATION-LOW)
          true)

      (if (and (is-eq (get sold item) false) (> (get quantity item) u0))
        (let ((platform-fee (/ (* price (var-get platform-fee-percentage)) u100))
              (seller-amount (- price platform-fee))
              (sale-id (var-get next-sale-id)))
          (begin
            ;; 2. Payment Processing (Unified STX/Token via payment-processor)
            (try! (contract-call? .payment-processor lock-funds-stx price))
            
            ;; 3. Escrow Creation
            (try! (contract-call? .escrow-manager create-escrow seller (var-get owner) seller-amount (+ block-height u1440) (list price)))
            
            ;; 4. Update State
            (map-set items { item-id: item-id }
                    (merge item { quantity: (- (get quantity item) u1), 
                                 sold: (is-eq (- (get quantity item) u1) u0) }))
            
            (map-insert sales { sale-id: sale-id }
                              { item-id: item-id, buyer: buyer, sale-price: price, 
                                sale-time: (default-to u0 (get-block-info? time u0)), refunded: false })
            
            (var-set next-sale-id (+ sale-id u1))

            ;; 5. Complementary Services
            (try! (contract-call? .purchase-nft mint-receipt buyer sale-id item-id))
            (try! (contract-call? .market-analytics record-purchase seller price (get category item)))
            (try! (contract-call? .loyalty-rewards award-points buyer u10))
            
            (ok sale-id)))
        ERR-ITEM-UNAVAILABLE))))

;; ----------------------------
;; Dispute Redirection
;; ----------------------------
(define-public (open-dispute (sale-id uint) (reason (string-ascii 256)))
  (begin
    ;; Delegate to Escrow Manager and DAO
    (try! (contract-call? .escrow-manager dispute-escrow sale-id))
    (contract-call? .marketplace-dao submit-dispute-proposal sale-id reason)))

;; ----------------------------
;; Admin
;; ----------------------------
(define-public (set-platform-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender (var-get owner)) ERR-NOT-AUTHORIZED)
    (ok (var-set platform-fee-percentage new-fee))))
