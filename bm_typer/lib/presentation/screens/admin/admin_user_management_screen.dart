import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin User Management Screen - Professional Master-Detail Layout
class AdminUserManagementScreen extends ConsumerStatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  ConsumerState<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends ConsumerState<AdminUserManagementScreen> {
  String _searchQuery = '';
  String _filterStatus = 'all';
  String? _selectedUserId;
  Map<String, dynamic>? _selectedUserData;
  bool _isLoadingDetails = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Row(
      children: [
        // Left Panel - User List (35%)
        Expanded(
          flex: 35,
          child: _buildUserListPanel(colorScheme),
        ),
        
        // Divider
        VerticalDivider(width: 1, thickness: 1, color: colorScheme.outline.withOpacity(0.2)),
        
        // Right Panel - User Details (65%)
        Expanded(
          flex: 65,
          child: _buildUserDetailsPanel(colorScheme),
        ),
      ],
    );
  }

  /// Left Panel - User List with Search & Filter
  Widget _buildUserListPanel(ColorScheme colorScheme) {
    return Column(
      children: [
        // Header with search
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(bottom: BorderSide(color: colorScheme.outline.withOpacity(0.1))),
          ),
          child: Column(
            children: [
              // Search Bar
              TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'ইউজার খুঁজুন...',
                  hintStyle: GoogleFonts.hindSiliguri(fontSize: 13),
                  prefixIcon: Icon(Icons.search, size: 20, color: colorScheme.onSurface.withOpacity(0.5)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              
              // Filter Row
              Row(
                children: [
                  Expanded(
                    child: _buildFilterChip('সব', 'all', colorScheme),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFilterChip('অ্যাক্টিভ', 'active', colorScheme),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFilterChip('প্রিমিয়াম', 'premium', colorScheme),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFilterChip('ব্যান', 'banned', colorScheme),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // User List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .limit(100)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                debugPrint('❌ Error loading users: ${snapshot.error}');
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                      const SizedBox(height: 12),
                      Text('ইউজার লোড করতে ত্রুটি', style: GoogleFonts.hindSiliguri(color: Colors.red)),
                      const SizedBox(height: 8),
                      Text('${snapshot.error}', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                );
              }
              
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text('কোনো ইউজার নেই', style: GoogleFonts.hindSiliguri(color: Colors.grey)),
                    ],
                  ),
                );
              }
              
              // Filter users
              final filteredUsers = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final profile = data['profile'] as Map<String, dynamic>?;
                
                final name = (data['name'] ?? profile?['name'] ?? '').toString().toLowerCase();
                final email = (data['email'] ?? profile?['email'] ?? '').toString().toLowerCase();
                final userId = (data['userId'] ?? profile?['customUserId'] ?? doc.id).toString().toLowerCase();
                final isBanned = data['isBanned'] ?? false;
                final isPremium = data['isPremium'] ?? false;
                
                // Search filter
                final matchesSearch = _searchQuery.isEmpty ||
                    name.contains(_searchQuery.toLowerCase()) ||
                    email.contains(_searchQuery.toLowerCase()) ||
                    userId.contains(_searchQuery.toLowerCase());
                
                // Status filter
                bool matchesFilter = true;
                if (_filterStatus == 'banned') matchesFilter = isBanned;
                if (_filterStatus == 'premium') matchesFilter = isPremium;
                if (_filterStatus == 'active') matchesFilter = !isBanned;
                
                return matchesSearch && matchesFilter;
              }).toList();
              
              if (filteredUsers.isEmpty) {
                return Center(
                  child: Text('কোনো ফলাফল নেই', style: GoogleFonts.hindSiliguri(color: Colors.grey)),
                );
              }
              
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final doc = filteredUsers[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildUserCard(doc.id, data, colorScheme);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, ColorScheme colorScheme) {
    final isSelected = _filterStatus == value;
    return InkWell(
      onTap: () => setState(() => _filterStatus = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.hindSiliguri(
              fontSize: 11,
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(String docId, Map<String, dynamic> data, ColorScheme colorScheme) {
    final profile = data['profile'] as Map<String, dynamic>?;
    
    final name = data['name'] ?? profile?['name'] ?? '';
    final email = data['email'] ?? profile?['email'] ?? '';
    final photoUrl = data['photoUrl'] ?? profile?['photoUrl'];
    final isBanned = data['isBanned'] ?? false;
    final isPremium = data['isPremium'] ?? false;
    
    final displayName = name.toString().isNotEmpty ? name : (email.toString().isNotEmpty ? email : 'Unknown User');
    final isSelected = _selectedUserId == docId;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: isSelected ? colorScheme.primaryContainer.withOpacity(0.5) : colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _selectUser(docId),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? colorScheme.primary : colorScheme.outline.withOpacity(0.1),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 22,
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                  backgroundColor: colorScheme.primaryContainer,
                  child: photoUrl == null
                      ? Text(
                          displayName.toString().isNotEmpty ? displayName[0].toUpperCase() : 'U',
                          style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              style: GoogleFonts.hindSiliguri(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isPremium)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.star, size: 12, color: Colors.amber.shade700),
                            ),
                          if (isBanned)
                            Container(
                              margin: const EdgeInsets.only(left: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.block, size: 12, color: Colors.red.shade700),
                            ),
                        ],
                      ),
                      if (name.toString().isNotEmpty && email.toString().isNotEmpty)
                        Text(
                          email,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                
                // Arrow
                Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _selectUser(String docId) async {
    setState(() {
      _selectedUserId = docId;
      _isLoadingDetails = true;
    });
    
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(docId).get();
      if (doc.exists && mounted) {
        setState(() {
          _selectedUserData = doc.data();
          _isLoadingDetails = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDetails = false);
      }
    }
  }

  /// Right Panel - User Details
  Widget _buildUserDetailsPanel(ColorScheme colorScheme) {
    if (_selectedUserId == null) {
      return _buildEmptyDetailsState(colorScheme);
    }
    
    if (_isLoadingDetails) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_selectedUserData == null) {
      return _buildEmptyDetailsState(colorScheme);
    }
    
    return _buildUserDetails(colorScheme);
  }

  Widget _buildEmptyDetailsState(ColorScheme colorScheme) {
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
            child: Icon(
              Icons.person_search_rounded,
              size: 64,
              color: colorScheme.primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'ইউজার সিলেক্ট করুন',
            style: GoogleFonts.hindSiliguri(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'বাম দিক থেকে একজন ইউজার সিলেক্ট করলে\nতার বিস্তারিত তথ্য এখানে দেখা যাবে',
            textAlign: TextAlign.center,
            style: GoogleFonts.hindSiliguri(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserDetails(ColorScheme colorScheme) {
    final data = _selectedUserData!;
    final profile = data['profile'] as Map<String, dynamic>?;
    final stats = data['stats'] as Map<String, dynamic>?;
    final progress = data['progress'] as Map<String, dynamic>?;
    
    // Extract user info
    final name = data['name'] ?? profile?['name'] ?? 'Unknown';
    final email = data['email'] ?? profile?['email'] ?? '';
    final phone = data['phone'] ?? profile?['phoneNumber'] ?? '';
    final photoUrl = data['photoUrl'] ?? profile?['photoUrl'];
    final userId = data['userId'] ?? profile?['customUserId'] ?? _selectedUserId;
    final isPremium = data['isPremium'] ?? false;
    final isBanned = data['isBanned'] ?? false;
    final subscriptionType = data['subscriptionType'] ?? 'free';
    final createdAt = data['createdAt'];
    
    // Stats
    final highestWpm = stats?['highestWpm'] ?? data['highestWpm'] ?? 0;
    final avgAccuracy = stats?['avgAccuracy'] ?? 0;
    final xpPoints = stats?['xpPoints'] ?? data['xpPoints'] ?? 0;
    final level = stats?['level'] ?? data['level'] ?? 1;
    final streakCount = stats?['streakCount'] ?? data['streakCount'] ?? 0;
    final totalSessions = stats?['totalSessions'] ?? 0;
    
    // Progress
    final completedLessons = (progress?['completedLessons'] ?? data['completedLessons'] ?? []) as List;
    final unlockedAchievements = (progress?['unlockedAchievements'] ?? data['unlockedAchievements'] ?? []) as List;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer.withOpacity(0.5),
                  colorScheme.primaryContainer.withOpacity(0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                // Large Avatar
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
                    backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                    backgroundColor: colorScheme.surface,
                    child: photoUrl == null
                        ? Text(
                            name.toString().isNotEmpty ? name[0].toUpperCase() : 'U',
                            style: TextStyle(
                              fontSize: 36,
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 24),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name with badges
                      Row(
                        children: [
                          Text(
                            name.toString(),
                            style: GoogleFonts.hindSiliguri(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (isPremium)
                            _buildBadge('প্রিমিয়াম', Colors.amber.shade700, Colors.amber.shade50, Icons.star),
                          if (isBanned)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: _buildBadge('ব্যান', Colors.red.shade700, Colors.red.shade50, Icons.block),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Contact info
                      if (email.toString().isNotEmpty)
                        _buildInfoRow(Icons.email_outlined, email.toString(), colorScheme),
                      if (phone.toString().isNotEmpty)
                        _buildInfoRow(Icons.phone_outlined, phone.toString(), colorScheme),
                      _buildInfoRow(Icons.badge_outlined, 'ID: $userId', colorScheme),
                      if (createdAt != null)
                        _buildInfoRow(
                          Icons.calendar_today_outlined,
                          'যোগদান: ${_formatDate(createdAt)}',
                          colorScheme,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Stats Section
          Text(
            '📊 পরিসংখ্যান',
            style: GoogleFonts.hindSiliguri(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Stats Grid
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildStatCard('সর্বোচ্চ WPM', '$highestWpm', Icons.speed_rounded, Colors.blue, colorScheme),
              _buildStatCard('নির্ভুলতা', '${(avgAccuracy is num ? avgAccuracy.toStringAsFixed(1) : avgAccuracy)}%', Icons.check_circle_outline, Colors.green, colorScheme),
              _buildStatCard('XP পয়েন্ট', '$xpPoints', Icons.star_rounded, Colors.amber, colorScheme),
              _buildStatCard('লেভেল', '$level', Icons.trending_up_rounded, Colors.purple, colorScheme),
              _buildStatCard('স্ট্রিক', '$streakCount দিন', Icons.local_fire_department_rounded, Colors.orange, colorScheme),
              _buildStatCard('মোট সেশন', '$totalSessions', Icons.history_rounded, Colors.teal, colorScheme),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Progress Section
          Text(
            '📈 অগ্রগতি',
            style: GoogleFonts.hindSiliguri(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildProgressCard(
                  'সম্পন্ন লেসন',
                  '${completedLessons.length}',
                  Icons.menu_book_rounded,
                  colorScheme.primary,
                  colorScheme,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildProgressCard(
                  'অ্যাচিভমেন্ট',
                  '${unlockedAchievements.length}',
                  Icons.emoji_events_rounded,
                  Colors.amber.shade700,
                  colorScheme,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildProgressCard(
                  'সাবস্ক্রিপশন',
                  subscriptionType.toString().toUpperCase(),
                  Icons.card_membership_rounded,
                  isPremium ? Colors.green.shade600 : Colors.grey,
                  colorScheme,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Actions Section
          Text(
            '⚡ অ্যাকশন',
            style: GoogleFonts.hindSiliguri(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (isBanned)
                ElevatedButton.icon(
                  onPressed: () => _toggleBan(_selectedUserId!, false),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: Text('আনব্যান করুন', style: GoogleFonts.hindSiliguri()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: () => _toggleBan(_selectedUserId!, true),
                  icon: const Icon(Icons.block, size: 18),
                  label: Text('ব্যান করুন', style: GoogleFonts.hindSiliguri()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade600,
                    side: BorderSide(color: Colors.red.shade300),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('এডিট ফিচার শীঘ্রই আসছে', style: GoogleFonts.hindSiliguri())),
                  );
                },
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text('প্রোফাইল এডিট', style: GoogleFonts.hindSiliguri()),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('মেসেজ ফিচার শীঘ্রই আসছে', style: GoogleFonts.hindSiliguri())),
                  );
                },
                icon: const Icon(Icons.message_outlined, size: 18),
                label: Text('মেসেজ পাঠান', style: GoogleFonts.hindSiliguri()),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
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
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.hindSiliguri(fontSize: 12, color: textColor, fontWeight: FontWeight.w600),
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

  Widget _buildStatCard(String label, String value, IconData icon, Color color, ColorScheme colorScheme) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.hindSiliguri(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(String label, String value, IconData icon, Color color, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.hindSiliguri(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else {
      return 'N/A';
    }
    
    return '${date.day}/${date.month}/${date.year}';
  }

  void _toggleBan(String userId, bool ban) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isBanned': ban,
      });
      
      // Refresh data
      _selectUser(userId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ban ? 'ইউজার ব্যান করা হয়েছে' : 'ইউজার আনব্যান করা হয়েছে',
              style: GoogleFonts.hindSiliguri(),
            ),
            backgroundColor: ban ? Colors.red : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ত্রুটি: $e', style: GoogleFonts.hindSiliguri()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
