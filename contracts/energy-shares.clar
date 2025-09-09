
;; Energy Shares Smart Contract
;; Tokenizes ownership of renewable energy assets for community participation
;; Manages share issuance, trading, dividends, and voting rights

;; Constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INSUFFICIENT-SHARES (err u101))
(define-constant ERR-INVALID-AMOUNT (err u102))
(define-constant ERR-ASSET-NOT-FOUND (err u103))
(define-constant ERR-TRADING-PAUSED (err u104))
(define-constant ERR-INVALID-RECIPIENT (err u105))
(define-constant ERR-DIVIDEND-NOT-AVAILABLE (err u106))
(define-constant ERR-ALREADY-CLAIMED (err u107))
(define-constant ERR-INVALID-PERIOD (err u108))
(define-constant ERR-ZERO-SHARES (err u109))
(define-constant ERR-INVALID-PRICE (err u110))
(define-constant ERR-ASSET-LIMIT-REACHED (err u111))
(define-constant ERR-DELEGATION-FAILED (err u112))

(define-constant CONTRACT-OWNER tx-sender)
(define-constant MAX-ASSETS u100)
(define-constant MIN-SHARE-PRICE u1000) ;; 0.001 STX
(define-constant DIVIDEND-PRECISION u1000000)
(define-constant MAX-DIVIDEND-RATE u70) ;; 70%

;; Data Variables
(define-data-var total-shares uint u0)
(define-data-var total-assets uint u0)
(define-data-var dividend-rate uint u65) ;; 65% default
(define-data-var trading-paused bool false)
(define-data-var total-dividends-paid uint u0)
(define-data-var share-counter uint u0)

;; Data Maps
(define-map energy-assets
  { asset-id: uint }
  {
    name: (string-utf8 100),
    asset-type: (string-ascii 20), ;; "solar", "wind", "hydro", "battery"
    capacity: uint, ;; in kWh
    installation-cost: uint,
    current-value: uint,
    annual-revenue: uint,
    shares-allocated: uint,
    status: (string-ascii 15), ;; "active", "planned", "maintenance"
    location: (string-utf8 100)
  }
)

(define-map shareholder-balances
  { holder: principal, asset-id: uint }
  {
    shares: uint,
    purchase-price: uint,
    purchase-date: uint,
    voting-power: uint,
    delegated-to: (optional principal)
  }
)

(define-map dividend-periods
  { period: uint, quarter: uint }
  {
    total-revenue: uint,
    dividend-per-share: uint,
    distribution-date: uint,
    claims-processed: uint,
    total-eligible-shares: uint
  }
)

(define-map dividend-claims
  { holder: principal, period: uint, quarter: uint }
  {
    amount-claimed: uint,
    claim-date: uint,
    shares-at-time: uint
  }
)

(define-map share-transfers
  { transfer-id: uint }
  {
    from: principal,
    to: principal,
    asset-id: uint,
    shares: uint,
    price: uint,
    transfer-date: uint,
    approved: bool
  }
)

(define-map voting-delegations
  { delegator: principal }
  {
    delegate: principal,
    asset-ids: (list 10 uint),
    delegation-date: uint,
    active: bool
  }
)

(define-map asset-performance
  { asset-id: uint, period: uint }
  {
    energy-generated: uint, ;; kWh
    revenue-earned: uint,
    maintenance-costs: uint,
    efficiency-rating: uint,
    carbon-offset: uint ;; kg CO2 equivalent
  }
)

;; Transfer counter for unique IDs
(define-data-var transfer-counter uint u0)

;; Public Functions

;; Create new energy asset for community investment
(define-public (create-energy-asset (name (string-utf8 100)) (asset-type (string-ascii 20)) (capacity uint) (installation-cost uint) (location (string-utf8 100)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (< (var-get total-assets) MAX-ASSETS) ERR-ASSET-LIMIT-REACHED)
    (asserts! (> capacity u0) ERR-INVALID-AMOUNT)
    (asserts! (> installation-cost u0) ERR-INVALID-AMOUNT)
    
    (let (
      (asset-id (+ (var-get total-assets) u1))
    )
      (map-set energy-assets
        { asset-id: asset-id }
        {
          name: name,
          asset-type: asset-type,
          capacity: capacity,
          installation-cost: installation-cost,
          current-value: installation-cost,
          annual-revenue: u0,
          shares-allocated: u0,
          status: "planned",
          location: location
        }
      )
      
      (var-set total-assets asset-id)
      (ok asset-id)
    )
  )
)

;; Issue shares for energy asset investment
(define-public (issue-shares (asset-id uint) (recipient principal) (shares uint) (price-per-share uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> shares u0) ERR-ZERO-SHARES)
    (asserts! (>= price-per-share MIN-SHARE-PRICE) ERR-INVALID-PRICE)
    
    (let (
      (asset-data (unwrap! (map-get? energy-assets { asset-id: asset-id }) ERR-ASSET-NOT-FOUND))
      (total-investment (* shares price-per-share))
      (current-balance (default-to
        { shares: u0, purchase-price: u0, purchase-date: u0, voting-power: u0, delegated-to: none }
        (map-get? shareholder-balances { holder: recipient, asset-id: asset-id })
      ))
    )
      ;; Update shareholder balance
      (map-set shareholder-balances
        { holder: recipient, asset-id: asset-id }
        {
          shares: (+ (get shares current-balance) shares),
          purchase-price: (+ (get purchase-price current-balance) total-investment),
          purchase-date: block-height,
          voting-power: (+ (get voting-power current-balance) shares),
          delegated-to: (get delegated-to current-balance)
        }
      )
      
      ;; Update asset shares allocated
      (map-set energy-assets
        { asset-id: asset-id }
        (merge asset-data {
          shares-allocated: (+ (get shares-allocated asset-data) shares)
        })
      )
      
      (var-set total-shares (+ (var-get total-shares) shares))
      (var-set share-counter (+ (var-get share-counter) u1))
      (ok shares)
    )
  )
)

;; Transfer shares between community members
(define-public (transfer-shares (asset-id uint) (recipient principal) (shares uint) (price-per-share uint))
  (begin
    (asserts! (not (var-get trading-paused)) ERR-TRADING-PAUSED)
    (asserts! (> shares u0) ERR-ZERO-SHARES)
    (asserts! (not (is-eq tx-sender recipient)) ERR-INVALID-RECIPIENT)
    
    (let (
      (sender-balance (unwrap! (map-get? shareholder-balances { holder: tx-sender, asset-id: asset-id }) ERR-INSUFFICIENT-SHARES))
      (recipient-balance (default-to
        { shares: u0, purchase-price: u0, purchase-date: u0, voting-power: u0, delegated-to: none }
        (map-get? shareholder-balances { holder: recipient, asset-id: asset-id })
      ))
      (transfer-id (+ (var-get transfer-counter) u1))
      (total-price (* shares price-per-share))
    )
      (asserts! (>= (get shares sender-balance) shares) ERR-INSUFFICIENT-SHARES)
      
      ;; Update sender balance
      (map-set shareholder-balances
        { holder: tx-sender, asset-id: asset-id }
        (merge sender-balance {
          shares: (- (get shares sender-balance) shares),
          voting-power: (- (get voting-power sender-balance) shares)
        })
      )
      
      ;; Update recipient balance
      (map-set shareholder-balances
        { holder: recipient, asset-id: asset-id }
        {
          shares: (+ (get shares recipient-balance) shares),
          purchase-price: (+ (get purchase-price recipient-balance) total-price),
          purchase-date: block-height,
          voting-power: (+ (get voting-power recipient-balance) shares),
          delegated-to: (get delegated-to recipient-balance)
        }
      )
      
      ;; Record transfer
      (map-set share-transfers
        { transfer-id: transfer-id }
        {
          from: tx-sender,
          to: recipient,
          asset-id: asset-id,
          shares: shares,
          price: price-per-share,
          transfer-date: block-height,
          approved: true
        }
      )
      
      (var-set transfer-counter transfer-id)
      (ok transfer-id)
    )
  )
)

;; Delegate voting rights to another community member
(define-public (delegate-voting (delegate principal) (asset-ids (list 10 uint)))
  (begin
    (asserts! (not (is-eq tx-sender delegate)) ERR-INVALID-RECIPIENT)
    
    (map-set voting-delegations
      { delegator: tx-sender }
      {
        delegate: delegate,
        asset-ids: asset-ids,
        delegation-date: block-height,
        active: true
      }
    )
    
    (ok true)
  )
)

;; Distribute dividends for a specific period
(define-public (distribute-dividends (period uint) (quarter uint) (total-revenue uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> total-revenue u0) ERR-INVALID-AMOUNT)
    (asserts! (<= quarter u4) ERR-INVALID-PERIOD)
    
    (let (
      (distributable-amount (/ (* total-revenue (var-get dividend-rate)) u100))
      (dividend-per-share (/ (* distributable-amount DIVIDEND-PRECISION) (var-get total-shares)))
    )
      (map-set dividend-periods
        { period: period, quarter: quarter }
        {
          total-revenue: total-revenue,
          dividend-per-share: dividend-per-share,
          distribution-date: block-height,
          claims-processed: u0,
          total-eligible-shares: (var-get total-shares)
        }
      )
      
      (ok dividend-per-share)
    )
  )
)

;; Claim dividends for specific period
(define-public (claim-dividends (asset-id uint) (period uint) (quarter uint))
  (begin
    (let (
      (dividend-period (unwrap! (map-get? dividend-periods { period: period, quarter: quarter }) ERR-DIVIDEND-NOT-AVAILABLE))
      (shareholder-data (unwrap! (map-get? shareholder-balances { holder: tx-sender, asset-id: asset-id }) ERR-INSUFFICIENT-SHARES))
      (existing-claim (map-get? dividend-claims { holder: tx-sender, period: period, quarter: quarter }))
      
      (shares-owned (get shares shareholder-data))
      (dividend-per-share (get dividend-per-share dividend-period))
      (dividend-amount (/ (* shares-owned dividend-per-share) DIVIDEND-PRECISION))
    )
      (asserts! (is-none existing-claim) ERR-ALREADY-CLAIMED)
      (asserts! (> shares-owned u0) ERR-ZERO-SHARES)
      
      ;; Record claim
      (map-set dividend-claims
        { holder: tx-sender, period: period, quarter: quarter }
        {
          amount-claimed: dividend-amount,
          claim-date: block-height,
          shares-at-time: shares-owned
        }
      )
      
      ;; Update dividend period stats
      (map-set dividend-periods
        { period: period, quarter: quarter }
        (merge dividend-period {
          claims-processed: (+ (get claims-processed dividend-period) u1)
        })
      )
      
      (var-set total-dividends-paid (+ (var-get total-dividends-paid) dividend-amount))
      (ok dividend-amount)
    )
  )
)

;; Update asset performance metrics
(define-public (update-asset-performance (asset-id uint) (period uint) (energy-generated uint) (revenue-earned uint) (maintenance-costs uint) (carbon-offset uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    
    (let (
      (efficiency-rating (if (> energy-generated u0) (/ (* revenue-earned u100) energy-generated) u0))
    )
      (map-set asset-performance
        { asset-id: asset-id, period: period }
        {
          energy-generated: energy-generated,
          revenue-earned: revenue-earned,
          maintenance-costs: maintenance-costs,
          efficiency-rating: efficiency-rating,
          carbon-offset: carbon-offset
        }
      )
      
      ;; Update asset annual revenue
      (let (
        (asset-data (unwrap! (map-get? energy-assets { asset-id: asset-id }) ERR-ASSET-NOT-FOUND))
      )
        (map-set energy-assets
          { asset-id: asset-id }
          (merge asset-data {
            annual-revenue: revenue-earned,
            status: "active"
          })
        )
      )
      
      (ok efficiency-rating)
    )
  )
)

;; Admin function to pause trading
(define-public (pause-trading)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set trading-paused true)
    (ok true)
  )
)

;; Admin function to resume trading
(define-public (resume-trading)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set trading-paused false)
    (ok true)
  )
)

;; Update dividend rate
(define-public (set-dividend-rate (new-rate uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (<= new-rate MAX-DIVIDEND-RATE) ERR-INVALID-AMOUNT)
    (var-set dividend-rate new-rate)
    (ok true)
  )
)

;; Read-only functions

;; Get energy asset information
(define-read-only (get-asset-info (asset-id uint))
  (map-get? energy-assets { asset-id: asset-id })
)

;; Get shareholder balance
(define-read-only (get-shareholder-balance (holder principal) (asset-id uint))
  (map-get? shareholder-balances { holder: holder, asset-id: asset-id })
)

;; Get dividend period information
(define-read-only (get-dividend-period (period uint) (quarter uint))
  (map-get? dividend-periods { period: period, quarter: quarter })
)

;; Get dividend claim information
(define-read-only (get-dividend-claim (holder principal) (period uint) (quarter uint))
  (map-get? dividend-claims { holder: holder, period: period, quarter: quarter })
)

;; Get asset performance data
(define-read-only (get-asset-performance (asset-id uint) (period uint))
  (map-get? asset-performance { asset-id: asset-id, period: period })
)

;; Get voting delegation info
(define-read-only (get-voting-delegation (delegator principal))
  (map-get? voting-delegations { delegator: delegator })
)

;; Get total shares issued
(define-read-only (get-total-shares)
  (var-get total-shares)
)

;; Get total assets created
(define-read-only (get-total-assets)
  (var-get total-assets)
)

;; Get current dividend rate
(define-read-only (get-dividend-rate)
  (var-get dividend-rate)
)

;; Check if trading is paused
(define-read-only (is-trading-paused)
  (var-get trading-paused)
)

;; Get total dividends paid
(define-read-only (get-total-dividends-paid)
  (var-get total-dividends-paid)
)

;; Calculate expected annual return for shareholder
(define-read-only (calculate-annual-return (holder principal) (asset-id uint))
  (let (
    (balance (unwrap! (map-get? shareholder-balances { holder: holder, asset-id: asset-id }) (err u0)))
    (asset (unwrap! (map-get? energy-assets { asset-id: asset-id }) (err u0)))
    
    (shares-owned (get shares balance))
    (total-shares-asset (get shares-allocated asset))
    (annual-revenue (get annual-revenue asset))
  )
    (if (and (> shares-owned u0) (> total-shares-asset u0))
      (ok (/ (* shares-owned annual-revenue (var-get dividend-rate)) (* total-shares-asset u100)))
      (ok u0)
    )
  )
)

