import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bm_typer/core/services/export_service.dart';
import 'package:bm_typer/core/providers/user_provider.dart';
import 'package:flutter/foundation.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  final ExportService _exportService = ExportService();
  bool _isGeneratingPdf = false;
  bool _isGeneratingCsv = false;
  bool _isGeneratingCertificate = false;
  String? _courseName = 'Bangla Typing Course';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Export Progress'),
        ),
        body: const Center(
          child: Text('User not found. Please log in.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'প্রোগ্রেস এক্সপোর্ট',
          style: GoogleFonts.hindSiliguri(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, 'প্রোগ্রেস এক্সপোর্ট করুন'),
            const SizedBox(height: 16),

            // Progress Report (PDF)
            _buildExportCard(
              context,
              title: 'প্রোগ্রেস রিপোর্ট (PDF)',
              description:
                  'আপনার টাইপিং স্পিড, অ্যাকুরেসি এবং অন্যান্য তথ্য সহ একটি বিস্তারিত রিপোর্ট ডাউনলোড করুন',
              icon: Icons.picture_as_pdf,
              isLoading: _isGeneratingPdf,
              onTap: () => _generateProgressReport(user),
            ),

            const SizedBox(height: 16),

            // Typing History (CSV)
            _buildExportCard(
              context,
              title: 'টাইপিং হিস্টোরি (CSV)',
              description: 'আপনার টাইপিং সেশন ডেটা CSV ফরম্যাটে ডাউনলোড করুন',
              icon: Icons.table_chart,
              isLoading: _isGeneratingCsv,
              onTap: () => _generateTypingHistoryCsv(user),
            ),

            const SizedBox(height: 16),

            // Certificate
            _buildExportCard(
              context,
              title: 'সার্টিফিকেট',
              description: 'কোর্স সম্পন্ন করার সার্টিফিকেট তৈরি করুন',
              icon: Icons.card_membership,
              isLoading: _isGeneratingCertificate,
              onTap: () => _showCertificateDialog(context, user),
            ),

            const SizedBox(height: 24),
            _buildSectionTitle(context, 'শেয়ার করুন'),
            const SizedBox(height: 16),

            // Share Achievement
            _buildExportCard(
              context,
              title: 'অর্জন শেয়ার করুন',
              description: 'আপনার টাইপিং অর্জন সোশ্যাল মিডিয়ায় শেয়ার করুন',
              icon: Icons.share,
              onTap: () => _shareAchievement(context, user),
            ),

            const SizedBox(height: 16),

            // Invite Friends
            _buildExportCard(
              context,
              title: 'বন্ধুদের আমন্ত্রণ জানান',
              description: 'বন্ধুদের BM টাইপার ব্যবহার করতে আমন্ত্রণ জানান',
              icon: Icons.people,
              onTap: () => _inviteFriends(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      title,
      style: GoogleFonts.hindSiliguri(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: colorScheme.primary,
      ),
    );
  }

  Widget _buildExportCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: isLoading
                    ? Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      )
                    : Icon(
                        icon,
                        color: colorScheme.onPrimaryContainer,
                        size: 28,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateProgressReport(user) async {
    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      final pdfBytes = await _exportService.generateProgressReportPdf(user);
      final fileName =
          'bm_typer_progress_${DateTime.now().millisecondsSinceEpoch}.pdf';

      final filePath = await _exportService.saveFile(pdfBytes, fileName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              kIsWeb
                  ? 'রিপোর্ট ডাউনলোড হয়েছে'
                  : 'রিপোর্ট সেভ হয়েছে: $filePath',
              style: GoogleFonts.hindSiliguri(),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'রিপোর্ট তৈরিতে সমস্যা হয়েছে: $e',
              style: GoogleFonts.hindSiliguri(),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
        });
      }
    }
  }

  Future<void> _generateTypingHistoryCsv(user) async {
    setState(() {
      _isGeneratingCsv = true;
    });

    try {
      final csvContent = await _exportService.generateTypingHistoryCsv(user);
      final fileName =
          'bm_typer_history_${DateTime.now().millisecondsSinceEpoch}.csv';

      final filePath = await _exportService.downloadCsv(csvContent, fileName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              kIsWeb
                  ? 'হিস্টোরি ডাউনলোড হয়েছে'
                  : 'হিস্টোরি সেভ হয়েছে: $filePath',
              style: GoogleFonts.hindSiliguri(),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'CSV তৈরিতে সমস্যা হয়েছে: $e',
              style: GoogleFonts.hindSiliguri(),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingCsv = false;
        });
      }
    }
  }

  Future<void> _showCertificateDialog(BuildContext context, user) async {
    final colorScheme = Theme.of(context).colorScheme;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'সার্টিফিকেট তৈরি করুন',
            style: GoogleFonts.hindSiliguri(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'কোর্সের নাম দিন',
                style: GoogleFonts.hindSiliguri(),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: 'কোর্সের নাম',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                controller: TextEditingController(text: _courseName),
                onChanged: (value) {
                  _courseName = value;
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'বাতিল',
                style: GoogleFonts.hindSiliguri(),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
              child: Text(
                'তৈরি করুন',
                style: GoogleFonts.hindSiliguri(),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _generateCertificate(user);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _generateCertificate(user) async {
    if (_courseName == null || _courseName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'দয়া করে কোর্সের নাম দিন',
            style: GoogleFonts.hindSiliguri(),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isGeneratingCertificate = true;
    });

    try {
      final pdfBytes =
          await _exportService.generateCertificate(user, _courseName!);
      final fileName =
          'bm_typer_certificate_${DateTime.now().millisecondsSinceEpoch}.pdf';

      final filePath = await _exportService.saveFile(pdfBytes, fileName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              kIsWeb
                  ? 'সার্টিফিকেট ডাউনলোড হয়েছে'
                  : 'সার্টিফিকেট সেভ হয়েছে: $filePath',
              style: GoogleFonts.hindSiliguri(),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'সার্টিফিকেট তৈরিতে সমস্যা হয়েছে: $e',
              style: GoogleFonts.hindSiliguri(),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingCertificate = false;
        });
      }
    }
  }

  void _shareAchievement(BuildContext context, user) {
    // For now, just show a dialog with sharing options
    // In a real app, this would integrate with platform sharing APIs

    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'অর্জন শেয়ার করুন',
          style: GoogleFonts.hindSiliguri(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'আমি BM টাইপারে ${user.averageWpm.toStringAsFixed(1)} WPM গতিতে টাইপ করতে পারি! আপনিও চেষ্টা করুন!',
              style: GoogleFonts.hindSiliguri(),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareButton(
                  context,
                  icon: Icons.facebook,
                  label: 'Facebook',
                  color: Colors.blue.shade800,
                ),
                _buildShareButton(
                  context,
                  icon: Icons.message,
                  label: 'WhatsApp',
                  color: Colors.green.shade600,
                ),
                _buildShareButton(
                  context,
                  icon: Icons.link,
                  label: 'Copy Link',
                  color: colorScheme.primary,
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'বাতিল',
              style: GoogleFonts.hindSiliguri(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$label এ শেয়ার করা হয়েছে',
              style: GoogleFonts.hindSiliguri(),
            ),
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundColor: color,
            radius: 20,
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _inviteFriends(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'বন্ধুদের আমন্ত্রণ জানান',
          style: GoogleFonts.hindSiliguri(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'আপনার বন্ধুদের সাথে BM টাইপার শেয়ার করুন এবং তাদের টাইপিং স্কিল উন্নত করতে সাহায্য করুন!',
              style: GoogleFonts.hindSiliguri(),
            ),
            const SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                hintText: 'ইমেইল ঠিকানা',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'আমন্ত্রণ পাঠানো হয়েছে',
                      style: GoogleFonts.hindSiliguri(),
                    ),
                  ),
                );
              },
              child: Text(
                'আমন্ত্রণ পাঠান',
                style: GoogleFonts.hindSiliguri(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'বাতিল',
              style: GoogleFonts.hindSiliguri(),
            ),
          ),
        ],
      ),
    );
  }
}
