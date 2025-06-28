;; Health Monitoring Contract
;; Monitors customer health scores and triggers alerts

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_CUSTOMER_NOT_FOUND (err u201))
(define-constant ERR_INVALID_SCORE (err u202))

;; Health score thresholds
(define-constant CRITICAL_THRESHOLD u30)
(define-constant WARNING_THRESHOLD u60)
(define-constant HEALTHY_THRESHOLD u80)

;; Data structures
(define-map customer-health
  { customer-id: (string-ascii 50) }
  {
    health-score: uint,
    last-updated: uint,
    trend: (string-ascii 20),
    risk-factors: (list 5 (string-ascii 30)),
    assigned-manager: principal
  }
)

(define-map health-history
  { customer-id: (string-ascii 50), timestamp: uint }
  {
    health-score: uint,
    change-reason: (string-ascii 100)
  }
)

(define-data-var total-customers uint u0)

;; Public functions
(define-public (add-customer (customer-id (string-ascii 50))
                            (initial-score uint)
                            (manager principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (<= initial-score u100) ERR_INVALID_SCORE)

    (map-set customer-health
      { customer-id: customer-id }
      {
        health-score: initial-score,
        last-updated: block-height,
        trend: "stable",
        risk-factors: (list),
        assigned-manager: manager
      }
    )

    (map-set health-history
      { customer-id: customer-id, timestamp: block-height }
      {
        health-score: initial-score,
        change-reason: "Initial assessment"
      }
    )

    (var-set total-customers (+ (var-get total-customers) u1))
    (ok true)
  )
)

(define-public (update-health-score (customer-id (string-ascii 50))
                                   (new-score uint)
                                   (change-reason (string-ascii 100))
                                   (risk-factors (list 5 (string-ascii 30))))
  (let ((customer-data (unwrap! (map-get? customer-health { customer-id: customer-id }) ERR_CUSTOMER_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (<= new-score u100) ERR_INVALID_SCORE)

    (let ((old-score (get health-score customer-data))
          (trend (if (> new-score old-score) "improving"
                    (if (< new-score old-score) "declining" "stable"))))

      (map-set customer-health
        { customer-id: customer-id }
        (merge customer-data {
          health-score: new-score,
          last-updated: block-height,
          trend: trend,
          risk-factors: risk-factors
        })
      )

      (map-set health-history
        { customer-id: customer-id, timestamp: block-height }
        {
          health-score: new-score,
          change-reason: change-reason
        }
      )

      (ok true)
    )
  )
)

;; Read-only functions
(define-read-only (get-customer-health (customer-id (string-ascii 50)))
  (map-get? customer-health { customer-id: customer-id })
)

(define-read-only (get-health-status (customer-id (string-ascii 50)))
  (match (map-get? customer-health { customer-id: customer-id })
    customer-data
      (let ((score (get health-score customer-data)))
        (if (<= score CRITICAL_THRESHOLD) "critical"
          (if (<= score WARNING_THRESHOLD) "warning"
            (if (<= score HEALTHY_THRESHOLD) "good" "excellent"))))
    "not-found"
  )
)

(define-read-only (get-at-risk-customers)
  ;; This would return a list of customers with health scores below WARNING_THRESHOLD
  ;; Implementation would require iteration capabilities
  (ok "at-risk-customers-list")
)
