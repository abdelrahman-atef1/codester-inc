/// bold_search_bar.dart — Search bar matching stitch-designs/03-inventory.html
///
/// Rounded white field, search icon on right (RTL), camera scan button on left,
/// red focus ring. Uses Cairo font.
library;

import 'package:flutter/material.dart';

import '../core/constants/bold_colors.dart';

class BoldSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onScanTap;
  final VoidCallback? onClear;

  const BoldSearchBar({
    super.key,
    required this.controller,
    this.hint = 'ابحث بالاسم أو الباركود...',
    this.onChanged,
    this.onScanTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textDirection: TextDirection.rtl,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 13,
          color: BoldColors.text,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintTextDirection: TextDirection.rtl,
          hintStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13,
            color: BoldColors.textFaint,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          // Search icon on right (RTL start)
          suffixIcon: const Padding(
            padding: EdgeInsetsDirectional.only(end: 14),
            child: Icon(Icons.search, color: BoldColors.textFaint, size: 20),
          ),
          suffixIconConstraints:
              const BoxConstraints(minWidth: 40, minHeight: 40),
          // Camera scan button on left (RTL end)
          prefixIcon: Padding(
            padding: const EdgeInsetsDirectional.only(start: 6),
            child: GestureDetector(
              onTap: onScanTap,
              child: Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: BoldColors.chipGrey,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.qr_code_scanner,
                    color: BoldColors.textLight, size: 18),
              ),
            ),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 44, minHeight: 44),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: BoldColors.borderStrong, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: BoldColors.borderStrong, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: BoldColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}
