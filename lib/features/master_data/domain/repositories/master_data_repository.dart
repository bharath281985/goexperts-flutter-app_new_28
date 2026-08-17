import '../../../../core/utils/result.dart';
import '../entities/master_option.dart';
import '../entities/skill_category.dart';
import '../entities/skill_option.dart';
import '../entities/ticket_size_option.dart';

abstract class MasterDataRepository {
  Future<Result<List<SkillCategory>>> getSkillCategories({
    String? industryId,
    int page,
    int pageSize,
    String search,
  });

  /// Categories for profile completion — backed by the public categories API.
  Future<Result<List<SkillCategory>>> getIndustries();

  Future<Result<List<SkillOption>>> getSkills({
    required String categoryId,
    int page,
    int pageSize,
  });

  Future<Result<int>> getSkillsTotal({required String categoryId});

  Future<Result<List<String>>> getMasters(String type);
  Future<Result<List<String>>> getCountries();
  Future<Result<List<String>>> getStates(String countryName);
  Future<Result<List<String>>> getExperienceLevels();
  Future<Result<List<String>>> getWorkModes();
  Future<Result<List<String>>> getHiringGoals();
  Future<Result<List<String>>> getHiringBudgetRanges();
  Future<Result<List<String>>> getInvestorTypes();
  Future<Result<List<String>>> getInvestorStages();
  Future<Result<List<String>>> getStartupStages();
  Future<Result<List<String>>> getStartupRoles();
  Future<Result<List<String>>> getCities();
  Future<Result<List<String>>> getDesignations();
  Future<Result<List<String>>> getCompanySizes();
  Future<Result<List<String>>> getStartupGoals();

  Future<Result<List<MasterOption>>> getCountriesOptions();
  Future<Result<List<MasterOption>>> getStatesOptions(String countryIdOrCode);
  Future<Result<List<MasterOption>>> getExperienceLevelOptions();
  Future<Result<List<MasterOption>>> getAvailabilityOptions();
  Future<Result<List<MasterOption>>> getCompanySizeOptions();
  Future<Result<List<MasterOption>>> getHiringBudgetOptions();
  Future<Result<List<MasterOption>>> getHiringGoalOptions();
  Future<Result<List<MasterOption>>> getTeamSizeOptions();

  Future<Result<List<MasterOption>>> getInvestorTypeOptions();
  Future<Result<List<MasterOption>>> getInvestorStageOptions();
  Future<Result<List<TicketSizeOption>>> getTicketSizeOptions();
  Future<Result<List<MasterOption>>> getIndustryOptions();
  Future<Result<List<MasterOption>>> getStartupStageOptions();
  Future<Result<List<MasterOption>>> getStartupRoleOptions();
  Future<Result<List<MasterOption>>> getFounderGoalOptions();
}
