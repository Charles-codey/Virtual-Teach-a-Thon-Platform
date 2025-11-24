# Virtual Teach-a-Thon Platform

A blockchain-based platform for organizing virtual teaching sessions connecting volunteer educators with underprivileged students.

## Overview

This smart contract manages virtual teach-a-thon sessions, allowing educators to create teaching sessions and students to enroll in them. All session data is stored transparently on the Stacks blockchain.

## Features

- **Session Creation**: Educators can create teaching sessions with subject and capacity
- **Student Enrollment**: Students can enroll in available sessions
- **Session Tracking**: Track active sessions and student participation
- **Completion Verification**: Mark sessions as completed for attendance records

## Contract Functions

### Public Functions

- `create-session`: Create a new teaching session (educator only)
- `enroll-in-session`: Enroll in an available session (students)
- `complete-session`: Mark a session as completed

### Read-Only Functions

- `get-session`: Retrieve session details
- `get-enrollment`: Check enrollment status
- `get-session-count`: Get total number of sessions

## Getting Started

1. Deploy the contract to Stacks blockchain
2. Educators create sessions using `create-session`
3. Students enroll using `enroll-in-session`
4. Track participation and completion

## Technology

- Built with Clarity smart contract language
- Deployed on Stacks blockchain
- Bitcoin-secured transparency