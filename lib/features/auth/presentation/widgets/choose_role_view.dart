import 'package:flutter/material.dart';
import '../../../../app/constants/app_assets.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../core/utils/enums.dart';
import '../../../../core/widgets/icon_widget.dart';

/// Redesigned Role Selection View matching attached image reference
class ChooseRoleView extends StatefulWidget {
  final ValueChanged<UserRole> onRoleSelected;
  final VoidCallback? onBack;

  const ChooseRoleView({super.key, required this.onRoleSelected, this.onBack});

  @override
  State<ChooseRoleView> createState() => _ChooseRoleViewState();
}

class _ChooseRoleViewState extends State<ChooseRoleView> {
  UserRole? _selectedRole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar Navigation
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconTapWidget(
                    onTap: () => widget.onBack?.call(),
                    iconImage: AppAssets.backIcon,
                  ),
                  // IconButton(
                  //   icon: const Icon(
                  //     Icons.chevron_left_rounded,
                  //     size: 32,
                  //     color: Color(0xFF1F2937),
                  //   ),
                  //   onPressed: widget.onBack,
                  //   tooltip: 'Back',
                  // ),
                  // IconButton(
                  //   icon: Icon(
                  //     Icons.chevron_right_rounded,
                  //     size: 32,
                  //     color: _selectedRole != null
                  //         ? const Color(0xFF1F2937)
                  //         : const Color(0xFFD1D5DB),
                  //   ),
                  //   onPressed: _selectedRole != null
                  //       ? () => widget.onRoleSelected(_selectedRole!)
                  //       : null,
                  //   tooltip: 'Continue',
                  // ),
                ],
              ),
            ),

            // Header Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Text(
                'Choose how you want\nto use Go Experts',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                  height: 1.25,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Role Cards List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _buildRoleCard(
                    role: UserRole.freelancer,
                    title: 'Freelancer / Expert',
                    subtitle: 'Find work & grow your career',
                    icon: Icons.person_outline_rounded,
                    bgColor: const Color(0xFFF5F3FF),
                    borderColor: const Color(0xFFDDD6FE),
                    activeBorderColor: const Color(0xFF7C3AED),
                    iconBgColor: const Color(0xFFEDE9FE),
                    iconColor: const Color(0xFF7C3AED),
                  ),
                  const SizedBox(height: 16),
                  _buildRoleCard(
                    role: UserRole.client,
                    title: 'Client / Business Owner',
                    subtitle: 'Find experts & get work done',
                    icon: Icons.groups_outlined,
                    bgColor: const Color(0xFFF0F9FF),
                    borderColor: const Color(0xFFBAE6FD),
                    activeBorderColor: const Color(0xFF0284C7),
                    iconBgColor: const Color(0xFFE0F2FE),
                    iconColor: const Color(0xFF0284C7),
                  ),
                  const SizedBox(height: 16),
                  _buildRoleCard(
                    role: UserRole.founder,
                    title: 'Startup Founder',
                    subtitle: 'Build, grow & raise funding',
                    icon: Icons.person_rounded,
                    bgColor: const Color(0xFFF0FDF4),
                    borderColor: const Color(0xFFBBF7D0),
                    activeBorderColor: const Color(0xFF16A34A),
                    iconBgColor: const Color(0xFFDCFCE7),
                    iconColor: const Color(0xFF16A34A),
                  ),
                  const SizedBox(height: 16),
                  _buildRoleCard(
                    role: UserRole.investor,
                    title: 'Investor',
                    subtitle: 'Discover & invest in opportunities',
                    icon: Icons.person_pin_outlined,
                    bgColor: const Color(0xFFFFF7ED),
                    borderColor: const Color(0xFFFFEDD5),
                    activeBorderColor: const Color(0xFFEA580C),
                    iconBgColor: const Color(0xFFFFEDD5),
                    iconColor: const Color(0xFFEA580C),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required UserRole role,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color bgColor,
    required Color borderColor,
    required Color activeBorderColor,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    final isSelected = _selectedRole == role;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedRole = role;
          });
          widget.onRoleSelected(role);
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? activeBorderColor : borderColor,
              width: isSelected ? 2 : 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeBorderColor.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
