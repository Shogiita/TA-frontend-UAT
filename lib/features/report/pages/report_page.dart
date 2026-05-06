import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../sna/pages/sna_visualization_page.dart';
import '../bloc/report_bloc.dart';
import '../bloc/report_event.dart';
import '../bloc/report_state.dart';
import '../models/hashtag_model.dart';
import '../models/network_analysis_model.dart';
import '../models/top_content_model.dart';

class _DS {
  static const Color surface = Color(0xFFF4F6FB);
  static const Color card = Colors.white;
  static const Color primary = Color(0xFF2563EB);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color green = Color(0xFF10B981);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);

  static const double radius = 22;
  static const double gap = 18;

  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 22,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> primaryShadow = [
    BoxShadow(
      color: primary.withValues(alpha: 0.28),
      blurRadius: 28,
      offset: const Offset(0, 10),
    ),
  ];
}

enum GeodesicViewMode { list, visualization }

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage>
    with SingleTickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;

  String selectedSource = 'app';

  GeodesicViewMode geodesicViewMode = GeodesicViewMode.list;
  int selectedGeodesicIndex = 0;

  @override
  void initState() {
    super.initState();

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    fadeAnimation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOut,
    );

    slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
          CurvedAnimation(
            parent: animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    animationController.forward();

    context.read<ReportBloc>().add(const LoadReportDashboard());
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  void _openSnaConfigDialog() {
    int selectedMode = 1;
    int selectedLimit = 300;
    String source = selectedSource;

    final limitController = TextEditingController(
      text: selectedLimit.toString(),
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 460,
                  maxHeight: 720,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_DS.primary, _DS.purple],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.hub_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Konfigurasi Visualisasi SNA',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 17,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Atur sumber data, mode jaringan, dan limit data.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          children: [
                            DropdownButtonFormField<String>(
                              initialValue: source,
                              decoration: const InputDecoration(
                                labelText: 'Sumber Data',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'app',
                                  child: Text('App / Firebase'),
                                ),
                                DropdownMenuItem(
                                  value: 'instagram',
                                  child: Text('Instagram'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setDialogState(() => source = value);
                              },
                            ),
                            const SizedBox(height: 14),
                            _modeCard(
                              title: '1-Mode User to User',
                              subtitle:
                                  'Relasi antar user berdasarkan interaksi pada post yang sama.',
                              icon: Icons.people_alt_rounded,
                              value: 1,
                              selected: selectedMode,
                              color: _DS.primary,
                              onTap: () {
                                setDialogState(() => selectedMode = 1);
                              },
                            ),
                            const SizedBox(height: 10),
                            _modeCard(
                              title: '2-Mode User to Post',
                              subtitle: 'Relasi langsung antara user dan post.',
                              icon: Icons.article_rounded,
                              value: 2,
                              selected: selectedMode,
                              color: _DS.purple,
                              onTap: () {
                                setDialogState(() => selectedMode = 2);
                              },
                            ),
                            const SizedBox(height: 10),
                            _modeCard(
                              title: 'Post to Post',
                              subtitle:
                                  'Relasi antar post berdasarkan user yang sama.',
                              icon: Icons.account_tree_rounded,
                              value: 3,
                              selected: selectedMode,
                              color: _DS.green,
                              onTap: () {
                                setDialogState(() => selectedMode = 3);
                              },
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: limitController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Limit Data',
                                helperText:
                                    'Semakin besar limit, semakin berat render graph.',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.data_usage_rounded),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                              },
                              child: const Text('Batal'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                final parsedLimit =
                                    int.tryParse(limitController.text) ?? 300;

                                Navigator.pop(dialogContext);

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SnaVisualizationPage(
                                      source: source,
                                      mode: selectedMode,
                                      limit: parsedLimit.clamp(50, 3000),
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: const Text('Visualisasikan'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _DS.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      limitController.dispose();
    });
  }

  Widget _modeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required int value,
    required int selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isSelected = value == selected;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : _DS.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : _DS.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isSelected ? color : _DS.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _DS.textSecondary,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DS.surface,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openSnaConfigDialog,
        backgroundColor: _DS.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.hub_rounded),
        label: const Text(
          'Visualisasi SNA',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: BlocBuilder<ReportBloc, ReportState>(
        builder: (context, state) {
          if (state is ReportLoading || state is ReportInitial) {
            return const LoadingWidget();
          }

          if (state is ReportError) {
            return _errorState(state.message);
          }

          if (state is ReportLoaded) {
            return FadeTransition(
              opacity: fadeAnimation,
              child: SlideTransition(
                position: slideAnimation,
                child: RefreshIndicator(
                  onRefresh: () async {
                    context.read<ReportBloc>().add(const LoadReportDashboard());
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 90),
                    children: [
                      _header(),
                      const SizedBox(height: _DS.gap),
                      if (state.instagramProfile != null)
                        _instagramProfile(state),
                      if (state.instagramProfile != null)
                        const SizedBox(height: _DS.gap),
                      _statsGrid(state),
                      const SizedBox(height: _DS.gap),
                      _sourceControl(),
                      const SizedBox(height: _DS.gap),
                      _contentArea(state),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_DS.primary, _DS.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(_DS.radius),
        boxShadow: _DS.primaryShadow,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            top: -36,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SNA Lite UAT Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Dashboard dummy data untuk hands-on User Acceptance Testing Social Network Analysis.',
                      style: TextStyle(color: Colors.white70, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _instagramProfile(ReportLoaded state) {
    final profile = state.instagramProfile!;
    final formatter = NumberFormat.decimalPattern('id_ID');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: _DS.primary.withValues(alpha: 0.12),
            backgroundImage: profile.profilePictureUrl.isNotEmpty
                ? NetworkImage(profile.profilePictureUrl)
                : null,
            child: profile.profilePictureUrl.isEmpty
                ? const Icon(Icons.person_rounded, size: 34)
                : null,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _DS.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '@${profile.username}',
                  style: const TextStyle(
                    color: _DS.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  profile.biography,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _DS.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
          _profileMetric('Followers', formatter.format(profile.followersCount)),
          _profileMetric('Following', formatter.format(profile.followsCount)),
          _profileMetric('Posts', formatter.format(profile.mediaCount)),
        ],
      ),
    );
  }

  Widget _profileMetric(String label, String value) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(left: 12),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: _DS.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: _DS.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _statsGrid(ReportLoaded state) {
    final d = state.dashboard;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final cardWidth = width > 1180
            ? (width - 54) / 4
            : width > 760
            ? (width - 18) / 2
            : width;

        return Wrap(
          spacing: 18,
          runSpacing: 18,
          children: [
            SizedBox(
              width: cardWidth,
              child: StatCard(
                title: 'New Users',
                value: d.totalNewUsers,
                icon: Icons.people_alt_rounded,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: StatCard(
                title: 'KawanSS Posts',
                value: d.totalKawanssPosts,
                icon: Icons.article_rounded,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: StatCard(
                title: 'Infoss Posts',
                value: d.totalInfossPosts,
                icon: Icons.newspaper_rounded,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: StatCard(
                title: 'Instagram Posts',
                value: d.totalInstagramPosts,
                icon: Icons.camera_alt_rounded,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: StatCard(
                title: 'Instagram Users',
                value: d.totalInstagramUsers,
                icon: Icons.person_pin_rounded,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: StatCard(
                title: 'Comments',
                value: d.totalComments,
                icon: Icons.forum_rounded,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: StatCard(
                title: 'Likes',
                value: d.totalLikes,
                icon: Icons.thumb_up_alt_rounded,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _sourceControl() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 720;

          final sourceDropdown = SizedBox(
            width: isSmall ? double.infinity : 240,
            child: DropdownButtonFormField<String>(
              initialValue: selectedSource,
              decoration: const InputDecoration(
                labelText: 'Sumber Data',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'app', child: Text('App / Firebase')),
                DropdownMenuItem(value: 'instagram', child: Text('Instagram')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  selectedSource = value;
                  selectedGeodesicIndex = 0;
                  geodesicViewMode = GeodesicViewMode.list;
                });
              },
            ),
          );

          final visualButton = ElevatedButton.icon(
            onPressed: _openSnaConfigDialog,
            icon: const Icon(Icons.hub_rounded),
            label: const Text('Buka Visualisasi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _DS.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          );

          if (isSmall) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _DS.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.dashboard_customize_rounded,
                        color: _DS.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Filter Dashboard',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: _DS.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                sourceDropdown,
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: visualButton),
              ],
            );
          }

          return Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _DS.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.dashboard_customize_rounded,
                  color: _DS.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Filter Dashboard',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: _DS.textPrimary,
                ),
              ),
              const SizedBox(width: 18),
              sourceDropdown,
              const Spacer(),
              visualButton,
            ],
          );
        },
      ),
    );
  }

  Widget _contentArea(ReportLoaded state) {
    final isApp = selectedSource == 'app';

    final topContent = isApp ? state.appTopContent : state.instagramTopContent;
    final hashtags = isApp ? state.appHashtags : state.instagramHashtags;
    final networkAnalysis = isApp
        ? state.appNetworkAnalysis
        : state.instagramNetworkAnalysis;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _networkAnalysisArea(networkAnalysis),
        const SizedBox(height: _DS.gap),
        LayoutBuilder(
          builder: (context, constraints) {
            final isSmall = constraints.maxWidth < 1050;

            if (isSmall) {
              return Column(
                children: [
                  _topContentCard(
                    title: isApp ? 'Top App Content' : 'Top Instagram Content',
                    items: topContent,
                  ),
                  const SizedBox(height: _DS.gap),
                  _hashtagCard(
                    title: isApp
                        ? 'Top App Hashtags'
                        : 'Top Instagram Hashtags',
                    items: hashtags,
                  ),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 7,
                  child: _topContentCard(
                    title: isApp ? 'Top App Content' : 'Top Instagram Content',
                    items: topContent,
                  ),
                ),
                const SizedBox(width: _DS.gap),
                Expanded(
                  flex: 4,
                  child: _hashtagCard(
                    title: isApp
                        ? 'Top App Hashtags'
                        : 'Top Instagram Hashtags',
                    items: hashtags,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _networkAnalysisArea(NetworkAnalysisModel analysis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _analysisSummaryCard(analysis),
        const SizedBox(height: _DS.gap),

        // Centrality dibuat full width supaya tidak kepotong dan tidak menyisakan blank besar
        _centralitySection(analysis),

        const SizedBox(height: _DS.gap),

        // Leiden dan Geodesic dibuat responsive
        LayoutBuilder(
          builder: (context, constraints) {
            final isSmall = constraints.maxWidth < 1050;

            if (isSmall) {
              return Column(
                children: [
                  _leidenCommunitySection(analysis),
                  const SizedBox(height: _DS.gap),
                  _geodesicSection(analysis),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: _leidenCommunitySection(analysis)),
                const SizedBox(width: _DS.gap),
                Expanded(flex: 5, child: _geodesicSection(analysis)),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _analysisSummaryCard(NetworkAnalysisModel analysis) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _DS.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.account_tree_rounded,
              color: _DS.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Network Analysis Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _DS.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${analysis.totalNodes} nodes • ${analysis.totalEdges} edges • ${analysis.totalCommunities} Leiden communities',
                  style: const TextStyle(color: _DS.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _centralitySection(NetworkAnalysisModel analysis) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.hub_rounded,
            title: 'Top 10 Centrality Measurements',
            subtitle:
                'Menampilkan node paling berpengaruh berdasarkan degree, eigenvector, closeness, dan betweenness.',
            color: _DS.primary,
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 900;

              final widgets = [
                _centralityList('Degree', analysis.degree, _DS.primary),
                _centralityList(
                  'Eigenvector',
                  analysis.eigenvector,
                  _DS.purple,
                ),
                _centralityList('Closeness', analysis.closeness, _DS.green),
                _centralityList(
                  'Betweenness',
                  analysis.betweenness,
                  const Color(0xFFEA580C),
                ),
              ];

              if (isSmall) {
                return Column(
                  children: widgets
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: item,
                        ),
                      )
                      .toList(),
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: widgets[0]),
                  const SizedBox(width: 12),
                  Expanded(child: widgets[1]),
                  const SizedBox(width: 12),
                  Expanded(child: widgets[2]),
                  const SizedBox(width: 12),
                  Expanded(child: widgets[3]),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _centralityList(
    String title,
    List<CentralityItem> items,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Text('No data', style: TextStyle(color: _DS.textSecondary))
          else
            ...items.take(10).map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.10)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${item.rank}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: _DS.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.score.toStringAsFixed(4),
                        style: TextStyle(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _leidenCommunitySection(NetworkAnalysisModel analysis) {
    final visibleCommunities = analysis.communities.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.bubble_chart_rounded,
            title: 'Leiden Community Detection',
            subtitle:
                '${analysis.totalCommunities} communities detected using Leiden Algorithm.',
            color: _DS.green,
          ),
          const SizedBox(height: 18),
          if (visibleCommunities.isEmpty)
            const Text(
              'No community detected',
              style: TextStyle(color: _DS.textSecondary),
            )
          else
            ...visibleCommunities.map((community) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _DS.green.withValues(alpha: 0.055),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _DS.green.withValues(alpha: 0.18)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: _DS.green,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${community.rank}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Community ${community.communityId}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: _DS.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _DS.green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${community.size} nodes',
                            style: const TextStyle(
                              color: _DS.green,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: community.members.take(6).map((member) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: _DS.border),
                          ),
                          child: Text(
                            member.label,
                            style: const TextStyle(
                              fontSize: 11,
                              color: _DS.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            }),
          if (analysis.communities.length > 5)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _DS.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _DS.border),
              ),
              child: Text(
                '+ ${analysis.communities.length - 5} communities lainnya',
                style: const TextStyle(
                  color: _DS.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _geodesicSection(NetworkAnalysisModel analysis) {
    final paths = analysis.geodesicPaths;
    final visiblePaths = paths.take(5).toList();

    final selectedIndex = paths.isEmpty
        ? 0
        : selectedGeodesicIndex.clamp(0, paths.length - 1);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.route_rounded,
            title: 'Top Geodesic Paths',
            subtitle: 'Jalur terpendek antar node beserta jumlah hops.',
            color: _DS.primary,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _viewModeButton(
                label: 'Daftar',
                active: geodesicViewMode == GeodesicViewMode.list,
                onTap: () {
                  setState(() => geodesicViewMode = GeodesicViewMode.list);
                },
              ),
              const SizedBox(width: 8),
              _viewModeButton(
                label: 'Visualisasi',
                active: geodesicViewMode == GeodesicViewMode.visualization,
                onTap: () {
                  setState(() {
                    geodesicViewMode = GeodesicViewMode.visualization;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (paths.isEmpty)
            const Text(
              'No geodesic path detected',
              style: TextStyle(color: _DS.textSecondary),
            )
          else if (geodesicViewMode == GeodesicViewMode.list)
            Column(
              children: visiblePaths.asMap().entries.map((entry) {
                final index = entry.key;
                final path = entry.value;

                return _geodesicPathCard(
                  path,
                  selected: index == selectedIndex,
                  onTap: () {
                    setState(() => selectedGeodesicIndex = index);
                  },
                );
              }).toList(),
            )
          else
            _geodesicVisualization(paths[selectedIndex]),
          if (paths.length > 5 && geodesicViewMode == GeodesicViewMode.list)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _DS.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _DS.border),
              ),
              child: Text(
                '+ ${paths.length - 5} paths lainnya',
                style: const TextStyle(
                  color: _DS.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _viewModeButton({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: active ? _DS.primary.withValues(alpha: 0.12) : _DS.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? _DS.primary : _DS.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? _DS.primary : _DS.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _geodesicPathCard(
    GeodesicPath path, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? _DS.primary.withValues(alpha: 0.08) : _DS.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? _DS.primary : _DS.border),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? _DS.primary : _DS.textSecondary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${path.rank}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${path.sourceLabel} → ${path.targetLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: _DS.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    path.pathDetails,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _DS.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${path.hops}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: _DS.textPrimary,
                  ),
                ),
                const Text(
                  'hops',
                  style: TextStyle(color: _DS.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _geodesicVisualization(GeodesicPath path) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _DS.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Path #${path.rank} • ${path.hops} hops',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: _DS.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < path.path.length; i++) ...[
                  _pathNode(path.path[i], i),
                  if (i < path.path.length - 1)
                    _pathArrow(
                      path.edges.length > i ? path.edges[i].weight : 1,
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Detail: ${path.pathDetails}',
            style: const TextStyle(color: _DS.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _pathNode(GeodesicNode node, int index) {
    return Column(
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: index == 0 ? _DS.primary : _DS.purple,
            shape: BoxShape.circle,
          ),
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 96,
          child: Text(
            node.label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: _DS.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _pathArrow(double weight) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          const Icon(Icons.arrow_forward_rounded, color: _DS.primary),
          Text(
            'w: ${weight.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 10, color: _DS.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _topContentCard({
    required String title,
    required List<TopContentModel> items,
  }) {
    final formatter = NumberFormat.decimalPattern('id_ID');

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _DS.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: _DS.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _DS.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Diurutkan berdasarkan jumlah likes tertinggi.',
                      style: TextStyle(color: _DS.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _DS.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _DS.border),
              ),
              child: const Text(
                'Belum ada top content.',
                style: TextStyle(color: _DS.textSecondary),
              ),
            )
          else
            ListView.separated(
              itemCount: items.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                final isTopThree = index < 3;

                final rankColor = index == 0
                    ? const Color(0xFFF59E0B)
                    : index == 1
                    ? const Color(0xFF64748B)
                    : index == 2
                    ? const Color(0xFFB45309)
                    : _DS.primary;

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isTopThree
                        ? rankColor.withValues(alpha: 0.075)
                        : _DS.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isTopThree
                          ? rankColor.withValues(alpha: 0.25)
                          : _DS.border,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: rankColor,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: rankColor.withValues(alpha: 0.25),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: _DS.textPrimary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (item.type.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _DS.primary.withValues(
                                        alpha: 0.10,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      item.type,
                                      style: const TextStyle(
                                        color: _DS.primary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _DS.textSecondary,
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _miniMetricChip(
                                  icon: Icons.favorite_rounded,
                                  label:
                                      '${formatter.format(item.likes)} likes',
                                  color: const Color(0xFFE11D48),
                                ),
                                _miniMetricChip(
                                  icon: Icons.comment_rounded,
                                  label:
                                      '${formatter.format(item.comments)} comments',
                                  color: _DS.primary,
                                ),
                                _miniMetricChip(
                                  icon: Icons.visibility_rounded,
                                  label:
                                      '${formatter.format(item.views)} views',
                                  color: _DS.green,
                                ),
                                _miniMetricChip(
                                  icon: Icons.share_rounded,
                                  label:
                                      '${formatter.format(item.shares)} shares',
                                  color: _DS.purple,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      Container(
                        width: 96,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _DS.border),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.favorite_rounded,
                              color: Color(0xFFE11D48),
                              size: 18,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              formatter.format(item.likes),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: _DS.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'likes',
                              style: TextStyle(
                                color: _DS.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _miniMetricChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _hashtagCard({
    required String title,
    required List<HashtagModel> items,
  }) {
    final formatter = NumberFormat.decimalPattern('id_ID');

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _DS.purple.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.tag_rounded,
                  color: _DS.purple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _DS.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _DS.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _DS.border),
              ),
              child: const Text(
                'Belum ada hashtag.',
                style: TextStyle(color: _DS.textSecondary),
              ),
            )
          else
            ListView.separated(
              itemCount: items.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                final progress = items.first.totalPosts == 0
                    ? 0.0
                    : item.totalPosts / items.first.totalPosts;

                return Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: _DS.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _DS.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _DS.purple.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: _DS.purple,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.hashtag,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: _DS.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            '${formatter.format(item.totalPosts)} posts',
                            style: const TextStyle(
                              color: _DS.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          minHeight: 7,
                          value: progress.clamp(0.0, 1.0),
                          backgroundColor: _DS.border,
                          valueColor: const AlwaysStoppedAnimation(_DS.purple),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${formatter.format(item.totalLikes)} likes',
                              style: const TextStyle(
                                color: _DS.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          Text(
                            '${formatter.format(item.totalComments)} comments',
                            style: const TextStyle(
                              color: _DS.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _DS.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _DS.textSecondary,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget _sectionTitle(String title, IconData icon) {
  //   return Row(
  //     children: [
  //       Icon(icon, color: _DS.primary, size: 20),
  //       const SizedBox(width: 8),
  //       Text(
  //         title,
  //         style: const TextStyle(
  //           fontSize: 18,
  //           fontWeight: FontWeight.w900,
  //           color: _DS.textPrimary,
  //         ),
  //       ),
  //     ],
  //   );
  // }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: _DS.card,
      borderRadius: BorderRadius.circular(_DS.radius),
      border: Border.all(color: _DS.border),
      boxShadow: _DS.softShadow,
    );
  }

  Widget _errorState(String message) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 620),
        decoration: _cardDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.red,
              size: 42,
            ),
            const SizedBox(height: 12),
            const Text(
              'Gagal memuat data',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _DS.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                context.read<ReportBloc>().add(const LoadReportDashboard());
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Muat Ulang'),
            ),
          ],
        ),
      ),
    );
  }
}
