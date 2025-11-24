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