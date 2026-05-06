import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../models/dashboard_model.dart';
import '../models/hashtag_model.dart';
import '../models/instagram_profile_model.dart';
import '../models/network_analysis_model.dart';
import '../models/top_content_model.dart';

class ReportService {
  final Dio dio;

  ReportService(this.dio);

  Future<DashboardModel> getDashboard() async {
    final response = await dio.get(ApiConstants.dashboard);
    return DashboardModel.fromJson(response.data['data']);
  }

  Future<InstagramProfileModel?> getInstagramProfile() async {
    final response = await dio.get(ApiConstants.instagramProfile);
    final data = response.data['data'];

    if (data == null) return null;

    return InstagramProfileModel.fromJson(data);
  }

  Future<List<TopContentModel>> getTopContent({
    required String source,
    int limit = 10,
  }) async {
    final response = await dio.get(
      ApiConstants.topContent,
      queryParameters: {'source': source, 'limit': limit},
    );

    final List data = response.data['data'] ?? [];

    return data.map((item) => TopContentModel.fromJson(item)).toList();
  }

  Future<List<HashtagModel>> getTopHashtags({
    required String source,
    int limit = 10,
  }) async {
    final response = await dio.get(
      ApiConstants.topHashtags,
      queryParameters: {'source': source, 'limit': limit},
    );

    final List data = response.data['data'] ?? [];

    return data.map((item) => HashtagModel.fromJson(item)).toList();
  }

  Future<NetworkAnalysisModel> getNetworkAnalysis({
    required String source,
    int limit = 1200,
    int top = 10,
  }) async {
    final response = await dio.get(
      ApiConstants.networkAnalysis,
      queryParameters: {'source': source, 'limit': limit, 'top': top},
    );

    return NetworkAnalysisModel.fromJson(response.data);
  }
}
