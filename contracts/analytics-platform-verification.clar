;; Analytics Platform Verification Contract
;; Validates real-time analytics platforms

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_PLATFORM_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_VERIFIED (err u102))

;; Data structures
(define-map verified-platforms
  { platform-id: uint }
  {
    name: (string-ascii 50),
    owner: principal,
    verified: bool,
    verification-timestamp: uint,
    trust-score: uint
  }
)

(define-data-var platform-counter uint u0)

;; Register a new analytics platform
(define-public (register-platform (name (string-ascii 50)))
  (let ((platform-id (+ (var-get platform-counter) u1)))
    (map-set verified-platforms
      { platform-id: platform-id }
      {
        name: name,
        owner: tx-sender,
        verified: false,
        verification-timestamp: u0,
        trust-score: u0
      }
    )
    (var-set platform-counter platform-id)
    (ok platform-id)
  )
)

;; Verify a platform (only contract owner)
(define-public (verify-platform (platform-id uint) (trust-score uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (match (map-get? verified-platforms { platform-id: platform-id })
      platform-data
      (begin
        (asserts! (not (get verified platform-data)) ERR_ALREADY_VERIFIED)
        (map-set verified-platforms
          { platform-id: platform-id }
          (merge platform-data {
            verified: true,
            verification-timestamp: block-height,
            trust-score: trust-score
          })
        )
        (ok true)
      )
      ERR_PLATFORM_NOT_FOUND
    )
  )
)

;; Get platform info
(define-read-only (get-platform-info (platform-id uint))
  (map-get? verified-platforms { platform-id: platform-id })
)

;; Check if platform is verified
(define-read-only (is-platform-verified (platform-id uint))
  (match (map-get? verified-platforms { platform-id: platform-id })
    platform-data (get verified platform-data)
    false
  )
)
