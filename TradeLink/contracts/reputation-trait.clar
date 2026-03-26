;; reputation-trait.clar
;; Unified interface for reputation oracles

(define-trait reputation-trait
  (
    ;; Get a user's reputation score
    (get-score (principal) (response uint uint))
    
    ;; Update reputation after a successful sale
    (record-success (principal uint) (response bool uint))
    
    ;; Apply a penalty (e.g., for losing a dispute)
    (record-penalty (principal uint) (response bool uint))
  )
)
