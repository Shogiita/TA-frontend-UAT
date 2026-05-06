import 'package:equatable/equatable.dart';

import '../models/dashboard_model.dart';
import '../models/hashtag_model.dart';
import '../models/instagram_profile_model.dart';
import '../models/network_analysis_model.dart';
import '../models/top_content_model.dart';

abstract class ReportState extends Equatable {
  const ReportState();

  @override
  List<Object?> get props => [];
}

class ReportInitial extends ReportState {}

class ReportLoading extends ReportState {}

class ReportLoaded extends ReportState {
  final DashboardModel dashboard;
  final InstagramProfileModel? instagramProfile;
  final List<TopContentModel> appTopContent;
  final List<TopContentModel> instagramTopContent;
  final List<HashtagModel> appHashtags;
  final List<HashtagModel> instagramHashtags;
  final NetworkAnalysisModel appNetworkAnalysis;
  final NetworkAnalysisModel instagramNetworkAnalysis;

  const ReportLoaded({
    required this.dashboard,
    required this.instagramProfile,
    required this.appTopContent,
    required this.instagramTopContent,
    required this.appHashtags,
    required this.instagramHashtags,
    required this.appNetworkAnalysis,
    required this.instagramNetworkAnalysis,
  });

  @override
  List<Object?> get props => [
    dashboard,
    instagramProfile,
    appTopContent,
    instagramTopContent,
    appHashtags,
    instagramHashtags,
    appNetworkAnalysis,
    instagramNetworkAnalysis,
  ];
}

class ReportError extends ReportState {
  final String message;

  const ReportError(this.message);

  @override
  List<Object?> get props => [message];
}
