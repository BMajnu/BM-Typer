import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:bm_typer/core/providers/user_provider.dart';
import 'package:bm_typer/core/providers/organization_provider.dart';
import 'package:bm_typer/core/models/organization_model.dart';

class TeamLeadDashboardScreen extends ConsumerStatefulWidget {
  const TeamLeadDashboardScreen({super.key});

  @override
  ConsumerState<TeamLeadDashboardScreen> createState() => _TeamLeadDashboardScreenState();
}

class _TeamLeadDashboardScreenState extends ConsumerState<TeamLeadDashboardScreen> {
  int _selectedIndex = 0;
  OrgMemberModel? _selectedMember;
  Map<String, dynamic>? _selectedMemberDetails;
  bool _isLoadingDetails = false;

  final _navItems = const [
    _NavItem(icon: Icons.people_rounded, label: 'সদস্যরা'),
    _NavItem(icon: Icons.analytics_rounded, label: 'টিম সামারি'),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      body: Row(
        children: [
          if (isWide)
            _buildSidebar(colorScheme)
          else
            _buildMiniRail(colorScheme),

          VerticalDivider(thickness: 1, width: 1, color: colorScheme.outline.withOpacity(0.2)),

          Expanded(
            child: Column(
              children: [
                _buildAppBar(colorScheme),
                Expanded(child: _buildContent(colorScheme)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(ColorScheme colorScheme) {
    return Container(
      width: 260,
      color: colorScheme.surface,
      child: Column(
        children: [
          // Header with Gradient
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade500, Colors.orange.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.groups_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'টিম ড্যাশবোর্ড',
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.visibility, size: 14, color: Colors.white),
                      SizedBox(width: 6),
                      Text('শুধুমাত্র দেখুন', style: TextStyle(fontSize: 12, color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Navigation Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = index == _selectedIndex;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Material(
                    color: isSelected ? Colors.orange.shade100 : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: ListTile(
                      leading: Icon(
                        item.icon,
                        color: isSelected ? Colors.orange.shade900 : colorScheme.onSurface.withOpacity(0.6),
                      ),
                      title: Text(
                        item.label,
                        style: GoogleFonts.hindSiliguri(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.orange.shade900 : colorScheme.onSurface,
                        ),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onTap: () => setState(() => _selectedIndex = index),
                    ),
                  ),
                );
              },
            ),
          ),

          // Practice Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/practice'),
                icon: Icon(Icons.keyboard),
                label: Text('প্র্যাকটিস করুন', style: GoogleFonts.hindSiliguri()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Org Admin Dashboard Button (Only for Owners)
          _buildOrgAdminButton(context),
          
          const SizedBox(height: 8),

          // Back Button
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back_rounded),
                label: Text('ফিরে যান', style: GoogleFonts.hindSiliguri()),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniRail(ColorScheme colorScheme) {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      labelType: NavigationRailLabelType.all,
      backgroundColor: colorScheme.surface,
      selectedIconTheme: IconThemeData(color: Colors.orange.shade900),
      destinations: _navItems.map((item) => NavigationRailDestination(
        icon: Icon(item.icon),
        label: Text(item.label, style: GoogleFonts.hindSiliguri(fontSize: 10)),
      )).toList(),
    );
  }

  Widget _buildAppBar(ColorScheme colorScheme) {
    final user = ref.watch(currentUserProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(bottom: BorderSide(color: colorScheme.outline.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Text(
            _navItems[_selectedIndex].label,
            style: GoogleFonts.hindSiliguri(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          // Read-Only Badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.visibility, size: 16, color: Colors.blue),
                SizedBox(width: 6),
                Text('শুধুমাত্র দেখুন', style: TextStyle(fontSize: 12, color: Colors.blue)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // User Info
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.orange,
                  backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
                  child: user?.photoUrl == null 
                    ? Text(user?.name[0].toUpperCase() ?? 'U', style: TextStyle(color: Colors.white, fontSize: 14))
                    : null,
                ),
                const SizedBox(width: 8),
                Text(user?.name ?? 'Team Lead', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ColorScheme colorScheme) {
    switch (_selectedIndex) {
      case 0:
        return _buildMembersContent(colorScheme);
      case 1:
        return _buildSummaryContent(colorScheme);
      default:
        return const Center(child: Text('Unknown'));
    }
  }

  // ================================================================
  // MEMBERS TAB (Read-Only)
  // ================================================================
  Widget _buildMembersContent(ColorScheme colorScheme) {
    // Show only my team members
    final membersAsync = ref.watch(teamMembersProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        if (isMobile && _selectedMember != null) {
          return _buildMemberDetailPanel(colorScheme, isMobile: true);
        }

        return membersAsync.when(
          data: (members) {
            print('🔍 TeamLeadDashboard: Got ${members.length} members');
            if (members.isEmpty) {
              return _buildEmptyState(colorScheme, 'কোনো সদস্য পাওয়া যায়নি', Icons.people_outline);
            }

            if (isMobile) {
              return _buildMembersList(members, colorScheme);
            }

            return Row(
              children: [
                Expanded(flex: 35, child: _buildMembersList(members, colorScheme)),
                VerticalDivider(width: 1, thickness: 1, color: colorScheme.outline.withOpacity(0.2)),
                Expanded(flex: 65, child: _buildMemberDetailPanel(colorScheme)),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
        );
      },
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: colorScheme.primary.withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          Text(message, style: GoogleFonts.hindSiliguri(fontSize: 18, color: colorScheme.onSurface.withOpacity(0.7))),
        ],
      ),
    );
  }

  Widget _buildMembersList(List<OrgMemberModel> members, ColorScheme colorScheme) {
    return ListView.builder(
      padding: EdgeInsets.all(12),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        final isSelected = _selectedMember?.userId == member.userId;

        return Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Material(
            color: isSelected ? Colors.orange.shade50 : colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            elevation: isSelected ? 2 : 0,
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: _buildMemberAvatar(member, colorScheme),
              title: Row(
                children: [
                  Expanded(
                    child: Text(member.name, style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.w600)),
                  ),
                  if (member.isTeamLead)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 12, color: Colors.orange.shade700),
                          SizedBox(width: 4),
                          Text('টিম লিড', style: TextStyle(fontSize: 10, color: Colors.orange.shade700)),
                        ],
                      ),
                    ),
                ],
              ),
              subtitle: Text(member.email, style: TextStyle(fontSize: 12, color: colorScheme.outline)),
              trailing: member.isActive
                  ? Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                      child: Icon(Icons.check, size: 14, color: Colors.green),
                    )
                  : Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                      child: Icon(Icons.block, size: 14, color: Colors.red),
                    ),
              onTap: () => _selectMember(member),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMemberAvatar(OrgMemberModel member, ColorScheme colorScheme) {
    // Team Lead specific styling
    final borderColor = Colors.orange;
    final bgColor = Colors.orange.shade100;
    final textColor = Colors.orange.shade800;

    Widget buildCircle(String? url) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 2),
        ),
        child: CircleAvatar(
          radius: 22,
          backgroundColor: bgColor,
          backgroundImage: url != null && url.isNotEmpty ? NetworkImage(url) : null,
          child: url == null || url.isEmpty
              ? Text(
                  member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                )
              : null,
        ),
      );
    }

    if (member.photoUrl != null && member.photoUrl!.isNotEmpty) {
      return buildCircle(member.photoUrl);
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: ref.read(organizationServiceProvider).getMemberDetails(member.userId),
      builder: (context, snapshot) {
        String? fetchedUrl;
        if (snapshot.hasData && snapshot.data != null) {
          fetchedUrl = snapshot.data!['profile']?['photoUrl'] ?? snapshot.data!['photoUrl'];
        }
        return buildCircle(fetchedUrl);
      },
    );
  }

  Widget _buildMemberDetailPanel(ColorScheme colorScheme, {bool isMobile = false}) {
    if (_selectedMember == null) {
      return _buildEmptyState(colorScheme, 'পারফরম্যান্স দেখতে একজন সদস্য নির্বাচন করুন', Icons.person_search);
    }

    final member = _selectedMember!;
    
    // Attempt to get fresh photo URL if details are loaded
    String? displayPhotoUrl = member.photoUrl;
    if (_selectedMemberDetails != null) {
      final profile = _selectedMemberDetails!['profile'] as Map<String, dynamic>?;
      if (profile != null && profile['photoUrl'] != null) {
        displayPhotoUrl = profile['photoUrl'];
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextButton.icon(
                onPressed: () => setState(() => _selectedMember = null),
                icon: const Icon(Icons.arrow_back),
                label: const Text('ফিরে যান'),
              ),
            ),

          // Profile Header Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange.shade100.withOpacity(0.8),
                  Colors.orange.shade50.withOpacity(0.4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                // Avatar with border
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.orange, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.white,
                    backgroundImage: displayPhotoUrl != null && displayPhotoUrl!.isNotEmpty
                        ? NetworkImage(displayPhotoUrl)
                        : null,
                    child: displayPhotoUrl == null || displayPhotoUrl!.isEmpty
                        ? Text(member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                            style: TextStyle(fontSize: 36, color: Colors.orange, fontWeight: FontWeight.bold))
                        : null,
                  ),
                ),
                const SizedBox(width: 24),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(member.name, style: GoogleFonts.hindSiliguri(fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.email_outlined, member.email, colorScheme),
                      _buildInfoRow(Icons.calendar_today_outlined, 'যোগদান: ${DateFormat('dd MMM yyyy').format(member.joinedAt)}', colorScheme),
                      const SizedBox(height: 12),
                      Chip(
                        avatar: Icon(member.isActive ? Icons.check_circle : Icons.block, size: 16, color: member.isActive ? Colors.green : Colors.red),
                        label: Text(member.isActive ? 'সক্রিয়' : 'নিষ্ক্রিয়'),
                        backgroundColor: member.isActive ? Colors.green.shade50 : Colors.red.shade50,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Stats Section
          Text('📊 পারফরম্যান্স', style: GoogleFonts.hindSiliguri(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          if (_isLoadingDetails)
            const Center(child: CircularProgressIndicator())
          else if (_selectedMemberDetails != null)
            _buildStatsGrid(_selectedMemberDetails!, colorScheme)
          else
            Text('স্ট্যাটস লোড হচ্ছে...', style: TextStyle(color: colorScheme.outline)),

          const SizedBox(height: 32),

          // Info Box
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'টিম লিডার হিসেবে আপনি শুধুমাত্র সদস্যদের পারফরম্যান্স দেখতে পারবেন।',
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> details, ColorScheme colorScheme) {
    final profile = details['profile'] as Map<String, dynamic>? ?? {};
    final stats = profile['stats'] as Map<String, dynamic>? ?? {};

    final highestWpm = stats['highestWpm'] ?? profile['highestWpm'] ?? 0;
    final avgAccuracy = stats['averageAccuracy'] ?? 0;
    final xpPoints = profile['xpPoints'] ?? 0;
    final level = profile['level'] ?? 1;
    final totalSessions = stats['totalSessions'] ?? 0;
    final streakCount = profile['streakCount'] ?? 0;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildStatCard('সর্বোচ্চ WPM', '$highestWpm', Icons.speed_rounded, Colors.blue, colorScheme),
        _buildStatCard('নির্ভুলতা', '${avgAccuracy is num ? avgAccuracy.toStringAsFixed(1) : avgAccuracy}%', Icons.check_circle_outline, Colors.green, colorScheme),
        _buildStatCard('XP পয়েন্ট', '$xpPoints', Icons.star_rounded, Colors.amber, colorScheme),
        _buildStatCard('লেভেল', '$level', Icons.trending_up_rounded, Colors.purple, colorScheme),
        _buildStatCard('স্ট্রিক', '$streakCount দিন', Icons.local_fire_department_rounded, Colors.orange, colorScheme),
        _buildStatCard('মোট সেশন', '$totalSessions', Icons.history_rounded, Colors.teal, colorScheme),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, ColorScheme colorScheme) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.25), color.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: color.withOpacity(1.0)),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            label,
            style: GoogleFonts.hindSiliguri(fontSize: 13, color: color.withOpacity(0.9), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colorScheme.onSurface.withOpacity(0.6)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withOpacity(0.8)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // SUMMARY TAB
  // ================================================================
  Widget _buildSummaryContent(ColorScheme colorScheme) {
    final membersAsync = ref.watch(orgMembersProvider);

    return membersAsync.when(
      data: (members) {
        final activeCount = members.where((m) => m.isActive).length;
        final inactiveCount = members.length - activeCount;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📊 টিম ওভারভিউ', style: GoogleFonts.hindSiliguri(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // Summary Cards
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildSummaryCard('মোট সদস্য', '${members.length}', Icons.people_rounded, Colors.blue, colorScheme),
                  _buildSummaryCard('সক্রিয়', '$activeCount', Icons.check_circle_rounded, Colors.green, colorScheme),
                  _buildSummaryCard('নিষ্ক্রিয়', '$inactiveCount', Icons.remove_circle_rounded, Colors.red, colorScheme),
                ],
              ),

              const SizedBox(height: 32),

              // Info Box
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade50, Colors.orange.shade100.withOpacity(0.5)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.lightbulb_outline, size: 48, color: Colors.orange),
                    SizedBox(height: 16),
                    Text(
                      'স্বতন্ত্র সদস্যদের পারফরম্যান্স দেখতে "সদস্যরা" ট্যাবে গিয়ে একজনকে নির্বাচন করুন।',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.hindSiliguri(fontSize: 16, color: Colors.orange.shade800),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color, ColorScheme colorScheme) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            label,
            style: GoogleFonts.hindSiliguri(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // ACTIONS
  // ================================================================
  void _selectMember(OrgMemberModel member) async {
    setState(() {
      _selectedMember = member;
      _isLoadingDetails = true;
    });

    final details = await ref.read(organizationServiceProvider).getMemberDetails(member.userId);
    
    setState(() {
      _selectedMemberDetails = details;
      _isLoadingDetails = false;
    });
  }

  Widget _buildOrgAdminButton(BuildContext context) {
    final orgAsync = ref.watch(currentOrgProvider);
    final user = ref.watch(currentUserProvider);
    
    return orgAsync.when(
      data: (org) {
        if (org == null || user == null) return const SizedBox.shrink();
        
        // Check if user is the owner
        if (org.adminUserId == user.id) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/org_admin'),
                icon: const Icon(Icons.admin_panel_settings_rounded),
                label: Text('অর্গানাইজেশন ড্যাশবোর্ড', style: GoogleFonts.hindSiliguri()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}
