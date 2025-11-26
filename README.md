# Food Ordering App

A Flutter-based food ordering application with local database storage for managing food items and order plans.

## Overview

This application allows users to manage a food menu and create daily order plans with budget tracking. Built with Flutter and SQLite, it provides a complete CRUD interface for food items and order management.

## Features

- **Food Item Management**: Add, edit, delete, and search food items with prices
- **Order Planning**: Create daily order plans by selecting multiple food items
- **Budget Tracking**: Set target budgets and track actual costs per day
- **Date-based Organization**: View and manage orders by specific dates
- **Local Database**: SQLite database with 25 pre-seeded food items
- **Cross-platform Support**: Runs on Android, iOS, Windows, Linux, and macOS

## Tech Stack

- **Framework**: Flutter 3.10.1+
- **Database**: SQLite with sqflite
- **State Management**: StatefulWidget
- **UI**: Material Design 3

## Project Structure

```
lib/
├── database/
│   └── database_helper.dart    # SQLite database operations
├── models/
│   ├── food_item.dart          # Food item data model
│   ├── order_plan.dart         # Order plan data model
│   └── models.dart             # Barrel export file
├── screens/
│   ├── home_screen.dart        # Main navigation screen
│   ├── manage_food_screen.dart # Food item CRUD interface
│   ├── create_order_screen.dart # Order creation interface
│   └── view_orders_screen.dart  # Order viewing and management
└── main.dart                   # Application entry point
```

## Getting Started

### Prerequisites

- Flutter SDK 3.10.1 or higher
- Dart SDK
- Android Studio / VS Code (with Flutter extensions)

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd mobile_assign_3
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the application:
```bash
flutter run
```

## Database Schema

### food_items
- `id` (INTEGER, PRIMARY KEY)
- `name` (TEXT)
- `cost` (REAL)

### order_plans
- `id` (INTEGER, PRIMARY KEY)
- `date` (TEXT, format: yyyy-MM-dd)
- `targetCost` (REAL)
- `foodItemId` (INTEGER, FOREIGN KEY)

## Usage

### Managing Food Items
Navigate to "Manage Food Items" to add, edit, or delete food items from the menu. Use the search functionality to quickly find specific items.

### Creating Orders
Select "Create New Order" to choose a date, set a budget, and add food items to your daily order plan. The app calculates the total cost and compares it against your target budget.

### Viewing Orders
Access "View Orders" to see all scheduled orders organized by date. Delete entire daily plans as needed.

## Dependencies

- `sqflite`: ^2.3.0 - SQLite database
- `sqflite_common_ffi`: ^2.3.0 - FFI support for desktop platforms
- `path_provider`: ^2.1.1 - File system path access
- `intl`: ^0.20.2 - Date formatting and internationalization
- `cupertino_icons`: ^1.0.8 - iOS-style icons

## License

This project is part of a mobile development assignment.
