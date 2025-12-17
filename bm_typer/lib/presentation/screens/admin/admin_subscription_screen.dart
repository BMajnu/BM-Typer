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
    String? userId;
    SubscriptionType selectedType = SubscriptionType.monthly;
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('নতুন সাবস্ক্রিপশন দিন', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold)),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'ইউজার ID',
                  labelStyle: GoogleFonts.hindSiliguri(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (val) => userId = val,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<SubscriptionType>(
                value: selectedType,
                decoration: InputDecoration(
                  labelText: 'প্ল্যান',
                  labelStyle: GoogleFonts.hindSiliguri(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: [
                  DropdownMenuItem(
                    value: SubscriptionType.monthly,
                    child: Text('মাসিক - ৳99', style: GoogleFonts.hindSiliguri()),
                  ),
                  DropdownMenuItem(
                    value: SubscriptionType.quarterly,
                    child: Text('৩ মাস - ৳249', style: GoogleFonts.hindSiliguri()),
                  ),
                  DropdownMenuItem(
                    value: SubscriptionType.halfYearly,
                    child: Text('৬ মাস - ৳449', style: GoogleFonts.hindSiliguri()),
                  ),
                  DropdownMenuItem(
                    value: SubscriptionType.yearly,
                    child: Text('বার্ষিক - ৳799', style: GoogleFonts.hindSiliguri()),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedType = val);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('বাতিল', style: GoogleFonts.hindSiliguri()),
          ),
          ElevatedButton(
            onPressed: () async {
              if (userId != null && userId!.isNotEmpty) {
                final service = ref.read(adminSubscriptionServiceProvider);
                final success = await service.grantSubscription(
                  userId: userId!,
                  type: selectedType,
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success ? 'সাবস্ক্রিপশন দেওয়া হয়েছে!' : 'ত্রুটি হয়েছে',
                        style: GoogleFonts.hindSiliguri(),
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                  ref.invalidate(subscriptionStatsProvider);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            child: Text('দিন', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold)),
          ),
        ],
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
