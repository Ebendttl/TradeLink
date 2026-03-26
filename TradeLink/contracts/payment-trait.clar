;; payment-trait.clar
;; Unified interface for payment processors

(define-trait payment-trait
  (
    ;; Lock funds for an item purchase
    (lock-funds (uint principal) (response bool uint))
    
    ;; Release funds to a recipient
    (release-funds (uint principal) (response bool uint))
    
    ;; Get normalization rate for a token
    (get-token-rate (principal) (response uint uint))
  )
)
