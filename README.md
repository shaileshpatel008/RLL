# Rainbow Line — Invoice App 2.0

Rebuilt from scratch in Flutter + GetX. It uses the same backend, the same API
request/response formats and the same invoice numbering as the previous app, so
**no backend changes are needed**.

## Run it

```bash
flutter pub get
flutter run
```

- Built and checked with Flutter 3.47 (Dart 3.13). Needs at least Dart 3.10 (Flutter 3.38+).
- Android application id: `com.soluspot.rainbowlineltd` (same as the old app, so it installs as an update).
- iOS bundle id: `com.raibow.rll` (same as the old app).
- Version `2.0.0+2`. Raise the build number if the store already has a higher one.
- Launcher icons are copied from the old app.

## Project structure (same layout as before)

```
lib/
├── main.dart                     GetMaterialApp, light/dark theme, routes
├── api/
│   ├── api_list.dart             Endpoint URLs
│   ├── api_method.dart           GET/POST/PUT/PATCH/DELETE with timeout + friendly errors
│   └── invoice_repository.dart   Every backend call (request bodies match the old app)
├── bindings/                     One binding per route
├── controller/
│   ├── splash_controller.dart
│   ├── main_controller.dart          Bottom navigation shell
│   ├── dashboard_controller.dart     Home stats (worked out from the invoice list)
│   ├── invoice_list_controller.dart  List, search, filters, share
│   ├── invoice_form_controller.dart  Create + edit (4 steps)
│   ├── invoice_preview_controller.dart
│   └── setting_controller.dart       Invoice number + appearance
├── models/                       InvoiceData / Customer / InvoiceItems (same JSON keys)
├── routes/                       app_pages.dart, app_routes.dart
├── utility/
│   ├── change_value.dart         ★ Company details, domain, prefix: re-brand here
│   ├── app_colors.dart / app_theme.dart
│   ├── app_messages.dart         Every message shown to the user
│   └── global_function.dart      Snackbars, loader, confirm dialog, formatting
├── views/                        Splash, Main shell, Dashboard, Invoice list,
│                                 Invoice form, Invoice preview, Settings
└── widgets/                      Shared widgets, invoice tile, text fields, PDF generator
```

## APIs used

| Screen | Call | Endpoint |
|---|---|---|
| Home / Invoices | List invoices | `GET  /api/invoice` |
| New invoice | Create invoice | `POST /api/invoice` |
| Edit invoice | Load invoice | `GET  /api/invoice/{id}` |
| Edit invoice | Save invoice | `PUT  /api/invoice/{id}` |
| Home / Settings / New invoice | Next invoice number | `GET  /api/app-settings` |
| Settings / after creating an invoice | Set next invoice number | `POST /api/app-settings` |

As before, the invoice number is `RLL/<current year>/<5-digit number>` and it goes up
by one after each invoice is created.

## Flow

1. **Splash:** animated logo. The first launch shows "Get started"; later launches continue on their own.
2. **Home:** this month's total (counts up), a six-month bar chart, quick actions and recent invoices. Pull down to refresh.
3. **Invoices:** search by customer, invoice number or reference, filter by This month / Last month, grouped by month with totals. Each invoice has Share and Edit buttons, and tapping it opens the PDF.
4. **New / Edit invoice:** four steps: Customer → Details → Trips → Review.
   - Tap a recent customer to fill in their details.
   - Due date shortcuts: On receipt / 7 / 14 / 30 days.
   - Trips are added from a bottom sheet with Minibus/SUV/Sedan buttons, a quantity stepper, and the amount worked out automatically.
   - Each step checks its fields and shows a clear message if something is missing.
   - Leaving with unsaved changes asks for confirmation first.
   - Creating an invoice ends on an animated success screen: View & share PDF / Create another / Back to home.
5. **PDF preview:** the real PDF with Save, Print, Copy number and Share buttons.
6. **Settings:** next invoice number (change it from a bottom sheet with a live preview), company details, and Light / Dark / Auto appearance (remembered).

## Notes

- Fonts (Manrope, Bricolage Grotesque, JetBrains Mono) are bundled in
  `assets/fonts`, so the app and PDFs look right offline. All three are SIL Open Font License fonts.
- The old app kept an "Advance deposit" field and a "To date" on each item, but never sent either
  to the server, so this version leaves them out. Each trip has a single date (`item_date`).
- The PDF keeps all the old content: logo, "Invoice", VAT registration number, company
  address, BILL TO, invoice/reference number, dates, the item table, notes, total and bank details.

## Tests

```bash
flutter analyze   # no issues
flutter test      # model parsing + PDF generation
```
