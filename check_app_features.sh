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
ask_confirmation "Are you logged in with credentials (masanja/Password123!)?"

# Products Module
print_header "📦 Products Module Testing"

print_step "1. View Products List"
ask_confirmation "Can you see the products list?"

print_step "2. Search Products"
ask_confirmation "Can you search for a product?"

print_step "3. Add Product (Category & Unit REQUIRED)"
echo "   - Try adding product WITHOUT category (should fail)"
echo "   - Try adding product WITHOUT unit (should fail)"
echo "   - Add product WITH category and unit (should succeed)"
ask_confirmation "Product validation working correctly?"

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

print_step "2. Create Purchase (Supplier REQUIRED)"
echo "   - Try creating purchase WITHOUT supplier (should fail)"
echo "   - Create purchase WITH supplier (should succeed)"
ask_confirmation "Purchase validation working correctly?"

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

print_step "2. Create Sale"
ask_confirmation "Can you create a new sale?"

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
ask_confirmation "Can you manage customers (view/add/edit/delete)?"

print_step "3. Suppliers Module"
ask_confirmation "Can you manage suppliers (view/add/edit/delete)?"

print_step "4. Expenses Module"
ask_confirmation "Can you track expenses?"

print_step "5. Reports Module"
ask_confirmation "Can you view sales/profit reports?"

print_step "6. Settings Module"
ask_confirmation "Can you access and modify settings?"

# Summary
print_header "Test Summary"

echo ""
echo "✅ Core Modules Tested:"
echo "   - Products (CRUD + validation)"
echo "   - Purchases (CRUD + supplier validation)"
echo "   - Sales (CRUD + auto-invoice)"
echo "   - Invoices (CRUD + bidirectional sync)"
echo "   - Returns (stock restoration)"
echo "   - Users (CRUD + permissions)"
echo ""
echo "🔑 Key Validations Checked:"
echo "   - Product requires category & unit"
echo "   - Purchase requires supplier"
echo "   - Stock managed by backend"
echo "   - Invoice discount updates sale"
echo "   - Returns restore stock"
echo ""
echo "📝 Testing Complete!"
echo ""
echo "If any test failed, check:"
echo "   1. Backend services running: curl http://localhost:8080/health"
echo "   2. API configuration: lib/config/config.dart"
echo "   3. Network connectivity"
echo "   4. Authentication token valid"
echo ""
