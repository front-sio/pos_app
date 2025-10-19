import 'package:flutter/material.dart';
import 'package:sales_app/constants/colors.dart';

class SampleData {
  static final List<Map<String, dynamic>> salesCardData = [
    {'title': 'Total Sales', 'value': '\$124,567', 'subtitle': '+15% vs last period', 'icon': Icons.trending_up, 'color': AppColors.kSuccess},
    {'title': 'Orders', 'value': '1,234', 'subtitle': '45 today', 'icon': Icons.shopping_cart, 'color': AppColors.kPrimary},
    {'title': 'Average Order', 'value': '\$101', 'subtitle': '-2% vs last period', 'icon': Icons.analytics, 'color': AppColors.kWarning},
    {'title': 'Top Product', 'value': 'Nike Air Max', 'subtitle': '234 units sold', 'icon': Icons.star, 'color': AppColors.kSecondary},
  ];

  static final List<Map<String, dynamic>> salesTrendData = [
    {'label': 'Jan', 'value': 25000.0},
    {'label': 'Feb', 'value': 30000.0},
    {'label': 'Mar', 'value': 28000.0},
    {'label': 'Apr', 'value': 35000.0},
  ];

  static final List<Map<String, dynamic>> topProductsData = [
    {'label': 'Product A', 'value': 100.0},
    {'label': 'Product B', 'value': 150.0},
    {'label': 'Product C', 'value': 80.0},
    {'label': 'Product D', 'value': 120.0},
  ];

  static final List<Map<String, dynamic>> salesByCategoryData = [
    {'label': 'Electronics', 'value': 40, 'color': AppColors.kPrimary},
    {'label': 'Apparel', 'value': 30, 'color': AppColors.kWarning},
    {'label': 'Home Goods', 'value': 20, 'color': AppColors.kSuccess},
    {'label': 'Other', 'value': 10, 'color': AppColors.kTextSecondary},
  ];

  static final List<Map<String, dynamic>> salesData = [
    {'Date': '2024-09-28', 'Product': 'Laptop', 'Revenue': 1200, 'Profit': 300},
    {'Date': '2024-09-29', 'Product': 'Mouse', 'Revenue': 50, 'Profit': 20},
    {'Date': '2024-09-30', 'Product': 'Keyboard', 'Revenue': 75, 'Profit': 35},
  ];

  static final List<Map<String, dynamic>> inventoryCardData = [
    {'title': 'Total Stock Value', 'value': '\$234,567', 'subtitle': '1,234 items', 'icon': Icons.inventory_2, 'color': AppColors.kPrimary},
    {'title': 'Low Stock Items', 'value': '45', 'subtitle': 'Below minimum quantity', 'icon': Icons.warning, 'color': AppColors.kWarning},
    {'title': 'Out of Stock', 'value': '12', 'subtitle': 'Needs attention', 'icon': Icons.error_outline, 'color': AppColors.kError},
    {'title': 'Stock Turnover', 'value': '4.5x', 'subtitle': 'Last 30 days', 'icon': Icons.cable, 'color': AppColors.kSuccess},
  ];

  static final List<Map<String, dynamic>> stockByCategoryData = [
    {'label': 'Electronics', 'value': 500},
    {'label': 'Apparel', 'value': 300},
    {'label': 'Home Goods', 'value': 200},
    {'label': 'Other', 'value': 100},
  ];

  static final List<Map<String, dynamic>> inventoryTurnoverData = [
    {'label': 'Q1', 'value': 3.5},
    {'label': 'Q2', 'value': 4.0},
    {'label': 'Q3', 'value': 4.5},
    {'label': 'Q4', 'value': 5.0},
  ];

  static final List<Map<String, dynamic>> inventoryData = [
    {'Product': 'Laptop', 'Stock': 50, 'Status': 'In Stock'},
    {'Product': 'Mouse', 'Stock': 10, 'Status': 'Low Stock'},
    {'Product': 'Keyboard', 'Stock': 5, 'Status': 'Low Stock'},
  ];

  static final List<Map<String, dynamic>> financialCardData = [
    {'title': 'Revenue', 'value': '\$345,678', 'subtitle': '+12% vs last period', 'icon': Icons.payments, 'color': AppColors.kSuccess},
    {'title': 'Expenses', 'value': '\$123,456', 'subtitle': '-5% vs last period', 'icon': Icons.money_off, 'color': AppColors.kError},
    {'title': 'Profit', 'value': '\$222,222', 'subtitle': '+18% vs last period', 'icon': Icons.trending_up, 'color': AppColors.kPrimary},
    {'title': 'Cash Flow', 'value': '\$45,678', 'subtitle': 'Available balance', 'icon': Icons.account_balance_wallet, 'color': AppColors.kSecondary},
  ];

  static final List<Map<String, dynamic>> revenueVsExpensesData = [
    {'label': 'Jan', 'revenue': 50000.0, 'expenses': 20000.0},
    {'label': 'Feb', 'revenue': 60000.0, 'expenses': 25000.0},
    {'label': 'Mar', 'revenue': 55000.0, 'expenses': 22000.0},
    {'label': 'Apr', 'revenue': 70000.0, 'expenses': 28000.0},
  ];

  static final List<Map<String, dynamic>> profitMarginData = [
    {'label': 'Q1', 'value': 25.0},
    {'label': 'Q2', 'value': 28.0},
    {'label': 'Q3', 'value': 30.0},
    {'label': 'Q4', 'value': 32.0},
  ];

  static final List<Map<String, dynamic>> financialData = [
    {'Date': '2024-09-28', 'Revenue': 5000, 'Expenses': 1500, 'Profit': 3500},
    {'Date': '2024-09-29', 'Revenue': 6000, 'Expenses': 1800, 'Profit': 4200},
    {'Date': '2024-09-30', 'Revenue': 5500, 'Expenses': 1600, 'Profit': 3900},
  ];

  static final List<Map<String, dynamic>> customerCardData = [
    {'title': 'Total Customers', 'value': '5,678', 'subtitle': '+5% vs last period', 'icon': Icons.people, 'color': AppColors.kPrimary},
    {'title': 'New Customers', 'value': '45', 'subtitle': 'Last 30 days', 'icon': Icons.person_add, 'color': AppColors.kSuccess},
    {'title': 'Returning Rate', 'value': '45%', 'subtitle': '+3% vs last period', 'icon': Icons.repeat, 'color': AppColors.kWarning},
    {'title': 'Avg. Spend', 'value': '\$125', 'subtitle': '+8% vs last period', 'icon': Icons.attach_money, 'color': AppColors.kSecondary},
  ];

  static final List<Map<String, dynamic>> customerData = [
    {'label': 'New', 'value': 30, 'color': AppColors.kPrimary},
    {'label': 'Returning', 'value': 70, 'color': AppColors.kSuccess},
  ];
}
