import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../models/sna_graph_model.dart';

class SnaService {
  final Dio dio;

  SnaService(this.dio);

  Future<SnaGraphModel> getVisualization({
    required String source,
    required int mode,
    int limit = 500,
  }) async {
    final response = await dio.get(
      ApiConstants.visualization,
      queryParameters: {'source': source, 'mode': mode, 'limit': limit},
    );

    return SnaGraphModel.fromJson(response.data);
  }
}
