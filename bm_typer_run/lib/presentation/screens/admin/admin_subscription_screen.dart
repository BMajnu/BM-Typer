import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bm_typer/core/models/subscription_model.dart';
import 'package:bm_typer/core/services/admin_subscription_service.dart';

/// Admin Subscription Management Screen
class AdminSubscriptionScreen extends ConsumerStatefulWidget {
  const AdminSubscriptionScreen({super.key});

  @override
  ConsumerState<AdminSubscriptionScreen> createState() => _AdminSubscriptionScreenState();
}

class _AdminSubscriptionScreenState extends ConsumerState<AdminSubscriptionScreen> {
  String _filterType = 'all'; // all, active, expired

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statsAsync = ref.watch(subscriptionStatsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Cards
          statsAsync.when(
            data: (stats) => _buildStatsRow(stats, colorScheme),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),

          const SizedBox(height: 24),

          // Subscriptions Table
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(Icons.card_membership, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      'সাবস্ক্রিপশন তালিকা',
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    // Filter Chips
                    _buildFilterChip('সব', 'all', colorScheme),
                    const SizedBox(width: 8),
                    _buildFilterChip('সক্রিয়', 'active', colorScheme),
                    const SizedBox(width: 8),
                    _buildFilterChip('মেয়াদ শেষ', 'expired', colorScheme),
                    const SizedBox(width: 16),
                    // Grant Button
                    ElevatedButton.icon(
                      onPressed: () => _showGrantDialog(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text('নতুন দিন', style: GoogleFonts.hindSiliguri()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Subscriptions List
                _buildSubscriptionsList(colorScheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(Map<String, dynamic> stats, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'মোট সাবস্ক্রিপশন',
            value: '${stats['totalSubscriptions'] ?? 0}',
            icon: Icons.card_membership,
            color: Colors.blue,
            colorScheme: colorScheme,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'সক্রিয়',
            value: '${stats['activeSubscriptions'] ?? 0}',
            icon: Icons.check_circle,
            color: Colors.green,
            colorScheme: colorScheme,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'মোট রেভিনিউ',
            value: '৳${stats['totalRevenue'] ?? 0}',
            icon: Icons.attach_money,
            color: Colors.purple,
            colorScheme: colorScheme,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'বার্ষিক প্ল্যান',
            value: '${stats['yearlyCount'] ?? 0}',
            icon: Icons.star,
            color: Colors.amber,
            colorScheme: colorScheme,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, ColorScheme colorScheme) {
    final isSelected = _filterType == value;
    return FilterChip(
      selected: isSelected,
      label: Text(label, style: GoogleFonts.hindSiliguri()),
      onSelected: (selected) {
        setState(() => _filterType = value);
      },
      selectedColor: colorScheme.primary.withOpacity(0.2),
    );
  }

  Widget _buildSubscriptionsList(ColorScheme colorScheme) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getFilteredStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.inbox, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(
                    'কোনো সাবস্ক্রিপশন নেই',
                    style: GoogleFonts.hindSiliguri(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        return DataTable(
          columns: [
            DataColumn(label: Text('ইউজার ID', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('প্ল্যান', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('শুরু', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('মেয়াদ', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('স্ট্যাটাস', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('অ্যাকশন', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold))),
          ],
          rows: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final userId = data['userId'] as String? ?? '';
            final type = data['type'] as String? ?? 'free';
            final startDate = data['startDate'] != null
                ? DateTime.parse(data['startDate'] as String)
                : null;
            final endDate = data['endDate'] != null
                ? DateTime.parse(data['endDate'] as String)
                : null;
            final isActive = data['isActive'] as bool? ?? false;
            final isExpired = endDate != null && DateTime.now().isAfter(endDate);

            return DataRow(cells: [
              DataCell(Text(
                userId.length > 15 ? '${userId.substring(0, 15)}...' : userId,
                style: const TextStyle(fontSize: 12),
              )),
              DataCell(_buildPlanChip(type)),
              DataCell(Text(
                startDate != null
                    ? '${startDate.day}/${startDate.month}/${startDate.year}'
                    : '-',
                style: const TextStyle(fontSize: 12),
              )),
              DataCell(Text(
                endDate != null
                    ? '${endDate.day}/${endDate.month}/${endDate.year}'
                    : '-',
                style: const TextStyle(fontSize: 12),
              )),
              DataCell(_buildStatusChip(isActive, isExpired)),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.add_circle_outline, color: Colors.green.shade400, size: 20),
                    tooltip: 'এক্সটেন্ড',
                    onPressed: () => _showExtendDialog(context, doc.id),
                  ),
                  IconButton(
                    icon: Icon(Icons.cancel_outlined, color: Colors.red.shade400, size: 20),
                    tooltip: 'বাতিল',
                    onPressed: () => _showCancelDialog(context, doc.id),
                  ),
                ],
              )),
            ]);
          }).toList(),
        );
      },
    );
  }

  Stream<QuerySnapshot> _getFilteredStream() {
    final collection = FirebaseFirestore.instance.collection('subscriptions');

    switch (_filterType) {
      case 'active':
        return collection.where('isActive', isEqualTo: true).snapshots();
      case 'expired':
        return collection.where('isActive', isEqualTo: false).snapshots();
      default:
        return collection.snapshots();
    }
  }

  Widget _buildPlanChip(String type) {
    Color color;
    String label;

    switch (type) {
      case 'monthly':
        color = Colors.blue;
        label = 'মাসিক';
        break;
      case 'quarterly':
        color = Colors.teal;
        label = '৩ মাস';
        break;
      case 'halfYearly':
      case 'half_yearly':
        color = Colors.purple;
        label = '৬ মাস';
        break;
      case 'yearly':
        color = Colors.amber;
        label = 'বার্ষিক';
        break;
      default:
        color = Colors.grey;
        label = 'ফ্রি';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.hindSiliguri(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool isActive, bool isExpired) {
    Color color;
    String label;

    if (isExpired) {
      color = Colors.red;
      label = 'মেয়াদ শেষ';
    } else if (isActive) {
      color = Colors.green;
      label = 'সক্রিয়';
    } else {
      color = Colors.grey;
      label = 'বাতিল';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.hindSiliguri(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showGrantDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _GrantSubscriptionDialog(
        ref: ref,
        onSuccess: () {
          ref.invalidate(subscriptionStatsProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('সাবস্ক্রিপশন দেওয়া হয়েছে!', style: GoogleFonts.hindSiliguri()),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _showExtendDialog(BuildContext context, String subscriptionId) {
    int days = 30;
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('সাবস্ক্রিপশন এক্সটেন্ড', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold)),
        content: TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'দিন সংখ্যা',
            labelStyle: GoogleFonts.hindSiliguri(),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (val) => days = int.tryParse(val) ?? 30,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('বাতিল', style: GoogleFonts.hindSiliguri()),
          ),
          ElevatedButton(
            onPressed: () async {
              final service = ref.read(adminSubscriptionServiceProvider);
              final success = await service.extendSubscription(
                subscriptionId: subscriptionId,
                additionalDays: days,
              );
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? '$days দিন এক্সটেন্ড হয়েছে!' : 'ত্রুটি হয়েছে',
                      style: GoogleFonts.hindSiliguri(),
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            child: Text('এক্সটেন্ড', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, String subscriptionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('সাবস্ক্রিপশন বাতিল?', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold)),
        content: Text(
          'আপনি কি নিশ্চিত এই সাবস্ক্রিপশনটি বাতিল করতে চান?',
          style: GoogleFonts.hindSiliguri(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('না', style: GoogleFonts.hindSiliguri()),
          ),
          ElevatedButton(
            onPressed: () async {
              final service = ref.read(adminSubscriptionServiceProvider);
              final success = await service.cancelSubscription(subscriptionId);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'বাতিল হয়েছে!' : 'ত্রুটি হয়েছে',
                      style: GoogleFonts.hindSiliguri(),
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('বাতিল করুন', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

/// Professional Grant Subscription Dialog with Tabs
class _GrantSubscriptionDialog extends StatefulWidget {
  final WidgetRef ref;
  final VoidCallback onSuccess;

  const _GrantSubscriptionDialog({
    required this.ref,
    required this.onSuccess,
  });

  @override
  State<_GrantSubscriptionDialog> createState() => _GrantSubscriptionDialogState();
}

class _GrantSubscriptionDialogState extends State<_GrantSubscriptionDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Search tab
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  Map<String, dynamic>? _selectedUser;
  SubscriptionType _selectedType = SubscriptionType.monthly;
  
  // New user tab
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  SubscriptionType _newUserPlanType = SubscriptionType.monthly;
  bool _isCreating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Load initial users to verify data connection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchUsers('');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    // Removed length check to allow fetching all users (handled in service)
    setState(() => _isSearching = true);
    
    final service = widget.ref.read(adminSubscriptionServiceProvider);
    final results = await service.searchUsers(query);
    
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  Future<void> _grantToExistingUser() async {
    if (_selectedUser == null) return;

    final service = widget.ref.read(adminSubscriptionServiceProvider);
    final success = await service.grantSubscription(
      userId: _selectedUser!['id'],
      type: _selectedType,
    );

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        widget.onSuccess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('সাবস্ক্রিপশন দিতে সমস্যা হয়েছে', style: GoogleFonts.hindSiliguri()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createUserAndGrant() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });

    final service = widget.ref.read(adminSubscriptionServiceProvider);
    final result = await service.createUserAndGrant(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      subscriptionType: _newUserPlanType,
    );

    if (mounted) {
      setState(() => _isCreating = false);

      if (result['success'] == true) {
        Navigator.pop(context);
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ইউজার তৈরি ও সাবস্ক্রিপশন দেওয়া হয়েছে!', style: GoogleFonts.hindSiliguri()),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => _errorMessage = result['error']);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 550,
        height: 600,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.card_membership, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'সাবস্ক্রিপশন দিন',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Tab Bar
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: colorScheme.onSurface,
                labelStyle: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: 'বিদ্যমান ইউজার'),
                  Tab(text: 'নতুন ইউজার'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSearchTab(colorScheme),
                  _buildCreateTab(colorScheme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchTab(ColorScheme colorScheme) {
    return Column(
      children: [
        // Search Field
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'নাম বা ইমেইল দিয়ে খুঁজুন...',
            hintStyle: GoogleFonts.hindSiliguri(),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
          ),
          onChanged: (value) => _searchUsers(value),
        ),

        const SizedBox(height: 12),

        // Search Results or Selected User
        Expanded(
          child: _selectedUser != null
              ? _buildSelectedUserCard(colorScheme)
              : _searchResults.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            _searchController.text.length < 2
                                ? 'কমপক্ষে ২ অক্ষর লিখুন'
                                : 'কোনো ইউজার পাওয়া যায়নি',
                            style: GoogleFonts.hindSiliguri(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      separatorBuilder: (c, i) => const SizedBox(height: 8),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
                        final hasName = user['name']?.toString().isNotEmpty ?? false;
                        final hasEmail = user['email']?.toString().isNotEmpty ?? false;
                        final hasPhone = user['phone']?.toString().isNotEmpty ?? false;
                        
                        // Priority: Name > Email > Phone > ID
                        final displayName = hasName ? user['name'] 
                            : (hasEmail ? user['email'] 
                            : (hasPhone ? user['phone'] : 'User ${user['userId']}'));
                            
                        final subtitle = hasName ? (hasEmail ? user['email'] : (hasPhone ? user['phone'] : 'ID: ${user['userId']}')) 
                            : 'ID: ${user['userId']}';

                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: colorScheme.primary.withOpacity(0.1),
                              backgroundImage: user['photoUrl'] != null
                                  ? NetworkImage(user['photoUrl'])
                                  : null,
                              child: user['photoUrl'] == null 
                                  ? Text(
                                      (user['name']?.toString().isNotEmpty ?? false)
                                          ? (user['name'].toString()[0].toUpperCase())
                                          : 'U',
                                      style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
                                    )
                                  : null,
                            ),
                            title: Text(
                              displayName,
                              style: GoogleFonts.hindSiliguri(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            trailing: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedUser = user;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                              ),
                              child: Text('সিলেক্ট', style: GoogleFonts.hindSiliguri()),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildSelectedUserCard(ColorScheme colorScheme) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Selected User Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: colorScheme.primaryContainer,
                    backgroundImage: _selectedUser!['photoUrl'] != null
                        ? NetworkImage(_selectedUser!['photoUrl'])
                        : null,
                    child: _selectedUser!['photoUrl'] == null
                        ? Text(
                            (_selectedUser!['name']?.toString().isNotEmpty ?? false)
                                ? (_selectedUser!['name'].toString()[0].toUpperCase())
                                : 'U',
                            style: TextStyle(color: colorScheme.primary, fontSize: 20),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Builder(
                          builder: (context) {
                            final user = _selectedUser!;
                            final hasName = user['name']?.toString().isNotEmpty ?? false;
                            final hasEmail = user['email']?.toString().isNotEmpty ?? false;
                            final hasPhone = user['phone']?.toString().isNotEmpty ?? false;
                            
                            final displayName = hasName ? user['name'] 
                                : (hasEmail ? user['email'] 
                                : (hasPhone ? user['phone'] : 'User ${user['userId']}'));
                                
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(displayName, style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold, fontSize: 16)),
                                if (hasName && hasEmail)
                                  Text(user['email'], style: const TextStyle(fontSize: 13)),
                                Text('ID: ${user['userId']}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                              ],
                            );
                          }
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _selectedUser = null),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Plan Selection
          Text('প্ল্যান সিলেক্ট করুন:', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),

          ...SubscriptionType.values.where((t) => t != SubscriptionType.free).map((type) {
            final isSelected = _selectedType == type;
            return Card(
              color: isSelected ? colorScheme.primary.withOpacity(0.1) : null,
              child: ListTile(
                leading: Radio<SubscriptionType>(
                  value: type,
                  groupValue: _selectedType,
                  onChanged: (val) => setState(() => _selectedType = val!),
                ),
                title: Text(SubscriptionModel.getDisplayName(type), style: GoogleFonts.hindSiliguri()),
                trailing: Text('৳${SubscriptionModel.getPrice(type)}', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold)),
                onTap: () => setState(() => _selectedType = type),
              ),
            );
          }).toList(),

          const SizedBox(height: 20),

          // Grant Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _grantToExistingUser,
              icon: const Icon(Icons.card_giftcard),
              label: Text('সাবস্ক্রিপশন দিন', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateTab(ColorScheme colorScheme) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'পুরো নাম *',
                labelStyle: GoogleFonts.hindSiliguri(),
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) => value?.isEmpty == true ? 'নাম দিন' : null,
            ),

            const SizedBox(height: 16),

            // Email
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'ইমেইল *',
                labelStyle: GoogleFonts.hindSiliguri(),
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (value?.isEmpty == true) return 'ইমেইল দিন';
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                  return 'সঠিক ইমেইল দিন';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Password
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'পাসওয়ার্ড *',
                labelStyle: GoogleFonts.hindSiliguri(),
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                helperText: 'কমপক্ষে ৬ অক্ষর',
              ),
              validator: (value) {
                if (value?.isEmpty == true) return 'পাসওয়ার্ড দিন';
                if (value!.length < 6) return 'কমপক্ষে ৬ অক্ষর দিন';
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Phone
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'ফোন (ঐচ্ছিক)',
                labelStyle: GoogleFonts.hindSiliguri(),
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 16),

            // Plan Selection
            DropdownButtonFormField<SubscriptionType>(
              value: _newUserPlanType,
              decoration: InputDecoration(
                labelText: 'প্ল্যান',
                labelStyle: GoogleFonts.hindSiliguri(),
                prefixIcon: const Icon(Icons.card_membership),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: SubscriptionType.values.where((t) => t != SubscriptionType.free).map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text('${SubscriptionModel.getDisplayName(type)} - ৳${SubscriptionModel.getPrice(type)}', style: GoogleFonts.hindSiliguri()),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _newUserPlanType = val);
              },
            ),

            const SizedBox(height: 16),

            // Error Message
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade400, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.hindSiliguri(color: Colors.red.shade700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Create Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isCreating ? null : _createUserAndGrant,
                icon: _isCreating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.person_add),
                label: Text(
                  _isCreating ? 'তৈরি হচ্ছে...' : 'ইউজার তৈরি ও সাবস্ক্রিপশন দিন',
                  style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
