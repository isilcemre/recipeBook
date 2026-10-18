import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class HeroBanner extends StatelessWidget {
  final int recipeCount;
  final VoidCallback onRandomPick;

  const HeroBanner({
    super.key,
    required this.recipeCount,
    required this.onRandomPick,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brandDark, AppColors.brand],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bugün ne pişirsen?',
                  style: GoogleFonts.fraunces(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                 
              ],
            ),
          ),
          const SizedBox(width: 12),
          _RandomButton(onPick: onRandomPick),
        ],
      ),
    );
  }
}

class _RandomButton extends StatelessWidget {
  final VoidCallback onPick;

  const _RandomButton({required this.onPick});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPick,
      icon: const Text('🎲', style: TextStyle(fontSize: 16)),
      label: const Text('Şansıma Bırak'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.mustard,
        foregroundColor: const Color(0xFF241A00),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}