import 'package:flutter/material.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../core/extensions/context_extensions.dart';

class ReferralPromoBanner extends StatelessWidget {
  const ReferralPromoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE0F2FE), // Light blue
            Color(0xFFF0F9FF), // Lighter blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '🚀',
                style: TextStyle(fontSize: 24),
              ),
              AppSizes.hGapSm,
              Expanded(
                child: Text(
                  'Refer. Earn. Grow.',
                  style: context.text.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0369A1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildBulletItem(
            context,
            icon: Icons.monetization_on_rounded,
            iconColor: const Color(0xFF16A34A),
            text: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Earn '),
                  const TextSpan(
                    text: '₹25 instantly',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                  ),
                  const TextSpan(text: ' for every successful referral.'),
                ],
              ),
              style: context.text.bodyMedium?.copyWith(color: const Color(0xFF0F172A)),
            ),
          ),
          const SizedBox(height: 12),
          _buildBulletItem(
            context,
            icon: Icons.percent_rounded,
            iconColor: const Color(0xFFD97706),
            text: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'When your referred user purchases a package, you’ll receive an additional '),
                  const TextSpan(
                    text: '5% commission',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                  ),
                  const TextSpan(text: ' on the package value.'),
                ],
              ),
              style: context.text.bodyMedium?.copyWith(color: const Color(0xFF0F172A)),
            ),
          ),
          const SizedBox(height: 12),
          _buildBulletItem(
            context,
            icon: Icons.account_balance_wallet_rounded,
            iconColor: const Color(0xFF2563EB),
            text: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'Every reward is credited instantly to your wallet',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: ', so you can track your earnings in real time.'),
                ],
              ),
              style: context.text.bodyMedium?.copyWith(color: const Color(0xFF0F172A)),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Refer → Earn ₹25 → Earn 5% Commission → Get Paid Instantly',
                    textAlign: TextAlign.center,
                    style: context.text.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Widget text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(child: text),
      ],
    );
  }
}
