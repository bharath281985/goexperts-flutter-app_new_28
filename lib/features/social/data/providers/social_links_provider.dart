import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../models/social_link_model.dart';

class SocialLinksState {
  final bool isLoading;
  final String? error;
  final List<SocialLink> links;

  SocialLinksState({
    this.isLoading = false,
    this.error,
    this.links = const [],
  });

  SocialLinksState copyWith({
    bool? isLoading,
    String? error,
    List<SocialLink>? links,
  }) {
    return SocialLinksState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      links: links ?? this.links,
    );
  }
}

class SocialLinksNotifier extends StateNotifier<SocialLinksState> {
  final ApiClient _apiClient;

  SocialLinksNotifier(this._apiClient) : super(SocialLinksState()) {
    fetchLinks();
  }

  Future<void> fetchLinks() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.get('/mobile/social-links');
      final apiResponse = ApiResponse.parse(response.data);

      if (apiResponse.success) {
        final linksList = (response.data['links'] as List?) ?? [];
        final links = linksList
            .map((json) => SocialLink.fromJson(json as Map<String, dynamic>))
            .toList();
        state = state.copyWith(isLoading: false, links: links);
      } else {
        state = state.copyWith(
            isLoading: false, error: apiResponse.message ?? 'Failed to load links');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> addLink(String platform, String url) async {
    try {
      final response = await _apiClient.post('/mobile/social-links', data: {
        'platform': platform,
        'url': url,
      });
      final apiResponse = ApiResponse.parse(response.data);
      if (apiResponse.success) {
        final newLink = SocialLink.fromJson(response.data['link']);
        state = state.copyWith(links: [newLink, ...state.links]);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateLink(String id, String platform, String url) async {
    try {
      final response = await _apiClient.put('/mobile/social-links/$id', data: {
        'platform': platform,
        'url': url,
      });
      final apiResponse = ApiResponse.parse(response.data);
      if (apiResponse.success) {
        final updatedLink = SocialLink.fromJson(response.data['link']);
        final newLinks = state.links.map((link) {
          if (link.id == id) {
            return updatedLink;
          }
          return link;
        }).toList();
        state = state.copyWith(links: newLinks);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteLink(String id) async {
    try {
      final response = await _apiClient.delete('/mobile/social-links/$id');
      final apiResponse = ApiResponse.parse(response.data);
      if (apiResponse.success) {
        final newLinks = state.links.where((link) => link.id != id).toList();
        state = state.copyWith(links: newLinks);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

final socialLinksProvider =
    StateNotifierProvider<SocialLinksNotifier, SocialLinksState>((ref) {
  return SocialLinksNotifier(sl<ApiClient>());
});
