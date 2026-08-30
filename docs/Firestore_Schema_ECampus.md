# Firestore Schema — E-Campus

**Phase:** Phase 2 — UML & Database Design
**Database:** Cloud Firestore (NoSQL, document-based)

---

## Collection: `users`

| Field | Type | Description |
|---|---|---|
| `uid` | String (doc ID) | Firebase Auth UID, primary identifier |
| `phone` | String | User's phone number (used for OTP login) |
| `name` | String | Full name |
| `role` | String | One of: `student`, `classrep`, `teacher` |
| `enrollmentNo` | String (optional) | Student enrollment number (students only) |
| `classId` | String (optional) | Class/section ID (student & class rep) |
| `department` | String (optional) | Department name (teacher only) |
| `profileImageUrl` | String | URL to profile photo in Firebase Storage |
| `createdAt` | Timestamp | Account creation time |

---

## Collection: `books`

| Field | Type | Description |
|---|---|---|
| `bookId` | String (doc ID) | Auto-generated document ID |
| `title` | String | Book/material title |
| `subject` | String | Subject or category tag |
| `semester` | Number | Applicable semester (optional filter) |
| `fileUrl` | String | Firebase Storage URL to the PDF/document |
| `uploadedBy` | String (ref) | UID of the teacher who uploaded it |
| `uploadedAt` | Timestamp | Upload time |

---

## Collection: `bus_locations`

| Field | Type | Description |
|---|---|---|
| `routeId` | String (doc ID) | Route identifier |
| `busNo` | String | Bus number/label |
| `stops` | Array<Map> | Ordered list of `{ name, lat, lng }` stop objects |
| `currentLat` | Number | Live latitude of the bus |
| `currentLng` | Number | Live longitude of the bus |
| `updatedBy` | String (ref) | UID of the admin/teacher managing this route |
| `lastUpdated` | Timestamp | Last location update time |

---

## Collection: `chats`

| Field | Type | Description |
|---|---|---|
| `chatId` | String (doc ID) | Auto-generated document ID |
| `senderId` | String (ref) | UID of the message sender |
| `receiverId` | String (ref) | UID of the recipient (or group/class ID) |
| `text` | String | Message content |
| `timestamp` | Timestamp | When the message was sent |
| `isGroupMessage` | Boolean | True if part of a class group chat |

**Note:** For simplicity in a solo-dev timeline, chats are stored flat with `senderId`/`receiverId` rather than nested subcollections. Query with a composite `where` clause on both fields (or a computed `conversationId` combining both UIDs sorted alphabetically) to fetch a thread efficiently.

---

## Collection: `tech_news`

| Field | Type | Description |
|---|---|---|
| `newsId` | String (doc ID) | Auto-generated document ID |
| `title` | String | Headline |
| `description` | String | Full news body |
| `department` | String | Department tag (for filtering) |
| `postedBy` | String (ref) | UID of the teacher/admin who posted it |
| `postedAt` | Timestamp | Publish time |

---

## Security rule notes (for Phase 4/5 implementation)

- All collections should require `request.auth != null` at minimum.
- Write access to `books`, `bus_locations`, and `tech_news` should check `get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'teacher'`.
- `chats` writes should only be allowed where `request.auth.uid == resource.data.senderId` (or on create, `request.resource.data.senderId`).
- `users` documents should only be writable by the user themselves for their own profile fields, and by teachers for the `role` field.
