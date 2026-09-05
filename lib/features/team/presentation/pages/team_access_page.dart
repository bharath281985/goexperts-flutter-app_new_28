import 'package:flutter/material.dart';

import '../../../../app/constants/app_sizes.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../core/network/api_client_helper.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/icon_widget.dart';
import '../../data/team_repository.dart';
import '../../domain/team_member.dart';
import '../widgets/inline_access_drawer.dart';

class TeamAccessPage extends StatefulWidget {
  const TeamAccessPage({super.key, this.repository});

  final TeamRepository? repository;

  @override
  State<TeamAccessPage> createState() => _TeamAccessPageState();
}

class _TeamAccessPageState extends State<TeamAccessPage> {
  late final TeamRepository _repository =
      widget.repository ?? TeamRepository(sl<ApiClientHelper>());
  
  List<TeamMember> _members = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repository.getTeam();
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _error = failure.message;
        _loading = false;
      }),
      (team) => setState(() {
        _members = team.members;
        _loading = false;
      }),
    );
  }

  void _showAccessDrawer(TeamMember member) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => InlineAccessDrawer(
        member: member,
        onSave: (dashboards, permissions) async {
          final result = await _repository.update(
            member,
            permittedDashboards: dashboards,
            permissions: permissions,
          );
          if (result.isFailure) {
            throw Exception(result.failureOrNull?.message ?? 'Unknown error');
          }
        },
        onSavedComplete: () {
          _load();
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int clientCount = 0;
    int freelancerCount = 0;
    int founderCount = 0;
    int investorCount = 0;

    for (final m in _members) {
      if (m.permissions.permittedDashboards.contains('client')) clientCount++;
      if (m.permissions.permittedDashboards.contains('freelancer')) freelancerCount++;
      if (m.permissions.permittedDashboards.contains('founder')) founderCount++;
      if (m.permissions.permittedDashboards.contains('investor')) investorCount++;
    }

    return AppScaffold(
      appBar: AppBar(
        leading: IconTapWidget(onTap: () => Navigator.of(context).maybePop()),
        title: const Text('Access Matrix'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSizes.screenPadding),
                children: [
                  Text('Portal Metrics', style: Theme.of(context).textTheme.titleMedium),
                  AppSizes.vGapMd,
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return GridView.count(
                        crossAxisCount: constraints.maxWidth > 600 ? 4 : 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 2.5,
                        children: [
                          _MetricCard('Client Portal', clientCount, Colors.blue),
                          _MetricCard('Freelancer HQ', freelancerCount, Colors.red),
                          _MetricCard('Founder OS', founderCount, Colors.purple),
                          _MetricCard('Investor OS', investorCount, Colors.orange),
                        ],
                      );
                    },
                  ),
                  AppSizes.vGapLg,
                  Text('Team Access Permissions', style: Theme.of(context).textTheme.titleMedium),
                  AppSizes.vGapMd,
                  if (_members.isEmpty) const Text('No team members found.'),
                  for (final member in _members)
                    AppCard(
                      margin: const EdgeInsets.only(bottom: AppSizes.sm),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          AppAvatar(name: member.name, size: 40),
                          AppSizes.hGapMd,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(member.role, style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                          Wrap(
                            spacing: 4,
                            children: member.permissions.permittedDashboards.map((db) {
                              return Tooltip(
                                message: db.toUpperCase(),
                                child: Icon(
                                  _getDashboardIcon(db),
                                  color: _getDashboardColor(db),
                                ),
                              );
                            }).toList(),
                          ),
                          AppSizes.hGapMd,
                          TextButton(
                            onPressed: () => _showAccessDrawer(member),
                            child: const Text('Manage Access'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  IconData _getDashboardIcon(String db) {
    switch (db) {
      case 'client': return Icons.business;
      case 'freelancer': return Icons.work;
      case 'founder': return Icons.rocket_launch;
      case 'investor': return Icons.trending_up;
      default: return Icons.dashboard;
    }
  }

  Color _getDashboardColor(String db) {
    switch (db) {
      case 'client': return Colors.blue;
      case 'freelancer': return Colors.red;
      case 'founder': return Colors.purple;
      case 'investor': return Colors.orange;
      default: return Colors.grey;
    }
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.title, this.count, this.color);
  final String title;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          Text(count.toString(), style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
