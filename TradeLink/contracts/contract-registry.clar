;; contract-registry.clar
;; Contract Registry & Upgrade Router
;; Centralizes address management for all protocol modules

;; ----------------------------
;; Constants & Errors
;; ----------------------------
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u900))
(define-constant ERR-NOT-FOUND (err u901))

;; ----------------------------
;; Data Maps
;; ----------------------------

;; Map: contract-name -> { principal, version, active }
(define-map contracts
  { name: (string-ascii 32) }
  { address: principal,
    version: uint,
    active: bool })

;; ----------------------------
;; Read-Only Functions
;; ----------------------------

(define-read-only (get-contract (name (string-ascii 32)))
  (map-get? contracts { name: name }))

(define-read-only (get-contract-address (name (string-ascii 32)))
  (get address (map-get? contracts { name: name })))

;; ----------------------------
;; Public Functions
;; ----------------------------

;; Admin: Register or update a module
(define-public (set-contract (name (string-ascii 32)) (address principal) (version uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (ok (map-set contracts { name: name }
      { address: address,
        version: version,
        active: true }))))

;; Admin: Deactivate a module
(define-public (deactivate-contract (name (string-ascii 32)))
  (let ((current (unwrap! (get-contract name) ERR-NOT-FOUND)))
    (begin
      (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
      (ok (map-set contracts { name: name }
        (merge current { active: false }))))))
