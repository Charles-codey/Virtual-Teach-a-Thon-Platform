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