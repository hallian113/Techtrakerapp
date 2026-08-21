import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPunchIn; // Agar true toh Green, agar false (punch out) toh Red
  final bool isLoading; // Agar true toh loading spinner show hoga

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isPunchIn = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    // Agar Punch In/Out ka button hai toh uski color change karein
    Color buttonColor = isPunchIn ? Colors.green.shade700 : Colors.red.shade700;

    // Agar normal button hai (jaise Login) toh Gold color do
    if (text.toLowerCase().contains('login') ||
        text.toLowerCase().contains('submit')) {
      buttonColor = const Color(0xFFD4AF37);
    }

    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.black, // Text color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 5,
          shadowColor: buttonColor.withOpacity(0.5),
        ),
        onPressed: isLoading ? null : onPressed, // Loading state
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.black)
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
      ),
    );
  }
}
