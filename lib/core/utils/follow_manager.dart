import 'package:flutter/foundation.dart';
import '../../app/dependency_injection/service_locator.dart';
import '../storage/local_storage.dart';

/// Central manager for the follow system and connections.
///
/// Persists followed profiles, categories, technologies and communities
/// to LocalStorage, and calculates followers, following and mutual connections.
class FollowManager extends ChangeNotifier {
  FollowManager._();

  static final FollowManager instance = FollowManager._();

  LocalStorage get _storage => sl<LocalStorage>();

  static const String categoryFreelancers = 'freelancers';
  static const String categoryCompanies = 'companies';
  static const String categoryInvestors = 'investors';
  static const String categoryFounders = 'founders';
  static const String categoryCategories = 'categories';
  static const String categoryTechnologies = 'technologies';
  static const String categoryServices = 'services';
  static const String categoryTopics = 'topics';
  static const String categoryCommunities = 'communities';

  /// Toggle follow state for an item in a category.
  Future<bool> toggleFollow(String category, String id) async {
    final list = getFollowing(category);
    final isFollowing = list.contains(id);
    if (isFollowing) {
      list.remove(id);
    } else {
      list.add(id);
    }
    await _storage.setStringList('following_$category', list);
    notifyListeners();
    return !isFollowing;
  }

  /// Sync follow state for an item in a category.
  Future<void> syncItem(String category, String id, bool isFollowing) async {
    final list = getFollowing(category);
    final currentlyFollowing = list.contains(id);
    if (isFollowing && !currentlyFollowing) {
      list.add(id);
      await _storage.setStringList('following_$category', list);
      notifyListeners();
    } else if (!isFollowing && currentlyFollowing) {
      list.remove(id);
      await _storage.setStringList('following_$category', list);
      notifyListeners();
    }
  }

  /// Check if following an item.
  bool isFollowing(String category, String id) {
    return getFollowing(category).contains(id);
  }

  /// Get list of followed item IDs.
  List<String> getFollowing(String category) {
    return _storage.getStringList('following_$category');
  }

  /// Get followers list (mocked).
  List<String> getFollowers(String category) {
    // Returns dummy follower IDs for display
    return ['user_1', 'user_2', 'user_3', 'user_4', 'user_5'];
  }

  /// Get mutual connections (mocked but deterministic).
  List<String> getMutualConnections() {
    return ['f1', 'i1', 'fo1'];
  }

  int getFollowingCount() {
    int total = 0;
    for (final cat in [
      categoryFreelancers,
      categoryCompanies,
      categoryInvestors,
      categoryFounders,
      categoryCategories,
      categoryTechnologies,
      categoryServices,
      categoryTopics,
      categoryCommunities,
    ]) {
      total += getFollowing(cat).length;
    }
    return total;
  }

  int getFollowersCount() {
    return 142; // Rich mock count
  }

  int getMutualConnectionsCount() {
    return getMutualConnections().length;
  }
}
