;; TradeLink: Decentralized Marketplace Protocol
;; Description: Implements a sophisticated decentralized marketplace built on the Stacks blockchain, 
;; providing a secure, transparent, and feature-rich platform for buying and selling digital items.

;; ----------------------------
;; Data Variables
;; ----------------------------
(define-data-var owner principal tx-sender)
(define-data-var next-item-id uint u1)
(define-data-var next-sale-id uint u1)
(define-data-var platform-fee-percentage uint u5) ;; Represents a percentage (e.g., 20 = 20%)

;; ----------------------------
;; Optional Type Helper Maps
;; ----------------------------
(define-map optional-uint-helper uint uint)
(define-map optional-string-helper uint (string-ascii 1024))
(define-map optional-bool-helper uint bool)

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
    refunded: bool, rating: (optional uint), review: (optional (string-ascii 1024)) })

(define-map seller-ratings
  { seller: principal, rater: principal }
  { rating: uint, review: (optional (string-ascii 1024)) })

(define-map escrow
  { sale-id: uint }
  { buyer: principal, seller: principal, amount: uint, released: bool })

(define-map item-categories
  {category: (string-ascii 128)}
  {exists: bool})

;; ----------------------------
;; Events
;; ----------------------------
(define-private (item-added (item-id uint) (seller principal) (name (string-ascii 256)))
  true)
  
(define-private (item-updated (item-id uint) (price uint))
  true)
  
(define-private (item-removed (item-id uint))
  true)
  
(define-private (item-purchased (sale-id uint) (item-id uint) (buyer principal))
  true)
  
(define-private (refund-issued (sale-id uint) (item-id uint) (buyer principal))
  true)
  
(define-private (escrow-released (sale-id uint) (buyer principal) (seller principal))
  true)
  
(define-private (owner-changed (old-owner principal) (new-owner principal))
  true)
  
(define-private (funds-withdrawn (recipient principal) (amount uint))
  true)

;; ----------------------------
;; Initialization
;; ----------------------------
(define-public (initialize) (ok (var-set owner tx-sender)))
(define-private (is-owner) (is-eq (var-get owner) tx-sender))

;; ----------------------------
;; Item Management
;; ----------------------------
(define-public (add-item (name (string-ascii 256)) (description (string-ascii 1024)) (price uint)
                          (category (string-ascii 128)) (image-url (string-ascii 2048)) (quantity uint))
  (begin
    (asserts! (>= quantity u1) (err u200)) ;;Quantity must be greater than 0.
    (let ((new-id (var-get next-item-id)))
      (map-insert items { item-id: new-id }
                  { seller: tx-sender, name: name, description: description, price: price,
                    sold: false, category: category, image-url: image-url, quantity: quantity })
      (map-insert item-categories {category: category} {exists: true})
      (var-set next-item-id (+ new-id u1))
      (item-added new-id tx-sender name)
      (ok new-id))))
      
(define-public (update-item-price (item-id uint) (new-price uint))
  (match (map-get? items { item-id: item-id })
    item
    (if (is-eq (get seller item) tx-sender)
      (begin
        (map-set items { item-id: item-id }
                  { seller: (get seller item), name: (get name item), description: (get description item),
                    price: new-price, sold: (get sold item), category: (get category item),
                    image-url: (get image-url item), quantity: (get quantity item) })
        (item-updated item-id new-price)
        (ok true))
      (err u100))
    (err u101)))

(define-public (remove-item (item-id uint))
    (match (map-get? items {item-id: item-id})
        item
        (if (is-eq (get seller item) tx-sender)
            (begin
                (map-delete items {item-id: item-id})
                (item-removed item-id)
                (ok true)
            )
            (err u100)
        )
        (err u101)
    )
)

;; ----------------------------
;; Sales and Escrow
;; ----------------------------
(define-public (buy-item (item-id uint))
  (match (map-get? items { item-id: item-id })
    item
    (if (and (is-eq (get sold item) false) (> (get quantity item) u0))
      (let ((sale-price (get price item))
            (platform-fee (/ (* sale-price (var-get platform-fee-percentage)) u100)))
        (let ((seller-amount (- sale-price platform-fee)))
          ;; Check if sender has enough STX
          (try! (stx-transfer? sale-price tx-sender tx-sender))
          ;; Send STX to seller and platform
          (try! (stx-transfer? seller-amount tx-sender (get seller item)))
          (try! (stx-transfer? platform-fee tx-sender (var-get owner)))
          (let ((sale-id (var-get next-sale-id)) 
                (block-time (default-to u0 (get-block-info? time u0))))
            ;; Update item quantity and sold status
            (map-set items { item-id: item-id }
                    { seller: (get seller item), 
                      name: (get name item), 
                      description: (get description item),
                      price: (get price item), 
                      sold: (is-eq (- (get quantity item) u1) u0), 
                      category: (get category item),
                      image-url: (get image-url item), 
                      quantity: (- (get quantity item) u1)})
            ;; Record the sale with no rating or review
            (map-insert sales { sale-id: sale-id }
                              { item-id: item-id, 
                                buyer: tx-sender, 
                                sale-price: sale-price, 
                                sale-time: block-time,
                                refunded: false, 
                                rating: (map-get? optional-uint-helper u0),
                                review: (map-get? optional-string-helper u0) })
            ;; Create escrow record
            (map-insert escrow { sale-id: sale-id } 
                              { buyer: tx-sender, 
                                seller: (get seller item), 
                                amount: seller-amount, 
                                released: false})
            ;; Increment sale ID
            (var-set next-sale-id (+ sale-id u1))
            ;; Log the purchase event
            (item-purchased sale-id item-id tx-sender)
            (ok true))))
      (err u102))
    (err u101)))

;; ----------------------------
;; Dispute Resolution System
;; ----------------------------
(define-map disputes
  { sale-id: uint }
  { buyer: principal, seller: principal, reason: (string-ascii 1024), 
    resolution-time: (optional uint), resolved: bool, arbiter-ruling: (optional bool) })

(define-private (dispute-opened (sale-id uint) (reason (string-ascii 1024)))
  true)

(define-private (dispute-resolved (sale-id uint) (in-favor-of-buyer bool))
  true)

(define-public (open-dispute (sale-id uint) (reason (string-ascii 1024)))
  (match (map-get? sales { sale-id: sale-id })
    sale
    (match (map-get? escrow { sale-id: sale-id })
      escrow-data
      (if (and (is-eq (get buyer escrow-data) tx-sender)
               (not (get released escrow-data))
               (< (- (default-to u0 (get-block-info? time u0)) (get sale-time sale)) u604800)) ;; 7 days in seconds
        (begin
          (map-insert disputes { sale-id: sale-id }
                     { buyer: (get buyer escrow-data), 
                      seller: (get seller escrow-data), 
                      reason: reason,
                      resolution-time: none,
                      resolved: false, 
                      arbiter-ruling: none })
          (dispute-opened sale-id reason)
          (ok true))
        (err u400)) ;; Cannot open dispute: either not the buyer, funds already released, or past 7-day window
      (err u401)) ;; No escrow record found
    (err u402)) ;; No sale record found
  )

(define-public (resolve-dispute (sale-id uint) (in-favor-of-buyer bool))
  (begin 
    (asserts! (is-owner) (err u403)) ;; Only owner can resolve disputes
    (match (map-get? disputes { sale-id: sale-id })
      dispute
      (if (not (get resolved dispute))
        (match (map-get? escrow { sale-id: sale-id })
          escrow-data
          (begin
            ;; Update dispute record
            (map-set disputes { sale-id: sale-id }
                     { buyer: (get buyer dispute),
                       seller: (get seller dispute),
                       reason: (get reason dispute),
                       resolution-time: (some (default-to u0 (get-block-info? time u0))),
                       resolved: true,
                       arbiter-ruling: (some in-favor-of-buyer) })
            
            ;; If in favor of buyer, refund
            (if in-favor-of-buyer
              (begin
                (try! (stx-transfer? (get amount escrow-data) (var-get owner) (get buyer dispute)))
                (map-set sales { sale-id: sale-id }
                         (merge (unwrap-panic (map-get? sales { sale-id: sale-id }))
                                { refunded: true }))
                (refund-issued sale-id 
                              (get item-id (unwrap-panic (map-get? sales { sale-id: sale-id })))
                              (get buyer dispute)))
              ;; Otherwise, release funds to seller
              (begin
                (map-set escrow { sale-id: sale-id }
                        { buyer: (get buyer escrow-data),
                          seller: (get seller escrow-data),
                          amount: (get amount escrow-data),
                          released: true })
                (escrow-released sale-id (get buyer escrow-data) (get seller escrow-data))))
            
            (dispute-resolved sale-id in-favor-of-buyer)
            (ok true))
          (err u404)) ;; No escrow record found
        (err u405)) ;; Dispute already resolved
      (err u406)) ;; No dispute record found
    ))
