
;; title: credit-union
;; version: 1.0.0
;; summary: Decentralized Credit Union Management Contract
;; description: A comprehensive smart contract for managing a decentralized credit union
;;             with member ownership, democratic governance, profit sharing, community lending,
;;             member services, and regulatory compliance features.

;; constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u401))
(define-constant ERR_MEMBER_NOT_FOUND (err u404))
(define-constant ERR_INSUFFICIENT_FUNDS (err u402))
(define-constant ERR_LOAN_NOT_FOUND (err u405))
(define-constant ERR_PROPOSAL_NOT_FOUND (err u406))
(define-constant ERR_ALREADY_VOTED (err u407))
(define-constant ERR_VOTING_ENDED (err u408))
(define-constant ERR_INVALID_AMOUNT (err u409))
(define-constant ERR_LOAN_ALREADY_APPROVED (err u410))
(define-constant ERR_COMPLIANCE_VIOLATION (err u411))
(define-constant MIN_MEMBER_DEPOSIT u100) ;; Minimum deposit to become a member
(define-constant LOAN_APPROVAL_THRESHOLD u51) ;; 51% voting threshold for loan approval
(define-constant PROPOSAL_VOTING_PERIOD u144) ;; ~24 hours in blocks (assuming 10 min blocks)

;; data vars
(define-data-var total-members uint u0)
(define-data-var total-funds uint u0)
(define-data-var total-loans-outstanding uint u0)
(define-data-var next-loan-id uint u1)
(define-data-var next-proposal-id uint u1)
(define-data-var annual-profit uint u0)
(define-data-var compliance-officer principal CONTRACT_OWNER)

;; data maps
;; Member ownership and registration
(define-map members principal {
  share-balance: uint,
  join-date: uint,
  is-active: bool,
  voting-power: uint,
  total-dividends-earned: uint
})

;; Community lending system
(define-map loans uint {
  borrower: principal,
  amount: uint,
  interest-rate: uint, ;; basis points (e.g., 500 = 5%)
  term-blocks: uint,
  issued-at: uint,
  due-at: uint,
  amount-repaid: uint,
  is-approved: bool,
  is-active: bool,
  collateral-amount: uint
})

;; Democratic governance system
(define-map proposals uint {
  proposer: principal,
  title: (string-ascii 100),
  description: (string-ascii 500),
  proposal-type: (string-ascii 20), ;; "loan", "policy", "budget", etc.
  target-loan-id: (optional uint),
  created-at: uint,
  voting-ends-at: uint,
  votes-for: uint,
  votes-against: uint,
  is-executed: bool
})

(define-map proposal-votes { proposal-id: uint, voter: principal } bool)

;; Member services and benefits
(define-map member-services principal {
  financial-counseling: bool,
  insurance-access: bool,
  educational-programs: bool,
  emergency-assistance: bool,
  business-development: bool
})

;; Regulatory compliance tracking
(define-map compliance-logs uint {
  event-type: (string-ascii 50),
  member: (optional principal),
  amount: (optional uint),
  timestamp: uint,
  details: (string-ascii 200)
})

(define-data-var next-compliance-log-id uint u1)

;; Profit sharing tracking
(define-map annual-dividends uint {
  total-profit: uint,
  total-members: uint,
  dividend-per-share: uint,
  distribution-date: uint
})

;; public functions

;; Member registration and ownership
(define-public (register-member (initial-deposit uint))
  (let (
    (sender tx-sender)
    (current-block block-height)
  )
    (asserts! (>= initial-deposit MIN_MEMBER_DEPOSIT) ERR_INVALID_AMOUNT)
    (asserts! (is-none (map-get? members sender)) ERR_NOT_AUTHORIZED)
    
    ;; Add member to registry
    (map-set members sender {
      share-balance: initial-deposit,
      join-date: current-block,
      is-active: true,
      voting-power: initial-deposit,
      total-dividends-earned: u0
    })
    
    ;; Update totals
    (var-set total-members (+ (var-get total-members) u1))
    (var-set total-funds (+ (var-get total-funds) initial-deposit))
    
    ;; Log compliance event
    (unwrap-panic (log-compliance-event "MEMBER_REGISTRATION" (some sender) (some initial-deposit) "New member registered"))
    
    (ok true)
  )
)

;; Democratic governance - Create proposal
(define-public (create-proposal (title (string-ascii 100)) (description (string-ascii 500)) (proposal-type (string-ascii 20)) (target-loan-id (optional uint)))
  (let (
    (sender tx-sender)
    (proposal-id (var-get next-proposal-id))
    (current-block block-height)
    (voting-ends-at (+ current-block PROPOSAL_VOTING_PERIOD))
  )
    (asserts! (is-member sender) ERR_NOT_AUTHORIZED)
    
    (map-set proposals proposal-id {
      proposer: sender,
      title: title,
      description: description,
      proposal-type: proposal-type,
      target-loan-id: target-loan-id,
      created-at: current-block,
      voting-ends-at: voting-ends-at,
      votes-for: u0,
      votes-against: u0,
      is-executed: false
    })
    
    (var-set next-proposal-id (+ proposal-id u1))
    (unwrap-panic (log-compliance-event "PROPOSAL_CREATED" (some sender) none "New governance proposal created"))
    
    (ok proposal-id)
  )
)

;; Democratic governance - Vote on proposal
(define-public (vote-on-proposal (proposal-id uint) (vote-for bool))
  (let (
    (sender tx-sender)
    (proposal (unwrap! (map-get? proposals proposal-id) ERR_PROPOSAL_NOT_FOUND))
    (member-data (unwrap! (map-get? members sender) ERR_MEMBER_NOT_FOUND))
    (vote-key { proposal-id: proposal-id, voter: sender })
    (voting-power (get voting-power member-data))
  )
    (asserts! (< block-height (get voting-ends-at proposal)) ERR_VOTING_ENDED)
    (asserts! (is-none (map-get? proposal-votes vote-key)) ERR_ALREADY_VOTED)
    
    ;; Record vote
    (map-set proposal-votes vote-key vote-for)
    
    ;; Update proposal vote counts
    (if vote-for
      (map-set proposals proposal-id (merge proposal { votes-for: (+ (get votes-for proposal) voting-power) }))
      (map-set proposals proposal-id (merge proposal { votes-against: (+ (get votes-against proposal) voting-power) }))
    )
    
    (unwrap-panic (log-compliance-event "VOTE_CAST" (some sender) (some voting-power) "Vote cast on proposal"))
    
    (ok true)
  )
)

;; Community lending - Request loan
(define-public (request-loan (amount uint) (interest-rate uint) (term-blocks uint) (collateral-amount uint))
  (let (
    (sender tx-sender)
    (loan-id (var-get next-loan-id))
    (current-block block-height)
    (due-at (+ current-block term-blocks))
  )
    (asserts! (is-member sender) ERR_MEMBER_NOT_FOUND)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (>= collateral-amount (/ (* amount u120) u100)) ERR_INVALID_AMOUNT) ;; 120% collateral requirement
    
    (map-set loans loan-id {
      borrower: sender,
      amount: amount,
      interest-rate: interest-rate,
      term-blocks: term-blocks,
      issued-at: current-block,
      due-at: due-at,
      amount-repaid: u0,
      is-approved: false,
      is-active: false,
      collateral-amount: collateral-amount
    })
    
    (var-set next-loan-id (+ loan-id u1))
    (unwrap-panic (log-compliance-event "LOAN_REQUESTED" (some sender) (some amount) "New loan request submitted"))
    
    (ok loan-id)
  )
)

;; Community lending - Approve loan (requires governance proposal)
(define-public (approve-loan (loan-id uint) (proposal-id uint))
  (let (
    (loan (unwrap! (map-get? loans loan-id) ERR_LOAN_NOT_FOUND))
    (proposal (unwrap! (map-get? proposals proposal-id) ERR_PROPOSAL_NOT_FOUND))
    (total-votes (+ (get votes-for proposal) (get votes-against proposal)))
    (approval-threshold (/ (* (var-get total-members) LOAN_APPROVAL_THRESHOLD) u100))
  )
    (asserts! (>= block-height (get voting-ends-at proposal)) ERR_VOTING_ENDED)
    (asserts! (>= (get votes-for proposal) approval-threshold) ERR_NOT_AUTHORIZED)
    (asserts! (is-eq (get proposal-type proposal) "loan") ERR_NOT_AUTHORIZED)
    (asserts! (is-eq (get target-loan-id proposal) (some loan-id)) ERR_NOT_AUTHORIZED)
    (asserts! (not (get is-approved loan)) ERR_LOAN_ALREADY_APPROVED)
    (asserts! (>= (var-get total-funds) (get amount loan)) ERR_INSUFFICIENT_FUNDS)
    
    ;; Approve and activate loan
    (map-set loans loan-id (merge loan { is-approved: true, is-active: true }))
    (var-set total-funds (- (var-get total-funds) (get amount loan)))
    (var-set total-loans-outstanding (+ (var-get total-loans-outstanding) (get amount loan)))
    
    ;; Mark proposal as executed
    (map-set proposals proposal-id (merge proposal { is-executed: true }))
    
    (unwrap-panic (log-compliance-event "LOAN_APPROVED" (some (get borrower loan)) (some (get amount loan)) "Loan approved through governance"))
    
    (ok true)
  )
)

;; Community lending - Repay loan
(define-public (repay-loan (loan-id uint) (payment-amount uint))
  (let (
    (sender tx-sender)
    (loan (unwrap! (map-get? loans loan-id) ERR_LOAN_NOT_FOUND))
    (remaining-balance (- (get amount loan) (get amount-repaid loan)))
    (interest-due (/ (* (get amount loan) (get interest-rate loan)) u10000))
    (total-due (+ remaining-balance interest-due))
  )
    (asserts! (is-eq sender (get borrower loan)) ERR_NOT_AUTHORIZED)
    (asserts! (get is-active loan) ERR_NOT_AUTHORIZED)
    (asserts! (> payment-amount u0) ERR_INVALID_AMOUNT)
    
    (let (
      (new-amount-repaid (+ (get amount-repaid loan) payment-amount))
      (is-fully-repaid (>= new-amount-repaid total-due))
    )
      ;; Update loan
      (map-set loans loan-id (merge loan { 
        amount-repaid: new-amount-repaid,
        is-active: (not is-fully-repaid)
      }))
      
      ;; Update total funds and outstanding loans
      (var-set total-funds (+ (var-get total-funds) payment-amount))
      (if is-fully-repaid
        (var-set total-loans-outstanding (- (var-get total-loans-outstanding) (get amount loan)))
        true
      )
      
      (unwrap-panic (log-compliance-event "LOAN_PAYMENT" (some sender) (some payment-amount) "Loan payment received"))
      
      (ok is-fully-repaid)
    )
  )
)

;; Profit sharing and dividend distribution
(define-public (distribute-dividends (annual-profit-amount uint))
  (let (
    (sender tx-sender)
    (current-year (/ block-height u52560)) ;; Approximate blocks per year
    (current-members (var-get total-members))
    (dividend-per-share (/ annual-profit-amount current-members))
  )
    (asserts! (is-eq sender (var-get compliance-officer)) ERR_NOT_AUTHORIZED)
    (asserts! (> annual-profit-amount u0) ERR_INVALID_AMOUNT)
    
    ;; Record annual dividend distribution
    (map-set annual-dividends current-year {
      total-profit: annual-profit-amount,
      total-members: current-members,
      dividend-per-share: dividend-per-share,
      distribution-date: block-height
    })
    
    (var-set annual-profit annual-profit-amount)
    (unwrap-panic (log-compliance-event "DIVIDEND_DISTRIBUTION" none (some annual-profit-amount) "Annual dividends distributed"))
    
    (ok dividend-per-share)
  )
)

;; Member can claim their dividend
(define-public (claim-dividend (year uint))
  (let (
    (sender tx-sender)
    (member-data (unwrap! (map-get? members sender) ERR_MEMBER_NOT_FOUND))
    (dividend-info (unwrap! (map-get? annual-dividends year) ERR_NOT_AUTHORIZED))
    (dividend-amount (get dividend-per-share dividend-info))
  )
    (asserts! (get is-active member-data) ERR_NOT_AUTHORIZED)
    
    ;; Update member's total dividends earned
    (map-set members sender (merge member-data {
      total-dividends-earned: (+ (get total-dividends-earned member-data) dividend-amount)
    }))
    
    (unwrap-panic (log-compliance-event "DIVIDEND_CLAIMED" (some sender) (some dividend-amount) "Member claimed dividend"))
    
    (ok dividend-amount)
  )
)

;; Member services management
(define-public (enroll-in-service (service-type (string-ascii 30)))
  (let (
    (sender tx-sender)
    (current-services (default-to {
      financial-counseling: false,
      insurance-access: false,
      educational-programs: false,
      emergency-assistance: false,
      business-development: false
    } (map-get? member-services sender)))
  )
    (asserts! (is-member sender) ERR_MEMBER_NOT_FOUND)
    
    ;; Update services based on type
    (let (
      (updated-services 
        (if (is-eq service-type "financial-counseling")
          (merge current-services { financial-counseling: true })
          (if (is-eq service-type "insurance-access")
            (merge current-services { insurance-access: true })
            (if (is-eq service-type "educational-programs")
              (merge current-services { educational-programs: true })
              (if (is-eq service-type "emergency-assistance")
                (merge current-services { emergency-assistance: true })
                (if (is-eq service-type "business-development")
                  (merge current-services { business-development: true })
                  current-services
                )
              )
            )
          )
        )
      )
    )
      (map-set member-services sender updated-services)
      (unwrap-panic (log-compliance-event "SERVICE_ENROLLMENT" (some sender) none "Member enrolled in service"))
      
      (ok true)
    )
  )
)

;; Add funds to the credit union (capital injection)
(define-public (add-capital (amount uint))
  (let (
    (sender tx-sender)
    (member-data (unwrap! (map-get? members sender) ERR_MEMBER_NOT_FOUND))
  )
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (get is-active member-data) ERR_NOT_AUTHORIZED)
    
    ;; Update member's share balance and voting power
    (map-set members sender (merge member-data {
      share-balance: (+ (get share-balance member-data) amount),
      voting-power: (+ (get voting-power member-data) amount)
    }))
    
    ;; Update total funds
    (var-set total-funds (+ (var-get total-funds) amount))
    
    (unwrap-panic (log-compliance-event "CAPITAL_ADDITION" (some sender) (some amount) "Member added capital"))
    
    (ok true)
  )
)

;; Compliance and regulatory functions
(define-public (update-compliance-officer (new-officer principal))
  (begin
    (asserts! (is-eq tx-sender (var-get compliance-officer)) ERR_NOT_AUTHORIZED)
    (var-set compliance-officer new-officer)
    (unwrap-panic (log-compliance-event "COMPLIANCE_OFFICER_UPDATED" (some new-officer) none "Compliance officer updated"))
    (ok true)
  )
)

(define-public (suspend-member (member principal) (reason (string-ascii 100)))
  (let (
    (sender tx-sender)
    (member-data (unwrap! (map-get? members member) ERR_MEMBER_NOT_FOUND))
  )
    (asserts! (is-eq sender (var-get compliance-officer)) ERR_NOT_AUTHORIZED)
    
    (map-set members member (merge member-data { is-active: false }))
    (unwrap-panic (log-compliance-event "MEMBER_SUSPENDED" (some member) none reason))
    
    (ok true)
  )
)

;; read only functions

(define-read-only (get-member-info (member principal))
  (map-get? members member)
)

(define-read-only (get-loan-info (loan-id uint))
  (map-get? loans loan-id)
)

(define-read-only (get-proposal-info (proposal-id uint))
  (map-get? proposals proposal-id)
)

(define-read-only (get-member-services (member principal))
  (map-get? member-services member)
)

(define-read-only (get-credit-union-stats)
  {
    total-members: (var-get total-members),
    total-funds: (var-get total-funds),
    total-loans-outstanding: (var-get total-loans-outstanding),
    annual-profit: (var-get annual-profit)
  }
)

(define-read-only (get-dividend-info (year uint))
  (map-get? annual-dividends year)
)

(define-read-only (has-voted (proposal-id uint) (voter principal))
  (is-some (map-get? proposal-votes { proposal-id: proposal-id, voter: voter }))
)

(define-read-only (calculate-loan-balance (loan-id uint))
  (match (map-get? loans loan-id)
    loan-data
      (let (
        (principal-amount (get amount loan-data))
        (interest-due (/ (* principal-amount (get interest-rate loan-data)) u10000))
        (total-due (+ principal-amount interest-due))
        (amount-repaid (get amount-repaid loan-data))
      )
        (ok (- total-due amount-repaid))
      )
    ERR_LOAN_NOT_FOUND
  )
)

;; private functions

(define-private (is-member (account principal))
  (match (map-get? members account)
    member-data (get is-active member-data)
    false
  )
)

(define-private (log-compliance-event (event-type (string-ascii 50)) (member (optional principal)) (amount (optional uint)) (details (string-ascii 200)))
  (let (
    (log-id (var-get next-compliance-log-id))
  )
    (map-set compliance-logs log-id {
      event-type: event-type,
      member: member,
      amount: amount,
      timestamp: block-height,
      details: details
    })
    
    (var-set next-compliance-log-id (+ log-id u1))
    (ok log-id)
  )
)
