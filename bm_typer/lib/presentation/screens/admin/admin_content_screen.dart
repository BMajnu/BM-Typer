import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin Content Management Screen - Manage lessons and content
class AdminContentScreen extends ConsumerStatefulWidget {
  const AdminContentScreen({super.key});

  @override
  ConsumerState<AdminContentScreen> createState() => _AdminContentScreenState();
}

class _AdminContentScreenState extends ConsumerState<AdminContentScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      children: [
        // Tab Bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
              Tab(text: 'লেসন'),
              Tab(text: 'এক্সারসাইজ'),
              Tab(text: 'সেটিংস'),
            ],
          ),
        ),
        
        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildLessonsTab(colorScheme),
              _buildExercisesTab(colorScheme),
              _buildContentSettingsTab(colorScheme),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildLessonsTab(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Toolbar
          Row(
            children: [
              Text(
                'লেসন ম্যানেজমেন্ট',
                style: GoogleFonts.hindSiliguri(color: Colors.grey),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showAddLessonDialog(context),
                icon: const Icon(Icons.add),
                label: Text('নতুন লেসন', style: GoogleFonts.hindSiliguri()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Lessons List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('lessons').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading lessons', style: GoogleFonts.hindSiliguri()));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.description_outlined, size: 64, color: Colors.grey.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text('কোনো লেসন পাওয়া যায়নি', style: GoogleFonts.hindSiliguri(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final title = data['title'] ?? 'Untitled Lesson';
                    final category = data['category'] ?? 'General';
                    final exerciseCount = (data['exercises'] as List?)?.length ?? 0;
                    final isPublished = data['isPublished'] == true;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        title: Text(
                          title,
                          style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Row(
                          children: [
                            _buildCategoryChip(category),
                            const SizedBox(width: 8),
                            Text('$exerciseCount এক্সারসাইজ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isPublished ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isPublished ? 'প্রকাশিত' : 'ড্রাফট',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isPublished ? Colors.green : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () {},
                              tooltip: 'এডিট',
                            ),
                            IconButton(
                              icon: const Icon(Icons.content_copy_outlined),
                              onPressed: () {},
                              tooltip: 'ডুপ্লিকেট',
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
                              onPressed: () {},
                              tooltip: 'ডিলিট',
                            ),
                          ],
                        ),
                      ),
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
  
  Widget _buildCategoryChip(String category) {
    Color color;
    switch (category) {
      case 'বিজয়':
        color = Colors.orange;
        break;
      case 'ফনেটিক':
        color = Colors.green;
        break;
      case 'QWERTY':
        color = Colors.blue;
        break;
      default:
        color = Colors.purple;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        category,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
  
  Widget _buildExercisesTab(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'এক্সারসাইজ ম্যানেজমেন্ট',
            style: GoogleFonts.hindSiliguri(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'শীঘ্রই আসছে - এখান থেকে আপনি এক্সারসাইজ যোগ, এডিট এবং মুছতে পারবেন',
            style: GoogleFonts.hindSiliguri(color: Colors.grey),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContentSettingsTab(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('কন্টেন্ট সেটিংস', style: GoogleFonts.hindSiliguri(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          
          _buildSettingTile(
            title: 'ডিফল্ট লেসন',
            subtitle: 'নতুন ইউজাররা প্রথমে এই লেসন দেখবে',
            trailing: DropdownButton<String>(
              value: '1',
              items: const [
                DropdownMenuItem(value: '1', child: Text('বাংলা বেসিক')),
                DropdownMenuItem(value: '2', child: Text('ফনেটিক')),
              ],
              onChanged: (value) {},
            ),
          ),
          
          _buildSettingTile(
            title: 'ফ্রি লেসন সংখ্যা',
            subtitle: 'ফ্রি ইউজাররা কতটি লেসন দেখতে পারবে',
            trailing: SizedBox(
              width: 80,
              child: TextField(
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                controller: TextEditingController(text: '5'),
              ),
            ),
          ),
          
          _buildSettingTile(
            title: 'অটো-সেভ ড্রাফট',
            subtitle: 'এডিট করার সময় স্বয়ংক্রিয়ভাবে সেভ করুন',
            trailing: Switch(value: true, onChanged: (v) {}),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold)),
                Text(subtitle, style: GoogleFonts.hindSiliguri(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
  
  void _showAddLessonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('নতুন লেসন', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'লেসনের নাম',
                labelStyle: GoogleFonts.hindSiliguri(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'ক্যাটাগরি',
                labelStyle: GoogleFonts.hindSiliguri(),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: const [
                DropdownMenuItem(value: 'bijoy', child: Text('বিজয়')),
                DropdownMenuItem(value: 'phonetic', child: Text('ফনেটিক')),
                DropdownMenuItem(value: 'qwerty', child: Text('QWERTY')),
              ],
              onChanged: (value) {},
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
                SnackBar(content: Text('লেসন যোগ করা হয়েছে', style: GoogleFonts.hindSiliguri())),
              );
            },
            child: Text('তৈরি করুন', style: GoogleFonts.hindSiliguri()),
          ),
        ],
      ),
    );
  }
}
