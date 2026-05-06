import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/network/dio_client.dart';
import 'core/theme/app_theme.dart';

import 'features/report/bloc/report_bloc.dart';
import 'features/report/pages/report_page.dart';
import 'features/report/services/report_service.dart';

import 'features/sna/bloc/sna_bloc.dart';
import 'features/sna/services/sna_service.dart';

void main() {
  final dioClient = DioClient();

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ReportService>(
          create: (_) => ReportService(dioClient.dio),
        ),
        RepositoryProvider<SnaService>(
          create: (_) => SnaService(dioClient.dio),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ReportBloc>(
            create: (context) =>
                ReportBloc(reportService: context.read<ReportService>()),
          ),
          BlocProvider<SnaBloc>(
            create: (context) =>
                SnaBloc(snaService: context.read<SnaService>()),
          ),
        ],
        child: const SnaLiteApp(),
      ),
    ),
  );
}

class SnaLiteApp extends StatelessWidget {
  const SnaLiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SNA Lite UAT',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const ReportPage(),
    );
  }
}
