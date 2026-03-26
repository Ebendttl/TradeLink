;; time-utils.clar
;; Time & State Utility Contract
;; Standardizes time-based logic across the protocol

;; ----------------------------
;; Read-Only Functions
;; ----------------------------

;; Get current block height (safe wrapper)
(define-read-only (get-now)
  block-height)

;; Check if a target height has been reached
(define-read-only (is-expired (expiry-height uint))
  (>= block-height expiry-height))

;; Check if current time is within a window
(define-read-only (within-window (start-height uint) (window-blocks uint))
  (<= block-height (+ start-height window-blocks)))

;; Calculate an expiry height from now
(define-read-only (get-expiry (blocks-from-now uint))
  (+ block-height blocks-from-now))

;; Standardized windows (in Stacks blocks, ~10 min each)
(define-constant WINDOW-DAY u144)
(define-constant WINDOW-WEEK u1008)
(define-constant WINDOW-MONTH u4320)

(define-read-only (get-standard-window (name (string-ascii 16)))
  (if (is-eq name "day") (some WINDOW-DAY)
  (if (is-eq name "week") (some WINDOW-WEEK)
  (if (is-eq name "month") (some WINDOW-MONTH)
  none))))
