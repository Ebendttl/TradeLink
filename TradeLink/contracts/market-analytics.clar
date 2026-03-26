;; market-analytics.clar
;; Analytics & Indexing Contract (Hardened)

;; ----------------------------
;; Constants & Errors
;; ----------------------------
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u600))
(define-constant ERR-PAUSED (err u601))

;; ----------------------------
;; Internal Helpers
;; ----------------------------
(define-private (check-not-paused)
  (asserts! (not (contract-call? .circuit-breaker is-paused "analytics")) ERR-PAUSED))

;; ----------------------------
;; Data Variables
;; ----------------------------
(define-data-var total-volume uint u0)
(define-data-var total-sales uint u0)

;; ----------------------------
;; Data Maps
;; ----------------------------
(define-map seller-stats
  { seller: principal }
  { total-volume: uint,
    sales-count: uint,
    last-sale-height: uint })

(define-map category-stats
  { category: (string-ascii 128) }
  { total-volume: uint,
    sales-count: uint })

;; ----------------------------
;; Public Functions
;; ----------------------------

(define-public (record-purchase (seller principal) (amount uint) (category (string-ascii 128)))
  (let ((current-seller (default-to { total-volume: u0, sales-count: u0, last-sale-height: u0 }
                                   (map-get? seller-stats { seller: seller })))
        (current-cat (default-to { total-volume: u0, sales-count: u0 }
                                 (map-get? category-stats { category: category }))))
    (begin
      (try! (check-not-paused))
      ;; Update global
      (var-set total-volume (+ (var-get total-volume) amount))
      (var-set total-sales (+ (var-get total-sales) u1))
      
      ;; Update seller
      (map-set seller-stats { seller: seller }
        { total-volume: (+ (get total-volume current-seller) amount),
          sales-count: (+ (get sales-count current-seller) u1),
          last-sale-height: (contract-call? .time-utils get-now) })
          
      ;; Update category
      (map-set category-stats { category: category }
        { total-volume: (+ (get total-volume current-cat) amount),
          sales-count: (+ (get sales-count current-cat) u1) })
      (ok true))))
