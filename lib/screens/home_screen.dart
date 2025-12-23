import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/import_template.dart';
import '../models/profile.dart';
import '../services/profile_provider.dart';
import 'profile_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _nameController = TextEditingController();
  ElevationUnit _unit = ElevationUnit.mil;
  bool _advanced = false;

  Future<bool> _confirmDelete(String subject) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm delete'),
            content: Text('Delete "$subject"? This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showCreateProfileDialog(ProfileProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ElevationUnit>(
                value: _unit,
                decoration: const InputDecoration(labelText: 'Units'),
                items: ElevationUnit.values
                    .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                    .toList(),
                onChanged: (val) => setState(() => _unit = val ?? ElevationUnit.mil),
              ),
              SwitchListTile(
                value: _advanced,
                onChanged: (val) => setState(() => _advanced = val),
                title: const Text('Advanced mode (MV + environmentals)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = _nameController.text.trim();
                if (name.isEmpty) return;
                await provider.addProfile(name, _unit, advanced: _advanced);
                _nameController.clear();
                setState(() => _advanced = false);
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _showImportProfileSheet(ProfileProvider provider) {
    final nameController = TextEditingController();
    final csvController = TextEditingController();
    CsvTemplate template = CsvTemplate.geoBallistics;
    ElevationUnit unit = _unit;
    bool advanced = false;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Import profile from CSV', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Profile name'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<ElevationUnit>(
                    value: unit,
                    decoration: const InputDecoration(labelText: 'Units'),
                    items: ElevationUnit.values
                        .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                        .toList(),
                    onChanged: (val) => setModalState(() => unit = val ?? ElevationUnit.mil),
                  ),
                  SwitchListTile(
                    value: advanced,
                    onChanged: (val) => setModalState(() => advanced = val),
                    title: const Text('Advanced mode (MV + environmentals)'),
                  ),
                  DropdownButtonFormField<CsvTemplate>(
                    value: template,
                    decoration: const InputDecoration(labelText: 'Import source'),
                    items: CsvTemplate.values
                        .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                        .toList(),
                    onChanged: (val) => setModalState(() => template = val ?? CsvTemplate.geoBallistics),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          try {
                            final sample = await rootBundle.loadString(template.assetPath);
                            csvController.text = sample.trim();
                          } catch (_) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Unable to load ${template.label} sample CSV')),
                            );
                          }
                        },
                        icon: const Icon(Icons.file_download_outlined),
                        label: const Text('Load example'),
                      ),
                      TextButton.icon(
                        onPressed: () => csvController.clear(),
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: csvController,
                    decoration: InputDecoration(
                      labelText: 'Paste CSV contents',
                      hintText: 'Paste ${template.label} export here',
                      alignLabelWithHint: true,
                    ),
                    maxLines: 8,
                    keyboardType: TextInputType.multiline,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty || csvController.text.trim().isEmpty) return;
                      final profileId = await provider.addProfile(name, unit, advanced: advanced);
                      int added = 0;
                      ImportResult? result;
                      if (template == CsvTemplate.shotView) {
                        result = await provider.importShotViewCsv(
                          profileId: profileId,
                          csvText: csvController.text,
                          defaultDistance: 100,
                          defaultElevation: 0,
                          sourceLabel: template.sourceLabel,
                        );
                        added = result.added;
                      } else {
                        result = await provider.importBallisticsCsv(
                          profileId: profileId,
                          csvText: csvController.text,
                          fallbackUnit: unit,
                          sourceLabel: template.sourceLabel,
                        );
                        added = result.added;
                      }

                      if (!mounted) return;
                      Navigator.pop(context);
                      final skippedText = result.skipped > 0
                          ? ' (${result.skipped} skipped)'
                          : '';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Created $name with $added imported points$skippedText')),
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfileDetailScreen(profileId: profileId),
                        ),
                      );
                    },
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Create from CSV'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Imports from other ballistics apps are marked unconfirmed until you validate them on the range.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Empirical Dope'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'Import profile from CSV',
            onPressed: () => _showImportProfileSheet(provider),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(provider.error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: provider.loadProfiles,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : provider.profiles.isEmpty
                  ? const Center(child: Text('No profiles yet. Add one to get started.'))
                  : ListView.builder(
                      itemCount: provider.profiles.length,
                      itemBuilder: (context, index) {
                        final profile = provider.profiles[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: ListTile(
                            title: Text(profile.name),
                            subtitle: Text('${profile.unit.label} • ${profile.dopePoints.length} DOPE points'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                final ok = await _confirmDelete(profile.name);
                                if (ok) {
                                  await provider.deleteProfile(profile.id!);
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Deleted profile ${profile.name}')),
                                  );
                                }
                              },
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProfileDetailScreen(profileId: profile.id!),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateProfileDialog(provider),
        icon: const Icon(Icons.add),
        label: const Text('Profile'),
      ),
    );
  }
}
