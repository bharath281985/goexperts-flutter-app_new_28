import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../domain/entities/startup.dart';

class AppStartupCard extends StatelessWidget {
  const AppStartupCard({
    super.key,
    required this.startup,
    this.onTap,
    this.onSave,
    this.onInterest,
    this.hasInvested = false,
    this.onEdit,
    this.onDelete,
  });

  final Startup startup;
  final VoidCallback? onTap;
  final VoidCallback? onSave;
  final VoidCallback? onInterest;
  final bool hasInvested;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 650) {
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 240,
                        child: _LeftPanelSmall(
                          startup: startup,
                          isRowLayout: false,
                        ),
                      ),
                      Expanded(
                        child: _RightPanelSmall(
                          startup: startup,
                          onTap: onTap,
                          onSave: onSave,
                          onInterest: onInterest,
                          hasInvested: hasInvested,
                          onEdit: onEdit,
                          onDelete: onDelete,
                          isWide: true,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Column(
                children: [
                  SizedBox(
                    height: 145,
                    width: double.infinity,
                    child: _LeftPanelSmall(
                      startup: startup,
                      isRowLayout: true,
                      onSave: onSave,
                      onTap: onTap,
                    ),
                  ),
                  _RightPanelSmall(
                    startup: startup,
                    onTap: onTap,
                    onSave: onSave,
                    onInterest: onInterest,
                    hasInvested: hasInvested,
                    onEdit: onEdit,
                    onDelete: onDelete,
                    isWide: false,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LeftPanelSmall extends StatelessWidget {
  const _LeftPanelSmall({
    required this.startup,
    required this.isRowLayout,
    this.onSave,
    this.onTap,
  });
  final Startup startup;
  final bool isRowLayout;
  final VoidCallback? onSave;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background Image
        Positioned.fill(
          child: startup.coverUrl != null && startup.coverUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: startup.coverUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, _) => Container(
                    color: AppColors.primary.withValues(alpha: 0.1),
                  ),
                  errorWidget: (context, _, __) =>
                      Container(color: const Color(0xFF1E1E2C)),
                )
              : Container(color: const Color(0xFF1E1E2C)),
        ),
        // Overlay gradient
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.2),
                  Colors.black.withValues(alpha: 0.6),
                ],
              ),
            ),
          ),
        ),
        // Red Swoop overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 100,
          child: ClipPath(
            clipper: _LeftPanelSwoopClipper(),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFF3B30), Color(0xFFC80010)],
                ),
              ),
            ),
          ),
        ),

        // Featured Badge
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFF3B30),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star_outline_rounded,
                  color: Colors.white,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  'Featured',
                  style: context.text.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Logo
        Positioned(top: 16, right: 16, child: _buildLogoBox(context)),

        // Title, Bio, Save Button (over Swoop)
        Positioned(
          bottom: 12,
          left: 16,
          right: 16,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            startup.name,
                            style: context.text.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (startup.isVerified) ...[
                          const SizedBox(width: 6),
                          const VerifiedBadge(size: 20, color: Colors.white),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      startup.problem.isNotEmpty
                          ? startup.problem
                          : startup.tagline,
                      style: context.text.titleSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onSave != null || onTap != null)
                InkWell(
                  onTap: onSave ?? onTap,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        startup.isSaved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_outline_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoBox(BuildContext context) {
    return InkWell(
      onTap: (startup.founderId != null && startup.founderId!.isNotEmpty)
          ? () => context.push('${Routes.publicFounder}/${startup.founderId}')
          : onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: (startup.logoUrl != null && startup.logoUrl!.isNotEmpty)
                ? CachedNetworkImage(
                    imageUrl: startup.logoUrl!,
                    width: 76,
                    height: 76,
                    fit: BoxFit.cover,
                    errorWidget: (context, _, __) => const Icon(
                      Icons.business_rounded,
                      color: Color(0xFFFF3B30),
                      size: 36,
                    ),
                  )
                : const Icon(
                    Icons.business_rounded,
                    color: Color(0xFFFF3B30),
                    size: 36,
                  ),
          ),
        ),
      ),
    );
  }
}

class _LeftPanelSwoopClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height * 0.4);
    path.quadraticBezierTo(size.width * 0.5, 0, size.width, size.height * 0.2);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _RightPanelSmall extends StatelessWidget {
  const _RightPanelSmall({
    required this.startup,
    this.onTap,
    this.onSave,
    this.onInterest,
    required this.hasInvested,
    this.onEdit,
    this.onDelete,
    required this.isWide,
  });
  final Startup startup;
  final VoidCallback? onTap;
  final VoidCallback? onSave;
  final VoidCallback? onInterest;
  final bool hasInvested;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isWide; // To adjust internal grids based on space

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scrollable thin chips row (to save vertical space)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (startup.founderName.isNotEmpty) ...[
                  InkWell(
                    onTap: (startup.founderId != null &&
                            startup.founderId!.isNotEmpty)
                        ? () => context.push(
                            '${Routes.publicFounder}/${startup.founderId}')
                        : null,
                    borderRadius: BorderRadius.circular(6),
                    child: _InfoChipSmall(
                      icon: Icons.person_outline_rounded,
                      label: startup.founderName,
                      color: const Color(0xFF5E5CE6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('|', style: TextStyle(color: Colors.grey.shade300)),
                  const SizedBox(width: 8),
                ],
                _InfoChipSmall(
                  icon: Icons.business_center_outlined,
                  label: startup.industry,
                  color: const Color(0xFFFF3B30),
                ),
                const SizedBox(width: 8),
                Text('|', style: TextStyle(color: Colors.grey.shade300)),
                const SizedBox(width: 8),
                _InfoChipSmall(
                  icon: Icons.location_on_outlined,
                  label: startup.location.isNotEmpty
                      ? startup.location
                      : 'Global',
                  color: const Color(0xFF4B5563),
                ),
                const SizedBox(width: 8),
                Text('|', style: TextStyle(color: Colors.grey.shade300)),
                const SizedBox(width: 8),
                const _InfoChipSmall(
                  icon: Icons.language_rounded,
                  label: 'Website',
                  color: Color(0xFF4B5563),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 4 Stats Grid (Responsive to wide vs narrow)
          if (isWide)
            Row(
              children: [
                Expanded(
                  child: _StatBlock(
                    icon: Icons.currency_rupee_rounded,
                    iconColor: const Color(0xFFFF3B30),
                    bgColor: const Color(0xFFFFEBEA),
                    label: 'Seeking',
                    value: Formatters.compactCurrency(startup.fundingRequired),
                  ),
                ),
                const SizedBox(width: 3), // User explicitly updated space to 3
                Expanded(
                  child: _StatBlock(
                    icon: Icons.pie_chart_rounded,
                    iconColor: const Color(0xFF34C759),
                    bgColor: const Color(0xFFE8F8EC),
                    label: 'Equity',
                    value: '${startup.equityOffered.toStringAsFixed(0)}%',
                  ),
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: _StatBlock(
                    icon: Icons.bar_chart_rounded,
                    iconColor: const Color(0xFF5E5CE6),
                    bgColor: const Color(0xFFEEEBFF),
                    label: 'Stage',
                    value: startup.stage.isNotEmpty ? startup.stage : 'Idea',
                  ),
                ),
                const SizedBox(width: 3),
                const Expanded(
                  child: _StatBlock(
                    icon: Icons.people_outline_rounded,
                    iconColor: Color(0xFFFF9500),
                    bgColor: Color(0xFFFFF4E5),
                    label: 'Team',
                    value: '15+',
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatBlock(
                        icon: Icons.currency_rupee_rounded,
                        iconColor: const Color(0xFFFF3B30),
                        bgColor: const Color(0xFFFFEBEA),
                        label: 'Seeking',
                        value: Formatters.compactCurrency(
                          startup.fundingRequired,
                        ),
                      ),
                    ),
                    const SizedBox(width: 3), // Updated space to 3
                    Expanded(
                      child: _StatBlock(
                        icon: Icons.pie_chart_rounded,
                        iconColor: const Color(0xFF34C759),
                        bgColor: const Color(0xFFE8F8EC),
                        label: 'Equity',
                        value: '${startup.equityOffered.toStringAsFixed(0)}%',
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 8,
                ), // Replaced large gap with compact gap
                Row(
                  children: [
                    Expanded(
                      child: _StatBlock(
                        icon: Icons.bar_chart_rounded,
                        iconColor: const Color(0xFF5E5CE6),
                        bgColor: const Color(0xFFEEEBFF),
                        label: 'Stage',
                        value: startup.stage.isNotEmpty
                            ? startup.stage
                            : 'Idea',
                      ),
                    ),
                    const SizedBox(width: 3), // Updated space to 3
                    const Expanded(
                      child: _StatBlock(
                        icon: Icons.people_outline_rounded,
                        iconColor: Color(0xFFFF9500),
                        bgColor: Color(0xFFFFF4E5),
                        label: 'Team',
                        value: '15+',
                      ),
                    ),
                  ],
                ),
              ],
            ),

          const SizedBox(height: 16),
          // Tags
          if (startup.tags.isNotEmpty) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: startup.tags
                    .map(
                      (t) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _OutlinedTagSmall(label: t),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
          ] else ...[
            const SizedBox(height: 0),
          ],

          // Funding Progress
          _FundingProgressSmall(startup: startup),

          const SizedBox(height: 8),

          Row(
            children: [
              if (onSave != null)
                Expanded(
                  child: _OutlinedBtnSmall(
                    icon: startup.isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_outline_rounded,
                    label: startup.isSaved ? 'Saved' : 'Save',
                    onTap: onSave!,
                  ),
                ),
              if (onSave != null) const SizedBox(width: 12),
              Expanded(
                flex: onSave != null ? 2 : 1,
                child: _SolidBtnSmall(
                  label: (hasInvested || startup.hasInvested)
                      ? 'Withdraw'
                      : (onInterest != null ? 'Invest' : 'View Details'),
                  hasInvested: (hasInvested || startup.hasInvested),
                  onTap: onInterest ?? onTap ?? () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChipSmall extends StatelessWidget {
  const _InfoChipSmall({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: context.text.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: context.text.labelMedium?.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: context.text.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1E1E2C),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _OutlinedTagSmall extends StatelessWidget {
  const _OutlinedTagSmall({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        color: const Color(0xFFF9FAFB),
      ),
      child: Text(
        label,
        style: context.text.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: const Color(0xFF374151),
        ),
      ),
    );
  }
}

class _FundingProgressSmall extends StatelessWidget {
  const _FundingProgressSmall({required this.startup});
  final Startup startup;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Funding Progress',
                style: context.text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E1E2C),
                ),
              ),
              Text(
                '${(startup.fundingProgress * 100).toStringAsFixed(0)}% Funded',
                style: context.text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFFF3B30),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: startup.fundingProgress,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B30),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Positioned(
                left: startup.fundingProgress == 0 ? 0 : null,
                right: startup.fundingProgress == 0
                    ? null
                    : (1 - startup.fundingProgress) *
                          (MediaQuery.of(context).size.width - 64) *
                          0.7,
                child: Align(
                  alignment: Alignment(startup.fundingProgress * 2 - 1, 0),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B30),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.rocket_launch_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${Formatters.compactCurrency(startup.fundingRaised)} Raised',
                style: context.text.labelSmall?.copyWith(
                  color: const Color(0xFF6B7280),
                ),
              ),
              Text(
                '${Formatters.compactCurrency(startup.fundingRequired)} Goal',
                style: context.text.labelSmall?.copyWith(
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OutlinedBtnSmall extends StatelessWidget {
  const _OutlinedBtnSmall({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFFFF3B30), size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: context.text.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E1E2C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SolidBtnSmall extends StatelessWidget {
  const _SolidBtnSmall({
    required this.label,
    required this.onTap,
    this.hasInvested = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool hasInvested;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: hasInvested
                ? [
                    const Color(0xFF6B7280),
                    const Color(0xFF374151),
                  ] // Grey metallic gradient for withdraw
                : [
                    const Color(0xFFFF3B30),
                    const Color(0xFF000000),
                  ], // Signature red for Invest
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF3B30).withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: context.text.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
