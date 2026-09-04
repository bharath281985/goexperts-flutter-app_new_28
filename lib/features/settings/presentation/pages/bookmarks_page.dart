import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/network/api_client_helper.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/utils/bookmark_manager.dart';
import '../../../../core/utils/enums.dart';
import '../../../../core/utils/paginated.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/catalog_view.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../catalog/domain/entities/catalog_entities.dart';
import '../../../catalog/domain/repositories/catalog_repository.dart';
import '../../../founder_dashboard/domain/entities/founder.dart';
import '../../../freelancer_dashboard/domain/entities/freelancer.dart';
import '../../../freelancer_dashboard/domain/repositories/freelancer_repository.dart';
import '../../../freelancer_dashboard/presentation/widgets/freelancer_card.dart';
import '../../../investor_dashboard/domain/entities/investor.dart';
import '../../../projects/domain/entities/project.dart';
import '../../../projects/domain/repositories/project_repository.dart';
import '../../../projects/presentation/widgets/project_card.dart';
import '../../../startup_ideas/domain/entities/startup.dart';
import '../../../startup_ideas/domain/repositories/startup_repository.dart';
import '../../../startup_ideas/presentation/widgets/investment_offer_sheet.dart';
import '../../../startup_ideas/presentation/widgets/startup_card.dart';
import '../../../../core/bloc/list_bloc.dart';
import '../../../../core/widgets/icon_widget.dart';

class BookmarksPage extends StatelessWidget {
  const BookmarksPage({super.key, this.embedded = false});

  final bool embedded;

  Future<Result<Paginated<Project>>> _fetchProjects(QueryParams params) async {
    final client = sl<ApiClientHelper>();
    final query = params.toApiQuery();
    query['entityType'] = 'project';

    // 1. Try unified favorites endpoint first
    final favRes = await client.getEnvelope<Paginated<Project>>(
      ApiEndpoints.favorites,
      query: query,
      parser: (env) {
        final list = env.data as List? ?? [];
        final items = list
            .map(
              (e) => Project.fromApiJson(
                Map<String, dynamic>.from(e as Map),
              ).copyWith(isSaved: true),
            )
            .toList();

        for (final p in items) {
          BookmarkManager.instance.syncItem(
            BookmarkManager.categoryProjects,
            p.id,
            true,
          );
        }

        return Paginated(
          items: items,
          page: params.page,
          totalPages: 1,
          totalItems: list.length,
        );
      },
    );

    if (favRes.isSuccess && (favRes.valueOrNull?.items.isNotEmpty ?? false)) {
      return favRes;
    }

    // 2. Fetch directly from backend saved projects endpoint
    final apiRes = await client.getEnvelope<Paginated<Project>>(
      ApiEndpoints.publicSavedProjects,
      query: params.toApiQuery(),
      parser: (env) {
        final list = env.data as List? ?? [];
        final items = list
            .map(
              (e) => Project.fromApiJson(
                Map<String, dynamic>.from(e as Map),
              ).copyWith(isSaved: true),
            )
            .toList();

        for (final p in items) {
          BookmarkManager.instance.syncItem(
            BookmarkManager.categoryProjects,
            p.id,
            true,
          );
        }

        return Paginated(
          items: items,
          page: params.page,
          totalPages: 1,
          totalItems: list.length,
        );
      },
    );

    if (apiRes.isSuccess && (apiRes.valueOrNull?.items.isNotEmpty ?? false)) {
      return apiRes;
    }

    // 3. Fallback to local bookmark repository if backend returned empty
    final res = await sl<ProjectRepository>().getProjects(params);
    return res.fold((f) => apiRes.isSuccess ? apiRes : Err(f), (paginated) {
      final savedIds = BookmarkManager.instance.getIds(
        BookmarkManager.categoryProjects,
      );
      final filtered = paginated.items
          .where((x) => savedIds.contains(x.id))
          .map((x) => x.copyWith(isSaved: true))
          .toList();
      return Success(
        Paginated(
          items: filtered,
          page: paginated.page,
          totalPages: 1,
          totalItems: filtered.length,
        ),
      );
    });
  }

  Future<Result<Paginated<Freelancer>>> _fetchFreelancers(
    QueryParams params,
  ) async {
    final client = sl<ApiClientHelper>();
    final query = params.toApiQuery();
    query['entityType'] = 'freelancer';

    // 1. Try unified favorites endpoint first
    final favRes = await client.getEnvelope<Paginated<Freelancer>>(
      ApiEndpoints.favorites,
      query: query,
      parser: (env) {
        final list = env.data as List? ?? [];
        final items = list
            .map((e) {
              final map = Map<String, dynamic>.from(e as Map);
              final fId = map['freelancerId'] ?? map['id'] ?? map['entityId'] ?? '';
              return Freelancer(
                id: fId.toString(),
                name: map['name'] ?? map['fullName'] ?? 'Freelancer',
                headline: map['headline'] ?? map['titleHeadline'] ?? '',
                category: map['category'] ?? 'General',
                skills:
                    (map['skills'] as List?)?.map((e) => e.toString()).toList() ??
                    const [],
                hourlyRate:
                    double.tryParse(
                      (map['rate'] ?? map['hourlyRate'] ?? 0).toString(),
                    ) ??
                    0.0,
                rating:
                    double.tryParse((map['rating'] ?? 5).toString()) ?? 5.0,
                reviewsCount:
                    int.tryParse((map['reviewsCount'] ?? 0).toString()) ?? 0,
                location:
                    map['location'] ??
                    (map['city'] != null
                        ? '${map['city']}, ${map['country'] ?? ''}'
                        : ''),
                avatarUrl: map['avatar'] ?? map['avatarUrl'] ?? '',
                bio: map['bio'] ?? '',
                isSaved: true,
              );
            })
            .toList();

        for (final f in items) {
          BookmarkManager.instance.syncItem(
            BookmarkManager.categoryFreelancers,
            f.id,
            true,
          );
        }

        return Paginated(
          items: items,
          page: params.page,
          totalPages: 1,
          totalItems: list.length,
        );
      },
    );

    if (favRes.isSuccess && (favRes.valueOrNull?.items.isNotEmpty ?? false)) {
      return favRes;
    }

    // 2. Fallback to client saved freelancers endpoint
    final apiRes = await client.getEnvelope<Paginated<Freelancer>>(
      ApiEndpoints.clientFreelancersSaved,
      query: params.toApiQuery(),
      parser: (env) {
        final list = env.data as List? ?? [];
        final items = list
            .map((e) {
              final map = Map<String, dynamic>.from(e as Map);
              final fId = map['freelancerId'] ?? map['id'] ?? '';
              return Freelancer(
                id: fId.toString(),
                name: map['name'] ?? map['fullName'] ?? 'Freelancer',
                headline: map['headline'] ?? map['titleHeadline'] ?? '',
                category: map['category'] ?? 'General',
                skills:
                    (map['skills'] as List?)?.map((e) => e.toString()).toList() ??
                    const [],
                hourlyRate:
                    double.tryParse(
                      (map['rate'] ?? map['hourlyRate'] ?? 0).toString(),
                    ) ??
                    0.0,
                rating:
                    double.tryParse((map['rating'] ?? 5).toString()) ?? 5.0,
                reviewsCount:
                    int.tryParse((map['reviewsCount'] ?? 0).toString()) ?? 0,
                location:
                    map['location'] ??
                    (map['city'] != null
                        ? '${map['city']}, ${map['country'] ?? ''}'
                        : ''),
                avatarUrl: map['avatar'] ?? map['avatarUrl'] ?? '',
                bio: map['bio'] ?? '',
                isSaved: true,
              );
            })
            .toList();

        for (final f in items) {
          BookmarkManager.instance.syncItem(
            BookmarkManager.categoryFreelancers,
            f.id,
            true,
          );
        }

        return Paginated(
          items: items,
          page: params.page,
          totalPages: 1,
          totalItems: list.length,
        );
      },
    );

    if (apiRes.isSuccess && (apiRes.valueOrNull?.items.isNotEmpty ?? false)) {
      return apiRes;
    }

    // 3. Fallback to local bookmark repository if backend returned empty
    final res = await sl<FreelancerRepository>().getFreelancers(params);
    return res.fold((f) => apiRes.isSuccess ? apiRes : Err(f), (paginated) {
      final savedIds = BookmarkManager.instance.getIds(
        BookmarkManager.categoryFreelancers,
      );
      final filtered = paginated.items
          .where((x) => savedIds.contains(x.id))
          .map((x) => x.copyWith(isSaved: true))
          .toList();
      return Success(
        Paginated(
          items: filtered,
          page: paginated.page,
          totalPages: 1,
          totalItems: filtered.length,
        ),
      );
    });
  }

  Future<Result<Paginated<Startup>>> _fetchStartups(QueryParams params) async {
    final client = sl<ApiClientHelper>();
    final query = params.toApiQuery();
    query['entityType'] = 'startup';

    // 1. Try unified favorites endpoint first
    final favRes = await client.getEnvelope<Paginated<Startup>>(
      ApiEndpoints.favorites,
      query: query,
      parser: (env) {
        final list = env.data as List? ?? [];
        final items = list
            .map(
              (e) => Startup.fromApiJson(Map<String, dynamic>.from(e as Map)).copyWith(isSaved: true),
            )
            .toList();

        for (final s in items) {
          BookmarkManager.instance.syncItem(
            BookmarkManager.categoryStartups,
            s.id,
            true,
          );
        }

        return Paginated(
          items: items,
          page: params.page,
          totalPages: 1,
          totalItems: list.length,
        );
      },
    );

    if (favRes.isSuccess && (favRes.valueOrNull?.items.isNotEmpty ?? false)) {
      return favRes;
    }

    // 2. Fallback to investor watchlist endpoint
    final apiRes = await client.getEnvelope<Paginated<Startup>>(
      ApiEndpoints.investorWatchlist,
      query: params.toApiQuery(),
      parser: (env) {
        final list = env.data as List? ?? [];
        final items = list
            .map(
              (e) => Startup.fromApiJson(Map<String, dynamic>.from(e as Map)).copyWith(isSaved: true),
            )
            .toList();

        for (final s in items) {
          BookmarkManager.instance.syncItem(
            BookmarkManager.categoryStartups,
            s.id,
            true,
          );
        }

        return Paginated(
          items: items,
          page: params.page,
          totalPages: 1,
          totalItems: list.length,
        );
      },
    );

    if (apiRes.isSuccess && (apiRes.valueOrNull?.items.isNotEmpty ?? false)) {
      return apiRes;
    }

    // 3. Fallback to local bookmark repository if backend returned empty
    final res = await sl<StartupRepository>().getStartups(params);
    return res.fold((f) => apiRes.isSuccess ? apiRes : Err(f), (paginated) {
      final savedIds = BookmarkManager.instance.getIds(
        BookmarkManager.categoryStartups,
      );
      final filtered = paginated.items
          .where((x) => savedIds.contains(x.id))
          .map((x) => x.copyWith(isSaved: true))
          .toList();
      return Success(
        Paginated(
          items: filtered,
          page: paginated.page,
          totalPages: 1,
          totalItems: filtered.length,
        ),
      );
    });
  }

  Future<Result<Paginated<Investor>>> _fetchInvestors(
    QueryParams params,
  ) async {
    final client = sl<ApiClientHelper>();
    final query = params.toApiQuery();
    query['entityType'] = 'investor';

    return client.getEnvelope<Paginated<Investor>>(
      ApiEndpoints.favorites,
      query: query,
      parser: (env) {
        final list = env.data as List? ?? [];
        return Paginated(
          items: list
              .map(
                (e) => Investor.fromApiJson(
                  Map<String, dynamic>.from(e as Map),
                ).copyWith(isSaved: true),
              )
              .toList(),
          page: params.page,
          totalPages: 1,
          totalItems: list.length,
        );
      },
    );
  }

  Future<Result<Paginated<Technology>>> _fetchTechnologies(
    QueryParams params,
  ) async {
    final res = await sl<CatalogRepository>().getTechnologies(params);
    return res.fold((f) => Err(f), (paginated) {
      final savedIds = BookmarkManager.instance.getIds(
        BookmarkManager.categoryTechnologies,
      );
      final filtered = paginated.items
          .where((x) => savedIds.contains(x.id))
          .toList();
      return Success(
        Paginated(
          items: filtered,
          page: paginated.page,
          totalPages: 1,
          totalItems: filtered.length,
        ),
      );
    });
  }

  Future<Result<Paginated<CategoryItem>>> _fetchCategories(
    QueryParams params,
  ) async {
    final res = await sl<CatalogRepository>().getCategories(params);
    return res.fold((f) => Err(f), (paginated) {
      final savedIds = BookmarkManager.instance.getIds(
        BookmarkManager.categoryCategories,
      );
      final filtered = paginated.items
          .where((x) => savedIds.contains(x.id))
          .toList();
      return Success(
        Paginated(
          items: filtered,
          page: paginated.page,
          totalPages: 1,
          totalItems: filtered.length,
        ),
      );
    });
  }

  Future<Result<Paginated<Founder>>> _fetchFounders(QueryParams params) async {
    final client = sl<ApiClientHelper>();
    final query = params.toApiQuery();
    query['entityType'] = 'founder';

    // 1. Try unified favorites endpoint first
    final favRes = await client.getEnvelope<Paginated<Founder>>(
      ApiEndpoints.favorites,
      query: query,
      parser: (env) {
        final list = env.data as List? ?? [];
        final items = list
            .map(
              (e) => Founder.fromApiJson(Map<String, dynamic>.from(e as Map)).copyWith(isSaved: true),
            )
            .toList();

        for (final f in items) {
          BookmarkManager.instance.syncItem(
            BookmarkManager.categoryFounders,
            f.id,
            true,
          );
        }

        return Paginated(
          items: items,
          page: params.page,
          totalPages: 1,
          totalItems: list.length,
        );
      },
    );

    if (favRes.isSuccess && (favRes.valueOrNull?.items.isNotEmpty ?? false)) {
      return favRes;
    }

    // 2. Fallback to investor watchlist founders endpoint
    return client.getEnvelope<Paginated<Founder>>(
      ApiEndpoints.investorWatchlistFounders,
      query: params.toApiQuery(),
      parser: (env) {
        final list = env.data as List? ?? [];
        final items = list
            .map(
              (e) => Founder.fromApiJson(Map<String, dynamic>.from(e as Map)).copyWith(isSaved: true),
            )
            .toList();

        for (final f in items) {
          BookmarkManager.instance.syncItem(
            BookmarkManager.categoryFounders,
            f.id,
            true,
          );
        }

        return Paginated(
          items: items,
          page: params.page,
          totalPages: 1,
          totalItems: list.length,
        );
      },
    );
  }

  Widget _projectsView(BuildContext context) {
    return CatalogView<Project>(
      fetcher: _fetchProjects,
      showSearch: false,
      emptyTitle: 'No saved projects',
      emptyIcon: Icons.bookmark_outline_rounded,
      itemBuilder: (context, p, _) {
        final bloc = context.read<ListBloc<Project>>();
        return AppProjectCard(
          project: p.copyWith(isSaved: true),
          onTap: () async {
            await context.push('${Routes.projectDetails}/${p.id}');
            if (context.mounted) {
              bloc.add(const ListRefreshed());
            }
          },
          onSave: () async {
            final result = await sl<ProjectRepository>().toggleSave(p.id);
            if (!context.mounted) return;
            result.fold(
              (failure) => context.showSnack(failure.message, isError: true),
              (_) {
                BookmarkManager.instance.syncItem(
                  BookmarkManager.categoryProjects,
                  p.id,
                  false,
                );
                bloc.add(
                  ListItemRemoved((item) => (item as Project).id == p.id),
                );
                context.showSnack('Removed from saved');
              },
            );
          },
        );
      },
    );
  }

  Widget _freelancersView(BuildContext context) {
    return CatalogView<Freelancer>(
      fetcher: _fetchFreelancers,
      showSearch: false,
      emptyTitle: 'No saved freelancers',
      emptyIcon: Icons.bookmark_outline_rounded,
      itemBuilder: (context, f, _) {
        final bloc = context.read<ListBloc<Freelancer>>();
        return AppFreelancerCard(
          freelancer: f.copyWith(isSaved: true),
          onTap: () async {
            await context.push('${Routes.publicFreelancer}/${f.id}');
            if (context.mounted) {
              bloc.add(const ListRefreshed());
            }
          },
          onSave: () async {
            final result = await sl<FreelancerRepository>().toggleSave(f.id);
            if (!context.mounted) return;
            result.fold(
              (failure) => context.showSnack(failure.message, isError: true),
              (_) {
                BookmarkManager.instance.syncItem(
                  BookmarkManager.categoryFreelancers,
                  f.id,
                  false,
                );
                bloc.add(
                  ListItemRemoved((item) => (item as Freelancer).id == f.id),
                );
                context.showSnack('Removed from saved');
              },
            );
          },
        );
      },
    );
  }

  Widget _startupsView(BuildContext context) {
    final repo = sl<StartupRepository>();
    return CatalogView<Startup>(
      fetcher: _fetchStartups,
      showSearch: false,
      emptyTitle: 'No saved startups',
      emptyIcon: Icons.bookmark_outline_rounded,
      itemBuilder: (context, s, _) {
        final bloc = context.read<ListBloc<Startup>>();
        return AppStartupCard(
          startup: s.copyWith(
            isSaved: BookmarkManager.instance.isBookmarked(
              BookmarkManager.categoryStartups,
              s.id,
            ),
          ),
          onTap: () => context.push('${Routes.startupDetails}/${s.id}'),
          onSave: () async {
            final res = await repo.toggleSave(s.id);
            res.fold((f) => context.showSnack(f.message, isError: true), (
              success,
            ) {
              if (success) {
                final isSavedNow = !BookmarkManager.instance.isBookmarked(
                  BookmarkManager.categoryStartups,
                  s.id,
                );
                BookmarkManager.instance.syncItem(
                  BookmarkManager.categoryStartups,
                  s.id,
                  isSavedNow,
                );

                if (!isSavedNow) {
                  bloc.add(
                    ListItemRemoved((item) => (item as Startup).id == s.id),
                  );
                }
                context.showSnack(
                  isSavedNow ? 'Saved startup' : 'Removed from saved',
                );
              }
            });
          },
          onInterest: () async {
            if (s.hasInvested) {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Withdraw Interest'),
                  content: const Text(
                    'Are you sure you want to withdraw your interest in this startup?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text(
                        'Withdraw',
                        style: TextStyle(color: AppColors.danger),
                      ),
                    ),
                  ],
                ),
              );
              if (confirm != true) return;

              final res = await repo.withdrawInterest(s.id);
              res.fold((f) => context.showSnack(f.message, isError: true), (
                success,
              ) {
                if (success) {
                  final updated = s.copyWith(hasInvested: false);
                  bloc.add(
                    ListItemUpdated(
                      updated,
                      (existing, newItem) => existing.id == newItem.id,
                    ),
                  );
                  context.showSnack('Withdrew interest successfully');
                }
              });
            } else {
              final submitted = await showInvestmentOfferSheet(
                context,
                startupId: s.id,
                startupName: s.name,
              );
              if (submitted == true) {
                final updated = s.copyWith(hasInvested: true);
                bloc.add(
                  ListItemUpdated(
                    updated,
                    (existing, newItem) => existing.id == newItem.id,
                  ),
                );
                if (context.mounted) {
                  context.push('${Routes.startupDetails}/${s.id}');
                }
              }
            }
          },
        );
      },
    );
  }

  Widget _investorsView(BuildContext context) {
    return CatalogView<Investor>(
      fetcher: _fetchInvestors,
      showSearch: false,
      emptyTitle: 'No saved investors',
      emptyIcon: Icons.bookmark_outline_rounded,
      itemBuilder: (context, i, _) {
        final bloc = context.read<ListBloc<Investor>>();
        return AppCard(
          onTap: () => context.push('${Routes.publicInvestor}/${i.id}'),
          child: Row(
            children: [
              AppAvatar(name: i.name, imageUrl: i.avatarUrl, size: 48),
              AppSizes.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(i.name, style: context.text.titleSmall),
                    Text(
                      '${i.investorType} · ${i.company}',
                      style: context.text.labelSmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.bookmark_rounded,
                  color: AppColors.primary,
                ),
                onPressed: () async {
                  final result = await sl<ApiClientHelper>().postAction(
                    '${ApiEndpoints.favorites}/toggle',
                    body: {'entityType': 'investor', 'entityId': i.id},
                  );
                  // Also trigger save deletion
                  sl<ApiClientHelper>().deleteAction(
                    ApiEndpoints.publicInvestorSave(i.id),
                  );
                  if (!context.mounted) return;
                  result.fold(
                    (failure) =>
                        context.showSnack(failure.message, isError: true),
                    (_) {
                      BookmarkManager.instance.syncItem(
                        BookmarkManager.categoryInvestors,
                        i.id,
                        false,
                      );
                      bloc.add(
                        ListItemRemoved(
                          (item) => (item as Investor).id == i.id,
                        ),
                      );
                      context.showSnack('Removed from saved');
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _foundersView(BuildContext context) {
    return CatalogView<Founder>(
      fetcher: _fetchFounders,
      showSearch: false,
      emptyTitle: 'No saved founders',
      emptyIcon: Icons.bookmark_outline_rounded,
      itemBuilder: (context, f, _) {
        final bloc = context.read<ListBloc<Founder>>();
        return AppCard(
          onTap: () => context.push('${Routes.publicFounder}/${f.id}'),
          child: Row(
            children: [
              AppAvatar(name: f.name, imageUrl: f.avatarUrl, size: 48),
              AppSizes.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.name, style: context.text.titleSmall),
                    Text(
                      '${f.founderType} · ${f.startupName}',
                      style: context.text.labelSmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  BookmarkManager.instance.isBookmarked(
                        BookmarkManager.categoryFounders,
                        f.id,
                      )
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_outline_rounded,
                  color: AppColors.primary,
                ),
                onPressed: () async {
                  final isCurrentlySaved = BookmarkManager.instance
                      .isBookmarked(BookmarkManager.categoryFounders, f.id);

                  final Result<dynamic> res;
                  if (isCurrentlySaved) {
                    res = await sl<ApiClientHelper>().deleteAction(
                      ApiEndpoints.investorFounderSave(f.id),
                    );
                  } else {
                    res = await sl<ApiClientHelper>().postAction(
                      ApiEndpoints.investorFounderSave(f.id),
                      body: {},
                    );
                  }

                  res.fold(
                    (err) => context.showSnack(err.message, isError: true),
                    (success) {
                      final isSavedNow = !isCurrentlySaved;
                      BookmarkManager.instance.syncItem(
                        BookmarkManager.categoryFounders,
                        f.id,
                        isSavedNow,
                      );

                      if (!isSavedNow) {
                        bloc.add(
                          ListItemRemoved(
                            (item) => (item as Founder).id == f.id,
                          ),
                        );
                      }
                      context.showSnack(
                        isSavedNow ? 'Saved founder' : 'Removed from saved',
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _technologiesView(BuildContext context) {
    return CatalogView<Technology>(
      fetcher: _fetchTechnologies,
      showSearch: false,
      emptyTitle: 'No saved technologies',
      emptyIcon: Icons.bookmark_outline_rounded,
      itemBuilder: (context, t, _) {
        final bloc = context.read<ListBloc<Technology>>();
        return AppCard(
          onTap: () => context.push('${Routes.technologyDetails}/${t.id}'),
          child: Row(
            children: [
              const Icon(
                Icons.code_rounded,
                color: AppColors.primary,
                size: 28,
              ),
              AppSizes.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.name, style: context.text.titleSmall),
                    Text(t.category, style: context.text.labelSmall),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.bookmark_rounded,
                  color: AppColors.primary,
                ),
                onPressed: () async {
                  final result = await sl<ApiClientHelper>().postAction(
                    '${ApiEndpoints.favorites}/toggle',
                    body: {'entityType': 'technology', 'entityId': t.id},
                  );
                  if (!context.mounted) return;
                  result.fold(
                    (failure) =>
                        context.showSnack(failure.message, isError: true),
                    (_) {
                      BookmarkManager.instance.syncItem(
                        BookmarkManager.categoryTechnologies,
                        t.id,
                        false,
                      );
                      bloc.add(
                        ListItemRemoved(
                          (item) => (item as Technology).id == t.id,
                        ),
                      );
                      context.showSnack('Removed from saved');
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _categoriesView(BuildContext context) {
    return CatalogView<CategoryItem>(
      fetcher: _fetchCategories,
      showSearch: false,
      emptyTitle: 'No saved categories',
      emptyIcon: Icons.bookmark_outline_rounded,
      itemBuilder: (context, c, _) {
        final bloc = context.read<ListBloc<CategoryItem>>();
        return AppCard(
          onTap: () => context.push('${Routes.categoryDetails}/${c.id}'),
          child: Row(
            children: [
              const Icon(
                Icons.category_outlined,
                color: AppColors.primary,
                size: 28,
              ),
              AppSizes.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name, style: context.text.titleSmall),
                    Text(
                      '${c.projectsCount} projects · ${c.freelancersCount} freelancers',
                      style: context.text.labelSmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.bookmark_rounded,
                  color: AppColors.primary,
                ),
                onPressed: () async {
                  final result = await sl<ApiClientHelper>().postAction(
                    '${ApiEndpoints.favorites}/toggle',
                    body: {'entityType': 'category', 'entityId': c.id},
                  );
                  if (!context.mounted) return;
                  result.fold(
                    (failure) =>
                        context.showSnack(failure.message, isError: true),
                    (_) {
                      BookmarkManager.instance.syncItem(
                        BookmarkManager.categoryCategories,
                        c.id,
                        false,
                      );
                      bloc.add(
                        ListItemRemoved(
                          (item) => (item as CategoryItem).id == c.id,
                        ),
                      );
                      context.showSnack('Removed from saved');
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    final user = state.user;
    final role = user?.role ?? UserRole.freelancer;

    final List<Tab> tabs;
    final List<Widget> tabViews;

    switch (role) {
      case UserRole.freelancer:
        tabs = const [
          Tab(text: 'Projects'),
          Tab(text: 'Startups'),
          Tab(text: 'Investors'),
        ];
        tabViews = [
          _projectsView(context),
          _startupsView(context),
          _investorsView(context),
        ];
        break;
      case UserRole.client:
        tabs = const [
          Tab(text: 'Freelancers'),
          Tab(text: 'Projects'),
          Tab(text: 'Startups'),
        ];
        tabViews = [
          _freelancersView(context),
          _projectsView(context),
          _startupsView(context),
        ];
        break;
      case UserRole.founder:
        tabs = const [
          Tab(text: 'Investors'),
          Tab(text: 'Freelancers'),
          Tab(text: 'Projects'),
        ];
        tabViews = [
          _investorsView(context),
          _freelancersView(context),
          _projectsView(context),
        ];
        break;
      case UserRole.investor:
        tabs = const [
          Tab(text: 'Startups'),
          Tab(text: 'Freelancers'),
          Tab(text: 'Projects'),
        ];
        tabViews = [
          _startupsView(context),
          _freelancersView(context),
          _projectsView(context),
        ];
        break;
    }

    return ListenableBuilder(
      listenable: BookmarkManager.instance,
      builder: (context, _) {
        return DefaultTabController(
          length: tabs.length,
          child: Scaffold(
            appBar: embedded
                ? null
                : AppBar(
                    leading: IconTapWidget(
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    title: const Text('Bookmarks'),
                    bottom: TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      tabs: tabs,
                    ),
                  ),
            body: embedded && tabs.isNotEmpty
                ? Column(
                    children: [
                      TabBar(
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        tabs: tabs,
                      ),
                      Expanded(child: TabBarView(children: tabViews)),
                    ],
                  )
                : TabBarView(children: tabViews),
          ),
        );
      },
    );
  }

  Widget _buildSearchesAndFilters(BuildContext context) {
    final searches = BookmarkManager.instance.getSavedSearches();
    final filters = BookmarkManager.instance.getSavedFilters();
    return ListView(
      padding: const EdgeInsets.all(AppSizes.screenPadding),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('SAVED SEARCHES', style: context.text.labelSmall),
            IconButton(
              icon: const Icon(Icons.add_rounded, size: 20),
              onPressed: () => _showAddSearchDialog(context),
            ),
          ],
        ),
        if (searches.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSizes.md),
            child: Text(
              'No saved searches yet',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          )
        else
          for (final s in searches)
            AppCard(
              margin: const EdgeInsets.only(bottom: AppSizes.sm),
              onTap: () => context.showSnack('Executing search for "$s"…'),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: AppColors.info,
                    size: 20,
                  ),
                  AppSizes.hGapMd,
                  Expanded(child: Text(s, style: context.text.bodyMedium)),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () =>
                        BookmarkManager.instance.removeSavedSearch(s),
                  ),
                ],
              ),
            ),
        AppSizes.vGapLg,
        Text('SAVED FILTERS', style: context.text.labelSmall),
        AppSizes.vGapMd,
        if (filters.isEmpty)
          const Text(
            'No saved filters yet',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          )
        else
          for (final f in filters)
            AppCard(
              margin: const EdgeInsets.only(bottom: AppSizes.sm),
              onTap: () => context.showSnack('Applying filter "${f['name']}"…'),
              child: Row(
                children: [
                  const Icon(
                    Icons.filter_list_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  AppSizes.hGapMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          f['name'] ?? 'Filter',
                          style: context.text.titleSmall,
                        ),
                        Text(
                          f.entries
                              .where((e) => e.key != 'name')
                              .map((e) => '${e.key}: ${e.value}')
                              .join(' · '),
                          style: context.text.labelSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.play_arrow_rounded,
                    color: AppColors.mutedText,
                  ),
                ],
              ),
            ),
      ],
    );
  }

  Widget _buildCollectionsAndFolders(BuildContext context) {
    final collections = BookmarkManager.instance.getCollections();
    final folders = BookmarkManager.instance.getFolders();
    return ListView(
      padding: const EdgeInsets.all(AppSizes.screenPadding),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('MY COLLECTIONS', style: context.text.labelSmall),
            IconButton(
              icon: const Icon(Icons.add_rounded, size: 20),
              onPressed: () => _showAddDialog(
                context,
                'Collection',
                (v) => BookmarkManager.instance.addCollection(v),
              ),
            ),
          ],
        ),
        for (final c in collections)
          AppCard(
            margin: const EdgeInsets.only(bottom: AppSizes.sm),
            onTap: () => context.showSnack('Opening collection "$c"…'),
            child: Row(
              children: [
                const Icon(
                  Icons.folder_special_outlined,
                  color: AppColors.warning,
                  size: 22,
                ),
                AppSizes.hGapMd,
                Expanded(child: Text(c, style: context.text.bodyMedium)),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.mutedText,
                ),
              ],
            ),
          ),
        AppSizes.vGapLg,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('BOOKMARK FOLDERS', style: context.text.labelSmall),
            IconButton(
              icon: const Icon(Icons.add_rounded, size: 20),
              onPressed: () => _showAddDialog(
                context,
                'Folder',
                (v) => BookmarkManager.instance.addFolder(v),
              ),
            ),
          ],
        ),
        for (final f in folders)
          AppCard(
            margin: const EdgeInsets.only(bottom: AppSizes.sm),
            onTap: () => context.showSnack('Opening folder "$f"…'),
            child: Row(
              children: [
                const Icon(
                  Icons.folder_open_outlined,
                  color: AppColors.info,
                  size: 22,
                ),
                AppSizes.hGapMd,
                Expanded(child: Text(f, style: context.text.bodyMedium)),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.mutedText,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildResourcesAndBlogs(BuildContext context) {
    final resources = [
      ('Clean Architecture in Flutter', 'Course · 4h duration', 'lr1'),
      ('Due Diligence Checklist', 'Document · 12 pages', 'lr2'),
      ('Pitch Deck Fundamentals', 'Video · 45 mins', 'lr3'),
    ];
    final blogs = [
      ('How to Raise Seed Capital', 'by Rajiv Anand · 5m read', 'b1'),
      ('State of Flutter in 2026', 'by Priya Nair · 8m read', 'b2'),
      ('AgriTech Scale Strategies', 'by Ishaan Verma · 10m read', 'b3'),
    ];

    return ListView(
      padding: const EdgeInsets.all(AppSizes.screenPadding),
      children: [
        Text('LEARNING RESOURCES', style: context.text.labelSmall),
        AppSizes.vGapMd,
        for (final r in resources)
          AppCard(
            margin: const EdgeInsets.only(bottom: AppSizes.sm),
            onTap: () => context.push(
              '${Routes.documentViewer}?type=PDF&name=${Uri.encodeComponent(r.$1)}',
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.menu_book_outlined,
                  color: AppColors.success,
                  size: 22,
                ),
                AppSizes.hGapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.$1, style: context.text.titleSmall),
                      Text(r.$2, style: context.text.labelSmall),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.bookmark_rounded,
                    color: AppColors.primary,
                  ),
                  onPressed: () => context.showSnack('Unsaved resource'),
                ),
              ],
            ),
          ),
        AppSizes.vGapLg,
        Text('BLOGS & ARTICLES', style: context.text.labelSmall),
        AppSizes.vGapMd,
        for (final b in blogs)
          AppCard(
            margin: const EdgeInsets.only(bottom: AppSizes.sm),
            onTap: () => context.showSnack('Opening article…'),
            child: Row(
              children: [
                const Icon(
                  Icons.article_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
                AppSizes.hGapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b.$1, style: context.text.titleSmall),
                      Text(b.$2, style: context.text.labelSmall),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.bookmark_rounded,
                    color: AppColors.primary,
                  ),
                  onPressed: () => context.showSnack('Unsaved article'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _showAddSearchDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Search Query'),
        content: AppTextField(
          controller: controller,
          hint: 'e.g. Flutter Remote',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                BookmarkManager.instance.addSavedSearch(controller.text);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(
    BuildContext context,
    String type,
    Function(String) onSave,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add New $type'),
        content: AppTextField(
          controller: controller,
          hint: 'e.g. New $type Name',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                onSave(controller.text);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
