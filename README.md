# Inventory Management App

A full-stack inventory management system designed for educational and laboratory environments. This open-source platform enables users to efficiently track, borrow, and return items with full administrative control and real-time database integrity.

## ✨ Features

- 📦 **Live Inventory Overview**: Items show name, current quantity, category/subcategory, and location.
- ➕ **Cart-Based Lifting**: Add items to a floating cart and associate with a curricular unit before confirming lift.
- 🔄 **Returns & Damage Tracking**: Return items, mark damages, and automatically update stock.
- 🧑‍🎓 **Unit Curricular System (UC)**: Organize lifts by subject, create new UCs or select existing ones.
- 📊 **Admin Dashboard**: Manage users, items, categories, locations, view full audit logs, and export inventory (CSV/PDF).
- 📉 **Statistics Module**: View low-stock alerts and most-lifted items.
- 🔐 **PIN-Based Authentication**: 4-digit PIN login system with role-based access.
- 📱 **Responsive Flutter Web Frontend**: Works smoothly across devices, optimized for tablets and desktop.
- 🧩 **Modular Backend API**: Built with Node.js, Express, and PostgreSQL. Socket.io integration ready for future real-time features.

## 📚 User Experience

Users log in with a PIN and can:
- Browse all available inventory.
- Select and lift materials linked to a Unit.
- View and manage personal lift history.
- Return materials, marking them as functional or damaged.

Admins have extended access:
- Full item/category/location CRUD.
- User management.
- Inventory export and visual statistics.
- Complete history of stock changes.

## 🚀 Quick Start

### Backend Setup (Node.js)

```bash
git clone https://github.com/miguellobato96/Inventory-Management-app.git
cd inventory-backend
npm install
```

Create a `.env` file with the following:

```
PORT=3000
DB_USER=postgres
DB_PASSWORD=yourpassword
DB_HOST=localhost
DB_NAME=inventory_db
JWT_SECRET=your_jwt_secret
```

Start the backend:

```bash
node src/app.js
```

### Frontend Setup (Flutter Web)

Ensure Flutter is installed and supports web:

```bash
flutter channel stable
flutter upgrade
flutter config --enable-web
```

Then:

```bash
cd ../inventory_flutter
flutter build web
flutter serve
```

## 🛠 Tech Stack

- **Frontend**: Flutter Web
- **Backend**: Node.js + Express
- **Database**: PostgreSQL
- **Auth**: JWT + 4-digit PIN
- **Real-time**: Socket.io (planned)

## 📦 Database Schema (Highlights)

- `users`: PIN login, roles (admin/user)
- `inventory`, `categories`, `locations`
- `unit_lifts`, `unit_item_lifts`
- `damaged_items`, `inventory_history`

## ✅ Example User Flow

1. Log in with PIN.
2. Add items to cart.
3. Associate a UC (create or select).
4. Confirm lift → entry is saved.
5. Return items later via UC menu.

## 🔒 Security & Audit

- All actions logged with user ID, timestamp, and quantity diff.
- Admin routes protected via JWT + role-check middleware.

## 📎 Contributing

Pull requests are welcome!
- Use consistent Node.js + Dart formatting.
- Describe all changes clearly in PR titles and bodies.

## 🧪 Test Deployment

This project has been successfully deployed on a **Raspberry Pi 400** using Chromium in kiosk mode, ensuring 100% offline usability in lab environments.

---

**Developed by [Miguel Lobato](https://github.com/miguellobato96)**
