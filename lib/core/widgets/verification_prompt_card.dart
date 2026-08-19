import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/constants/app_colors.dart';

class VerificationPromptCard extends StatelessWidget {
  const VerificationPromptCard({
    super.key,
    required this.missingCount,
    required this.accountVerified,
    required this.route,
  });

  final int missingCount;
  final bool accountVerified;
  final String route;

  @override
  Widget build(BuildContext context) {
    if (missingCount <= 0 && accountVerified) {
      return const SizedBox.shrink();
    }

    final hasMissingDocuments = missingCount > 0;
    final title = hasMissingDocuments
        ? 'Upload Verification Documents'
        : 'Verification in Process ';
    final message = hasMissingDocuments
        ? 'Upload verification documents to approve your profile.'
        : 'Your documents are submitted and under review. We will notify you once your profile is approved.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF044071),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.subtleText,
                ),
              ),
              if (hasMissingDocuments) ...[
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => context.push(route),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF044071),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Upload Documents'),
                ),
              ],
            ],
          );

          final icon = Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: Color(0xFFFF460C),
              size: 28,
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                icon,
                const SizedBox(height: 12),
                content,
              ],
            );
          }

          return Row(
            children: [
              icon,
              const SizedBox(width: 14),
              Expanded(child: content),
            ],
          );
        },
      ),
    );
  }
}
