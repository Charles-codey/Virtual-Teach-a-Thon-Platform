;; virtual-teachathon.clar
;; Virtual Teach-a-Thon session management and volunteer tracking

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-registered (err u102))
(define-constant err-session-full (err u103))
(define-constant err-not-enrolled (err u104))
(define-constant err-invalid-rating (err u105))
(define-constant err-session-inactive (err u106))
(define-constant err-unauthorized (err u107))
(define-constant err-already-rated (err u108))
(define-constant err-invalid-amount (err u109))
(define-constant err-session-not-complete (err u110))
(define-constant err-already-completed (err u111))
(define-constant err-session-active (err u112))
(define-constant err-invalid-duration (err u113))

;; Data variables
(define-data-var session-counter uint u0)
(define-data-var total-reward-pool uint u0)
(define-data-var platform-fee-percentage uint u5)
(define-data-var certification-counter uint u0)
(define-data-var material-counter uint u0)

;; Data maps
(define-map sessions
    { session-id: uint }
    {
        educator: principal,
        subject: (string-ascii 50),
        max-students: uint,
        current-students: uint,
        timestamp: uint,
        active: bool,
        duration-blocks: uint,
        reward-amount: uint,
        total-rating: uint,
        rating-count: uint
    }
)

(define-map student-enrollments
    { student: principal, session-id: uint }
    { 
        enrolled: bool, 
        completed: bool, 
        attendance-time: uint,
        completion-time: uint
    }
)

(define-map educator-stats
    { educator: principal }
    { 
        total-sessions: uint, 
        total-students-taught: uint,
        total-earnings: uint,
        average-rating: uint,
        total-ratings: uint,
        active-sessions: uint
    }
)

(define-map student-stats
    { student: principal }
    {
        total-sessions-attended: uint,
        total-sessions-completed: uint,
        total-hours-learned: uint,
        certificates-earned: uint
    }
)

(define-map session-ratings
    { student: principal, session-id: uint }
    { 
        rating: uint, 
        feedback: (string-ascii 200), 
        rated: bool,
        timestamp: uint
    }
)

(define-map educator-certifications
    { educator: principal, certification-id: uint }
    { 
        certification-name: (string-ascii 100),
        issued-at: uint,
        verified: bool
    }
)

(define-map session-materials
    { session-id: uint, material-id: uint }
    {
        title: (string-ascii 100),
        content-hash: (string-ascii 64),
        uploaded-at: uint
    }
)

(define-map session-categories
    { category-name: (string-ascii 50) }
    { 
        total-sessions: uint,
        active: bool
    }
)

;; Create new teaching session with enhanced details
;; #[allow(unchecked_data)]
(define-public (create-session (subject (string-ascii 50)) (max-students uint) (duration-blocks uint) (reward-amount uint))
    (let
        (
            (new-session-id (+ (var-get session-counter) u1))
            (educator-data (default-to 
                { total-sessions: u0, total-students-taught: u0, total-earnings: u0, average-rating: u0, total-ratings: u0, active-sessions: u0 }
                (map-get? educator-stats { educator: tx-sender })))
        )
        (asserts! (> duration-blocks u0) err-invalid-duration)
        (asserts! (> max-students u0) err-invalid-amount)
        (map-set sessions
            { session-id: new-session-id }
            {
                educator: tx-sender,
                subject: subject,
                max-students: max-students,
                current-students: u0,
                timestamp: stacks-block-height,
                active: true,
                duration-blocks: duration-blocks,
                reward-amount: reward-amount,
                total-rating: u0,
                rating-count: u0
            }
        )
        (map-set educator-stats
            { educator: tx-sender }
            (merge educator-data { 
                total-sessions: (+ (get total-sessions educator-data) u1),
                active-sessions: (+ (get active-sessions educator-data) u1)
            })
        )
        (var-set session-counter new-session-id)
        (ok new-session-id)
    )
)

;; Student enrollment with timestamp tracking
;; #[allow(unchecked_data)]
(define-public (enroll-in-session (session-id uint))
    (let
        (
            (session (unwrap! (map-get? sessions { session-id: session-id }) err-not-found))
            (student-data (default-to 
                { total-sessions-attended: u0, total-sessions-completed: u0, total-hours-learned: u0, certificates-earned: u0 }
                (map-get? student-stats { student: tx-sender })))
        )
        (asserts! (get active session) err-session-inactive)
        (asserts! (< (get current-students session) (get max-students session)) err-session-full)
        (asserts! (is-none (map-get? student-enrollments { student: tx-sender, session-id: session-id })) err-already-registered)
        (map-set student-enrollments
            { student: tx-sender, session-id: session-id }
            { enrolled: true, completed: false, attendance-time: stacks-block-height, completion-time: u0 }
        )
        (map-set sessions
            { session-id: session-id }
            (merge session { current-students: (+ (get current-students session) u1) })
        )
        (map-set student-stats
            { student: tx-sender }
            (merge student-data { total-sessions-attended: (+ (get total-sessions-attended student-data) u1) })
        )
        (ok true)
    )
)

;; Mark session as completed by student
;; #[allow(unchecked_data)]
(define-public (complete-session (session-id uint))
    (let
        (
            (session (unwrap! (map-get? sessions { session-id: session-id }) err-not-found))
            (enrollment (unwrap! (map-get? student-enrollments { student: tx-sender, session-id: session-id }) err-not-found))
            (student-data (unwrap! (map-get? student-stats { student: tx-sender }) err-not-found))
        )
        (asserts! (get enrolled enrollment) err-not-enrolled)
        (asserts! (not (get completed enrollment)) err-already-completed)
        (map-set student-enrollments
            { student: tx-sender, session-id: session-id }
            (merge enrollment { completed: true, completion-time: stacks-block-height })
        )
        (map-set student-stats
            { student: tx-sender }
            (merge student-data { total-sessions-completed: (+ (get total-sessions-completed student-data) u1) })
        )
        (ok true)
    )
)

;; Close session (educator only)
;; #[allow(unchecked_data)]
(define-public (close-session (session-id uint))
    (let
        (
            (session (unwrap! (map-get? sessions { session-id: session-id }) err-not-found))
            (educator-data (unwrap! (map-get? educator-stats { educator: tx-sender }) err-not-found))
        )
        (asserts! (is-eq (get educator session) tx-sender) err-unauthorized)
        (asserts! (get active session) err-session-inactive)
        (map-set sessions
            { session-id: session-id }
            (merge session { active: false })
        )
        (map-set educator-stats
            { educator: tx-sender }
            (merge educator-data { active-sessions: (- (get active-sessions educator-data) u1) })
        )
        (ok true)
    )
)

;; Withdraw from session (before completion)
;; #[allow(unchecked_data)]
(define-public (withdraw-from-session (session-id uint))
    (let
        (
            (session (unwrap! (map-get? sessions { session-id: session-id }) err-not-found))
            (enrollment (unwrap! (map-get? student-enrollments { student: tx-sender, session-id: session-id }) err-not-found))
        )
        (asserts! (not (get completed enrollment)) err-already-completed)
        (asserts! (get active session) err-session-inactive)
        (map-delete student-enrollments { student: tx-sender, session-id: session-id })
        (map-set sessions
            { session-id: session-id }
            (merge session { current-students: (- (get current-students session) u1) })
        )
        (ok true)
    )
)

;; Rate a session (1-5 stars)
;; #[allow(unchecked_data)]
(define-public (rate-session (session-id uint) (rating uint) (feedback (string-ascii 200)))
    (let
        (
            (session (unwrap! (map-get? sessions { session-id: session-id }) err-not-found))
            (enrollment (unwrap! (map-get? student-enrollments { student: tx-sender, session-id: session-id }) err-not-found))
            (existing-rating (map-get? session-ratings { student: tx-sender, session-id: session-id }))
            (educator-data (unwrap! (map-get? educator-stats { educator: (get educator session) }) err-not-found))
        )
        (asserts! (get completed enrollment) err-session-not-complete)
        (asserts! (and (>= rating u1) (<= rating u5)) err-invalid-rating)
        (asserts! (is-none existing-rating) err-already-rated)
        (map-set session-ratings
            { student: tx-sender, session-id: session-id }
            { rating: rating, feedback: feedback, rated: true, timestamp: stacks-block-height }
        )
        (map-set sessions
            { session-id: session-id }
            (merge session { 
                total-rating: (+ (get total-rating session) rating),
                rating-count: (+ (get rating-count session) u1)
            })
        )
        (map-set educator-stats
            { educator: (get educator session) }
            (merge educator-data { 
                total-ratings: (+ (get total-ratings educator-data) u1),
                average-rating: (/ (+ (* (get average-rating educator-data) (get total-ratings educator-data)) rating) 
                                   (+ (get total-ratings educator-data) u1))
            })
        )
        (ok true)
    )
)

;; Upload session materials
;; #[allow(unchecked_data)]
(define-public (upload-material (session-id uint) (title (string-ascii 100)) (content-hash (string-ascii 64)))
    (let
        (
            (session (unwrap! (map-get? sessions { session-id: session-id }) err-not-found))
            (new-material-id (+ (var-get material-counter) u1))
        )
        (asserts! (is-eq (get educator session) tx-sender) err-unauthorized)
        (map-set session-materials
            { session-id: session-id, material-id: new-material-id }
            {
                title: title,
                content-hash: content-hash,
                uploaded-at: stacks-block-height
            }
        )
        (var-set material-counter new-material-id)
        (ok new-material-id)
    )
)

;; Add certification for educator
;; #[allow(unchecked_data)]
(define-public (add-certification (certification-name (string-ascii 100)))
    (let
        (
            (new-cert-id (+ (var-get certification-counter) u1))
        )
        (map-set educator-certifications
            { educator: tx-sender, certification-id: new-cert-id }
            {
                certification-name: certification-name,
                issued-at: stacks-block-height,
                verified: false
            }
        )
        (var-set certification-counter new-cert-id)
        (ok new-cert-id)
    )
)

;; Verify certification (contract owner only)
;; #[allow(unchecked_data)]
(define-public (verify-certification (educator principal) (certification-id uint))
    (let
        (
            (cert (unwrap! (map-get? educator-certifications { educator: educator, certification-id: certification-id }) err-not-found))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set educator-certifications
            { educator: educator, certification-id: certification-id }
            (merge cert { verified: true })
        )
        (ok true)
    )
)

;; Update educator earnings
(define-public (update-earnings (session-id uint) (amount uint))
    (let
        (
            (session (unwrap! (map-get? sessions { session-id: session-id }) err-not-found))
            (educator-data (unwrap! (map-get? educator-stats { educator: (get educator session) }) err-not-found))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set educator-stats
            { educator: (get educator session) }
            (merge educator-data { total-earnings: (+ (get total-earnings educator-data) amount) })
        )
        (ok true)
    )
)

;; Read-only functions
(define-read-only (get-session (session-id uint))
    (map-get? sessions { session-id: session-id })
)

(define-read-only (get-enrollment (student principal) (session-id uint))
    (map-get? student-enrollments { student: student, session-id: session-id })
)

(define-read-only (get-session-count)
    (ok (var-get session-counter))
)

(define-read-only (get-educator-stats (educator principal))
    (map-get? educator-stats { educator: educator })
)

(define-read-only (get-student-stats (student principal))
    (map-get? student-stats { student: student })
)

(define-read-only (get-session-rating (student principal) (session-id uint))
    (map-get? session-ratings { student: student, session-id: session-id })
)

(define-read-only (get-average-session-rating (session-id uint))
    (let
        (
            (session (map-get? sessions { session-id: session-id }))
        )
        (match session
            session-data
                (if (> (get rating-count session-data) u0)
                    (ok (/ (get total-rating session-data) (get rating-count session-data)))
                    (ok u0))
            (err err-not-found)
        )
    )
)

(define-read-only (get-certification (educator principal) (certification-id uint))
    (map-get? educator-certifications { educator: educator, certification-id: certification-id })
)

(define-read-only (get-session-material (session-id uint) (material-id uint))
    (map-get? session-materials { session-id: session-id, material-id: material-id })
)

(define-read-only (get-total-reward-pool)
    (ok (var-get total-reward-pool))
)

(define-read-only (get-platform-fee-percentage)
    (ok (var-get platform-fee-percentage))
)

(define-read-only (is-session-active (session-id uint))
    (match (map-get? sessions { session-id: session-id })
        session-data (ok (get active session-data))
        (err err-not-found)
    )
)

(define-read-only (is-student-enrolled (student principal) (session-id uint))
    (match (map-get? student-enrollments { student: student, session-id: session-id })
        enrollment-data (ok (get enrolled enrollment-data))
        (ok false)
    )
)

(define-read-only (has-student-completed (student principal) (session-id uint))
    (match (map-get? student-enrollments { student: student, session-id: session-id })
        enrollment-data (ok (get completed enrollment-data))
        (ok false)
    )
)

(define-read-only (get-session-capacity (session-id uint))
    (match (map-get? sessions { session-id: session-id })
        session-data 
            (ok {
                current: (get current-students session-data),
                max: (get max-students session-data),
                available: (- (get max-students session-data) (get current-students session-data))
            })
        (err err-not-found)
    )
)