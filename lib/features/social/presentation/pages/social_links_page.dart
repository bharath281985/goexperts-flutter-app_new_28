import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/network/api_client_helper.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../data/models/social_link_model.dart';
import '../../data/providers/social_links_cubit.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialLinksPage extends StatelessWidget {
  const SocialLinksPage({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SocialLinksCubit(sl<ApiClientHelper>()),
      child: const _SocialLinksPageContent(),
    );
  }
}

class _SocialLinksPageContent extends StatefulWidget {
  const _SocialLinksPageContent();

  @override
  State<_SocialLinksPageContent> createState() =>
      _SocialLinksPageContentState();
}

class _SocialLinksPageContentState extends State<_SocialLinksPageContent> {
  IconData _getIconForPlatform(String platform) {
    switch (platform.toLowerCase()) {
      case 'linkedin':
        return Icons.business_center;
      case 'github':
        return Icons.code;
      case 'twitter':
        return Icons.flutter_dash;
      case 'facebook':
        return Icons.facebook;
      case 'instagram':
        return Icons.camera_alt;
      case 'portfolio':
        return Icons.language;
      default:
        return Icons.link;
    }
  }

  void _deleteLink(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Link'),
        content: const Text('Are you sure you want to delete this link?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      final success = await context.read<SocialLinksCubit>().deleteLink(id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Link deleted'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not launch $urlString')));
      }
    }
  }

  void _showFormSheet({SocialLink? link}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return BlocProvider.value(
          value: context.read<SocialLinksCubit>(),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: _SocialLinkFormSheet(initialLink: link),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'My Social Links',
          style: TextStyle(color: AppColors.darkText),
        ),
        backgroundColor: AppColors.card,
        iconTheme: const IconThemeData(color: AppColors.darkText),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _showFormSheet(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: BlocBuilder<SocialLinksCubit, SocialLinksState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Connected Profiles',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add links to your professional and social profiles to enhance your portfolio.',
                  style: TextStyle(color: AppColors.mutedText),
                ),
                const SizedBox(height: 32),

                if (state.isLoading && state.links.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else if (state.error != null && state.links.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Error: ${state.error}',
                          style: const TextStyle(color: AppColors.danger),
                        ),
                        TextButton(
                          onPressed: () =>
                              context.read<SocialLinksCubit>().fetchLinks(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                else if (state.links.isEmpty)
                  _buildEmptyState()
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.links.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final link = state.links[index];
                      return _buildLinkCard(link);
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.link_off,
                size: 48,
                color: AppColors.mutedText,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No social links yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your first link using the + button below.',
              style: TextStyle(color: AppColors.mutedText),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkCard(SocialLink link) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getIconForPlatform(link.platform),
            color: AppColors.primary,
          ),
        ),
        title: Text(
          link.platform,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          link.url,
          style: const TextStyle(color: AppColors.info),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.open_in_new, color: AppColors.mutedText),
              onPressed: () => _launchUrl(link.url),
              tooltip: 'Open link',
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.mutedText),
              onPressed: () => _showFormSheet(link: link),
              tooltip: 'Edit link',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              onPressed: () => _deleteLink(link.id),
              tooltip: 'Delete link',
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialLinkFormSheet extends StatefulWidget {
  final SocialLink? initialLink;

  const _SocialLinkFormSheet({this.initialLink});

  @override
  State<_SocialLinkFormSheet> createState() => _SocialLinkFormSheetState();
}

class _SocialLinkFormSheetState extends State<_SocialLinkFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _urlController;
  String _selectedPlatform = 'LinkedIn';

  final List<String> _platforms = [
    'LinkedIn',
    'GitHub',
    'Twitter',
    'Facebook',
    'Instagram',
    'Portfolio',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.initialLink?.url ?? '');
    if (widget.initialLink != null &&
        _platforms.contains(widget.initialLink!.platform)) {
      _selectedPlatform = widget.initialLink!.platform;
    } else if (widget.initialLink != null) {
      _selectedPlatform = 'Other';
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  IconData _getIconForPlatform(String platform) {
    switch (platform.toLowerCase()) {
      case 'linkedin':
        return Icons.business_center;
      case 'github':
        return Icons.code;
      case 'twitter':
        return Icons.flutter_dash;
      case 'facebook':
        return Icons.facebook;
      case 'instagram':
        return Icons.camera_alt;
      case 'portfolio':
        return Icons.language;
      default:
        return Icons.link;
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final cubit = context.read<SocialLinksCubit>();
      final platform = _selectedPlatform;
      final url = _urlController.text;

      bool success;
      if (widget.initialLink != null) {
        success = await cubit.updateLink(widget.initialLink!.id, platform, url);
      } else {
        success = await cubit.addLink(platform, url);
      }

      if (mounted) {
        Navigator.pop(context); // Close the sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Saved successfully' : 'Error saving link'),
            backgroundColor: success ? AppColors.success : AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialLink != null;
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Edit Link' : 'Add New Link',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  value: _selectedPlatform,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Platform',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: _platforms.map((platform) {
                    return DropdownMenuItem(
                      value: platform,
                      child: Row(
                        children: [
                          Icon(
                            _getIconForPlatform(platform),
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              platform,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedPlatform = val);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    labelText: 'URL',
                    hintText: 'https://...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Please enter a URL';
                    }
                    final uri = Uri.tryParse(val.trim());

                    if (uri == null ||
                        (uri.scheme != 'http' && uri.scheme != 'https') ||
                        uri.host.isEmpty) {
                      return 'Please enter a valid URL';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                BlocBuilder<SocialLinksCubit, SocialLinksState>(
                  builder: (context, state) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: state.isLoading ? null : _submit,
                        child: state.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                isEditing ? 'Update Link' : 'Add Link',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
