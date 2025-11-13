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

## License

Private - All Rights Reserved
