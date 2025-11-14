# Sales Management Flutter App

A comprehensive Point of Sale (POS) and Sales Management System built with Flutter. This mobile/desktop application provides a complete interface for managing sales, inventory, customers, and business operations.

## Features

### 📦 Product Management
- ✅ View all products with search and filter
- ✅ Add new products with categories and units (REQUIRED)
- ✅ Edit product details and pricing
- ✅ Delete products
- ✅ Stock level monitoring
- ✅ Barcode support
- ✅ Category and unit management

### 🛒 Purchase Management  
- ✅ Create purchase orders with supplier selection (REQUIRED)
- ✅ View purchase history
- ✅ Edit purchase orders
- ✅ Delete purchase orders
- ✅ Automatic stock updates
- ✅ Multi-item purchases

### 💰 Sales Management
- ✅ Create sales transactions
- ✅ View sales history
- ✅ Edit sales (before invoice)
- ✅ Multi-item sales
- ✅ Customer assignment
- ✅ Payment tracking
- ✅ Automatic invoice generation

### 📄 Invoice Management
- ✅ Auto-generated invoices from sales
- ✅ View invoice details
- ✅ Apply discounts to invoices
- ✅ Payment status tracking (paid/unpaid/credited)
- ✅ Invoice PDF generation
- ✅ Bidirectional sync with sales (discount updates sales)

### 🔄 Returns Management
- ✅ Process product returns
- ✅ Automatic stock restoration
- ✅ Sales and invoice updates
- ✅ Return history tracking

### 👥 User Management
- ✅ Create users with roles
- ✅ View all users
- ✅ Edit user information
- ✅ Delete users
- ✅ Role-based access control (RBAC)
- ✅ Permissions management

### 📊 Additional Features
- ✅ Dashboard with analytics
- ✅ Customer management
- ✅ Supplier management
- ✅ Expense tracking
- ✅ Profit analysis
- ✅ Stock reports
- ✅ Sales reports
- ✅ Real-time notifications
- ✅ Settings management

## Prerequisites

- Flutter SDK 3.0+
- Dart 3.0+
- Running backend services (see `../sales-gateway/README.md`)

## Installation

1. **Install Flutter:**
   ```bash
   # Follow: https://flutter.dev/docs/get-started/install
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure API:**
   
   Edit `lib/config/config.dart`:
   ```dart
   static const String baseUrl = 'http://localhost:8080';
   ```

## Running

```bash
# Mobile/Desktop
flutter run

# Web
flutter run -d chrome

# Specific device
flutter run -d linux
```

## Testing Checklist

Run the testing script:
```bash
./check_app_features.sh
```

Or manually test:

### ✅ Products
- [ ] View products list
- [ ] Add product (category & unit required)
- [ ] Edit product
- [ ] Delete product

### ✅ Purchases
- [ ] View purchases
- [ ] Create purchase (supplier required)
- [ ] Edit purchase
- [ ] Delete purchase

### ✅ Sales
- [ ] Create sale
- [ ] View sales
- [ ] Verify invoice auto-created
- [ ] Verify stock reduced

### ✅ Invoices
- [ ] View invoices
- [ ] Apply discount
- [ ] Verify sale updated (bidirectional)

### ✅ Returns
- [ ] Process return
- [ ] Verify stock restored
- [ ] Verify sale/invoice updated

### ✅ Users
- [ ] Create user
- [ ] Edit user
- [ ] Delete user
- [ ] Test permissions

## Default Login

- **Username:** `masanja`
- **Password:** `Password123!`

## Key Features

### Bidirectional Sync
When discount applied to invoice:
1. Invoice updates ✅
2. Sale updates automatically ✅
3. Data stays consistent ✅

### Stock Management
- Sales reduce stock (via Products service)
- Returns restore stock
- Purchases increase stock
- All managed by backend

## Troubleshooting

### Connection Issues
```dart
// Android emulator use:
baseUrl = 'http://10.0.2.2:8080';

// iOS simulator/Physical device:
baseUrl = 'http://YOUR_IP:8080';
```

### Build Issues
```bash
flutter clean
flutter pub get
flutter run
```

## Build Production

```bash
# Android
flutter build apk --release

# iOS  
flutter build ios --release

# Web
flutter build web --release
```

## Documentation

- Backend API: `../sales-gateway/README.md`
- Testing: `./check_app_features.sh`

## Recent Updates (2025-11-14)

### Login Flow Fix
- **Login Error Handling**: Fixed issue where invalid credentials caused "Preparing app..." screen
  - `AuthFailure` state now properly handled in app.dart
  - User stays on login screen to correct credentials
  - Removed redundant navigation from login_screen.dart
  - Error messages show immediately on login screen

### Compilation Fixes
- **Flutter**: Fixed const constructor issues in SalesEvent
  - `LoadSales` and `ResetCart` now have const constructors
  - Updated all usages to use `const` keyword
- **TypeScript**: Fixed variable scope issue in sales-service processReturn function
  - Backend ready for deployment

### Latest Frontend Improvements
- **Error Handling**: Created generic error placeholder widget for all features
  - User-friendly messages instead of technical errors
  - Consistent error UI across all screens
  - Retry functionality for network issues

### Backend Fixes
- **Invoice Payment Adjustment**: Automatic payment adjustment when discount or return is processed
  - Bidirectional communication between sales and invoices services working correctly

### Frontend Updates
- **Products Screen**: Category/Unit buttons with labels, Sort/Filter as icons
- **Login Flow**: Fast and simple - stays on screen for errors, direct navigation on success
- **Error States**: Generic placeholder for timeouts, network errors, server errors

### Bug Fixes & Enhancements
1. **Login UX**: Invalid credentials no longer cause stuck "Preparing app..." screen
2. **Error UX**: User-friendly error messages, no technical details exposed
3. **Idle Timeout Handling**: Generic error placeholder when API becomes unreachable
4. **Invoice-Sales Communication**: Full bidirectional sync
5. **Payment Adjustment**: Automatic recalculation on discount/return
6. **View Toggle**: Working List/Grid view
7. **Session Expiry**: Auto-logout on 401

### Technical Changes (Backend)
- sales-service: Fixed TypeScript compilation error in processReturn
- invoices-service: Payment adjustment logic
- invoices-service: POST /invoices/adjust-for-return endpoint
- sales-service: Return notifications to invoices

### Technical Changes (Frontend)
- app.dart: Added AuthFailure state handling, removed redundant navigation
- login_screen.dart: Removed redundant BlocListener for navigation
- sales_event.dart: Added const constructors to LoadSales and ResetCart
- Updated all event dispatches to use const
- Created `widgets/error_placeholder.dart` for consistent error UI
- Updated products_screen, sales_screen to use ErrorPlaceholder
- Generic error handling with retry functionality

## License

Private - All Rights Reserved
