;; GeneVault - Biotech Protocol on Stacks (STX)
;; Providing synthetic exposure to gene editing breakthroughs and personalized medicine
;; Built with Clarity for safety and simplicity

;; Token Definition
(define-fungible-token GENE)

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant VAULT-OPEN u0)
(define-constant VAULT-CLOSED u1)
(define-constant INITIAL-SUPPLY u1000000000000) ;; 1B tokens with 12 decimals
(define-constant MIN-DEPOSIT u1000000) ;; Minimum 0.001 STX
(define-constant DEPOSIT-FEE-PERCENT u2) ;; 2% deposit fee
(define-constant WITHDRAWAL-FEE-PERCENT u1) ;; 1% withdrawal fee

;; Data Structures
(define-map vault-state
  { vault-id: uint }
  {
    name: (string-ascii 64),
    description: (string-ascii 256),
    status: uint,
    total-deposits: uint,
    total-withdrawals: uint,
    created-at: uint,
    last-updated: uint
  }
)

(define-map user-positions
  { user: principal, vault-id: uint }
  {
    gene-balance: uint,
    stx-deposited: uint,
    deposit-timestamp: uint,
    last-claim: uint
  }
)

(define-map vault-performance
  { vault-id: uint, day: uint }
  {
    apy: uint,
    tvl: uint
  }
)

(define-map governance-proposals
  { proposal-id: uint }
  {
    title: (string-ascii 128),
    description: (string-ascii 256),
    votes-for: uint,
    votes-against: uint,
    execution-block: uint,
    executed: bool
  }
)

;; Data Variables
(define-data-var next-vault-id uint u0)
(define-data-var next-proposal-id uint u0)
(define-data-var protocol-balance uint u0)
(define-data-var total-tvl uint u0)
(define-data-var average-apy uint u1500) ;; 15% initial APY
(define-data-var current-timestamp uint u0)

;; Events/Logging
(define-data-var event-log (list 100 (string-ascii 256)) (list))

;; Initialize Protocol
(define-public (initialize-protocol)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) (err u1001))
    (try! (ft-mint? GENE INITIAL-SUPPLY CONTRACT-OWNER))
    (ok true)
  )
)

;; Create New Vault
(define-public (create-vault (name (string-ascii 64)) (description (string-ascii 256)))
  (let
    (
      (vault-id (var-get next-vault-id))
    )
    (begin
      (asserts! (is-eq tx-sender CONTRACT-OWNER) (err u1002))
      (map-set vault-state
        { vault-id: vault-id }
        {
          name: name,
          description: description,
          status: VAULT-OPEN,
          total-deposits: u0,
          total-withdrawals: u0,
          created-at: burn-block-height,
          last-updated: burn-block-height
        }
      )
      (var-set next-vault-id (+ vault-id u1))
      (ok vault-id)
    )
  )
)

;; Deposit STX and receive GENE tokens
(define-public (deposit (vault-id uint) (amount uint))
  (let
    (
      (vault (unwrap! (map-get? vault-state { vault-id: vault-id }) (err u2001)))
      (fee (/ (* amount DEPOSIT-FEE-PERCENT) u100))
      (net-amount (- amount fee))
      (gene-amount (/ (* net-amount u1000000) u1)) ;; 1:1 conversion for simplicity
      (current-position (default-to
        { gene-balance: u0, stx-deposited: u0, deposit-timestamp: u0, last-claim: u0 }
        (map-get? user-positions { user: tx-sender, vault-id: vault-id })
      ))
    )
    (begin
      ;; Validate inputs
      (asserts! (>= amount MIN-DEPOSIT) (err u2002))
      (asserts! (is-eq (get status vault) VAULT-OPEN) (err u2003))
      
      ;; Transfer STX from user to contract
      (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
      
      ;; Transfer GENE tokens to user
      (try! (ft-transfer? GENE gene-amount (as-contract tx-sender) tx-sender))
      
      ;; Update user position
      (map-set user-positions
        { user: tx-sender, vault-id: vault-id }
        {
          gene-balance: (+ (get gene-balance current-position) gene-amount),
          stx-deposited: (+ (get stx-deposited current-position) amount),
          deposit-timestamp: burn-block-height,
          last-claim: burn-block-height
        }
      )
      
      ;; Update vault state
      (map-set vault-state
        { vault-id: vault-id }
        (merge vault {
          total-deposits: (+ (get total-deposits vault) amount),
          last-updated: burn-block-height
        })
      )
      
      ;; Update protocol metrics
      (var-set total-tvl (+ (var-get total-tvl) net-amount))
      (var-set protocol-balance (+ (var-get protocol-balance) fee))
      
      (ok { gene-received: gene-amount, fee-paid: fee })
    )
  )
)

;; Withdraw and burn GENE tokens to get STX back
(define-public (withdraw (vault-id uint) (gene-amount uint))
  (let
    (
      (vault (unwrap! (map-get? vault-state { vault-id: vault-id }) (err u2001)))
      (position (unwrap! (map-get? user-positions { user: tx-sender, vault-id: vault-id }) (err u2004)))
      (stx-amount (/ (* gene-amount u1000000) u1)) ;; 1:1 conversion
      (withdrawal-fee (/ (* stx-amount WITHDRAWAL-FEE-PERCENT) u100))
      (net-stx (- stx-amount withdrawal-fee))
    )
    (begin
      ;; Validate inputs
      (asserts! (>= (get gene-balance position) gene-amount) (err u2005))
      (asserts! (is-eq (get status vault) VAULT-OPEN) (err u2003))
      
      ;; Burn GENE tokens
      (try! (ft-burn? GENE gene-amount tx-sender))
      
      ;; Transfer STX back to user
      (try! (stx-transfer? net-stx (as-contract tx-sender) tx-sender))
      
      ;; Update user position
      (map-set user-positions
        { user: tx-sender, vault-id: vault-id }
        {
          gene-balance: (- (get gene-balance position) gene-amount),
          stx-deposited: (- (get stx-deposited position) stx-amount),
          deposit-timestamp: (get deposit-timestamp position),
          last-claim: burn-block-height
        }
      )
      
      ;; Update vault state
      (map-set vault-state
        { vault-id: vault-id }
        (merge vault {
          total-withdrawals: (+ (get total-withdrawals vault) stx-amount),
          last-updated: burn-block-height
        })
      )
      
      ;; Update protocol metrics
      (var-set total-tvl (- (var-get total-tvl) stx-amount))
      (var-set protocol-balance (+ (var-get protocol-balance) withdrawal-fee))
      
      (ok { stx-received: net-stx, fee-paid: withdrawal-fee })
    )
  )
)

;; Claim Rewards (simulated APY)
(define-public (claim-rewards (vault-id uint))
  (let
    (
      (position (unwrap! (map-get? user-positions { user: tx-sender, vault-id: vault-id }) (err u2004)))
      (blocks-staked (- burn-block-height (get last-claim position)))
      (apy (var-get average-apy))
      (reward (/ (* (get gene-balance position) apy blocks-staked) u52560000)) ;; Annual divisor
    )
    (begin
      (asserts! (> blocks-staked u0) (err u2006))
      
      ;; Mint reward tokens
      (try! (ft-mint? GENE reward tx-sender))
      
      ;; Update position
      (map-set user-positions
        { user: tx-sender, vault-id: vault-id }
        (merge position {
          last-claim: burn-block-height
        })
      )
      
      (ok { reward-amount: reward })
    )
  )
)

;; Get user balance
(define-read-only (get-balance (user principal) (vault-id uint))
  (match (map-get? user-positions { user: user, vault-id: vault-id })
    position (ok (get gene-balance position))
    (err u2004)
  )
)

;; Get vault info
(define-read-only (get-vault-info (vault-id uint))
  (match (map-get? vault-state { vault-id: vault-id })
    vault (ok vault)
    (err u2001)
  )
)

;; Get total TVL
(define-read-only (get-tvl)
  (ok (var-get total-tvl))
)

;; Get protocol balance
(define-read-only (get-protocol-balance)
  (ok (var-get protocol-balance))
)

;; Update APY (owner only)
(define-public (update-apy (new-apy uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) (err u1001))
    (asserts! (<= new-apy u10000) (err u2007)) ;; Max 100% APY
    (var-set average-apy new-apy)
    (ok true)
  )
)

;; Close vault emergency
(define-public (close-vault (vault-id uint))
  (let
    (
      (vault (unwrap! (map-get? vault-state { vault-id: vault-id }) (err u2001)))
    )
    (begin
      (asserts! (is-eq tx-sender CONTRACT-OWNER) (err u1001))
      (map-set vault-state
        { vault-id: vault-id }
        (merge vault { status: VAULT-CLOSED })
      )
      (ok true)
    )
  )
)

;; Error Codes:
;; 1001: Unauthorized (not owner)
;; 1002: Unauthorized (create vault)
;; 2001: Vault not found
;; 2002: Deposit below minimum
;; 2003: Vault is closed
;; 2004: Position not found
;; 2005: Insufficient balance
;; 2006: No rewards to claim
;; 2007: APY exceeds maximum