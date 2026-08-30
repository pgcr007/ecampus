# Software Requirements Specification — E-Campus

**Project:** E-Campus (Flutter College Management App)
**Prepared by:** Prathamesh
**Date:** September 2026
**Phase:** Phase 1 — Requirement Analysis & Planning

---

## 1. Introduction

E-Campus is a Flutter-based college management mobile application that consolidates authentication, role-based access, an e-library, campus bus tracking, chat, an AI chatbot, and department tech news into a single platform for students, class representatives, and teachers/admins.

---

## 2. Functional Requirements

### 2.1 Authentication / OTP
- FR1.1: User enters their phone number and receives a one-time password (OTP) via SMS through Firebase Authentication.
- FR1.2: User enters the OTP to verify their identity and log in.
- FR1.3: On first successful login, the system creates a new user profile in Firestore with a default role (Student), pending role assignment by an admin if needed.
- FR1.4: User can log out from any screen via the drawer menu.
- FR1.5: OTP requests are rate-limited to prevent abuse (Firebase default protection).
- FR1.6: Session persists across app restarts until the user explicitly logs out.

### 2.2 Role-Based Access Control (RBAC)
- FR2.1: System defines exactly three roles: Student, Class Representative, Teacher/Admin.
- FR2.2: Each user document in Firestore stores a `role` field used to gate UI and data access.
- FR2.3: Firestore security rules enforce role checks server-side, not just client-side UI hiding.
- FR2.4: Admin/Teacher can view and update the role of any user.

### 2.3 Drawer Navigation
- FR3.1: App displays a role-aware navigation drawer — menu items differ based on the logged-in user's role.
- FR3.2: Common items (Home, E-Library, Bus Tracking, Chat, Chatbot, Tech News, Profile, Logout) are visible to all roles.
- FR3.3: Class Representative sees an additional "Post Announcement" item.
- FR3.4: Teacher/Admin sees additional items: "Manage Library", "Manage Bus Routes", "Manage Users", "Post Tech News".

### 2.4 E-Library
- FR4.1: Students/CR can browse a list of available books/study materials by subject or semester.
- FR4.2: Students/CR can open/download a PDF or document from the library.
- FR4.3: Teacher/Admin can upload new materials (PDF, images, docs) to Firebase Storage with metadata saved in Firestore.
- FR4.4: Teacher/Admin can delete or update existing materials.
- FR4.5: Library list supports search/filter by title or subject.

### 2.5 Bus Tracking
- FR5.1: Students/CR can view live bus location(s) on a Google Map.
- FR5.2: System displays estimated route and stops for each bus.
- FR5.3: Teacher/Admin can update/manage bus route data (start point, stops, end point).
- FR5.4: Bus location updates are pulled from a live location feed (simulated or device-based GPS updates written to Firestore/Realtime DB).

### 2.6 Chat
- FR6.1: Students can chat one-to-one with a Teacher.
- FR6.2: Students can chat with classmates/friends (individual or class group chat).
- FR6.3: Messages are stored and synced in real time via Firestore/Realtime Database.
- FR6.4: Chat screen shows sender name, timestamp, and message status.
- FR6.5: Users can see a list of recent conversations on the Chat home screen.

### 2.7 AI Chatbot
- FR7.1: Any logged-in user can ask the chatbot academic or campus-related questions.
- FR7.2: Chatbot sends the user's query to the OpenAI ChatGPT API and displays the response.
- FR7.3: Chat history with the bot is retained for the session (optionally persisted per user).
- FR7.4: System handles API errors/timeouts gracefully with a fallback message.

### 2.8 Tech News
- FR8.1: Users can view a feed of department-wise tech news/updates.
- FR8.2: News items display title, description, department tag, and posted date.
- FR8.3: Teacher/Admin can post, edit, or delete news items.
- FR8.4: Feed supports filtering by department.

---

## 3. User Roles

| Role | Can Access |
|---|---|
| **Student** | E-Library (view/download), Bus Tracking (view), Chat (with teacher/friends), AI Chatbot, Tech News (view), own profile |
| **Class Representative** | Everything a Student has, plus: post class announcements, manage class-level group chat |
| **Teacher/Admin** | Everything above, plus: upload/manage E-Library materials, manage bus routes, manage user roles, post/edit/delete Tech News |

---

## 4. Non-Functional Requirements

- **Performance:** Home screen and core feature screens should load within 2 seconds on a standard 4G connection.
- **Security:** OTP expires within 5 minutes of issue; Firestore security rules restrict read/write access based on authenticated user's role; no sensitive data (API keys) stored client-side in plain text.
- **Offline Handling:** Previously loaded E-Library list and Tech News feed remain viewable when offline (Firestore's built-in local cache); actions requiring network (chat send, bot query) show a clear "no connection" state.
- **Scalability:** Firestore data structure should reasonably support 500+ concurrent student users without redesign.
- **Usability:** Consistent navigation pattern (drawer-based) across all roles; minimum tap targets and readable typography per Material Design guidelines.
- **Maintainability:** Codebase organized by feature/layer (models, services, screens, widgets, providers) to support solo iterative development across phases.

---

## 5. Tech Stack

| Layer | Tool / Technology |
|---|---|
| IDE | Android Studio with Flutter and Dart plugins |
| Frontend | Flutter (Dart) |
| State Management | Riverpod (`flutter_riverpod` package) |
| Authentication | Firebase Authentication — Phone/OTP based |
| Database | Cloud Firestore (NoSQL) — users, books, chats, bus locations, tech news |
| Storage | Firebase Storage — e-library files, profile images |
| Maps | Google Maps API + `google_maps_flutter` package |
| AI Chatbot | OpenAI ChatGPT API |
| Diagrams | draw.io / Lucidchart / StarUML (UML), dbdiagram.io (ER diagrams) |
| Design | Figma (wireframes and blueprint) |
| Version Control | Git + GitHub |

---

## 6. Deliverables for Phase 1

- This SRS document
- Finalized feature list (Section 2)
- Confirmed tech stack (Section 5)
