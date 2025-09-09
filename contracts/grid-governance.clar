
;; Grid Governance Smart Contract
;; Facilitates democratic decision-making for renewable energy grid operations
;; Manages proposals, voting, and community governance processes

;; Constants
(define-constant ERR-NOT-AUTHORIZED (err u200))
(define-constant ERR-PROPOSAL-NOT-FOUND (err u201))
(define-constant ERR-VOTING-ENDED (err u202))
(define-constant ERR-ALREADY-VOTED (err u203))
(define-constant ERR-INSUFFICIENT-VOTING-POWER (err u204))
(define-constant ERR-PROPOSAL-NOT-ACTIVE (err u205))
(define-constant ERR-QUORUM-NOT-MET (err u206))
(define-constant ERR-INVALID-VOTING-PERIOD (err u207))
(define-constant ERR-PROPOSAL-EXISTS (err u208))
(define-constant ERR-EXECUTION-FAILED (err u209))
(define-constant ERR-GOVERNANCE-PAUSED (err u210))
(define-constant ERR-INVALID-THRESHOLD (err u211))
(define-constant ERR-DELEGATION-INVALID (err u212))

(define-constant CONTRACT-OWNER tx-sender)
(define-constant MIN-VOTING-PERIOD u1008) ;; 1 week in blocks
(define-constant MAX-VOTING-PERIOD u5040) ;; 5 weeks in blocks
(define-constant DEFAULT-QUORUM u30) ;; 30%
(define-constant PROPOSAL-THRESHOLD u5) ;; 5% of total voting power needed
(define-constant MAX-PROPOSALS u1000)
(define-constant EXECUTION-DELAY u144) ;; 1 day delay after voting ends

;; Data Variables
(define-data-var proposal-counter uint u0)
(define-data-var total-voting-power uint u0)
(define-data-var governance-paused bool false)
(define-data-var quorum-threshold uint DEFAULT-QUORUM)
(define-data-var voting-period-default uint MIN-VOTING-PERIOD)
(define-data-var executed-proposals uint u0)

;; Data Maps
(define-map proposals
  { proposal-id: uint }
  {
    title: (string-utf8 200),
    description: (string-utf8 1000),
    proposer: principal,
    proposal-type: (string-ascii 30), ;; "infrastructure", "budget", "governance", "emergency"
    funding-amount: uint,
    target-asset: (optional uint), ;; Asset ID if applicable
    created-at: uint,
    voting-starts: uint,
    voting-ends: uint,
    status: (string-ascii 15), ;; "active", "passed", "failed", "executed", "cancelled"
    votes-for: uint,
    votes-against: uint,
    total-votes: uint,
    execution-time: (optional uint)
  }
)

(define-map proposal-votes
  { proposal-id: uint, voter: principal }
  {
    vote: bool, ;; true for yes, false for no
    voting-power: uint,
    vote-time: uint,
    delegated: bool
  }
)

(define-map governance-parameters
  { parameter: (string-ascii 30) }
  {
    value: uint,
    last-updated: uint,
    updated-by: principal
  }
)

(define-map voter-delegations
  { delegator: principal }
  {
    delegate: principal,
    delegated-power: uint,
    delegation-time: uint,
    active: bool
  }
)

(define-map voting-history
  { voter: principal }
  {
    proposals-voted: uint,
    total-voting-power-used: uint,
    last-vote-time: uint,
    participation-rate: uint
  }
)

(define-map proposal-results
  { proposal-id: uint }
  {
    final-vote-count: uint,
    participation-rate: uint,
    margin-of-victory: uint,
    execution-status: (string-ascii 20),
    impact-assessment: (optional (string-utf8 500))
  }
)

(define-map community-metrics
  { metric: (string-ascii 30) }
  {
    current-value: uint,
    previous-value: uint,
    trend: (string-ascii 10), ;; "increasing", "decreasing", "stable"
    last-updated: uint
  }
)

;; Public Functions

;; Create new governance proposal
(define-public (create-proposal (title (string-utf8 200)) (description (string-utf8 1000)) (proposal-type (string-ascii 30)) (funding-amount uint) (target-asset (optional uint)) (voting-period uint))
  (begin
    (asserts! (not (var-get governance-paused)) ERR-GOVERNANCE-PAUSED)
    (asserts! (>= voting-period MIN-VOTING-PERIOD) ERR-INVALID-VOTING-PERIOD)
    (asserts! (<= voting-period MAX-VOTING-PERIOD) ERR-INVALID-VOTING-PERIOD)
    (asserts! (< (var-get proposal-counter) MAX-PROPOSALS) ERR-PROPOSAL-EXISTS)
    
    (let (
      (proposal-id (+ (var-get proposal-counter) u1))
      (voting-starts (+ block-height u144)) ;; 1 day delay before voting starts
      (voting-ends (+ voting-starts voting-period))
      (required-power (/ (* (var-get total-voting-power) PROPOSAL-THRESHOLD) u100))
    )
      ;; Check if proposer has sufficient voting power (implement via external check)
      (asserts! (> required-power u0) ERR-INSUFFICIENT-VOTING-POWER)
      
      (map-set proposals
        { proposal-id: proposal-id }
        {
          title: title,
          description: description,
          proposer: tx-sender,
          proposal-type: proposal-type,
          funding-amount: funding-amount,
          target-asset: target-asset,
          created-at: block-height,
          voting-starts: voting-starts,
          voting-ends: voting-ends,
          status: "active",
          votes-for: u0,
          votes-against: u0,
          total-votes: u0,
          execution-time: none
        }
      )
      
      (var-set proposal-counter proposal-id)
      (ok proposal-id)
    )
  )
)

;; Cast vote on active proposal
(define-public (cast-vote (proposal-id uint) (vote bool) (voting-power uint))
  (begin
    (asserts! (not (var-get governance-paused)) ERR-GOVERNANCE-PAUSED)
    
    (let (
      (proposal-data (unwrap! (map-get? proposals { proposal-id: proposal-id }) ERR-PROPOSAL-NOT-FOUND))
      (existing-vote (map-get? proposal-votes { proposal-id: proposal-id, voter: tx-sender }))
    )
      (asserts! (is-eq (get status proposal-data) "active") ERR-PROPOSAL-NOT-ACTIVE)
      (asserts! (>= block-height (get voting-starts proposal-data)) ERR-VOTING-ENDED)
      (asserts! (< block-height (get voting-ends proposal-data)) ERR-VOTING-ENDED)
      (asserts! (is-none existing-vote) ERR-ALREADY-VOTED)
      (asserts! (> voting-power u0) ERR-INSUFFICIENT-VOTING-POWER)
      
      ;; Record vote
      (map-set proposal-votes
        { proposal-id: proposal-id, voter: tx-sender }
        {
          vote: vote,
          voting-power: voting-power,
          vote-time: block-height,
          delegated: false
        }
      )
      
      ;; Update proposal vote counts
      (map-set proposals
        { proposal-id: proposal-id }
        (merge proposal-data {
          votes-for: (if vote (+ (get votes-for proposal-data) voting-power) (get votes-for proposal-data)),
          votes-against: (if vote (get votes-against proposal-data) (+ (get votes-against proposal-data) voting-power)),
          total-votes: (+ (get total-votes proposal-data) voting-power)
        })
      )
      
      ;; Update voter history
      (let (
        (current-history (default-to
          { proposals-voted: u0, total-voting-power-used: u0, last-vote-time: u0, participation-rate: u0 }
          (map-get? voting-history { voter: tx-sender })
        ))
      )
        (map-set voting-history
          { voter: tx-sender }
          {
            proposals-voted: (+ (get proposals-voted current-history) u1),
            total-voting-power-used: (+ (get total-voting-power-used current-history) voting-power),
            last-vote-time: block-height,
            participation-rate: (/ (* (+ (get proposals-voted current-history) u1) u100) (var-get proposal-counter))
          }
        )
      )
      
      (ok voting-power)
    )
  )
)

;; Execute approved proposal
(define-public (execute-proposal (proposal-id uint))
  (begin
    (let (
      (proposal-data (unwrap! (map-get? proposals { proposal-id: proposal-id }) ERR-PROPOSAL-NOT-FOUND))
      (votes-for (get votes-for proposal-data))
      (votes-against (get votes-against proposal-data))
      (total-votes (get total-votes proposal-data))
      (required-quorum (/ (* (var-get total-voting-power) (var-get quorum-threshold)) u100))
    )
      (asserts! (is-eq (get status proposal-data) "active") ERR-PROPOSAL-NOT-ACTIVE)
      (asserts! (> block-height (get voting-ends proposal-data)) ERR-VOTING-ENDED)
      (asserts! (>= block-height (+ (get voting-ends proposal-data) EXECUTION-DELAY)) ERR-VOTING-ENDED)
      (asserts! (>= total-votes required-quorum) ERR-QUORUM-NOT-MET)
      
      (let (
        (proposal-passed (> votes-for votes-against))
        (new-status (if proposal-passed "passed" "failed"))
      )
        ;; Update proposal status
        (map-set proposals
          { proposal-id: proposal-id }
          (merge proposal-data {
            status: (if proposal-passed "executed" "failed"),
            execution-time: (some block-height)
          })
        )
        
        ;; Record proposal results
        (map-set proposal-results
          { proposal-id: proposal-id }
          {
            final-vote-count: total-votes,
            participation-rate: (/ (* total-votes u100) (var-get total-voting-power)),
            margin-of-victory: (if (> votes-for votes-against) (- votes-for votes-against) (- votes-against votes-for)),
            execution-status: (if proposal-passed "executed" "rejected"),
            impact-assessment: none
          }
        )
        
        (if proposal-passed
          (var-set executed-proposals (+ (var-get executed-proposals) u1))
          true
        )
        
        (ok { passed: proposal-passed, votes-for: votes-for, votes-against: votes-against })
      )
    )
  )
)

;; Delegate voting power to another community member
(define-public (delegate-voting-power (delegate principal) (power-amount uint))
  (begin
    (asserts! (not (is-eq tx-sender delegate)) ERR-DELEGATION-INVALID)
    (asserts! (> power-amount u0) ERR-INSUFFICIENT-VOTING-POWER)
    
    (map-set voter-delegations
      { delegator: tx-sender }
      {
        delegate: delegate,
        delegated-power: power-amount,
        delegation-time: block-height,
        active: true
      }
    )
    
    (ok true)
  )
)

;; Vote on behalf of delegators
(define-public (vote-with-delegation (proposal-id uint) (vote bool) (delegator-list (list 20 principal)))
  (begin
    (asserts! (not (var-get governance-paused)) ERR-GOVERNANCE-PAUSED)
    
    (let (
      (proposal-data (unwrap! (map-get? proposals { proposal-id: proposal-id }) ERR-PROPOSAL-NOT-FOUND))
    )
      (asserts! (is-eq (get status proposal-data) "active") ERR-PROPOSAL-NOT-ACTIVE)
      (asserts! (>= block-height (get voting-starts proposal-data)) ERR-VOTING-ENDED)
      (asserts! (< block-height (get voting-ends proposal-data)) ERR-VOTING-ENDED)
      
      ;; Process delegated votes (simplified - would need proper validation)
      (let (
        (total-delegated-power (fold process-delegated-vote delegator-list u0))
      )
        (map-set proposal-votes
          { proposal-id: proposal-id, voter: tx-sender }
          {
            vote: vote,
            voting-power: total-delegated-power,
            vote-time: block-height,
            delegated: true
          }
        )
        
        (ok total-delegated-power)
      )
    )
  )
)

;; Update governance parameters
(define-public (update-governance-parameter (parameter (string-ascii 30)) (new-value uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    
    (map-set governance-parameters
      { parameter: parameter }
      {
        value: new-value,
        last-updated: block-height,
        updated-by: tx-sender
      }
    )
    
    ;; Update relevant system variables
    (if (is-eq parameter "quorum")
      (var-set quorum-threshold new-value)
      (if (is-eq parameter "voting-period")
        (var-set voting-period-default new-value)
        true
      )
    )
    
    (ok true)
  )
)

;; Emergency pause governance
(define-public (emergency-pause)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set governance-paused true)
    (ok true)
  )
)

;; Resume governance operations
(define-public (resume-governance)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set governance-paused false)
    (ok true)
  )
)

;; Update total voting power (called by energy shares contract)
(define-public (update-total-voting-power (new-total uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set total-voting-power new-total)
    (ok true)
  )
)

;; Cancel active proposal (owner only)
(define-public (cancel-proposal (proposal-id uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    
    (let (
      (proposal-data (unwrap! (map-get? proposals { proposal-id: proposal-id }) ERR-PROPOSAL-NOT-FOUND))
    )
      (asserts! (is-eq (get status proposal-data) "active") ERR-PROPOSAL-NOT-ACTIVE)
      
      (map-set proposals
        { proposal-id: proposal-id }
        (merge proposal-data { status: "cancelled" })
      )
      
      (ok true)
    )
  )
)

;; Private helper function for delegation processing
(define-private (process-delegated-vote (delegator principal) (accumulated-power uint))
  (let (
    (delegation (map-get? voter-delegations { delegator: delegator }))
  )
    (if (and (is-some delegation) (get active (unwrap-panic delegation)))
      (+ accumulated-power (get delegated-power (unwrap-panic delegation)))
      accumulated-power
    )
  )
)

;; Read-only functions

;; Get proposal information
(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals { proposal-id: proposal-id })
)

;; Get vote information
(define-read-only (get-vote (proposal-id uint) (voter principal))
  (map-get? proposal-votes { proposal-id: proposal-id, voter: voter })
)

;; Get voter history
(define-read-only (get-voter-history (voter principal))
  (map-get? voting-history { voter: voter })
)

;; Get governance parameter
(define-read-only (get-governance-parameter (parameter (string-ascii 30)))
  (map-get? governance-parameters { parameter: parameter })
)

;; Get proposal results
(define-read-only (get-proposal-results (proposal-id uint))
  (map-get? proposal-results { proposal-id: proposal-id })
)

;; Get delegation information
(define-read-only (get-delegation (delegator principal))
  (map-get? voter-delegations { delegator: delegator })
)

;; Get total proposals created
(define-read-only (get-total-proposals)
  (var-get proposal-counter)
)

;; Get total voting power
(define-read-only (get-total-voting-power)
  (var-get total-voting-power)
)

;; Get current quorum threshold
(define-read-only (get-quorum-threshold)
  (var-get quorum-threshold)
)

;; Check if governance is paused
(define-read-only (is-governance-paused)
  (var-get governance-paused)
)

;; Get executed proposals count
(define-read-only (get-executed-proposals)
  (var-get executed-proposals)
)

;; Calculate voting power for specific proposal
(define-read-only (calculate-voting-power (voter principal) (proposal-id uint))
  (let (
    (proposal-data (unwrap! (map-get? proposals { proposal-id: proposal-id }) (err u0)))
    (delegation (map-get? voter-delegations { delegator: voter }))
  )
    ;; Would integrate with energy shares contract to get actual voting power
    (ok u100) ;; Placeholder return
  )
)

;; Check if proposal meets quorum
(define-read-only (check-quorum (proposal-id uint))
  (let (
    (proposal-data (unwrap! (map-get? proposals { proposal-id: proposal-id }) (err false)))
    (required-quorum (/ (* (var-get total-voting-power) (var-get quorum-threshold)) u100))
  )
    (ok (>= (get total-votes proposal-data) required-quorum))
  )
)

