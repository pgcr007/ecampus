// lib/screens/technews/add_tech_news_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/news_article_model.dart';
import '../../models/tech_news_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tech_news_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/department_utils.dart';

/// Teacher/Admin-only. Curate-and-publish flow: pick a department, pull
/// live articles from NewsApiService, select which ones to publish,
/// they get written into Firestore's tech_news collection tagged with
/// that department. Falls back to a manual entry form if the News API
/// key isn't configured or a fetch fails — same graceful-degradation
/// spirit as GeminiService.isConfigured in Phase 10.
class AddTechNewsScreen extends ConsumerStatefulWidget {
  const AddTechNewsScreen({super.key});

  @override
  ConsumerState<AddTechNewsScreen> createState() => _AddTechNewsScreenState();
}

class _AddTechNewsScreenState extends ConsumerState<AddTechNewsScreen> {
  String _department = DepartmentUtils.all.first;
  bool _loading = false;
  bool _publishing = false;
  String? _error;
  List<NewsArticle> _articles = [];
  final Set<int> _selected = {};

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
      _articles = [];
      _selected.clear();
    });
    try {
      final articles = await ref.read(newsApiServiceProvider).fetchTechNews(department: _department);
      setState(() => _articles = articles);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _publishSelected() async {
    final user = ref.read(userProfileProvider).valueOrNull;
    if (user == null || _selected.isEmpty) return;

    setState(() => _publishing = true);
    try {
      for (final index in _selected) {
        final a = _articles[index];
        await ref.read(techNewsServiceProvider).publish(
              TechNewsModel(
                id: '',
                title: a.title,
                description: a.description,
                url: a.url,
                imageUrl: a.imageUrl,
                sourceName: a.sourceName,
                department: _department,
                postedBy: user.uid,
                postedByName: user.name,
                timestamp: null,
              ),
            );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Published ${_selected.length} article(s) to $_department.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to publish: $e')));
      }
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  Future<void> _openManualEntry() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final urlController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Manual Entry'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  minLines: 2,
                  maxLines: 4,
                ),
                TextFormField(
                  controller: urlController,
                  decoration: const InputDecoration(labelText: 'Link (optional)'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Publish'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final user = ref.read(userProfileProvider).valueOrNull;
    if (user == null) return;

    try {
      await ref.read(techNewsServiceProvider).publish(
            TechNewsModel(
              id: '',
              title: titleController.text.trim(),
              description: descController.text.trim(),
              url: urlController.text.trim(),
              imageUrl: '',
              sourceName: 'Manual entry',
              department: _department,
              postedBy: user.uid,
              postedByName: user.name,
              timestamp: null,
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Published.')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to publish: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Post Tech News'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded),
            tooltip: 'Manual entry',
            onPressed: _openManualEntry,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _department,
                    decoration: const InputDecoration(labelText: 'Fetch news for', border: OutlineInputBorder(), isDense: true),
                    items: DepartmentUtils.all
                        .map((d) => DropdownMenuItem(value: d, child: Text(d, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) => setState(() => _department = v!),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _loading ? null : _fetch,
                  icon: _loading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.refresh_rounded),
                  label: const Text('Fetch'),
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                child: Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
              ),
            ),
          Expanded(
            child: _articles.isEmpty
                ? Center(
                    child: Text(
                      _loading ? 'Fetching articles...' : 'Tap "Fetch" to pull live tech news for this department.',
                      style: const TextStyle(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: _articles.length,
                    itemBuilder: (context, index) {
                      final a = _articles[index];
                      final isSelected = _selected.contains(index);
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (v) => setState(() {
                          if (v == true) {
                            _selected.add(index);
                          } else {
                            _selected.remove(index);
                          }
                        }),
                        title: Text(a.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Text(a.sourceName, style: const TextStyle(fontSize: 12)),
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _articles.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: (_selected.isEmpty || _publishing) ? null : _publishSelected,
                    style: FilledButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: _publishing
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text('Publish ${_selected.length} Selected'),
                  ),
                ),
              ),
            ),
    );
  }
}