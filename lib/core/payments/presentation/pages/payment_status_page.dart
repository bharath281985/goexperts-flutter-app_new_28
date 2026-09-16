import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../extensions/context_extensions.dart';

class PaymentStatusPage extends StatelessWidget {
  const PaymentStatusPage({
    super.key,
    required this.isSuccess,
    this.message,
  });

  final bool isSuccess;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: context.isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.xl),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSuccess
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.danger.withValues(alpha: 0.1),
                  ),
                  child: Icon(
                    isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    size: 100,
                    color: isSuccess ? AppColors.success : AppColors.danger,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.xxl),
              Text(
                isSuccess ? 'Payment Successful' : 'Payment Failed',
                textAlign: TextAlign.center,
                style: context.text.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: AppSizes.md),
              Text(
                message ??
                    (isSuccess
                        ? 'Your transaction has been completed successfully.'
                        : 'Something went wrong while processing your payment. Please try again.'),
                textAlign: TextAlign.center,
                style: context.text.bodyLarge?.copyWith(
                  color: AppColors.mutedText,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              AppPrimaryButton(
                label: isSuccess ? 'Continue' : 'Try Again',
                onPressed: () {
                  if (context.canPop()) {
                    context.pop(isSuccess);
                  } else {
                    context.go(Routes.subscriptionsManage);
                  }
                },
              ),
              const SizedBox(height: AppSizes.xl),
            ],
          ),
        ),
      ),
    );
  }
}
