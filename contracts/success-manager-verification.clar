;; Success Manager Verification Contract
;; Validates and manages customer success managers

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_VERIFIED (err u101))
(define-constant ERR_NOT_FOUND (err u102))
(define-constant ERR_INVALID_CREDENTIALS (err u103))

;; Data structures
(define-map success-managers
  { manager-id: principal }
  {
    verified: bool,
    certification-level: uint,
    verification-date: uint,
    performance-score: uint,
    active-accounts: uint
  }
)

(define-map manager-credentials
  { manager-id: principal }
  {
    experience-years: uint,
    certifications: (list 10 (string-ascii 50)),
    specializations: (list 5 (string-ascii 30))
  }
)

(define-data-var total-managers uint u0)

;; Public functions
(define-public (register-manager (manager-id principal)
                                (experience-years uint)
                                (certifications (list 10 (string-ascii 50)))
                                (specializations (list 5 (string-ascii 30))))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-none (map-get? success-managers { manager-id: manager-id })) ERR_ALREADY_VERIFIED)

    (map-set success-managers
      { manager-id: manager-id }
      {
        verified: false,
        certification-level: u0,
        verification-date: u0,
        performance-score: u0,
        active-accounts: u0
      }
    )

    (map-set manager-credentials
      { manager-id: manager-id }
      {
        experience-years: experience-years,
        certifications: certifications,
        specializations: specializations
      }
    )

    (var-set total-managers (+ (var-get total-managers) u1))
    (ok true)
  )
)

(define-public (verify-manager (manager-id principal) (certification-level uint))
  (let ((manager-data (unwrap! (map-get? success-managers { manager-id: manager-id }) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (not (get verified manager-data)) ERR_ALREADY_VERIFIED)

    (map-set success-managers
      { manager-id: manager-id }
      (merge manager-data {
        verified: true,
        certification-level: certification-level,
        verification-date: block-height
      })
    )
    (ok true)
  )
)

(define-public (update-performance-score (manager-id principal) (score uint))
  (let ((manager-data (unwrap! (map-get? success-managers { manager-id: manager-id }) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (get verified manager-data) ERR_UNAUTHORIZED)

    (map-set success-managers
      { manager-id: manager-id }
      (merge manager-data { performance-score: score })
    )
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-manager-info (manager-id principal))
  (map-get? success-managers { manager-id: manager-id })
)

(define-read-only (get-manager-credentials (manager-id principal))
  (map-get? manager-credentials { manager-id: manager-id })
)

(define-read-only (is-verified-manager (manager-id principal))
  (match (map-get? success-managers { manager-id: manager-id })
    manager-data (get verified manager-data)
    false
  )
)

(define-read-only (get-total-managers)
  (var-get total-managers)
)
