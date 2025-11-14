#!/bin/bash

# Flutter App Feature Testing Checklist
# This script guides you through testing all app features

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_header() {
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo -e "${BLUE}  $1${NC}"
    echo "════════════════════════════════════════════════════════"
    echo ""
}

print_step() {
    echo -e "${YELLOW}➜ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

ask_confirmation() {
    echo -n -e "${BLUE}$1 (y/n): ${NC}"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        print_success "Confirmed"
        return 0
    else
        print_error "Skipped or Failed"
        return 1
    fi
}

clear
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║       Sales Management Flutter App - Feature Testing        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Pre-requisites
print_header "Pre-requisites Check"

print_step "1. Backend services running?"
ask_confirmation "Are backend services running on http://localhost:8080?"

print_step "2. Flutter app compiled?"
ask_confirmation "Is the Flutter app running? (flutter run)"

print_step "3. Logged in?"
echo "   - Login screen has FULL PAGE animated background"
echo "   - Sales patterns: cash register, $ symbols, receipt, chart, cart"
echo "   - All patterns animate smoothly (float/bounce)"
echo "   - Button shows 'Logging in...' when submitting"
echo "   - Invalid credentials show error immediately"
ask_confirmation "Are you logged in with credentials (masanja/Password123!)?"

# Products Module
print_header "📦 Products Module Testing"

print_step "1. View Products List"
echo "   - Check AppBar has labeled buttons: Grid/List, Sort, Filter, Category, Unit"
echo "   - Buttons show both icon AND text"
echo "   - Category list scrolls horizontally below"
ask_confirmation "Can you see the products list with labeled AppBar buttons?"

print_step "2. Search Products & Toggle View"
echo "   - Search for a product"
echo "   - Click view toggle button in AppBar"
echo "   - Should switch between list and grid view"
echo "   - Grid shows 2 columns (mobile), 3 (tablet), 4 (desktop)"
ask_confirmation "Can you search and toggle between list/grid views?"

print_step "3. Add Product (Category & Unit REQUIRED)"
echo "   - Try adding product WITHOUT category (should show validation error)"
echo "   - Try adding product WITHOUT unit (should show validation error)"
echo "   - In product form: Click 'Add Category' button to add new category"
echo "   - In product form: Click 'Add Unit' button to add new unit"
echo "   - In product form: Click 'Add' button next to Supplier to add new supplier"
echo "   - In products screen: Use 'Add Category' and 'Add Unit' buttons at top"
echo "   - Add product WITH category, unit, and supplier (should succeed)"
ask_confirmation "Product validation, inline creation in form and screen working correctly?"

print_step "4. Edit Product"
ask_confirmation "Can you edit a product successfully?"

print_step "5. Delete Product"
ask_confirmation "Can you delete a product?"

print_step "6. View Product Details"
ask_confirmation "Can you view detailed product information?"

# Purchases Module
print_header "🛒 Purchases Module Testing"

print_step "1. View Purchases List"
ask_confirmation "Can you see the purchases list?"

print_step "2. Create Purchase (Products & Supplier Loading)"
echo "   - Open create purchase screen"
echo "   - Verify products load immediately (no need to refresh)"
echo "   - Verify suppliers load immediately"
echo "   - Try creating purchase WITHOUT supplier (should fail)"
echo "   - Create purchase WITH supplier and products (should succeed)"
ask_confirmation "Purchase product/supplier loading and validation working correctly?"

print_step "3. Add Multiple Items to Purchase"
ask_confirmation "Can you add multiple items to a purchase?"

print_step "4. Check Stock Increased"
ask_confirmation "Did product stock increase after purchase?"

print_step "5. Edit Purchase"
ask_confirmation "Can you edit a purchase order?"

print_step "6. Delete Purchase"
ask_confirmation "Can you delete a purchase order?"

# Sales Module
print_header "💰 Sales Module Testing"

print_step "1. View Sales List"
ask_confirmation "Can you see the sales list?"

print_step "2. Create Sale (Products & Customers Loading)"
echo "   - Open create sale screen"
echo "   - Verify products load immediately (no need to refresh)"
echo "   - Verify customers load immediately"
echo "   - Add products to cart and create sale"
ask_confirmation "Sale product/customer loading working correctly?"

print_step "3. Add Multiple Items"
ask_confirmation "Can you add multiple items to a sale?"

print_step "4. Assign Customer"
ask_confirmation "Can you assign a customer to the sale?"

print_step "5. Check Stock Decreased"
ask_confirmation "Did product stock decrease after sale?"

print_step "6. Check Invoice Auto-Created"
ask_confirmation "Was an invoice automatically created for the sale?"

# Invoices Module
print_header "📄 Invoices Module Testing"

print_step "1. View Invoices List"
ask_confirmation "Can you see the invoices list?"

print_step "2. View Invoice Details"
ask_confirmation "Can you view invoice details?"

print_step "3. Apply Discount to Invoice (CRITICAL TEST)"
echo "   - Note the current sale total"
echo "   - Apply 10% discount to invoice"
echo "   - Check if sale total updated automatically"
ask_confirmation "Does invoice discount update the sale? (Bidirectional sync)"

print_step "4. Change Payment Status"
ask_confirmation "Can you change invoice payment status?"

print_step "5. Generate Invoice PDF"
ask_confirmation "Can you generate/view invoice PDF?"

# Returns Module
print_header "🔄 Returns Module Testing"

print_step "1. View Returns List"
ask_confirmation "Can you see the returns list?"

print_step "2. Process Return"
ask_confirmation "Can you process a product return?"

print_step "3. Check Stock Restored"
ask_confirmation "Was product stock restored after return?"

print_step "4. Check Sale Updated"
ask_confirmation "Was sale total updated after return?"

print_step "5. Check Invoice Updated"
ask_confirmation "Was invoice updated after return?"

# Users Module
print_header "👥 Users Module Testing"

print_step "1. View Users List"
ask_confirmation "Can you see the users list?"

print_step "2. Create User"
ask_confirmation "Can you create a new user?"

print_step "3. Assign Role to User"
ask_confirmation "Can you assign a role to the user?"

print_step "4. Edit User Information"
ask_confirmation "Can you edit user details?"

print_step "5. Delete User"
ask_confirmation "Can you delete a user?"

print_step "6. Test Permissions"
ask_confirmation "Are permissions enforced correctly?"

# Additional Modules
print_header "📊 Additional Features Testing"

print_step "1. Dashboard"
ask_confirmation "Is the dashboard showing analytics correctly?"

print_step "2. Customers Module"
echo "   - Customers load from backend API"
echo "   - No mock data is used"
ask_confirmation "Can you manage customers from backend (view/add/edit/delete)?"

print_step "3. Suppliers Module"
ask_confirmation "Can you manage suppliers (view/add/edit/delete)?"

print_step "4. Expenses Module"
ask_confirmation "Can you track expenses?"

print_step "5. Reports Module"
ask_confirmation "Can you view sales/profit reports?"

print_step "6. Settings Module"
ask_confirmation "Can you access and modify settings?"

print_step "7. Session Expiry Test (CRITICAL)"
echo "   - Try accessing features after token expiry"
echo "   - Should automatically logout without errors"
echo "   - Should redirect to login screen"
ask_confirmation "Does session expiry handling work correctly (auto-logout)?"

# Summary
print_header "Test Summary"

echo ""
echo "✅ Core Modules Tested:"
echo "   - Products (CRUD + validation + inline creation + screen buttons)"
echo "   - Purchases (CRUD + auto-loading + validation)"
echo "   - Sales (CRUD + auto-loading + auto-invoice)"
echo "   - Invoices (CRUD + bidirectional sync)"
echo "   - Returns (stock restoration)"
echo "   - Users (CRUD + permissions)"
echo ""
echo "🔑 Key Validations Checked:"
echo "   - Product requires category & unit (with validation)"
echo "   - Category/Unit buttons with labels in product form"
echo "   - Category/Unit buttons with labels in products screen"
echo "   - Supplier quick-add button in product form"
echo "   - Purchase products load immediately"
echo "   - Purchase suppliers load immediately"
echo "   - Sale products load immediately"
echo "   - Sale customers load immediately"
echo "   - Customers load from backend API (not mock)"
echo "   - Stock managed by backend"
echo "   - Invoice discount updates sale"
echo "   - Returns restore stock"
echo "   - Session expiry auto-logout"
echo ""
echo "🐛 Recent Bug Fixes (2025-11-14):"
echo "   - ✓ Product form validates category & unit as required"
echo "   - ✓ Add Category/Unit moved to AppBar (cleaner layout)"
echo "   - ✓ View toggle working (list ↔ grid)"
echo "   - ✓ Grid view responsive (2/3/4 columns)"
echo "   - ✓ Supplier quick-add button added to product form"
echo "   - ✓ Purchase screen loads products immediately"
echo "   - ✓ Purchase screen loads suppliers immediately"
echo "   - ✓ Sales screen loads products immediately"
echo "   - ✓ Sales screen loads customers immediately"
echo "   - ✓ Customers confirmed loading from backend API"
echo "   - ✓ Login: FULL PAGE animated background"
echo "   - ✓ Login: Sales-themed patterns (register, $, receipt, chart, cart)"
echo "   - ✓ Login button: inline loading ('Logging in...')"
echo "   - ✓ Login errors: shown immediately with icon"
echo "   - ✓ Session expiry auto-logout (401 handling)"
echo ""
echo "📝 Testing Complete!"
echo ""
echo "If any test failed, check:"
echo "   1. Backend services running: curl http://localhost:8080/health"
echo "   2. API configuration: lib/config/config.dart"
echo "   3. Network connectivity"
echo "   4. Authentication token valid"
echo ""
