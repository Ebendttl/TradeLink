;; escrow-trait.clar
;; Unified interface for escrow managers

(define-trait escrow-trait
  (
    ;; Create a new escrow
    (create-escrow (principal principal uint uint (list 10 uint)) (response uint uint))
    
    ;; Release a specific milestone
    (release-milestone (uint uint) (response bool uint))
    
    ;; Flag an escrow as disputed
    (dispute-escrow (uint) (response bool uint))
    
    ;; Resolve a dispute
    (resolve-escrow (uint bool) (response bool uint))
  )
)
