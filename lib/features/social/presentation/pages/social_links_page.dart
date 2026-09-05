import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/dashboard_app_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../data/providers/social_links_provider.dart';
import '../data/models/social_link_model.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialLinksPage extends ConsumerStatefulWidget {
  const SocialLinksPage({super.key});

  @override
  ConsumerState<SocialLinksPage> createState() => _SocialLinksPageState();
}

class _SocialLinksPageState extends ConsumerState<SocialLinksPage> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  String _selectedPlatform = 'LinkedIn';
  String? _editingId;

  final List<String> _platforms = [
    'LinkedIn',
    'GitHub',
    'Twitter',
    'Facebook',
    'Instagram',
    'Portfolio',
    'Other'
  ];

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  IconData _getIconForPlatform(String platform) {
    switch (platform.toLowerCase()) {
      case 'linkedin':
        return Icons.business_center; // or specific linkedin icon if available
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

  Color _getColorForPlatform(String platform) {
    switch (platform.toLowerCase()) {
      case 'linkedin':
        return const Color(0xFF0077b5);
      case 'github':
        return const Color(0xFF333333);
      case 'twitter':
        return const Color(0xFF1DA1F2);
      case 'facebook':
        return const Color(0xFF1877F2);
      case 'instagram':
        return const Color(0xFFE4405F);
      case 'portfolio':
        return AppColors.primary;
      default:
        return Colors.grey.shade700;
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final notifier = ref.read(socialLinksProvider.notifier);
      bool success = false;
      
      if (_editingId != null) {
        success = await notifier.updateLink(
          _editingId!,
          _selectedPlatform,
          _urlController.text.trim(),
        );
      } else {
        success = await notifier.addLink(
          _selectedPlatform,
          _urlController.text.trim(),
        );
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_editingId != null ? 'Link updated' : 'Link added'),
            backgroundColor: Colors.green,
          ),
        );
        _resetForm();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save link'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _resetForm() {
    setState(() {
      _editingId = null;
      _selectedPlatform = 'LinkedIn';
      _urlController.clear();
    });
  }

  void _editLink(SocialLink link) {
    setState(() {
      _editingId = link.id;
      _selectedPlatform = _platforms.contains(link.platform) 
          ? link.platform 
          : 'Other';
      _urlController.text = link.url;
    });
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref.read(socialLinksProvider.notifier).deleteLink(id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link deleted'), backgroundColor: Colors.red),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $urlString')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(socialLinksProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const DashboardAppBar(title: 'My Social Links'),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Connected Profiles',
                    style: AppTextStyles.h3,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add links to your social profiles, portfolios, and other relevant professional sites to build trust with clients and collaborators.',
                    style: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 32),
                  
                  if (state.isLoading && state.links.isEmpty)
                    const Center(child: CircularProgressIndicator())
                  else if (state.error != null && state.links.isEmpty)
                    Center(child: Text(state.error!, style: const TextStyle(color: Colors.red)))
                  else if (state.links.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.link_off, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'No links added yet',
                            style: AppTextStyles.h4.copyWith(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Use the form to add your first social link',
                            style: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: state.links.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final link = state.links[index];
                        return _buildLinkCard(link);
                      },
                    ),
                ],
              ),
            ),
          ),
          
          // Form sidebar
          Container(
            width: 400,
            color: Colors.white,
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _editingId != null ? 'Edit Link' : 'Add New Link',
                    style: AppTextStyles.h4,
                  ),
                  const SizedBox(height: 24),
                  
                  const Text('Platform', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedPlatform,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: _platforms.map((platform) {
                      return DropdownMenuItem(
                        value: platform,
                        child: Row(
                          children: [
                            Icon(_getIconForPlatform(platform), color: _getColorForPlatform(platform), size: 20),
                            const SizedBox(width: 12),
                            Text(platform),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedPlatform = val);
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  const Text('URL', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      hintText: 'https://...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a URL';
                      }
                      if (!value.startsWith('http://') && !value.startsWith('https://')) {
                        return 'URL must start with http:// or https://';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: state.isLoading ? null : _submitForm,
                      child: state.isLoading && _editingId == null
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              _editingId != null ? 'Update Link' : 'Save Link',
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                  
                  if (_editingId != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _resetForm,
                        child: Text('Cancel Edit', style: TextStyle(color: Colors.grey.shade700)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkCard(SocialLink link) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getColorForPlatform(link.platform).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getIconForPlatform(link.platform),
            color: _getColorForPlatform(link.platform),
          ),
        ),
        title: Text(link.platform, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          link.url,
          style: TextStyle(color: Colors.blue.shade700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.open_in_new, color: Colors.grey),
              tooltip: 'Visit link',
              onPressed: () => _launchUrl(link.url),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
              tooltip: 'Edit link',
              onPressed: () => _editLink(link),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Delete link',
              onPressed: () => _deleteLink(link.id),
            ),
          ],
        ),
      ),
    );
  }
}
