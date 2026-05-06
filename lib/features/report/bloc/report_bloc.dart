import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/report_service.dart';
import 'report_event.dart';
import 'report_state.dart';

class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final ReportService reportService;

  ReportBloc({required this.reportService}) : super(ReportInitial()) {
    on<LoadReportDashboard>(_onLoadReportDashboard);
  }

  Future<void> _onLoadReportDashboard(
    LoadReportDashboard event,
    Emitter<ReportState> emit,
  ) async {
    emit(ReportLoading());

    try {
      final dashboard = await reportService.getDashboard();
      final instagramProfile = await reportService.getInstagramProfile();

      final appTopContent = await reportService.getTopContent(
        source: 'app',
        limit: 10,
      );

      final instagramTopContent = await reportService.getTopContent(
        source: 'instagram',
        limit: 10,
      );

      final appHashtags = await reportService.getTopHashtags(
        source: 'app',
        limit: 10,
      );

      final instagramHashtags = await reportService.getTopHashtags(
        source: 'instagram',
        limit: 10,
      );

      final appNetworkAnalysis = await reportService.getNetworkAnalysis(
        source: 'app',
        limit: 1200,
        top: 10,
      );

      final instagramNetworkAnalysis = await reportService.getNetworkAnalysis(
        source: 'instagram',
        limit: 1200,
        top: 10,
      );

      emit(
        ReportLoaded(
          dashboard: dashboard,
          instagramProfile: instagramProfile,
          appTopContent: appTopContent,
          instagramTopContent: instagramTopContent,
          appHashtags: appHashtags,
          instagramHashtags: instagramHashtags,
          appNetworkAnalysis: appNetworkAnalysis,
          instagramNetworkAnalysis: instagramNetworkAnalysis,
        ),
      );
    } catch (e) {
      emit(ReportError('Failed to load report data.\n\n$e'));
    }
  }
}
