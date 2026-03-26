;; market-analytics.clar
;; Analytics & Indexing Contract
;; Part of the TradeLink Protocol

;; ----------------------------
;; Constants & Errors
;; ----------------------------
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u600))

;; ----------------------------
;; Data Variables
;; ----------------------------
(define-data-var total-volume uint u0)
(define-data-var total-sales uint u0)

;; ----------------------------
;; Data Maps
;; ----------------------------

;; Statistics per seller
(define-map seller-stats
  { seller: principal }
  { total-volume: uint,
    sales-count: uint })

;; Statistics per category
(define-map category-stats
  { category: (string-ascii 128) }
  { total-volume: uint,
    sales-count: uint })

;; ----------------------------
;; Read-Only Functions
;; ----------------------------

(define-read-only (get-global-stats)
  { total-volume: (var-get total-volume),
    total-sales: (var-get total-sales) })

(define-read-only (get-seller-stats (seller principal))
  (default-to { total-volume: u0, sales-count: u0 } (map-get? seller-stats { seller: seller })))

(define-read-only (get-category-stats (category (string-ascii 128)))
  (default-to { total-volume: u0, sales-count: u0 } (map-get? category-stats { category: category })))

;; ----------------------------
;; Public Functions
;; ----------------------------

;; Record a purchase event (TradeLink only)
(define-public (record-purchase (seller principal) (amount uint) (category (string-ascii 128)))
  (begin
    ;; In production: (asserts! (is-eq tx-sender TRADELINK-CONTRACT) ERR-NOT-AUTHORIZED)
    
    ;; Update global stats
    (var-set total-volume (+ (var-get total-volume) amount))
    (var-set total-sales (+ (var-get total-sales) u1))
    
    ;; Update seller stats
    (let ((current-seller-stats (get-seller-stats seller)))
      (map-set seller-stats { seller: seller }
        { total-volume: (+ (get total-volume current-seller-stats) amount),
          sales-count: (+ (get sales-count current-seller-stats) u1) }))
          
    ;; Update category stats
    (let ((current-cat-stats (get-category-stats category)))
      (map-set category-stats { category: category }
        { total-volume: (+ (get total-volume current-cat-stats) amount),
          sales-count: (+ (get sales-count current-cat-stats) u1) }))
          
    (ok true)))
