import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';

import '../constants/colors.dart';
import '../constants/sizes.dart';

/// Custom reusable input widget
/// - TextFormField with validation, password toggle, and rich customization
/// - Image picker wrapped in a FormField for proper validation and error display
///
/// Mobile-first and responsive by default.
class CustomInput extends StatefulWidget {
  // Common (Text) props
  final TextEditingController? controller;
  final String label;
  final String? hintText;
  final String? helperText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool isPassword;
  final TextInputType keyboardType;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final EdgeInsetsGeometry? contentPadding;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final AutovalidateMode? autovalidateMode;
  final Function(String)? onChanged;
  final Function(String)? onFieldSubmitted;
  final String? Function(String?)? validator;

  // Image picker props
  final bool isImagePicker;
  final double? height;
  final bool allowCamera;
  final bool allowGallery;
  final bool showClearButton;
  final File? initialImage;
  final void Function(File?)? onImageSelected;
  final String? Function(File?)? imageValidator;

  const CustomInput({
    super.key,
    required this.label,
    this.controller,
    this.hintText,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.contentPadding,
    this.focusNode,
    this.textInputAction,
    this.inputFormatters,
    this.autovalidateMode,
    this.onChanged,
    this.onFieldSubmitted,
    this.validator,

    // Image picker
    this.isImagePicker = false,
    this.height,
    this.allowCamera = true,
    this.allowGallery = true,
    this.showClearButton = true,
    this.initialImage,
    this.onImageSelected,
    this.imageValidator,
  });

  @override
  State<CustomInput> createState() => _CustomInputState();
}

class _CustomInputState extends State<CustomInput> {
  bool _obscureText = true;
  File? _selectedImage;
  bool _loadingImage = false;

  @override
  void initState() {
    super.initState();
    _selectedImage = widget.initialImage;
  }

  Future<void> _pickImage(ImageSource source, FormFieldState<File?>? formState) async {
    setState(() => _loadingImage = true);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      if (picked != null) {
        final file = File(picked.path);
        setState(() => _selectedImage = file);
        widget.onImageSelected?.call(file);
        formState?.didChange(file);
      }
    } catch (e) {
      debugPrint("Image pick error: $e");
    } finally {
      if (mounted) setState(() => _loadingImage = false);
    }
  }

  Future<void> _showImageSourceSheet(FormFieldState<File?> formState) async {
    // If only one option is allowed, go directly
    if (widget.allowGallery && !widget.allowCamera) {
      return _pickImage(ImageSource.gallery, formState);
    }
    if (widget.allowCamera && !widget.allowGallery) {
      return _pickImage(ImageSource.camera, formState);
    }

    // Otherwise show a bottom sheet to choose
    if (!widget.allowCamera && !widget.allowGallery) return;

    // Mobile-first action sheet
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.borderRadius)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              runSpacing: 8,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery, formState);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Take a Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera, formState);
                  },
                ),
                if (widget.showClearButton && _selectedImage != null)
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: Colors.red),
                    title: const Text('Remove Image'),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _selectedImage = null);
                      widget.onImageSelected?.call(null);
                      formState.didChange(null);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      labelText: widget.label,
      hintText: widget.hintText,
      helperText: widget.helperText,
      prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
      suffixIcon: widget.isPassword
          ? IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility_off : Icons.visibility,
                color: AppColors.kSecondary,
              ),
              onPressed: () => setState(() => _obscureText = !_obscureText),
            )
          : widget.suffixIcon,
      filled: true,
      fillColor: AppColors.kInputBackground,
      contentPadding: widget.contentPadding ??
          const EdgeInsets.symmetric(
            horizontal: AppSizes.padding,
            vertical: 16,
          ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Branch: Image picker as a FormField for proper validation and errors
    if (widget.isImagePicker) {
      final height = widget.height ?? 160.0;
      return FormField<File?>(
        initialValue: _selectedImage,
        autovalidateMode: widget.autovalidateMode ?? AutovalidateMode.onUserInteraction,
        validator: widget.imageValidator,
        builder: (formState) {
          final errorText = formState.errorText;
          return Semantics(
            label: widget.label,
            button: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.label, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                InkWell(
                  onTap: widget.enabled ? () => _showImageSourceSheet(formState) : null,
                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                  child: Container(
                    height: height,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.kInputBackground,
                      borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                      border: Border.all(
                        color: (errorText != null ? AppColors.kError : AppColors.kSecondary)
                            .withOpacity(errorText != null ? 0.6 : 0.3),
                      ),
                    ),
                    child: _loadingImage
                        ? Center(
                            child: Lottie.asset(
                              'assets/lottie/loader.json',
                              width: 80,
                              height: 80,
                              repeat: true,
                            ),
                          )
                        : _selectedImage != null
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                                    child: Image.file(_selectedImage!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                                  ),
                                  if (widget.showClearButton)
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Material(
                                        color: Colors.black45,
                                        borderRadius: BorderRadius.circular(20),
                                        child: InkWell(
                                          onTap: () {
                                            setState(() => _selectedImage = null);
                                            widget.onImageSelected?.call(null);
                                            formState.didChange(null);
                                          },
                                          borderRadius: BorderRadius.circular(20),
                                          child: const Padding(
                                            padding: EdgeInsets.all(6),
                                            child: Icon(Icons.close, color: Colors.white, size: 18),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image_outlined, size: 40, color: AppColors.kSecondary),
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.hintText ?? "Tap to upload image",
                                    style: TextStyle(color: AppColors.kTextSecondary),
                                  ),
                                ],
                              ),
                  ),
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    errorText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.kError),
                  ),
                ],
                if (widget.helperText != null && errorText == null) ...[
                  const SizedBox(height: 6),
                  Text(
                    widget.helperText!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.kTextSecondary),
                  ),
                ],
              ],
            ),
          );
        },
      );
    }

    // Text input (TextFormField) with validation and password toggle
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      inputFormatters: widget.inputFormatters,
      autovalidateMode: widget.autovalidateMode ?? AutovalidateMode.onUserInteraction,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      maxLines: widget.isPassword ? 1 : widget.maxLines,
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      obscureText: widget.isPassword ? _obscureText : false,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      decoration: _inputDecoration(),
    );
  }
}