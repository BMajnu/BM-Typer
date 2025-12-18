import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bm_typer/core/providers/user_provider.dart';
import 'package:bm_typer/core/services/admin_auth_service.dart';
import 'package:bm_typer/core/models/admin_user_model.dart';
import 'package:bm_typer/presentation/screens/admin/admin_user_management_screen.dart';
import 'package:bm_typer/presentation/screens/admin/admin_analytics_screen.dart';
import 'package:bm_typer/presentation/screens/admin/admin_content_screen.dart';
import 'package:bm_typer/presentation/screens/admin/admin_settings_screen.dart';
import 'package:bm_typer/presentation/screens/admin/admin_notifications_screen.dart';
import 'package:bm_typer/presentation/screens/admin/admin_login_screen.dart';
import 'package:bm_typer/presentation/screens/admin/admin_subscription_screen.dart';
import 'package:bm_typer/presentation/screens/admin/admin_organization_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin Dashboard - Main screen for admin panel
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _selectedIndex = 0;
  
  /// Get nav items based on admin role
  List<_NavItem> _getNavItems(AdminRole? role) {
    final allItems = [
      _NavItem(icon: Icons.dashboard_rounded, label: 'ড্যাশবোর্ড', permission: AdminPermission.viewDashboard),
      _NavItem(icon: Icons.people_rounded, label: 'ইউজার', permission: AdminPermission.viewUsers),
      _NavItem(icon: Icons.analytics_rounded, label: 'অ্যানালিটিক্স', permission: AdminPermission.viewAnalytics),
      _NavItem(icon: Icons.article_rounded, label: 'কন্টেন্ট', permission: AdminPermission.viewAppConfig),
      _NavItem(icon: Icons.card_membership_rounded, label: 'সাবস্ক্রিপশন', permission: AdminPermission.viewSubscriptions),
      _NavItem(icon: Icons.business_rounded, label: 'প্রতিষ্ঠান', permission: AdminPermission.viewOrganizations),
      _NavItem(icon: Icons.notifications_rounded, label: 'নোটিফিকেশন', permission: AdminPermission.viewNotifications),
      _NavItem(icon: Icons.settings_rounded, label: 'সেটিংস', permission: AdminPermission.viewSettings),
      // Developer Tools (hidden for non-developers)
      _NavItem(icon: Icons.developer_mode_rounded, label: 'ডেভ টুলস', permission: AdminPermission.accessDevTools),
    ];
    
    if (role == null) return allItems.take(8).toList(); // Default: all except dev tools
    
    return allItems.where((item) => role.canAccess(item.permission)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final adminSession = ref.watch(adminSessionProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width > 800;
    
    // Check if user is admin
    // Add admin emails here
    const adminEmails = [
      'badiuzzamanmajnu786@gmail.com',
      // Add more admin emails as needed
    ];
    
    // Strict admin check
    final isAdmin = adminEmails.contains(user?.email?.toLowerCase());

    if (!isAdmin) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_rounded, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                'অ্যাক্সেস অননুমোদিত',
                style: GoogleFonts.hindSiliguri(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'এই পেজ শুধুমাত্র অ্যাডমিনদের জন্য',
                style: GoogleFonts.hindSiliguri(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('ফিরে যান'),
              ),
            ],
          ),
        ),
      );
    }

    // Check admin session - require PIN if not authenticated
    if (!adminSession.isSessionValid) {
      return AdminLoginScreen(
        onSuccess: () {
          // Load admin user after successful login
          if (user?.email != null) {
            ref.read(adminSessionProvider.notifier).setAdminUser(user!.email!);
          }
          // Force rebuild to show dashboard
          setState(() {});
        },
      );
    }
    
    // Get nav items based on role
    final navItems = _getNavItems(adminSession.role);

    return Scaffold(
      body: Row(
        children: [
          // Navigation Rail / Drawer
          if (isWide)
            _buildNavigationRail(colorScheme, navItems)
          else
            _buildMiniRail(colorScheme, navItems),
          
          // Divider
          VerticalDivider(thickness: 1, width: 1, color: colorScheme.outline.withOpacity(0.2)),
          
          // Main Content
          Expanded(
            child: Column(
              children: [
                _buildAppBar(colorScheme, user?.name ?? 'Admin', navItems),
                Expanded(
                  child: _buildContent(navItems),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNavigationRail(ColorScheme colorScheme, List<_NavItem> navItems) {
    return Container(
      width: 240,
      color: colorScheme.surface,
      child: Column(
        children: [
          // Logo Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade700],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                Text(
                  'BM Typer',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Navigation Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              itemCount: navItems.length,
              itemBuilder: (context, index) {
                final item = navItems[index];
                final isSelected = index == _selectedIndex;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
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
                    selected: isSelected,
                    selectedTileColor: colorScheme.primaryContainer.withOpacity(0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onTap: () => setState(() => _selectedIndex = index),
                  ),
                );
              },
            ),
          ),
          
          // Logout Button
          Padding(
            padding: const EdgeInsets.all(12),
            child: ListTile(
              leading: Icon(Icons.logout_rounded, color: Colors.red.shade400),
              title: Text('লগআউট', style: GoogleFonts.hindSiliguri(color: Colors.red.shade400)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: () => Navigator.pushReplacementNamed(context, '/login'),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMiniRail(ColorScheme colorScheme, List<_NavItem> navItems) {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      labelType: NavigationRailLabelType.all,
      backgroundColor: colorScheme.surface,
      selectedIconTheme: IconThemeData(color: colorScheme.primary),
      selectedLabelTextStyle: GoogleFonts.hindSiliguri(
        color: colorScheme.primary,
        fontWeight: FontWeight.bold,
        fontSize: 11,
      ),
      unselectedLabelTextStyle: GoogleFonts.hindSiliguri(fontSize: 10),
      destinations: navItems.map((item) => NavigationRailDestination(
        icon: Icon(item.icon),
        label: Text(item.label),
      )).toList(),
    );
  }
  
  Widget _buildAppBar(ColorScheme colorScheme, String userName, List<_NavItem> navItems) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(bottom: BorderSide(color: colorScheme.outline.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          Text(
            _selectedIndex < navItems.length ? navItems[_selectedIndex].label : 'ড্যাশবোর্ড',
            style: GoogleFonts.hindSiliguri(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          
          // Search (optional)
          Container(
            width: 250,
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.search, size: 20, color: colorScheme.onSurface.withOpacity(0.5)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'সার্চ করুন...',
                      hintStyle: GoogleFonts.hindSiliguri(fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Notifications
          IconButton(
            icon: Badge(
              smallSize: 8,
              child: Icon(Icons.notifications_outlined, color: colorScheme.onSurface),
            ),
            onPressed: () {},
          ),
          
          const SizedBox(width: 8),
          
          // User Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: colorScheme.primaryContainer,
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContent(List<_NavItem> navItems) {
    if (_selectedIndex >= navItems.length) return _buildDashboardHome();
    
    final permission = navItems[_selectedIndex].permission;
    
    switch (permission) {
      case AdminPermission.viewDashboard:
        return _buildDashboardHome();
      case AdminPermission.viewUsers:
        return const AdminUserManagementScreen();
      case AdminPermission.viewAnalytics:
        return const AdminAnalyticsScreen();
      case AdminPermission.viewAppConfig:
        return const AdminContentScreen();
      case AdminPermission.viewSubscriptions:
        return const AdminSubscriptionScreen();
      case AdminPermission.viewOrganizations:
        return const AdminOrganizationScreen();
      case AdminPermission.viewNotifications:
        return const AdminNotificationsScreen();
      case AdminPermission.viewSettings:
        return const AdminSettingsScreen();
      case AdminPermission.accessDevTools:
        return _buildDevToolsScreen();
      default:
        return _buildDashboardHome();
    }
  }
  
  Widget _buildDevToolsScreen() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.developer_mode_rounded, size: 64, color: colorScheme.primary),
          const SizedBox(height: 16),
          Text('ডেভেলপার টুলস', style: GoogleFonts.hindSiliguri(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('এই ফিচার শীঘ্রই আসছে...', style: GoogleFonts.hindSiliguri(color: Colors.grey)),
        ],
      ),
    );
  }
  
  Widget _buildDashboardHome() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Banner
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade700],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'স্বাগতম, অ্যাডমিন! 👋',
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'আজকের সব কিছু এখানে দেখুন',
                        style: GoogleFonts.hindSiliguri(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.dashboard_customize_rounded, size: 64, color: Colors.white.withOpacity(0.3)),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Stats Cards
          Text(
            'সারসংক্ষেপ',
            style: GoogleFonts.hindSiliguri(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              final cardWidth = isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2;
              
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  final totalUsers = snapshot.data?.docs.length ?? 0;
                  final premiumUsers = snapshot.data?.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>?;
                    return data?['isPremium'] == true;
                  }).length ?? 0;
                  
                  // Count today's new users
                  final today = DateTime.now();
                  final todayStart = DateTime(today.year, today.month, today.day);
                  final newUsersToday = snapshot.data?.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>?;
                    final lastSynced = data?['lastSynced'];
                    if (lastSynced == null) return false;
                    final date = (lastSynced as Timestamp).toDate();
                    return date.isAfter(todayStart);
                  }).length ?? 0;
                  
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildStatCard(
                        icon: Icons.people_rounded,
                        label: 'মোট ইউজার',
                        value: '$totalUsers',
                        trend: '',
                        trendUp: true,
                        color: Colors.blue,
                        width: cardWidth,
                      ),
                      _buildStatCard(
                        icon: Icons.person_add_rounded,
                        label: 'নতুন ইউজার (আজ)',
                        value: '$newUsersToday',
                        trend: '',
                        trendUp: newUsersToday > 0,
                        color: Colors.green,
                        width: cardWidth,
                      ),
                      _buildStatCard(
                        icon: Icons.star_rounded,
                        label: 'প্রিমিয়াম ইউজার',
                        value: '$premiumUsers',
                        trend: '',
                        trendUp: premiumUsers > 0,
                        color: Colors.purple,
                        width: cardWidth,
                      ),
                      _buildStatCard(
                        icon: Icons.notifications_rounded,
                        label: 'নোটিফিকেশন',
                        value: '-',
                        trend: '',
                        trendUp: true,
                        color: Colors.orange,
                        width: cardWidth,
                      ),
                    ],
                  );
                },
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // Quick Actions
          Text(
            'দ্রুত কার্যক্রম',
            style: GoogleFonts.hindSiliguri(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildQuickAction(
                icon: Icons.person_add,
                label: 'নতুন ইউজার',
                color: Colors.blue,
                onTap: () => setState(() => _selectedIndex = 1),
              ),
              _buildQuickAction(
                icon: Icons.article_rounded,
                label: 'নতুন লেসন',
                color: Colors.green,
                onTap: () => setState(() => _selectedIndex = 3),
              ),
              _buildQuickAction(
                icon: Icons.notifications_active,
                label: 'নোটিফিকেশন পাঠান',
                color: Colors.orange,
                onTap: () => setState(() => _selectedIndex = 4),
              ),
              _buildQuickAction(
                icon: Icons.analytics,
                label: 'রিপোর্ট দেখুন',
                color: Colors.purple,
                onTap: () => setState(() => _selectedIndex = 2),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Recent Activity
          Text(
            'সাম্প্রতিক কার্যক্রম',
            style: GoogleFonts.hindSiliguri(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text('কোনো কার্যক্রম নেই', style: GoogleFonts.hindSiliguri(color: Colors.grey)),
                    ),
                  );
                }
                
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: colorScheme.outline.withOpacity(0.1)),
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final profile = data['profile'] as Map<String, dynamic>? ?? {};
                    final name = profile['name'] ?? data['name'] ?? 'Unknown User';
                    final email = profile['email'] ?? data['email'] ?? '';
                    final lastSynced = data['lastSynced'] != null
                        ? (data['lastSynced'] as Timestamp).toDate()
                        : DateTime.now();
                    
                    final photoUrl = profile['photoUrl'] as String?;
                    
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) 
                            ? NetworkImage(photoUrl) 
                            : null,
                        backgroundColor: Colors.green.withOpacity(0.15),
                        child: (photoUrl == null || photoUrl.isEmpty)
                            ? Text(
                                name.toString().isNotEmpty ? name.toString()[0].toUpperCase() : 'U',
                                style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      title: Text('ইউজার: $name', style: GoogleFonts.hindSiliguri(fontSize: 14)),
                      subtitle: Text(email, style: TextStyle(fontSize: 11, color: Colors.grey)),
                      trailing: Text(_formatTimeAgo(lastSynced), style: TextStyle(color: Colors.grey, fontSize: 12)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String trend,
    required bool trendUp,
    required Color color,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (trendUp ? Colors.green : Colors.red).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      trendUp ? Icons.trending_up : Icons.trending_down,
                      size: 14,
                      color: trendUp ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trend,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: trendUp ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.hindSiliguri(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.hindSiliguri(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    
    if (diff.inMinutes < 1) {
      return 'এইমাত্র';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} মিনিট আগে';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} ঘন্টা আগে';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} দিন আগে';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final AdminPermission permission;
  
  _NavItem({required this.icon, required this.label, required this.permission});
}
