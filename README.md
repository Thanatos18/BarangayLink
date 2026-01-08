# BarangayLink (Tagum City)

**Bridging Citizens and Local Government through Technology.**

BarangayLink is a comprehensive citizen-engagement platform designed specifically for Tagum City. It bridges the communication gap between residents and their local Barangays, offering a unified marketplace for jobs, rentals, and services, alongside critical citizen tools like incident reporting and feedback channels.

---

## 🏗️ System Architecture

BarangayLink is built on **Flutter**, utilizing a **Clean Architecture** approach with the **Provider Pattern** for state management. This architecture was chosen to ensure:
- **Scalability:** The app is modular, allowing individual features (Phases) to be updated without affecting the core system.
- **Maintainability:** Separation of concerns between the UI (Screens), Logic (Providers), and Data (Services/Models).
- **Performance:** Efficient state rebuilding using `ChangeNotifier` and `Consumer` widgets.

### Tech Stack
- **Frontend:** Flutter (Dart)
- **Backend:** Firebase (Auth, Firestore, Storage)
- **Maps:** Google Maps API
- **State Management:** Provider

---

## 🧩 The 11-Phase Modular Logic

The application's state management is divided into 11 distinct "Phases," each represented by a dedicated Provider. This modularity ensures that data domains remain isolated and manageable.

| Phase | Module | Description |
| :--- | :--- | :--- |
| **01** | **User Management** | Authentication, Profile Management, and Role-Based Access Control (RBAC). |
| **02** | **Barangay Context** | Location services and Barangay-specific data isolation. |
| **03** | **Jobs Market** | Job posting, searching, and application workflow. |
| **04** | **Services Market** | Service listing (plumbing, electrical, etc.) and booking. |
| **05** | **Rentals Market** | Property and equipment rental listings and management. |
| **06** | **Transactions** | Unified history of all user activities (Applications, Reports, Feedback). |
| **07** | **Feedback System** | Direct channel for citizens to rate and review Barangay services. |
| **08** | **Admin Dashboard** | Content moderation, user oversight, and system-wide settings. |
| **09** | **Notifications** | Real-time updates on application status and report outcomes. |
| **10** | **Favorites** | User personalization for saving listings and services. |
| **11** | **Incident Reporting** | Critical reporting tool for emergencies and community issues. |

---

## 🚀 Feature Deep-Dive

### 1. Incident Reporting (CRUD)
The Report module typifies the app's CRUD capabilities:
- **Create:** Users submit reports with images (Cloud Storage) and precise location data (GeoPoint).
- **Read:** Users view their report history; Admins view all reports filtered by Barangay.
- **Update:** Admins change report status (Pending -> Investigating -> Resolved).
- **Delete:** Users can retract reports before they are processed.

### 2. The Marketplace (Jobs, Services, Rentals)
A unified economy ecosystem where users can seamlessly switch between roles (Seeker vs. Provider) without needing separate accounts. All listings support rich media, categorization, and search filtering.

---

## 📂 Folder Structure

The project follows a semantic feature-first structure:

```
lib/
├── constants/         # App-wide colors, styles, and configuration
├── models/            # Data models (User, Job, Report, etc.)
├── providers/         # State Management (The 11 Phases)
├── screens/           # UI Screens organized by feature (Auth, Home, Main)
├── services/          # External API calls (Firebase, Cloudinary)
├── utils/             # Helper functions (Formatters, Validators)
└── widgets/           # Reusable UI components (CustomAppBar, Cards)
```

---

## ⚙️ Installation & Setup

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK
- Firebase CLI (for configuration updates)

### Steps
1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-repo/barangay_link.git
   ```
2. **Install dependencies:**
   ```bash
   flutter pub get
   ```
3. **Configure Firebase:**
   Ensure `firebase_options.dart` is present in the `lib` directory. If not, run:
   ```bash
   flutterfire configure
   ```
4. **Run the app:**
   ```bash
   flutter run
   ```

---

## 📸 Screenshots

| Home Dashboard | Incident Reporting | Marketplace Listing |
| :---: | :---: | :---: |
| *(Add Screenshot)* | *(Add Screenshot)* | *(Add Screenshot)* |