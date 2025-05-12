import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool isError;

  const CustomTextField({
    Key? key,
    required this.label,
    required this.controller,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.isError = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1976D2); // 主题蓝色
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 16.0),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isError ? Colors.red : Colors.grey[600],
            fontSize: 15.0,
          ),
          prefixIcon: prefixIcon != null 
              ? Icon(prefixIcon, color: isError ? Colors.red : primaryColor, size: 22) 
              : null,
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(
              color: isError ? Colors.red : Colors.grey[300]!,
              width: 1.0,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(
              color: isError ? Colors.red : Colors.grey[300]!,
              width: 1.0,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(
              color: isError ? Colors.red : primaryColor,
              width: 2.0,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 1.0,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 2.0,
            ),
          ),
          errorStyle: const TextStyle(
            color: Colors.red,
            fontSize: 12.0,
          ),
        ),
      ),
    );
  }
} 