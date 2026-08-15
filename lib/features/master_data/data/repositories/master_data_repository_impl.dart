import 'package:dio/dio.dart';

import '../../../../app/config/app_config.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/public_catalog_client.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/master_option.dart';
import '../../domain/entities/skill_category.dart';
import '../../domain/entities/skill_option.dart';
import '../../domain/entities/ticket_size_option.dart';
import '../../domain/repositories/master_data_repository.dart';

class MasterDataRepositoryImpl implements MasterDataRepository {
  MasterDataRepositoryImpl([PublicCatalogClient? client])
    : _client = client ?? PublicCatalogClient();

  final PublicCatalogClient _client;
  final Map<String, String> _countryCodesByName = {};

  @override
  Future<Result<List<SkillCategory>>> getSkillCategories({
    String? industryId,
    int page = 1,
    int pageSize = 50,
    String search = '',
  }) async {
    final result = await _client.getList<SkillCategory>(
      path: ApiEndpoints.publicCategories,
      query: {
        if (industryId != null) 'industryId': industryId,
        'page': page,
        'pageSize': pageSize,
        if (search.trim().isNotEmpty) 'search': search.trim(),
      },
      itemParser: SkillCategory.fromJson,
    );
    if (result.isFailure) {
      return Err(result.failureOrNull!);
    }
    return Success(result.valueOrNull!.rows);
  }

  @override
  Future<Result<List<SkillCategory>>> getIndustries() async {
    final result = await _client.getList<SkillCategory>(
      path: ApiEndpoints.publicIndustries,
      query: const {'page': 1, 'pageSize': 200},
      itemParser: SkillCategory.fromJson,
    );
    if (result.isFailure) {
      return Err(result.failureOrNull!);
    }
    final rows =
        result.valueOrNull!.rows
            .where((item) => item.id.isNotEmpty && item.name.trim().isNotEmpty)
            .toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
    return Success(rows);
  }

  @override
  Future<Result<List<SkillOption>>> getSkills({
    required String categoryId,
    int page = 1,
    int pageSize = 100,
  }) async {
    final result = await _client.getList<SkillOption>(
      path: ApiEndpoints.publicSkills,
      query: {'categoryId': categoryId, 'page': page, 'pageSize': pageSize},
      itemParser: SkillOption.fromJson,
    );
    if (result.isFailure) {
      return Err(result.failureOrNull!);
    }
    return Success(result.valueOrNull!.rows);
  }

  @override
  Future<Result<int>> getSkillsTotal({required String categoryId}) async {
    final result = await _client.getList<SkillOption>(
      path: ApiEndpoints.publicSkills,
      query: {'categoryId': categoryId, 'page': 1, 'pageSize': 1},
      itemParser: SkillOption.fromJson,
    );
    if (result.isFailure) {
      return Err(result.failureOrNull!);
    }
    return Success(result.valueOrNull!.total);
  }

  @override
  Future<Result<List<String>>> getMasters(String type) async {
    try {
      final result = await _client.getList<String>(
        path: '/public/masters',
        query: {'type': type, 'limit': 200},
        itemParser: (json) {
          final val =
              json['name'] ??
              json['label'] ??
              json['value'] ??
              json['title'] ??
              '';
          return val.toString();
        },
      );
      if (result.isSuccess) {
        final list = result.valueOrNull!.rows
            .where((s) => s.trim().isNotEmpty)
            .toList();
        return Success(list);
      }
    } catch (_) {}
    return const Success([]);
  }

  @override
  Future<Result<List<String>>> getCountries() async {
    try {
      final countryCodes = <String, String>{};
      final result = await _client.getList<String>(
        path: ApiEndpoints.publicCountries,
        query: const {'limit': 250},
        itemParser: (json) {
          final val = json['name'] ?? json['countryName'] ?? json['code'] ?? '';
          final name = val.toString();
          final code = json['code']?.toString();
          if (name.isNotEmpty && code != null && code.isNotEmpty) {
            countryCodes[name] = code;
          }
          return name;
        },
      );
      if (result.isSuccess && result.valueOrNull!.rows.isNotEmpty) {
        _countryCodesByName
          ..clear()
          ..addAll(countryCodes);
        final list = result.valueOrNull!.rows
            .where((s) => s.trim().isNotEmpty)
            .toList();
        return Success(list);
      }
    } catch (_) {}
    return getMasters('country');
  }

  @override
  Future<Result<List<String>>> getStates(String countryName) async {
    try {
      if (_countryCodesByName.isEmpty) {
        await getCountries();
      }
      final countryCode =
          _countryCodesByName[countryName] ??
          (countryName.toLowerCase() == 'india' ? 'IN' : countryName);
      final dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.publicBaseUrl,
          connectTimeout: AppConfig.connectTimeout,
          receiveTimeout: AppConfig.receiveTimeout,
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );
      final response = await dio.get<Map<String, dynamic>>(
        ApiEndpoints.publicStates,
        queryParameters: {'countryCode': countryCode},
      );
      final raw = response.data?['data'];
      final list = (raw is List ? raw : const [])
          .whereType<Map>()
          .map((item) => item['name']?.toString() ?? '')
          .where((name) => name.trim().isNotEmpty)
          .toList();
      return Success(list);
    } catch (e) {
      return Err(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<String>>> getExperienceLevels() {
    return _getLabelValueOptions(ApiEndpoints.publicExperienceLevels);
  }

  @override
  Future<Result<List<String>>> getWorkModes() {
    return _getLabelValueOptions(ApiEndpoints.publicWorkModes);
  }

  @override
  Future<Result<List<String>>> getHiringGoals() {
    return _getLabelValueOptions(ApiEndpoints.publicHiringGoals);
  }

  @override
  Future<Result<List<String>>> getHiringBudgetRanges() {
    return _getLabelValueOptions(ApiEndpoints.publicHiringBudgetRanges);
  }

  @override
  Future<Result<List<String>>> getInvestorTypes() {
    return _getLabelValueOptions(ApiEndpoints.publicInvestorTypes);
  }

  @override
  Future<Result<List<String>>> getInvestorStages() {
    return _getLabelValueOptions(ApiEndpoints.publicInvestorStages);
  }

  @override
  Future<Result<List<String>>> getStartupStages() {
    return _getLabelValueOptions(ApiEndpoints.publicStartupStages);
  }

  @override
  Future<Result<List<String>>> getStartupRoles() {
    return _getLabelValueOptions(ApiEndpoints.publicStartupRoles);
  }

  Future<Result<List<String>>> _getLabelValueOptions(String path) async {
    final result = await _client.getList<String>(
      path: path,
      itemParser: (json) {
        final val = json['label'] ?? json['value'] ?? json['name'] ?? '';
        return val.toString();
      },
    );
    if (result.isFailure) {
      return Err(result.failureOrNull!);
    }
    final list = result.valueOrNull!.rows
        .where((s) => s.trim().isNotEmpty)
        .toList();
    return Success(list);
  }

  @override
  Future<Result<List<String>>> getCities() async {
    try {
      final result = await _client.getList<String>(
        path: '/public/masters',
        query: const {'type': 'city', 'limit': 200},
        itemParser: (json) {
          final val = json['name'] ?? json['label'] ?? json['value'] ?? '';
          return val.toString();
        },
      );
      if (result.isSuccess && result.valueOrNull!.rows.isNotEmpty) {
        final list = result.valueOrNull!.rows
            .where((s) => s.trim().isNotEmpty)
            .toList();
        return Success(list);
      }
    } catch (_) {}
    return getMasters('city');
  }

  @override
  Future<Result<List<String>>> getDesignations() async {
    return getMasters('designation');
  }

  @override
  Future<Result<List<String>>> getCompanySizes() async {
    try {
      final result = await _client.getList<String>(
        path: ApiEndpoints.publicCompanySizes,
        itemParser: (json) {
          final val =
              json['label'] ??
              json['name'] ??
              json['size'] ??
              json['value'] ??
              '';
          return val.toString();
        },
      );
      if (result.isSuccess && result.valueOrNull!.rows.isNotEmpty) {
        final list = result.valueOrNull!.rows
            .where((s) => s.trim().isNotEmpty)
            .toList();
        return Success(list);
      }
    } catch (_) {}
    return getMasters('company_size');
  }

  @override
  Future<Result<List<String>>> getStartupGoals() async {
    return _getLabelValueOptions(ApiEndpoints.publicFounderGoals);
  }

  @override
  Future<Result<List<MasterOption>>> getCountriesOptions() async {
    final result = await _client.getList<MasterOption>(
      path: ApiEndpoints.publicCountries,
      query: const {'limit': 250},
      itemParser: MasterOption.fromJson,
    );
    if (result.isFailure) return Err(result.failureOrNull!);
    final list = result.valueOrNull!.rows
        .where((opt) => opt.id.isNotEmpty && opt.name.isNotEmpty)
        .toList();
    return Success(list);
  }

  @override
  Future<Result<List<MasterOption>>> getStatesOptions(String countryIdOrCode) async {
    try {
      final result = await _client.getList<MasterOption>(
        path: ApiEndpoints.publicStates,
        query: {
          'countryCode': countryIdOrCode,
          'countryId': countryIdOrCode,
        },
        itemParser: MasterOption.fromJson,
      );
      if (result.isSuccess && result.valueOrNull!.rows.isNotEmpty) {
        final list = result.valueOrNull!.rows
            .where((opt) => opt.id.isNotEmpty && opt.name.isNotEmpty)
            .toList();
        return Success(list);
      }
    } catch (_) {}
    final strStatesRes = await getStates(countryIdOrCode);
    if (strStatesRes.isSuccess) {
      return Success(
        strStatesRes.valueOrNull!
            .map((s) => MasterOption(id: s, name: s))
            .toList(),
      );
    }
    return const Success([]);
  }

  @override
  Future<Result<List<MasterOption>>> getExperienceLevelOptions() async {
    final result = await _client.getList<MasterOption>(
      path: ApiEndpoints.publicExperienceLevels,
      itemParser: MasterOption.fromJson,
    );
    if (result.isFailure) return Err(result.failureOrNull!);
    final list = result.valueOrNull!.rows
        .where((opt) => opt.id.isNotEmpty && opt.name.isNotEmpty)
        .toList();
    return Success(list);
  }

  @override
  Future<Result<List<MasterOption>>> getAvailabilityOptions() async {
    final result = await _client.getList<MasterOption>(
      path: ApiEndpoints.publicAvailabilities,
      itemParser: MasterOption.fromJson,
    );
    if (result.isFailure) return Err(result.failureOrNull!);
    final list = result.valueOrNull!.rows
        .where((opt) => opt.id.isNotEmpty && opt.name.isNotEmpty)
        .toList();
    return Success(list);
  }

  @override
  Future<Result<List<MasterOption>>> getCompanySizeOptions() async {
    final result = await _client.getList<MasterOption>(
      path: ApiEndpoints.publicCompanySizes,
      itemParser: MasterOption.fromJson,
    );
    if (result.isFailure) return Err(result.failureOrNull!);
    final list = result.valueOrNull!.rows
        .where((opt) => opt.id.isNotEmpty && opt.name.isNotEmpty)
        .toList();
    return Success(list);
  }

  @override
  Future<Result<List<MasterOption>>> getHiringBudgetOptions() async {
    final result = await _client.getList<MasterOption>(
      path: ApiEndpoints.publicHiringBudgetRanges,
      itemParser: MasterOption.fromJson,
    );
    if (result.isFailure) return Err(result.failureOrNull!);
    final list = result.valueOrNull!.rows
        .where((opt) => opt.id.isNotEmpty && opt.name.isNotEmpty)
        .toList();
    return Success(list);
  }

  @override
  Future<Result<List<MasterOption>>> getHiringGoalOptions() async {
    final result = await _client.getList<MasterOption>(
      path: ApiEndpoints.publicHiringGoals,
      itemParser: MasterOption.fromJson,
    );
    if (result.isFailure) return Err(result.failureOrNull!);
    final list = result.valueOrNull!.rows
        .where((opt) => opt.id.isNotEmpty && opt.name.isNotEmpty)
        .toList();
    return Success(list);
  }

  @override
  Future<Result<List<MasterOption>>> getInvestorTypeOptions() async {
    final result = await _client.getList<MasterOption>(
      path: ApiEndpoints.publicInvestorTypes,
      itemParser: MasterOption.fromJson,
    );
    if (result.isFailure) return Err(result.failureOrNull!);
    final list = result.valueOrNull!.rows
        .where((opt) => opt.id.isNotEmpty && opt.name.isNotEmpty)
        .toList();
    return Success(list);
  }

  @override
  Future<Result<List<MasterOption>>> getInvestorStageOptions() async {
    final result = await _client.getList<MasterOption>(
      path: ApiEndpoints.publicInvestorStages,
      itemParser: MasterOption.fromJson,
    );
    if (result.isFailure) return Err(result.failureOrNull!);
    final list = result.valueOrNull!.rows
        .where((opt) => opt.id.isNotEmpty && opt.name.isNotEmpty)
        .toList();
    return Success(list);
  }

  @override
  Future<Result<List<TicketSizeOption>>> getTicketSizeOptions() async {
    try {
      final result = await _client.getList<TicketSizeOption>(
        path: ApiEndpoints.publicMobileTicketSizes,
        itemParser: (json) =>
            TicketSizeOption.fromJson(Map<String, dynamic>.from(json as Map)),
      );
      if (result.isSuccess && result.valueOrNull!.rows.isNotEmpty) {
        return Success(result.valueOrNull!.rows);
      }
    } catch (_) {}
    final result = await _client.getList<TicketSizeOption>(
      path: '/public/ticket-sizes',
      itemParser: (json) =>
          TicketSizeOption.fromJson(Map<String, dynamic>.from(json as Map)),
    );
    if (result.isFailure) return Err(result.failureOrNull!);
    return Success(result.valueOrNull!.rows);
  }

  @override
  Future<Result<List<MasterOption>>> getIndustryOptions() async {
    final result = await _client.getList<MasterOption>(
      path: ApiEndpoints.publicIndustries,
      query: const {'page': 1, 'pageSize': 200},
      itemParser: MasterOption.fromJson,
    );
    if (result.isFailure) return Err(result.failureOrNull!);
    final list = result.valueOrNull!.rows
        .where((opt) => opt.id.isNotEmpty && opt.name.isNotEmpty)
        .toList();
    return Success(list);
  }

  @override
  Future<Result<List<MasterOption>>> getStartupStageOptions() async {
    final result = await _client.getList<MasterOption>(
      path: ApiEndpoints.publicStartupStages,
      itemParser: MasterOption.fromJson,
    );
    if (result.isFailure) return Err(result.failureOrNull!);
    final list = result.valueOrNull!.rows
        .where((opt) => opt.id.isNotEmpty && opt.name.isNotEmpty)
        .toList();
    return Success(list);
  }

  @override
  Future<Result<List<MasterOption>>> getStartupRoleOptions() async {
    final result = await _client.getList<MasterOption>(
      path: ApiEndpoints.publicStartupRoles,
      itemParser: MasterOption.fromJson,
    );
    if (result.isFailure) return Err(result.failureOrNull!);
    final list = result.valueOrNull!.rows
        .where((opt) => opt.id.isNotEmpty && opt.name.isNotEmpty)
        .toList();
    return Success(list);
  }

  @override
  Future<Result<List<MasterOption>>> getFounderGoalOptions() async {
    final result = await _client.getList<MasterOption>(
      path: ApiEndpoints.publicFounderGoals,
      itemParser: MasterOption.fromJson,
    );
    if (result.isFailure) return Err(result.failureOrNull!);
    final list = result.valueOrNull!.rows
        .where((opt) => opt.id.isNotEmpty && opt.name.isNotEmpty)
        .toList();
    return Success(list);
  }
}
