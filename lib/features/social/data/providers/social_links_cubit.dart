import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client_helper.dart';
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

class SocialLinksCubit extends Cubit<SocialLinksState> {
  final ApiClientHelper _apiClient;

  SocialLinksCubit(this._apiClient) : super(SocialLinksState()) {
    fetchLinks();
  }

  Future<void> fetchLinks() async {
    emit(state.copyWith(isLoading: true, error: null));
    
    final response = await _apiClient.getEnvelope<List<SocialLink>>(
      '/social-links',
      parser: (envelope) {
        final data = envelope.data;
        final linksList = data is List
            ? data
            : (data is Map && data['links'] is List
                  ? data['links'] as List
                  : const []);
        return linksList
            .map((json) => SocialLink.fromJson(json as Map<String, dynamic>))
            .toList();
      },
    );

    response.fold(
      (failure) => emit(state.copyWith(isLoading: false, error: failure.message)),
      (links) => emit(state.copyWith(isLoading: false, links: links)),
    );
  }

  Future<bool> addLink(String platform, String url) async {
    final response = await _apiClient.postEnvelope<SocialLink>(
      '/social-links',
      body: {'platform': platform, 'url': url},
      parser: (envelope) {
        final data = envelope.data;
        final linkJson = data is Map && data['link'] is Map
            ? data['link']
            : data;
        return SocialLink.fromJson(linkJson as Map<String, dynamic>);
      },
    );

    return response.fold(
      (failure) => false,
      (newLink) {
        emit(state.copyWith(links: [newLink, ...state.links]));
        return true;
      },
    );
  }

  Future<bool> updateLink(String id, String platform, String url) async {
    final response = await _apiClient.putEnvelope<SocialLink>(
      '/social-links/$id',
      body: {'platform': platform, 'url': url},
      parser: (envelope) {
        final data = envelope.data;
        final linkJson = data is Map && data['link'] is Map
            ? data['link']
            : data;
        return SocialLink.fromJson(linkJson as Map<String, dynamic>);
      },
    );

    return response.fold(
      (failure) => false,
      (updatedLink) {
        final newLinks = state.links.map((link) {
          if (link.id == id) {
            return updatedLink;
          }
          return link;
        }).toList();
        emit(state.copyWith(links: newLinks));
        return true;
      },
    );
  }

  Future<bool> deleteLink(String id) async {
    final response = await _apiClient.deleteAction('/social-links/$id');
    return response.fold(
      (failure) => false,
      (_) {
        final newLinks = state.links.where((link) => link.id != id).toList();
        emit(state.copyWith(links: newLinks));
        return true;
      },
    );
  }
}
