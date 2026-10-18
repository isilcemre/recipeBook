import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.mustard,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                size: 50,
                color: Color(0xFF241A00),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'My Recipe Book',
              style: GoogleFonts.fraunces(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Akıllı Tarif Defteri',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: const Color(0xFFDFE9DF),
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              color: AppColors.mustard,
              strokeWidth: 2.5,
            ),
          ],
        ),
      ),
    );
  }
}
