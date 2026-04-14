import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/customBottomNavBar.dart';
import 'package:odlikas_mobilna/services/leaderboard_service.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage>
    with SingleTickerProviderStateMixin {
  final _service = LeaderboardService();
  late TabController _tabController;

  // Hive data
  late final String _schoolId;
  late final String _classId;
  late final String _city;
  late final String _program;
  String? _nickname;

  // Opt-in form
  final _nicknameController = TextEditingController();
  final _countyController = TextEditingController();
  late final TextEditingController _cityController;
  bool _isSubmitting = false;
  String? _optInError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    final box = Hive.box('User');
    _schoolId = box.get('studentSchool', defaultValue: '') as String;
    _classId = box.get('studentGrade', defaultValue: '') as String;
    _city = box.get('studentSchoolCity', defaultValue: '') as String;
    _program = box.get('studentProgram', defaultValue: '') as String;
    _nickname = box.get('leaderboard_nickname') as String?;
    _cityController = TextEditingController(text: _city);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nicknameController.dispose();
    _countyController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _submitOptIn() async {
    final nickname = _nicknameController.text.trim();
    final county = _countyController.text.trim();
    final city = _cityController.text.trim();

    if (nickname.isEmpty || nickname.length > 50) {
      setState(() => _optInError = 'Nadimak mora imati između 1 i 50 znakova');
      return;
    }
    if (county.isEmpty) {
      setState(() => _optInError = 'Unesi županiju');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _optInError = null;
    });

    try {
      await _service.optIn(
        nickname: nickname,
        classId: _classId,
        schoolId: _schoolId,
        city: city,
        county: county,
      );
      await Hive.box('User').put('leaderboard_nickname', nickname);
      if (mounted) setState(() => _nickname = nickname);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 409) {
        setState(() => _optInError = 'Nadimak je već zauzet, probaj drugi');
      } else if (status == 400) {
        final msg = e.response?.data?['message'] as String?;
        setState(() => _optInError =
            msg ?? 'Otvori profil u aplikaciji i pokušaj ponovo');
      } else {
        setState(() => _optInError = 'Greška, pokušaj ponovo');
      }
    } catch (_) {
      setState(() => _optInError = 'Greška, pokušaj ponovo');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _optOut() async {
    try {
      await _service.optOut();
    } catch (_) {}
    await Hive.box('User').delete('leaderboard_nickname');
    if (mounted) setState(() => _nickname = null);
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        surfaceTintColor: AppColors.background,
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Ljestvica',
          style: GoogleFonts.inter(
            fontSize: sw * 0.06,
            fontWeight: FontWeight.w700,
            color: AppColors.secondary,
          ),
        ),
        actions: _nickname != null
            ? [
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'optout') _optOut();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'optout',
                      child: Text('Odjavi se s ljestvice'),
                    ),
                  ],
                ),
              ]
            : null,
      ),
      body: _nickname == null ? _buildOptInForm(sw) : _buildLeaderboard(sw),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildOptInForm(double sw) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(sw * 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pridruži se ljestvici',
            style: GoogleFonts.inter(
              fontSize: sw * 0.065,
              fontWeight: FontWeight.w800,
              color: AppColors.secondary,
            ),
          ),
          SizedBox(height: sw * 0.02),
          Text(
            'Odaberi nadimak i natječi se s učenicima svoje škole i programa.',
            style: GoogleFonts.inter(
              fontSize: sw * 0.038,
              color: AppColors.tertiary,
            ),
          ),
          SizedBox(height: sw * 0.08),
          _buildField('Nadimak', _nicknameController, sw),
          SizedBox(height: sw * 0.04),
          _buildField('Grad', _cityController, sw),
          SizedBox(height: sw * 0.04),
          _buildField('Županija', _countyController, sw),
          SizedBox(height: sw * 0.02),
          Text(
            'Razred i škola se preuzimaju automatski iz tvog profila.',
            style: GoogleFonts.inter(
              fontSize: sw * 0.032,
              color: AppColors.tertiary,
            ),
          ),
          if (_optInError != null) ...[
            SizedBox(height: sw * 0.04),
            Text(
              _optInError!,
              style: GoogleFonts.inter(
                fontSize: sw * 0.035,
                color: AppColors.nedovoljan,
              ),
            ),
          ],
          SizedBox(height: sw * 0.08),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitOptIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: sw * 0.04),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'Pridruži se',
                      style: GoogleFonts.inter(
                        fontSize: sw * 0.045,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
      String label, TextEditingController controller, double sw) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: sw * 0.035,
            fontWeight: FontWeight.w600,
            color: AppColors.secondary,
          ),
        ),
        SizedBox(height: sw * 0.015),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            contentPadding:
                EdgeInsets.symmetric(horizontal: sw * 0.04, vertical: sw * 0.03),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.tertiary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboard(double sw) {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.symmetric(horizontal: sw * 0.04),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.background,
            unselectedLabelColor: AppColors.primary,
            indicator: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
            tabs: const [
              Tab(text: 'Razred'),
              Tab(text: 'Škola'),
              Tab(text: 'Program'),
            ],
          ),
        ),
        SizedBox(height: sw * 0.02),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _LeaderboardTab(
                future: _service.getClassLeaderboard(_schoolId, _classId),
                showClassId: false,
                showCity: false,
                nickname: _nickname!,
              ),
              _LeaderboardTab(
                future: _service.getSchoolLeaderboard(_schoolId),
                showClassId: true,
                showCity: false,
                nickname: _nickname!,
              ),
              _LeaderboardTab(
                future: _service.getProgramLeaderboard(_program),
                showClassId: false,
                showCity: true,
                nickname: _nickname!,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LeaderboardTab extends StatelessWidget {
  final Future<List<LeaderboardEntry>> future;
  final bool showClassId;
  final bool showCity;
  final String nickname;

  const _LeaderboardTab({
    required this.future,
    required this.showClassId,
    required this.showCity,
    required this.nickname,
  });

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;

    return FutureBuilder<List<LeaderboardEntry>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Center(
            child: Lottie.asset(
              'assets/animations/loadingBird.json',
              width: sw * 0.5,
              height: sw * 0.5,
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Greška pri dohvaćanju ljestvice',
              style: GoogleFonts.inter(color: AppColors.tertiary),
            ),
          );
        }

        final entries = snapshot.data ?? [];

        if (entries.isEmpty) {
          return Center(
            child: Text(
              'Još nema sudionika',
              style: GoogleFonts.inter(
                fontSize: sw * 0.045,
                color: AppColors.tertiary,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(
              horizontal: sw * 0.04, vertical: sw * 0.02),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            final isMe = entry.nickname == nickname;
            final rank = index + 1;

            return Container(
              margin: EdgeInsets.only(bottom: sw * 0.025),
              padding: EdgeInsets.symmetric(
                  horizontal: sw * 0.04, vertical: sw * 0.03),
              decoration: BoxDecoration(
                color: isMe
                    ? AppColors.primary.withAlpha(31)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: isMe
                    ? Border.all(color: AppColors.primary, width: 2)
                    : null,
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.08),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Rank
                  SizedBox(
                    width: sw * 0.1,
                    child: Text(
                      _rankLabel(rank),
                      style: GoogleFonts.inter(
                        fontSize: sw * 0.045,
                        fontWeight: FontWeight.w800,
                        color: _rankColor(rank),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(width: sw * 0.03),
                  // Nickname + subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.nickname + (isMe ? ' (ti)' : ''),
                          style: GoogleFonts.inter(
                            fontSize: sw * 0.04,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary,
                          ),
                        ),
                        if (showClassId && entry.classId != null)
                          Text(
                            entry.classId!,
                            style: GoogleFonts.inter(
                              fontSize: sw * 0.032,
                              color: AppColors.tertiary,
                            ),
                          ),
                        if (showCity && entry.city != null)
                          Text(
                            entry.city!,
                            style: GoogleFonts.inter(
                              fontSize: sw * 0.032,
                              color: AppColors.tertiary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Score + streak
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Tooltip(
                        message:
                            'Bodovi = (poboljšanje prosjeka × 60%) + (konzistentnost učenja × 40%)',
                        child: Text(
                          '${entry.combinedScore.toStringAsFixed(1)} bod.',
                          style: GoogleFonts.inter(
                            fontSize: sw * 0.038,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      Text(
                        '🔥 ${entry.currentStreak}d',
                        style: GoogleFonts.inter(
                          fontSize: sw * 0.032,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _rankLabel(int rank) {
    if (rank == 1) return '🥇';
    if (rank == 2) return '🥈';
    if (rank == 3) return '🥉';
    return '#$rank';
  }

  Color _rankColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFF9E9E9E);
    if (rank == 3) return const Color(0xFFCD7F32);
    return AppColors.secondary;
  }
}
