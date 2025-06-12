;; Alert Generation Contract
;; Generates real-time alerts based on detected events

(define-constant ERR_UNAUTHORIZED (err u400))
(define-constant ERR_ALERT_NOT_FOUND (err u401))
(define-constant ERR_INVALID_PRIORITY (err u402))

;; Data structures
(define-map alert-configs
  { config-id: uint }
  {
    name: (string-ascii 50),
    event-rule-id: uint,
    priority: (string-ascii 20), ;; "low", "medium", "high", "critical"
    notification-type: (string-ascii 30), ;; "email", "sms", "webhook"
    active: bool,
    owner: principal,
    created-at: uint
  }
)

(define-map generated-alerts
  { alert-id: uint }
  {
    config-id: uint,
    event-id: uint,
    message: (string-ascii 200),
    priority: (string-ascii 20),
    status: (string-ascii 20), ;; "pending", "sent", "failed"
    generated-at: uint,
    sent-at: uint
  }
)

(define-data-var config-counter uint u0)
(define-data-var alert-counter uint u0)

;; Create alert configuration
(define-public (create-alert-config
  (name (string-ascii 50))
  (event-rule-id uint)
  (priority (string-ascii 20))
  (notification-type (string-ascii 30))
)
  (let ((config-id (+ (var-get config-counter) u1)))
    (map-set alert-configs
      { config-id: config-id }
      {
        name: name,
        event-rule-id: event-rule-id,
        priority: priority,
        notification-type: notification-type,
        active: true,
        owner: tx-sender,
        created-at: block-height
      }
    )
    (var-set config-counter config-id)
    (ok config-id)
  )
)

;; Generate alert
(define-public (generate-alert
  (config-id uint)
  (event-id uint)
  (message (string-ascii 200))
)
  (match (map-get? alert-configs { config-id: config-id })
    config-data
    (begin
      (asserts! (get active config-data) ERR_UNAUTHORIZED)
      (let ((alert-id (+ (var-get alert-counter) u1)))
        (map-set generated-alerts
          { alert-id: alert-id }
          {
            config-id: config-id,
            event-id: event-id,
            message: message,
            priority: (get priority config-data),
            status: "pending",
            generated-at: block-height,
            sent-at: u0
          }
        )
        (var-set alert-counter alert-id)
        (ok alert-id)
      )
    )
    ERR_ALERT_NOT_FOUND
  )
)

;; Update alert status
(define-public (update-alert-status (alert-id uint) (status (string-ascii 20)))
  (match (map-get? generated-alerts { alert-id: alert-id })
    alert-data
    (begin
      (map-set generated-alerts
        { alert-id: alert-id }
        (merge alert-data {
          status: status,
          sent-at: (if (is-eq status "sent") block-height (get sent-at alert-data))
        })
      )
      (ok true)
    )
    ERR_ALERT_NOT_FOUND
  )
)

;; Get alert config
(define-read-only (get-alert-config (config-id uint))
  (map-get? alert-configs { config-id: config-id })
)

;; Get generated alert
(define-read-only (get-generated-alert (alert-id uint))
  (map-get? generated-alerts { alert-id: alert-id })
)

;; Toggle alert config
(define-public (toggle-alert-config (config-id uint))
  (match (map-get? alert-configs { config-id: config-id })
    config-data
    (begin
      (asserts! (is-eq (get owner config-data) tx-sender) ERR_UNAUTHORIZED)
      (map-set alert-configs
        { config-id: config-id }
        (merge config-data { active: (not (get active config-data)) })
      )
      (ok (not (get active config-data)))
    )
    ERR_ALERT_NOT_FOUND
  )
)
