# Bill Reminder

A polished Flutter bill reminder app with local persistence, notifications, and analytics.

## Features
- Add, edit, delete bills with categories, notes, and recurrence rules.
- Mark bills as paid and track payment history.
- Local notifications 3 days before, 1 day before, and on due date.
- Dashboard with upcoming bills, overdue bills, and monthly totals.
- Search and filter bills by category, status, or date range.
- Insights screen with a pie chart of spending by category.
- Export payment history to CSV.
- Theme, currency, and notification preferences.

## Folder Structure
```
lib/
  models/
  providers/
  screens/
  services/
  utils/
  widgets/
```

## Setup
1. Install Flutter 3.x and ensure `flutter doctor` passes.
2. From the project root, run:
   ```bash
   flutter pub get
   ```
3. Run the app on an emulator or device:
   ```bash
   flutter run
   ```

## Notes
- The app uses `sqflite` for local persistence and `flutter_local_notifications` for reminders.
- Payment history exports are saved to the app documents directory and shared using the system share sheet.
