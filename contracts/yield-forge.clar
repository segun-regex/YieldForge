;; Title: 
;; YieldForge: Stacks L2 Yield Aggregator Protocol
;; Summary:
;; A non-custodial multi-protocol yield optimization engine with Bitcoin settlement compliance,
;; featuring dynamic APY strategies, SIP-010 token support, and institutional-grade security controls

;; Description:
;; YieldForge is a decentralized yield aggregation protocol built on Stacks Layer 2 that enables
;; trustless capital deployment across multiple DeFi strategies while maintaining Bitcoin network
;; compliance. The protocol features:
;;
;; - Multi-strategy allocation with real-time APY optimization
;; - SIP-010 token standard support for seamless Stacks ecosystem integration
;; - Military-grade security model with formal verification
;; - Autonomous treasury management with yield-bearing positions
;; - Compliant Bitcoin settlement finality for all transactions
;; - Dynamic rate limiting and anti-flashloan protections
;; - Institutional liquidity management tools (min/max deposits, emergency shutdown)
;;
;; The contract implements a novel Proof-of-Yield mechanism through:
;; 1. Protocol registry with APY-based weight calculations
;; 2. Compound-aware reward distribution algorithm
;; 3. TVL-controlled strategy rebalancing
;; 4. Non-custodial architecture with cryptographic proof of reserves
;; 5. Bitcoin-native security guarantees through Stacks L2 consensus
;;
;; Designed for both retail participants and enterprise vaults, YieldForge combines Clarity's
;; inherent security with sophisticated yield engineering, creating a new standard for trust-minimized
;; decentralized finance on Bitcoin-related ecosystems.

;; Constants
(define-constant contract-owner tx-sender)

;; Error Codes
(define-constant ERR-NOT-AUTHORIZED (err u1000))
(define-constant ERR-INVALID-AMOUNT (err u1001))
(define-constant ERR-INSUFFICIENT-BALANCE (err u1002))
(define-constant ERR-PROTOCOL-NOT-WHITELISTED (err u1003))
(define-constant ERR-STRATEGY-DISABLED (err u1004))
(define-constant ERR-MAX-DEPOSIT-REACHED (err u1005))
(define-constant ERR-MIN-DEPOSIT-NOT-MET (err u1006))
(define-constant ERR-INVALID-PROTOCOL-ID (err u1007))
(define-constant ERR-PROTOCOL-EXISTS (err u1008))
(define-constant ERR-INVALID-APY (err u1009))
(define-constant ERR-INVALID-NAME (err u1010))
(define-constant ERR-INVALID-TOKEN (err u1011))
(define-constant ERR-TOKEN-NOT-WHITELISTED (err u1012))
(define-constant ERR-ZERO-AMOUNT (err u1013))
(define-constant ERR-INVALID-USER (err u1014))
(define-constant ERR-ALREADY-WHITELISTED (err u1015))
(define-constant ERR-AMOUNT-TOO-LARGE (err u1016))
(define-constant ERR-INVALID-STATE (err u1017))
(define-constant ERR-RATE-LIMITED (err u1018))

;; Protocol Constants
(define-constant PROTOCOL-ACTIVE true)
(define-constant PROTOCOL-INACTIVE false)
(define-constant MAX-PROTOCOL-ID u100)
(define-constant MAX-APY u10000)
(define-constant MIN-APY u0)
(define-constant MAX-TOKEN-TRANSFER u1000000000000)

;; State Variables
(define-data-var total-tvl uint u0)
(define-data-var platform-fee-rate uint u100)
(define-data-var min-deposit uint u100000)
(define-data-var max-deposit uint u1000000000)
(define-data-var emergency-shutdown bool false)

;; Data Maps
(define-map user-deposits 
	{ user: principal } 
	{ amount: uint, last-deposit-block: uint })

(define-map user-rewards 
    { user: principal } 
    { pending: uint, claimed: uint })

(define-map protocols 
    { protocol-id: uint } 
    { name: (string-ascii 64), active: bool, apy: uint })

(define-map strategy-allocations 
    { protocol-id: uint } 
    { allocation: uint })

(define-map whitelisted-tokens 
    { token: principal } 
    { approved: bool })

(define-map user-operations 
    { user: principal }
    { last-operation: uint, count: uint })

;; SIP-010 Token Interface
(define-trait sip-010-trait
    (
        (transfer (uint principal principal (optional (buff 34))) (response bool uint))
        (get-balance (principal) (response uint uint))
        (get-decimals () (response uint uint))
        (get-name () (response (string-ascii 32) uint))
        (get-symbol () (response (string-ascii 32) uint))
        (get-total-supply () (response uint uint))
    )
)

;; Authorization Functions
(define-private (is-contract-owner)
    (is-eq tx-sender contract-owner)
)

;; Validation Functions
(define-private (is-valid-protocol-id (protocol-id uint))
    (and 
        (> protocol-id u0)
        (<= protocol-id MAX-PROTOCOL-ID)
    )
)