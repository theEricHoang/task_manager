# Task Manager

A Flutter task management app backed by Firebase Firestore with real-time streaming, nested subtasks, search filtering, and animated list transitions.

## Features

- **Task CRUD** — Create, read (streamed in real time), toggle completion, and delete tasks.
- **Nested Subtasks** — Expand any task to reveal a subtask list stored as a Firestore subcollection. Subtasks support the same CRUD operations as tasks.
- **Search / Filter** — A search bar filters the task list by name in real time using case-insensitive substring matching. A clear button resets the query, and a dedicated empty state is shown when no tasks match.
- **Animated Lists** — Tasks and subtasks use `AnimatedList` with combined `SizeTransition` + `FadeTransition` animations (300ms). Items slide and fade in when added, and slide and fade out when removed or filtered away.
- **UX State Handling** — Loading spinners during Firestore operations, inline input validation with error text, confirmation dialogs on delete, and `SnackBar` error messages on operation failure.

## Setup

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x or later)
- A Firebase project with Firestore enabled
- [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/) (recommended) or manual Firebase configuration

### Installation

1. **Clone the repository**

   ```bash
   git clone <repository-url>
   cd task_manager
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Configure Firebase**

   If you have the FlutterFire CLI installed:

   ```bash
   flutterfire configure
   ```

   This generates `lib/firebase_options.dart`. If you prefer manual setup, follow the [FlutterFire documentation](https://firebase.flutter.dev/docs/overview) and place your configuration in `lib/firebase_options.dart`.

4. **Enable Firestore**

   In the [Firebase Console](https://console.firebase.google.com), navigate to your project and enable Cloud Firestore. Start in test mode for development or configure security rules as needed.

5. **Run the app**

   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart                  # App entry point, Firebase init
├── firebase_options.dart      # Generated Firebase config
├── models/
│   ├── task.dart              # Task model (id, name, completionStatus)
│   └── subtask.dart           # Subtask model (id, name, completionStatus)
├── services/
│   ├── task_service.dart      # Firestore CRUD for tasks collection
│   └── subtask_service.dart   # Firestore CRUD for tasks/{id}/subtasks subcollection
├── screens/
│   └── task_list_screen.dart  # Main screen with search, add input, and AnimatedList
└── widgets/
    ├── task_card.dart         # Expandable task card with subtask AnimatedList
    └── subtask_card.dart      # Compact subtask card (indented, dense)
```

## Known Limitations

- **No authentication** — All users share the same Firestore `tasks` collection. There is no per-user data isolation.
- **No offline persistence** — The app relies on an active network connection. Firestore offline caching is not explicitly configured.
- **Subtask ordering** — Subtasks are returned in Firestore's default document order, which is not guaranteed to be consistent. No explicit sort field exists.
- **Cascade delete** — Deleting a task removes the task document but does not automatically delete its subtasks subcollection. Firestore does not support cascading deletes natively; a Cloud Function or batch delete would be needed for cleanup.
- **Search is client-side only** — All tasks are streamed to the client and filtered locally. This works for small to moderate task counts but does not scale to very large datasets.
- **Single level of nesting** — Only one level of subtasks is supported. Subtasks cannot have their own subtasks.
- **No drag-to-reorder** — Task and subtask order cannot be changed by the user.
