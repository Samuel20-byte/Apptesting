# Malihub

Malihub is a personal finance management mobile app, built as part of a 3-week Industrial-Based Learning (IBL) academic project. Users can track income and expenses, categorize transactions, and visualize spending — backed by a real database and a live production deployment.

## Team

| Role | Responsibility |
|---|---|
| Tech Lead/Database admin | Full-stack coordination, Railway deployment, MySQL schema and data management |
| Frontend | Flutter/Dart development |
| Backend | Node.js/Express API development |
| System architecture |  systems analysis, cross-stack integration and fixes |

## Tech Stack

### Frontend
- Flutter / Dart (pinned to **3.44.4**)
- Android-only (iOS deprioritized, not verified working)
- Tested on a physical Android device via USB debugging

### Backend
- Node.js + Express
- Prisma ORM
- MySQL
- JWT authentication (7-day expiry) + bcrypt password hashing

### Hosting & Infrastructure
- **Railway** hosts both the backend service and the MySQL database
- Auto-deploys on every push to GitHub
- Frontend and backend live in the same repo — Railway's **Root Directory** setting distinguishes the two services

### Tools
- VS Code, GitHub Desktop, MySQL Workbench
- Figma (design), LucidChart (diagrams)

## Repository & Deployment

- **GitHub:** `Samuel20-byte/Apptesting` (version control — not application hosting)
- **Backend (live):** `https://apptesting-production.up.railway.app/api`

## Features

- User registration & login (JWT + bcrypt)
- Income and Expense tracking with distinct categories (`category_type` ENUM column in the DB, filtered per tab in Flutter)
- Spending breakdown via donut chart, using a stable alphabetical category-color mapping
- Custom app branding/icon (generated via `flutter_launcher_icons` + Python/Pillow)

## Getting Started

### Backend Setup
```bash
cd backend
npm install
```
Create a `.env` file:
```
DATABASE_URL=<mysql-connection-string>
JWT_SECRET=<fixed-secret-value>
```
```bash
npx prisma generate
npm run dev
```

> `schema.prisma` needs `binaryTargets = ["native", "debian-openssl-3.0.x"]` for Railway/Linux compatibility, and `package.json` needs a `"build": "prisma generate"` script.

### Frontend Setup
```bash
cd frontend
flutter pub get
flutter run
```
- Point the API base URL to the backend — local LAN IP for development, or the Railway URL for production.
- A physical Android device is recommended over an emulator (LDPlayer's `10.0.2.2` alias hasn't been reliable).

## Future Considerations

- **Password recovery (forgot password):** Deferred from the current MVP due to project timeline constraints. An initial implementation (Nodemailer over Gmail SMTP) surfaced a Railway-specific networking issue affecting outbound SMTP delivery; resolving this reliably was deprioritized in favor of core features, and is planned for a future release.
- Containerization (Docker)
- Migration from MySQL to PostgreSQL
- Render / Supabase as alternative hosting to Railway
- Firebase App Distribution for APK delivery to testers
- Automated financial insights as a literacy-building feature
- Automated testing coverage

## Notes on Accuracy (for presentation/documentation)

- The app is **Android-only** in practice — iOS support has not been verified.
- JWT sessions **expire after 7 days** — they are not indefinite.
- GitHub is used for **version control**, not application hosting; Railway is the host.
