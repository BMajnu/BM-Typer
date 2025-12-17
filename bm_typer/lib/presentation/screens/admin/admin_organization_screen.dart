import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bm_typer/core/models/organization_model.dart';
import 'package:bm_typer/core/services/admin_organization_service.dart';

/// Admin Organization Management Screen
class AdminOrganizationScreen extends ConsumerStatefulWidget {
  const AdminOrganizationScreen({super.key});

  @override
  ConsumerState<AdminOrganizationScreen> createState() => _AdminOrganizationScreenState();
}

class _AdminOrganizationScreenState extends ConsumerState<AdminOrganizationScreen> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statsAsync = ref.watch(organizationStatsProvider);

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

          // Organizations Table
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
                    Icon(Icons.business, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      'প্রতিষ্ঠান তালিকা',
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () => _showCreateDialog(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text('নতুন প্রতিষ্ঠান', style: GoogleFonts.hindSiliguri()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Organizations List
                _buildOrganizationsList(colorScheme),
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
            title: 'মোট প্রতিষ্ঠান',
            value: '${stats['totalOrganizations'] ?? 0}',
            icon: Icons.business,
            color: Colors.blue,
            colorScheme: colorScheme,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'সক্রিয়',
            value: '${stats['activeOrganizations'] ?? 0}',
            icon: Icons.check_circle,
            color: Colors.green,
            colorScheme: colorScheme,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'মোট সদস্য',
            value: '${stats['totalMembers'] ?? 0}',
            icon: Icons.people,
            color: Colors.purple,
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
                  style: GoogleFonts.hindSiliguri(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.hindSiliguri(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizationsList(ColorScheme colorScheme) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('organizations')
          .orderBy('createdAt', descending: true)
          .snapshots(),
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
                  Icon(Icons.business_outlined, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(
                    'কোনো প্রতিষ্ঠান নেই',
                    style: GoogleFonts.hindSiliguri(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        return DataTable(
          columns: [
            DataColumn(label: Text('নাম', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('অ্যাডমিন ইমেইল', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('সদস্য', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('প্ল্যান', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('মেয়াদ', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('অ্যাকশন', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold))),
          ],
          rows: docs.map((doc) {
            final org = OrganizationModel.fromFirestore(doc);
            final isExpired = org.expiryDate != null && DateTime.now().isAfter(org.expiryDate!);

            return DataRow(cells: [
              DataCell(Text(org.name, style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(Text(org.adminEmail, style: const TextStyle(fontSize: 12))),
              DataCell(Text('${org.memberCount}/${org.maxMembers}')),
              DataCell(_buildPlanChip(org.subscriptionType)),
              DataCell(_buildExpiryChip(org.expiryDate, isExpired)),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.people, color: Colors.blue.shade400, size: 20),
                    tooltip: 'সদস্য দেখুন',
                    onPressed: () => _showMembersDialog(context, org),
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline, color: Colors.green.shade400, size: 20),
                    tooltip: 'এক্সটেন্ড',
                    onPressed: () => _showExtendDialog(context, org.id),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 20),
                    tooltip: 'মুছুন',
                    onPressed: () => _showDeleteDialog(context, org.id),
                  ),
                ],
              )),
            ]);
          }).toList(),
        );
      },
    );
  }

  Widget _buildPlanChip(String type) {
    Color color;
    String label;

    switch (type) {
      case 'team_monthly':
        color = Colors.blue;
        label = 'টিম মাসিক';
        break;
      case 'team_yearly':
        color = Colors.purple;
        label = 'টিম বার্ষিক';
        break;
      case 'enterprise':
        color = Colors.amber;
        label = 'এন্টারপ্রাইজ';
        break;
      default:
        color = Colors.grey;
        label = 'অজানা';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: GoogleFonts.hindSiliguri(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildExpiryChip(DateTime? expiryDate, bool isExpired) {
    if (expiryDate == null) {
      return Text('-', style: GoogleFonts.hindSiliguri());
    }

    final color = isExpired ? Colors.red : Colors.green;
    final label = '${expiryDate.day}/${expiryDate.month}/${expiryDate.year}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }

  void _showCreateDialog(BuildContext context) {
    String name = '';
    String adminEmail = '';
    int maxMembers = 10;
    String subscriptionType = 'team_monthly';
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('নতুন প্রতিষ্ঠান', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold)),
        content: StatefulBuilder(
          builder: (context, setDialogState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'প্রতিষ্ঠানের নাম',
                    labelStyle: GoogleFonts.hindSiliguri(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (val) => name = val,
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'অ্যাডমিন ইমেইল',
                    labelStyle: GoogleFonts.hindSiliguri(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (val) => adminEmail = val,
                ),
                const SizedBox(height: 16),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'সর্বোচ্চ সদস্য',
                    labelStyle: GoogleFonts.hindSiliguri(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (val) => maxMembers = int.tryParse(val) ?? 10,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: subscriptionType,
                  decoration: InputDecoration(
                    labelText: 'প্ল্যান',
                    labelStyle: GoogleFonts.hindSiliguri(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: [
                    DropdownMenuItem(value: 'team_monthly', child: Text('টিম মাসিক', style: GoogleFonts.hindSiliguri())),
                    DropdownMenuItem(value: 'team_yearly', child: Text('টিম বার্ষিক', style: GoogleFonts.hindSiliguri())),
                    DropdownMenuItem(value: 'enterprise', child: Text('এন্টারপ্রাইজ', style: GoogleFonts.hindSiliguri())),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => subscriptionType = val);
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('বাতিল', style: GoogleFonts.hindSiliguri()),
          ),
          ElevatedButton(
            onPressed: () async {
              if (name.isNotEmpty && adminEmail.isNotEmpty) {
                final service = ref.read(adminOrganizationServiceProvider);
                final days = subscriptionType == 'team_yearly' ? 365 : 30;
                final orgId = await service.createOrganization(
                  name: name,
                  adminEmail: adminEmail,
                  maxMembers: maxMembers,
                  subscriptionType: subscriptionType,
                  durationDays: days,
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        orgId != null ? 'প্রতিষ্ঠান তৈরি হয়েছে!' : 'ত্রুটি হয়েছে',
                        style: GoogleFonts.hindSiliguri(),
                      ),
                      backgroundColor: orgId != null ? Colors.green : Colors.red,
                    ),
                  );
                  ref.invalidate(organizationStatsProvider);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary),
            child: Text('তৈরি করুন', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showMembersDialog(BuildContext context, OrganizationModel org) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text('${org.name} - সদস্য', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: () {
                Navigator.pop(context);
                _showAddMemberDialog(context, org.id);
              },
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          height: 300,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('organizations')
                .doc(org.id)
                .collection('members')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return Center(
                  child: Text('কোনো সদস্য নেই', style: GoogleFonts.hindSiliguri(color: Colors.grey)),
                );
              }

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.primaryContainer,
                      child: Text(
                        (data['name'] as String? ?? 'U')[0].toUpperCase(),
                        style: TextStyle(color: colorScheme.primary),
                      ),
                    ),
                    title: Text(data['name'] as String? ?? '', style: GoogleFonts.hindSiliguri()),
                    subtitle: Text(data['email'] as String? ?? '', style: const TextStyle(fontSize: 12)),
                    trailing: IconButton(
                      icon: Icon(Icons.remove_circle_outline, color: Colors.red.shade400),
                      onPressed: () async {
                        final service = ref.read(adminOrganizationServiceProvider);
                        await service.removeMember(org.id, docs[index].id);
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('বন্ধ করুন', style: GoogleFonts.hindSiliguri()),
          ),
        ],
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context, String orgId) {
    String email = '';
    String name = '';
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('সদস্য যুক্ত করুন', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'নাম',
                labelStyle: GoogleFonts.hindSiliguri(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) => name = val,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'ইমেইল',
                labelStyle: GoogleFonts.hindSiliguri(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) => email = val,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('বাতিল', style: GoogleFonts.hindSiliguri()),
          ),
          ElevatedButton(
            onPressed: () async {
              if (name.isNotEmpty && email.isNotEmpty) {
                final service = ref.read(adminOrganizationServiceProvider);
                final success = await service.addMember(
                  orgId: orgId,
                  userId: email,
                  email: email,
                  name: name,
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'সদস্য যুক্ত হয়েছে!' : 'ত্রুটি হয়েছে', style: GoogleFonts.hindSiliguri()),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary),
            child: Text('যুক্ত করুন', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showExtendDialog(BuildContext context, String orgId) {
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
              final service = ref.read(adminOrganizationServiceProvider);
              final success = await service.extendSubscription(orgId, days);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? '$days দিন এক্সটেন্ড হয়েছে!' : 'ত্রুটি হয়েছে', style: GoogleFonts.hindSiliguri()),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary),
            child: Text('এক্সটেন্ড', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String orgId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('প্রতিষ্ঠান মুছবেন?', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold)),
        content: Text('এই প্রতিষ্ঠান এবং সকল সদস্য মুছে যাবে।', style: GoogleFonts.hindSiliguri()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('না', style: GoogleFonts.hindSiliguri()),
          ),
          ElevatedButton(
            onPressed: () async {
              final service = ref.read(adminOrganizationServiceProvider);
              final success = await service.deleteOrganization(orgId);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'প্রতিষ্ঠান মুছে গেছে!' : 'ত্রুটি হয়েছে', style: GoogleFonts.hindSiliguri()),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
                ref.invalidate(organizationStatsProvider);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text('মুছুন', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
