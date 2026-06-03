import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:odlikas_mobilna/constants/constants.dart';
import 'package:odlikas_mobilna/customBottomNavBar.dart';
import 'package:odlikas_mobilna/services/leaderboard_service.dart';
import 'package:odlikas_mobilna/utilities/scoring_info_sheet.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage>
    with SingleTickerProviderStateMixin {
  final _service = LeaderboardService();
  late TabController _tabController;

  late final String _schoolId;
  late final String _classId;
  late final String _city;
  late final String _program;
  String? _nickname;

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
        setState(() =>
            _optInError = msg ?? 'Otvori profil u aplikaciji i pokušaj ponovo');
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
            fontSize: sw * 0.075,
            fontWeight: FontWeight.w700,
            color: AppColors.secondary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => showScoringInfoSheet(context),
            color: AppColors.secondary,
          ),
          if (_nickname != null) ...[
            PopupMenuButton<String>(
              color: Colors.white,
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
          ],
        ],
      ),
      body: _nickname == null ? _buildOptInForm(sw) : _buildLeaderboard(sw),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildLeaderboard(double sw) {
    return Column(
      children: [
        _buildTabBar(sw),
        const SizedBox(height: 8),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _LeaderboardTab(
                fetchData: () => _service.getClassLeaderboard(_schoolId, _classId),
                nickname: _nickname!,
              ),
              _LeaderboardTab(
                fetchData: () => _service.getSchoolLeaderboard(_schoolId),
                nickname: _nickname!,
              ),
              _LeaderboardTab(
                fetchData: () => _service.getProgramLeaderboard(_program),
                nickname: _nickname!,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Custom tab bar: active tab uses the same rgba(20,133,186,0.74) as the podium
  // cards; each inactive tab has its own #1794D2 border pill — exactly as in Figma.
  // AnimatedBuilder keeps it in sync with TabBarView swipes.
  Widget _buildTabBar(double sw) {
    const ref = 430.0;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: sw * 30 / ref),
      child: Container(
        // Taller container so pills have more visual presence
        height: sw * 62 / ref,
        // 4px padding so the outer border is clearly visible around the pills
        padding: const EdgeInsets.all(4),
        child: AnimatedBuilder(
          animation: _tabController,
          builder: (context, _) => Row(
            children: [
              _tabButton(0, 'Razred', sw, ref),
              const SizedBox(width: 4),
              _tabButton(1, 'Škola', sw, ref),
              const SizedBox(width: 4),
              _tabButton(2, 'Program', sw, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabButton(int index, String label, double sw, double ref) {
    final active = _tabController.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _tabController.animateTo(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFF1485BA).withValues(alpha: 0.74)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: active
                ? null
                : Border.all(color: AppColors.primary, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: sw * 14 / ref,
              fontWeight: active ? FontWeight.w700 : FontWeight.w600,
              color: active ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
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
            contentPadding: EdgeInsets.symmetric(
                horizontal: sw * 0.04, vertical: sw * 0.03),
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
}

// ─── Tab widget ────────────────────────────────────────────────────────────────

class _LeaderboardTab extends StatefulWidget {
  final Future<List<LeaderboardEntry>> Function() fetchData;
  final String nickname;

  const _LeaderboardTab({required this.fetchData, required this.nickname});

  @override
  State<_LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends State<_LeaderboardTab> {
  late Future<List<LeaderboardEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.fetchData();
  }

  @override
  void didUpdateWidget(_LeaderboardTab old) {
    super.didUpdateWidget(old);
    if (old.fetchData != widget.fetchData) _future = widget.fetchData();
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;

    return FutureBuilder<List<LeaderboardEntry>>(
      future: _future,
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

        final myIndex =
            entries.indexWhere((e) => e.nickname == widget.nickname);
        final myEntry = myIndex >= 0 ? entries[myIndex] : null;
        final myRank = myIndex >= 0 ? myIndex + 1 : null;

        final maxDelta = entries.fold<double>(
          0.001,
          (m, e) => e.gradeDeltaScore > m ? e.gradeDeltaScore : m,
        );

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => setState(() {
            _future = widget.fetchData();
          }),
          child: ListView(
            padding:
                EdgeInsets.fromLTRB(sw * 0.04, sw * 0.05, sw * 0.04, sw * 0.05),
            children: [
              _buildPodium(entries, sw),
              SizedBox(height: sw * 0.04),
              if (myEntry != null) ...[
                _buildMyRankCard(myEntry, myRank!, maxDelta, sw),
                SizedBox(height: sw * 0.04),
              ],
              ...entries.skip(3).toList().asMap().entries.map(
                    (e) => Padding(
                      padding: EdgeInsets.only(bottom: sw * 0.03),
                      child: _buildListRow(e.value, e.key + 4, sw),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }

  // ── Podium ─────────────────────────────────────────────────────────────────
  //
  // All pixel values derived from the Figma reference (430 px wide screen):
  //   card 124×150 px, gap 13 px, lift 24 px,
  //   badge 30 px, badge extends 7 px outside the card corner.

  static const double _ref = 430;

  Widget _buildPodium(List<LeaderboardEntry> entries, double sw) {
    if (entries.isEmpty) return const SizedBox();

    final first = entries[0];
    final second = entries.length > 1 ? entries[1] : null;
    final third = entries.length > 2 ? entries[2] : null;

    final gap = sw * 13 / _ref;
    final cardHeight = sw * 150 / _ref;
    final lift = sw * 24 / _ref; // 1st card sits higher than 2nd & 3rd
    final badgeSize = sw * 30 / _ref;
    final badgeOverlap =
        sw * 7 / _ref; // badge extends this far outside the card corner

    return LayoutBuilder(builder: (_, constraints) {
      final cw = (constraints.maxWidth - 2 * gap) / 3; // card width

      // Cards have no fixed height — they size to their content.
      // The SizedBox is generous enough to contain the tallest card + lift + badge room.
      // badgeOverlap shifts cards down so the badge above has space within the SizedBox.
      final rowH = badgeOverlap + cardHeight + lift + sw * 0.06;

      return SizedBox(
        height: rowH,
        // clipBehavior.none: the 3rd-card badge extends badgeOverlap beyond the
        // Stack's right edge (into the ListView's right padding); without this it
        // gets clipped.
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Cards (rendered bottom-up in z-order) ──────────────────────
            // 1st place (bottom layer – 2nd card will paint over its edge)
            Positioned(
              left: cw + gap,
              top: badgeOverlap,
              width: cw,
              child: _podiumCardBox(first, sw),
            ),
            // 3rd place
            if (third != null)
              Positioned(
                left: 2 * (cw + gap),
                top: lift + badgeOverlap,
                width: cw,
                child: _podiumCardBox(third, sw),
              ),
            // 2nd place (top layer – its badge is never covered by the 1st card)
            if (second != null)
              Positioned(
                left: 0,
                top: lift + badgeOverlap,
                width: cw,
                child: _podiumCardBox(second, sw),
              ),
            // ── Badges (always on top of all cards) ────────────────────────
            // Badge position: right edge = card right + badgeOverlap,
            //                 top  edge = card top  - badgeOverlap.
            Positioned(
              left: 2 * cw + gap + badgeOverlap - badgeSize,
              top: 0,
              child: _rankBadge(1, badgeSize, sw),
            ),
            if (second != null)
              Positioned(
                left: cw + badgeOverlap - badgeSize,
                top: lift,
                child: _rankBadge(2, badgeSize, sw),
              ),
            if (third != null)
              Positioned(
                left: 3 * cw + 2 * gap + badgeOverlap - badgeSize,
                top: lift,
                child: _rankBadge(3, badgeSize, sw),
              ),
          ],
        ),
      );
    });
  }

  Widget _podiumCardBox(LeaderboardEntry entry, double sw) {
    final deltaStr = entry.gradeDeltaScore >= 0
        ? '+${entry.gradeDeltaScore.toStringAsFixed(1)}%'
        : '${entry.gradeDeltaScore.toStringAsFixed(1)}%';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1485BA).withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.primary, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.25),
            blurRadius: 7.8,
            offset: Offset(2, 2),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: sw * 8 / _ref,
        vertical: sw * 13 / _ref,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: sw * 23 / _ref,
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            child:
                Icon(Icons.person, color: Colors.white, size: sw * 26 / _ref),
          ),
          SizedBox(height: sw * 8 / _ref),
          Text(
            entry.nickname,
            style: GoogleFonts.inter(
              fontSize: sw * 13 / _ref,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: sw * 6 / _ref),
          Text(
            '🔥 ${entry.currentStreak} dana',
            style: GoogleFonts.inter(
              fontSize: sw * 14 / _ref,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            'streak dana zaredom',
            style: GoogleFonts.inter(
              fontSize: sw * 7 / _ref,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: sw * 6 / _ref),
          Text(
            deltaStr,
            style: GoogleFonts.inter(
              fontSize: sw * 14 / _ref,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            'podignut prosjek',
            style: GoogleFonts.inter(
              fontSize: sw * 7 / _ref,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _rankBadge(int rank, double size, double sw) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.accent,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '$rank.',
        style: GoogleFonts.inter(
          fontSize: sw * 15 / _ref,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  // ── "Tvoj Rang" card ───────────────────────────────────────────────────────

  Widget _buildMyRankCard(
      LeaderboardEntry entry, int rank, double maxDelta, double sw) {
    final progress = (entry.gradeDeltaScore / maxDelta).clamp(0.0, 1.0);
    final deltaStr = entry.gradeDeltaScore >= 0
        ? '+${entry.gradeDeltaScore.toStringAsFixed(1)}%'
        : '${entry.gradeDeltaScore.toStringAsFixed(1)}%';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.25),
            blurRadius: 4,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(sw * 0.035),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tvoj Rang: $rank.',
            style: GoogleFonts.inter(
              fontSize: sw * 0.035,
              fontWeight: FontWeight.w700,
              color: AppColors.secondary,
            ),
          ),
          SizedBox(height: sw * 0.025),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              CircleAvatar(
                radius: sw * 0.056,
                backgroundColor: AppColors.tertiary.withValues(alpha: 0.15),
                child: Icon(
                  Icons.person,
                  color: AppColors.tertiary,
                  size: sw * 0.055,
                ),
              ),
              SizedBox(width: sw * 0.02),
              // Col 1: name + subtitle
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.nickname,
                      style: GoogleFonts.inter(
                        fontSize: sw * 0.033,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Dani streaka',
                      style: GoogleFonts.inter(
                        fontSize: sw * 0.026,
                        color: AppColors.tertiary,
                      ),
                    ),
                  ],
                ),
              ),
              _verticalDivider(sw),
              // Col 2: streak days + score
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.currentStreak} dana 🔥',
                      style: GoogleFonts.inter(
                        fontSize: sw * 0.033,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondary,
                      ),
                    ),
                    Text(
                      '${entry.combinedScore.toStringAsFixed(1)} bod.',
                      style: GoogleFonts.inter(
                        fontSize: sw * 0.026,
                        color: AppColors.tertiary,
                      ),
                    ),
                  ],
                ),
              ),
              _verticalDivider(sw),
              // Col 3: grade delta + progress bar
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Podignut prosjek',
                      style: GoogleFonts.inter(
                        fontSize: sw * 0.026,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondary,
                      ),
                    ),
                    Text(
                      deltaStr,
                      style: GoogleFonts.inter(
                        fontSize: sw * 0.026,
                        fontWeight: FontWeight.w600,
                        color: AppColors.tertiary,
                      ),
                    ),
                    SizedBox(height: sw * 0.01),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: const Color(0xFFD9D9D9),
                            color: AppColors.primary,
                            minHeight: sw * 0.032,
                          ),
                        ),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: GoogleFonts.inter(
                            fontSize: sw * 0.02,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
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

  Widget _verticalDivider(double sw) {
    return Container(
      height: sw * 0.1,
      width: 1.5,
      color: AppColors.tertiary.withValues(alpha: 0.3),
      margin: EdgeInsets.symmetric(horizontal: sw * 0.02),
    );
  }

  // ── List row (rank 4+) ─────────────────────────────────────────────────────

  Widget _buildListRow(LeaderboardEntry entry, int rank, double sw) {
    final isMe = entry.nickname == widget.nickname;

    return Container(
      height: sw * 0.13,
      decoration: BoxDecoration(
        color: isMe ? AppColors.primary.withValues(alpha: 0.07) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isMe
              ? AppColors.primary
              : const Color(0xFF1485BA).withValues(alpha: 0.3),
          width: isMe ? 1.5 : 1,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: sw * 0.04),
      child: Row(
        children: [
          // Rank number
          SizedBox(
            width: sw * 0.08,
            child: Text(
              '$rank.',
              style: GoogleFonts.inter(
                fontSize: sw * 0.042,
                fontWeight: FontWeight.w800,
                color: AppColors.secondary,
              ),
            ),
          ),
          SizedBox(width: sw * 0.02),
          // Nickname
          Expanded(
            child: Text(
              entry.nickname + (isMe ? ' (ti)' : ''),
              style: GoogleFonts.inter(
                fontSize: sw * 0.042,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Score + streak
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.combinedScore.toStringAsFixed(1)} bod.',
                style: GoogleFonts.inter(
                  fontSize: sw * 0.028,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              Text(
                '🔥 ${entry.currentStreak}d',
                style: GoogleFonts.inter(
                  fontSize: sw * 0.028,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
