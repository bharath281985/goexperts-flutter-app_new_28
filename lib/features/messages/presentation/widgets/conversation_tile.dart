import 'package:flutter/material.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../domain/entities/conversation.dart';

/// Reusable conversation list row.
class ConversationTile extends StatelessWidget {
  const ConversationTile({
    super.key,
    required this.conversation,
    this.onTap,
    this.onLongPress,
  });

  final Conversation conversation;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = conversation;
    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.xs,
        vertical: 2,
      ),
      leading: AppAvatar(
        name: c.name,
        imageUrl: c.avatarUrl,
        size: 50,
        showOnline: true,
        isOnline: c.isOnline,
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    c.name,
                    style: context.text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (c.role.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  _RoleBadge(role: c.role),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (c.isPinned) ...[
                const Icon(
                  Icons.push_pin_rounded,
                  size: 13,
                  color: AppColors.mutedText,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                Formatters.relative(c.lastMessageAt),
                style: context.text.labelSmall?.copyWith(
                  color: AppColors.mutedText,
                ),
              ),
            ],
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Row(
          children: [
            if (c.isMuted)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.volume_off_rounded,
                  size: 13,
                  color: AppColors.mutedText,
                ),
              ),
            Expanded(
              child: Text(
                c.isTyping ? 'typing…' : c.lastMessage,
                style: context.text.bodySmall?.copyWith(
                  color: c.isTyping ? AppColors.success : null,
                  fontStyle: c.isTyping ? FontStyle.italic : FontStyle.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (c.unreadCount > 0)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                child: Text(
                  '${c.unreadCount}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    final clean = role.trim().toLowerCase();
    if (clean.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color border;
    Color text;
    String label;

    switch (clean) {
      case 'freelancer':
        bg = isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.4) : const Color(0xFFEFF6FF);
        border = isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.5) : const Color(0xFFBFDBFE);
        text = isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB);
        label = 'Freelancer';
        break;
      case 'client':
        bg = isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFECFDF5);
        border = isDark ? const Color(0xFF10B981).withValues(alpha: 0.5) : const Color(0xFFA7F3D0);
        text = isDark ? const Color(0xFF6EE7B7) : const Color(0xFF059669);
        label = 'Client';
        break;
      case 'founder':
        bg = isDark ? const Color(0xFF78350F).withValues(alpha: 0.4) : const Color(0xFFFFFBEB);
        border = isDark ? const Color(0xFFF59E0B).withValues(alpha: 0.5) : const Color(0xFFFDE68A);
        text = isDark ? const Color(0xFFFCD34D) : const Color(0xFFD97706);
        label = 'Founder';
        break;
      case 'investor':
        bg = isDark ? const Color(0xFF4C1D95).withValues(alpha: 0.4) : const Color(0xFFF5F3FF);
        border = isDark ? const Color(0xFF8B5CF6).withValues(alpha: 0.5) : const Color(0xFFDDD6FE);
        text = isDark ? const Color(0xFFC4B5FD) : const Color(0xFF7C3AED);
        label = 'Investor';
        break;
      case 'admin':
        bg = isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.4) : const Color(0xFFFEF2F2);
        border = isDark ? const Color(0xFFEF4444).withValues(alpha: 0.5) : const Color(0xFFFECACA);
        text = isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626);
        label = 'Admin';
        break;
      default:
        bg = isDark ? Colors.grey.shade800 : const Color(0xFFF3F4F6);
        border = isDark ? Colors.grey.shade700 : const Color(0xFFE5E7EB);
        text = isDark ? Colors.grey.shade300 : const Color(0xFF4B5563);
        label = role[0].toUpperCase() + role.substring(1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

