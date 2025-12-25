import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:bm_typer/core/providers/user_provider.dart';
import 'package:bm_typer/core/enums/user_role.dart';
import 'package:bm_typer/core/providers/organization_provider.dart';
import 'package:bm_typer/core/models/organization_model.dart';
import 'package:bm_typer/core/services/csv_export_service.dart';

class OrgAdminDashboardScreen extends ConsumerWidget {
  const OrgAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgAsync = ref.watch(currentOrgProvider);

    return orgAsync.when(
      data: (org) {
        if (org == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business_center, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('কোনো প্রতিষ্ঠান পাওয়া যায়নি', style: GoogleFonts.hindSiliguri(fontSize: 18)),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back),
                    label: Text('ফিরে যান'),
                  ),
                ],
              ),
            ),
          );
        }
        return _OrgDashboard(org: org);
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }
}

class _OrgDashboard extends ConsumerStatefulWidget {
  final OrganizationModel org;
  const _OrgDashboard({required this.org});

  @override
  ConsumerState<_OrgDashboard> createState() => _OrgDashboardState();
}

class _OrgDashboardState extends ConsumerState<_OrgDashboard> {
  int _selectedIndex = 0;
  OrgMemberModel? _selectedMember;
  Map<String, dynamic>? _selectedMemberDetails;
  bool _isLoadingDetails = false;

  final _navItems = const [
    _NavItem(icon: Icons.people_rounded, label: 'সদস্য'),
    _NavItem(icon: Icons.settings_rounded, label: 'সেটিংস'),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
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
          // Logo Header with Org Info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade800],
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
                      child: const Icon(Icons.business_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.org.name,
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
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
                  child: Text(
                    '${widget.org.memberCount}/${widget.org.maxMembers} সদস্য',
                    style: TextStyle(fontSize: 12, color: Colors.white),
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
                    color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: ListTile(
                      leading: Icon(
                        item.icon,
                        color: isSelected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.6),
                      ),
                      title: Text(
                        item.label,
                        style: GoogleFonts.hindSiliguri(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? colorScheme.primary : colorScheme.onSurface,
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

          // Team Dashboard Button (For Owners or Team Leads)
          _buildTeamDashboardButton(context),
          
          const SizedBox(height: 8),

          // Back Button
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/practice'),
                icon: Icon(Icons.arrow_back_rounded),
                label: Text('টাইপিং অ্যাপে ফিরুন', style: GoogleFonts.hindSiliguri()),
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
      selectedIconTheme: IconThemeData(color: colorScheme.primary),
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
          if (_selectedIndex == 0 && widget.org.canAddMembers)
            ElevatedButton.icon(
              onPressed: () => _showAddMemberDialog(context),
              icon: Icon(Icons.person_add, size: 18),
              label: Text('সদস্য যোগ করুন', style: GoogleFonts.hindSiliguri()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                  backgroundColor: colorScheme.primary,
                  backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
                  child: user?.photoUrl == null 
                    ? Text(user?.name[0].toUpperCase() ?? 'U', style: TextStyle(color: Colors.white, fontSize: 14))
                    : null,
                ),
                const SizedBox(width: 8),
                Text(user?.name ?? 'Admin', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.w500)),
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
        return _buildSettingsContent(colorScheme);
      default:
        return const Center(child: Text('Unknown'));
    }
  }

  // ================================================================
  // MEMBERS TAB
  // ================================================================
  Widget _buildMembersContent(ColorScheme colorScheme) {
    final membersAsync = ref.watch(orgMembersProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        if (isMobile && _selectedMember != null) {
          return _buildMemberDetailPanel(colorScheme, isMobile: true);
        }

        return membersAsync.when(
          data: (members) {
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
          error: (err, stack) => Center(child: Text('Error: $err')),
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
            color: isSelected ? colorScheme.primaryContainer.withOpacity(0.5) : colorScheme.surface,
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
    final borderColor = member.isTeamLead ? Colors.orange : colorScheme.primary;
    final bgColor = member.isTeamLead ? Colors.orange.shade100 : colorScheme.primaryContainer;
    final textColor = member.isTeamLead ? Colors.orange : colorScheme.primary;

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
      return _buildEmptyState(colorScheme, 'একজন সদস্য নির্বাচন করুন', Icons.person_search);
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

          // Profile Header Card (Matching Admin Panel)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade100.withOpacity(0.6),
                  Colors.purple.shade50.withOpacity(0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                // Avatar with border
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.primary, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: colorScheme.surface,
                    backgroundImage: displayPhotoUrl != null && displayPhotoUrl!.isNotEmpty
                        ? NetworkImage(displayPhotoUrl)
                        : null,
                    child: displayPhotoUrl == null || displayPhotoUrl!.isEmpty
                        ? Text(member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontSize: 36,
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ))
                        : null,
                  ),
                ),
                const SizedBox(width: 24),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(member.name, style: GoogleFonts.hindSiliguri(fontSize: 28, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 12),
                          if (member.isTeamLead)
                            _buildBadge('টিম লিডার', Colors.orange.shade700, Colors.orange.shade50, Icons.star),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.email_outlined, member.email, colorScheme),
                      _buildInfoRow(Icons.calendar_today_outlined, 'যোগদান: ${DateFormat('dd MMM yyyy').format(member.joinedAt)}', colorScheme),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Chip(
                            avatar: Icon(member.isActive ? Icons.check_circle : Icons.block, size: 16, color: member.isActive ? Colors.green : Colors.red),
                            label: Text(member.isActive ? 'সক্রিয়' : 'ব্লক'),
                            backgroundColor: member.isActive ? Colors.green.shade50 : Colors.red.shade50,
                          ),
                        ],
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

          // Actions Section
          Text('⚡ অ্যাকশন', style: GoogleFonts.hindSiliguri(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: () => _toggleTeamLead(member),
                icon: Icon(member.isTeamLead ? Icons.person_remove : Icons.supervisor_account, size: 18),
                label: Text(member.isTeamLead ? 'টিম লিডার থেকে সরান' : 'টিম লিডার নিযুক্ত করুন', style: GoogleFonts.hindSiliguri()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: member.isTeamLead ? Colors.grey : Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              if (member.isActive)
                OutlinedButton.icon(
                  onPressed: () => _toggleBlock(member),
                  icon: const Icon(Icons.block, size: 18),
                  label: Text('ব্লক করুন', style: GoogleFonts.hindSiliguri()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade600,
                    side: BorderSide(color: Colors.red.shade300),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: () => _toggleBlock(member),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: Text('আনব্লক করুন', style: GoogleFonts.hindSiliguri()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: () => _showRemoveConfirmation(member),
                icon: const Icon(Icons.person_off, size: 18),
                label: Text('সদস্যপদ বাতিল', style: GoogleFonts.hindSiliguri()),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade200),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
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
            child: Icon(icon, size: 22, color: color.withOpacity(1.0)), // Full opacity icon
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

  Widget _buildBadge(String label, Color textColor, Color bgColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.hindSiliguri(fontSize: 12, color: textColor, fontWeight: FontWeight.w600)),
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
  // SETTINGS TAB
  // ================================================================
  Widget _buildSettingsContent(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Org Info Card
          _buildSettingsCard(
            'প্রতিষ্ঠানের তথ্য',
            Icons.business_rounded,
            Colors.blue,
            colorScheme,
            children: [
              _buildSettingsRow('নাম', widget.org.name),
              _buildSettingsRow('অ্যাডমিন ইমেইল', widget.org.adminEmail),
              _buildSettingsRow('তৈরির তারিখ', DateFormat('dd MMM yyyy').format(widget.org.createdAt)),
            ],
          ),

          const SizedBox(height: 24),

          // Subscription Card
          _buildSettingsCard(
            'সাবস্ক্রিপশন',
            Icons.card_membership_rounded,
            Colors.green,
            colorScheme,
            children: [
              _buildSettingsRow('প্ল্যান', OrganizationModel.getSubscriptionName(widget.org.subscriptionType)),
              _buildSettingsRow('সদস্য সীমা', '${widget.org.memberCount} / ${widget.org.maxMembers}'),
              _buildSettingsRow('মেয়াদ', widget.org.expiryDate != null
                  ? DateFormat('dd MMM yyyy').format(widget.org.expiryDate!)
                  : 'আজীবন'),
              _buildSettingsRow('স্ট্যাটাস', widget.org.isValid ? '✅ সক্রিয়' : '❌ মেয়াদোত্তীর্ণ'),
            ],
          ),

          const SizedBox(height: 24),

          // Export Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _exportMembers,
              icon: const Icon(Icons.download_rounded),
              label: Text('সদস্যদের CSV রপ্তানি করুন', style: GoogleFonts.hindSiliguri()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(String title, IconData icon, Color color, ColorScheme colorScheme, {required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Text(title, style: GoogleFonts.hindSiliguri(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingsRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
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

  void _showAddMemberDialog(BuildContext context) {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('সদস্য যোগ করুন', style: GoogleFonts.hindSiliguri()),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(labelText: 'ইমেইল', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('বাতিল')),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) return;
              Navigator.pop(context);
              
              try {
                await ref.read(organizationServiceProvider).addMember(orgId: widget.org.id, email: email);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('সদস্য সফলভাবে যোগ হয়েছে!')));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text('যোগ করুন'),
          ),
        ],
      ),
    );
  }

  void _toggleTeamLead(OrgMemberModel member) async {
    debugPrint('🔄 Toggling team lead for member: ${member.name}, memberId(doc): ${member.id}, userId: ${member.userId}, orgId: ${widget.org.id}');
    
    try {
      final success = await ref.read(organizationServiceProvider).assignTeamLead(
        orgId: widget.org.id,
        memberDocId: member.id, // Use the Document ID
        userId: member.userId,  // Use the User ID
        isTeamLead: !member.isTeamLead,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(member.isTeamLead ? 'টিম লিডার থেকে সরানো হয়েছে' : 'টিম লিডার নিযুক্ত করা হয়েছে'),
              backgroundColor: Colors.green,
            ),
          );
          // Refresh member list
          ref.invalidate(orgMembersProvider);
          setState(() => _selectedMember = null);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('টিম লিডার আপডেট করতে ব্যর্থ হয়েছে'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error toggling team lead: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleBlock(OrgMemberModel member) async {
    final success = await ref.read(organizationServiceProvider).blockMember(
      orgId: widget.org.id,
      memberId: member.userId,
      block: member.isActive,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(member.isActive ? 'সদস্য ব্লক করা হয়েছে' : 'সদস্য আনব্লক করা হয়েছে')),
      );
      setState(() => _selectedMember = null);
    }
  }

  void _showRemoveConfirmation(OrgMemberModel member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('সদস্য সরান?', style: GoogleFonts.hindSiliguri()),
        content: Text('${member.name}-কে এই প্রতিষ্ঠান থেকে সরাতে চান?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('না')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref.read(organizationServiceProvider).removeMember(
                orgId: widget.org.id,
                memberId: member.userId,
              );
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('সদস্য সরানো হয়েছে')));
                setState(() => _selectedMember = null);
              }
            },
            child: const Text('হ্যাঁ, সরান'),
          ),
        ],
      ),
    );
  }

  void _exportMembers() async {
    final members = ref.read(orgMembersProvider).value ?? [];
    if (members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('কোনো সদস্য নেই')));
      return;
    }

    await CsvExportService().exportOrganizationMembersToCSV(widget.org.id, widget.org.name);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV ডাউনলোড হচ্ছে...')));
  }

  Widget _buildTeamDashboardButton(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    
    if (user == null) return const SizedBox.shrink();

    // Show if user is Owner OR has TeamLead role
    final isOwner = widget.org.adminUserId == user.id;
    final isTeamLead = user.role == UserRole.teamLead;

    if (isOwner || isTeamLead) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/team_lead'),
            icon: const Icon(Icons.groups_rounded),
            label: Text('টিম ড্যাশবোর্ড', style: GoogleFonts.hindSiliguri()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}
