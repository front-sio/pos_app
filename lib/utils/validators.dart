// lib/utils/validators.dart

String? validateName(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter a product name';
  }
  return null;
}

String? validateDescription(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter a product description';
  }
  return null;
}

String? validateQuantity(String? value) {
  if (value == null || double.tryParse(value) == null) {
    return 'Please enter a valid quantity';
  }
  return null;
}

String? validatePrice(String? value) {
  if (value == null || double.tryParse(value) == null) {
    return 'Please enter a valid price';
  }
  return null;
}