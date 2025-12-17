import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin User Management Screen
class AdminUserManagementScreen extends ConsumerStatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  ConsumerState<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends ConsumerState<AdminUserManagementScreen> {
  String _searchQuery = '';
  String _filterStatus = 'all'; // all, active, banned, premium
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toolbar
          Row(
            children: [
              // Search
              Expanded(
                flex: 2,
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'ইউজার খুঁজুন (নাম, ইমেইল, আইডি)',
                    hintStyle: GoogleFonts.hindSiliguri(fontSize: 13),
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Filter Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _filterStatus,
                    items: [
                      DropdownMenuItem(value: 'all', child: Text('সব ইউজার', style: GoogleFonts.hindSiliguri())),
                      DropdownMenuItem(value: 'active', child: Text('অ্যাক্টিভ', style: GoogleFonts.hindSiliguri())),
                      DropdownMenuItem(value: 'banned', child: Text('ব্যান করা', style: GoogleFonts.hindSiliguri())),
                      DropdownMenuItem(value: 'premium', child: Text('প্রিমিয়াম', style: GoogleFonts.hindSiliguri())),
                    ],
                    onChanged: (value) => setState(() => _filterStatus = value!),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Export Button
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download),
                label: Text('এক্সপোর্ট', style: GoogleFonts.hindSiliguri()),
              ),
              
              const SizedBox(width: 8),
              
              // Add User Button
              ElevatedButton.icon(
                onPressed: () => _showAddUserDialog(context),
                icon: const Icon(Icons.person_add),
                label: Text('নতুন ইউজার', style: GoogleFonts.hindSiliguri()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Users Table
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Row(
                      children: [
                        _buildTableHeader('ইউজার', flex: 2),
                        _buildTableHeader('ইমেইল', flex: 2),
                        _buildTableHeader('স্ট্যাটাস'),
                        _buildTableHeader('প্ল্যান'),
                        _buildTableHeader('যোগদান'),
                        _buildTableHeader('কার্যক্রম', flex: 1),
                      ],
                    ),
                  ),
                  
                  // Table Body - Firestore Stream
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .limit(50)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        
                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                                const SizedBox(height: 12),
                                Text('ডাটা লোড হয়নি', style: GoogleFonts.hindSiliguri()),
                                Text(snapshot.error.toString(), style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          );
                        }
                        
                        final docs = snapshot.data?.docs ?? [];
                        
                        if (docs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text('কোনো ইউজার নেই', style: GoogleFonts.hindSiliguri(color: Colors.grey)),
                              ],
                            ),
                          );
                        }
                        
                        // Filter users
                        final filteredDocs = docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final profile = data['profile'] as Map<String, dynamic>? ?? {};
                          final name = (profile['name'] ?? '').toString().toLowerCase();
                          final email = (profile['email'] ?? '').toString().toLowerCase();
                          final query = _searchQuery.toLowerCase();
                          
                          if (_searchQuery.isNotEmpty && !name.contains(query) && !email.contains(query)) {
                            return false;
                          }
                          
                          // Apply filter
                          if (_filterStatus == 'banned' && data['isBanned'] != true) return false;
                          if (_filterStatus == 'premium' && data['subscription']?['type'] != 'premium') return false;
                          if (_filterStatus == 'active' && data['isBanned'] == true) return false;
                          
                          return true;
                        }).toList();
                        
                        return ListView.separated(
                          itemCount: filteredDocs.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: colorScheme.outline.withOpacity(0.1)),
                          itemBuilder: (context, index) {
                            final doc = filteredDocs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final profile = data['profile'] as Map<String, dynamic>? ?? {};
                            
                            return _buildUserRow(
                              userId: doc.id,
                              name: profile['name'] ?? 'Unknown',
                              email: profile['email'] ?? '',
                              photoUrl: profile['photoUrl'],
                              isBanned: data['isBanned'] == true,
                              isPremium: data['subscription']?['type'] == 'premium',
                              joinedAt: data['lastSynced'],
                              colorScheme: colorScheme,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTableHeader(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: GoogleFonts.hindSiliguri(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
  
  Widget _buildUserRow({
    required String userId,
    required String name,
    required String email,
    String? photoUrl,
    required bool isBanned,
    required bool isPremium,
    dynamic joinedAt,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // User info
          Expanded(
            flex: 2,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: colorScheme.primaryContainer,
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null 
                    ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?', 
                        style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold))
                    : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(userId, style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Email
          Expanded(
            flex: 2,
            child: Text(email, style: TextStyle(fontSize: 13)),
          ),
          
          // Status
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isBanned ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isBanned ? 'ব্যান' : 'অ্যাক্টিভ',
                textAlign: TextAlign.center,
                style: GoogleFonts.hindSiliguri(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isBanned ? Colors.red : Colors.green,
                ),
              ),
            ),
          ),
          
          // Plan
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isPremium ? Colors.amber.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isPremium) Icon(Icons.star, size: 12, color: Colors.amber.shade700),
                  Text(
                    isPremium ? 'PRO' : 'ফ্রি',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isPremium ? Colors.amber.shade700 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Joined
          Expanded(
            child: Text(
              _formatDate(joinedAt),
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          
          // Actions
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility, size: 18),
                  tooltip: 'বিস্তারিত',
                  onPressed: () => _showUserDetails(userId),
                ),
                IconButton(
                  icon: Icon(
                    isBanned ? Icons.lock_open : Icons.block,
                    size: 18,
                    color: isBanned ? Colors.green : Colors.red,
                  ),
                  tooltip: isBanned ? 'আনব্যান' : 'ব্যান',
                  onPressed: () => _toggleBan(userId, !isBanned),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18),
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'edit', child: Text('এডিট', style: GoogleFonts.hindSiliguri())),
                    PopupMenuItem(value: 'reset_password', child: Text('পাসওয়ার্ড রিসেট', style: GoogleFonts.hindSiliguri())),
                    PopupMenuItem(value: 'delete', child: Text('ডিলিট', style: GoogleFonts.hindSiliguri(color: Colors.red))),
                  ],
                  onSelected: (value) => _handleMenuAction(value, userId),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '-';
    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return '${date.day}/${date.month}/${date.year}';
      }
      return '-';
    } catch (e) {
      return '-';
    }
  }
  
  void _showAddUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('নতুন ইউজার যোগ করুন', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'নাম',
                labelStyle: GoogleFonts.hindSiliguri(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: 'ইমেইল',
                labelStyle: GoogleFonts.hindSiliguri(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('বাতিল', style: GoogleFonts.hindSiliguri()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('ফিচার শীঘ্রই আসছে', style: GoogleFonts.hindSiliguri())),
              );
            },
            child: Text('যোগ করুন', style: GoogleFonts.hindSiliguri()),
          ),
        ],
      ),
    );
  }
  
  void _showUserDetails(String userId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('ইউজার ডিটেইলস: $userId', style: GoogleFonts.hindSiliguri())),
    );
  }
  
  void _toggleBan(String userId, bool ban) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isBanned': ban,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ban ? 'ইউজার ব্যান করা হয়েছে' : 'ইউজার আনব্যান করা হয়েছে', style: GoogleFonts.hindSiliguri()),
            backgroundColor: ban ? Colors.red : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ত্রুটি: $e', style: GoogleFonts.hindSiliguri()), backgroundColor: Colors.red),
        );
      }
    }
  }
  
  void _handleMenuAction(String action, String userId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action: $userId - শীঘ্রই আসছে', style: GoogleFonts.hindSiliguri())),
    );
  }
}
