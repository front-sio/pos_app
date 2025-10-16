import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:sales_app/constants/colors.dart';
import 'package:sales_app/models/settings.dart';


class SettingsScreen extends StatefulWidget {
  final AppSettings settings;

  const SettingsScreen({super.key, required this.settings});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Color primaryColor;
  late String? brandLogo;

  @override
  void initState() {
    super.initState();
    primaryColor = widget.settings.primaryColorValue != null
        ? Color(widget.settings.primaryColorValue!)
        : AppColors.kPrimary;
    brandLogo = widget.settings.brandLogoUrl;
  }

  void _pickPrimaryColor() async {
    Color tempColor = primaryColor;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Pick Primary Color"),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: primaryColor,
            onColorChanged: (color) {
              tempColor = color;
            },
            showLabel: true,
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                primaryColor = tempColor;
                AppColors.updatePrimary(primaryColor);
              });
              Navigator.pop(context);
            },
            child: const Text("Select"),
          ),
        ],
      ),
    );
  }

  void _pickBrandLogo() async {
    // Placeholder for file picker
    setState(() {
      brandLogo = "https://via.placeholder.com/150";
    });
  }

  void _saveSettings() {
    widget.settings.primaryColorValue = primaryColor.value;
    widget.settings.brandLogoUrl = brandLogo;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Settings saved successfully!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          const Text("Brand Logo", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickBrandLogo,
            child: brandLogo != null
                ? Image.network(brandLogo!, height: 100)
                : Container(
                    height: 100,
                    color: Colors.grey[300],
                    child: const Center(child: Text("Tap to upload logo")),
                  ),
          ),
          const SizedBox(height: 20),
          const Text("Primary Color", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickPrimaryColor,
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saveSettings,
            child: const Text("Save Settings"),
          ),
        ],
      ),
    );
  }
}
