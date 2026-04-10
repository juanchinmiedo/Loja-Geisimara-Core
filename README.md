# Salon Booking App

> Full-featured appointment management system for a beauty salon — handles scheduling, client tracking, booking requests, and worker availability in real time.

## Stack

Flutter 3 · Dart 3 · Firebase (Firestore + Auth) · Google Sign-In · Provider · Material 3 · i18n (pt, en, es)

## Features

- 🔐 Google Sign-In with Firebase Custom Claims RBAC (admin / worker / admin+worker roles)
- 📅 Week & day calendar view with drag-free slot booking and blocked-slot management
- 👤 Client profiles — appointment history, stats, contact info, and search by name/phone/instagram
- 🔔 Booking request system — clients register preferred days/times; admin gets match alerts when a slot opens
- 🏠 Admin home — live dashboard of clients looking for appointments, cancellations, and no-shows
- 🔍 Full-text client search using Firestore array-contains tokens
- 🌍 Three-locale i18n (pt-BR, en, es-ES) with live language switching
- 📊 Worker stats — completed procedures, revenue, and breakdown by service
- 🔕 Audit log integration — every create, edit, and delete action is recorded
- 🚨 Notification panel — freed-slot matches, expired requests, and booking confirmations

## Structure
lib/
├── components/       ui primitives (header, cards, pills, date strip, searchbar)
├── controller/       auth controller (Google Sign-In flow)
├── provider/         UserProvider, LocaleProvider, AdminNavProvider, BookingViewProvider
├── repositories/     AppointmentRepo, BookingRequestRepo, BlockedSlotRepo, ClientRepo
├── screens/
│   ├── booking/      booking_admin, week_calendar_view, create/edit/past dialogs, block_slot
│   ├── clients/      clients_admin (list + search), clients_profile (tabs + booking requests)
│   ├── home/         home_admin (dashboard), lost_clients
│   ├── introduction/ splash, onboarding
│   └── profile/      profile (roles, stats, sign-out)
├── services/         AppointmentService, AvailabilityService, AuditService, ClientService, ConflictService
├── utils/            date/time helpers, booking request utils, localization helper
└── widgets/          booking request card/form, worker pills, notifications overlay, async switch

## Setup

```bash
flutter pub get
flutterfire configure --project=agenda-loja
flutter run
```

> Custom Claims (`roles`, `workerId`) must be set via Firebase Admin SDK.  
> Shares the `agenda-loja` Firebase project with the Admin Audit App.
