;; Constants
(define-constant contract-owner tx-sender)
(define-constant min-stake u100000)
(define-constant max-nodes u1000)

;; Error codes
(define-constant err-owner-only (err u100))
(define-constant err-not-registered (err u101))
(define-constant err-already-registered (err u102))
(define-constant err-insufficient-stake (err u103))
(define-constant err-max-nodes-reached (err u104))

;; Data variables
(define-map nodes 
  { node-address: principal } 
  { stake: uint,
    reputation: uint,
    status: (string-ascii 20),
    registered-at: uint })

(define-data-var total-nodes uint u0)
(define-data-var total-stake uint u0)

;; Register new node
(define-public (register-node (stake uint))
  (let ((node-address tx-sender))
    (asserts! (>= stake min-stake) err-insufficient-stake)
    (asserts! (< (var-get total-nodes) max-nodes) err-max-nodes-reached)
    (asserts! (is-none (map-get? nodes {node-address: node-address})) err-already-registered)
    
    (try! (stx-transfer? stake tx-sender (as-contract tx-sender)))
    
    (map-set nodes 
      {node-address: node-address}
      {stake: stake,
       reputation: u100,
       status: "active",
       registered-at: block-height})
       
    (var-set total-nodes (+ (var-get total-nodes) u1))
    (var-set total-stake (+ (var-get total-stake) stake))
    (ok true)))

;; Update node status
(define-public (update-status (new-status (string-ascii 20)))
  (let ((node-address tx-sender)
        (node (unwrap! (map-get? nodes {node-address: node-address}) err-not-registered)))
    
    (map-set nodes
      {node-address: node-address}
      (merge node {status: new-status}))
    (ok true)))

;; Update node reputation
(define-public (update-reputation (node-address principal) (delta int))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (let ((node (unwrap! (map-get? nodes {node-address: node-address}) err-not-registered)))
      (map-set nodes
        {node-address: node-address}
        (merge node {reputation: (to-uint (+ delta (unwrap-panic (to-int (get reputation node)))))}))
      (ok true))))

;; Get node details
(define-read-only (get-node-details (node-address principal))
  (ok (map-get? nodes {node-address: node-address})))

;; Get network stats
(define-read-only (get-network-stats)
  (ok {
    total-nodes: (var-get total-nodes),
    total-stake: (var-get total-stake)
  }))
