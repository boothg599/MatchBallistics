import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Empirical Dope'),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
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
                          onPressed: () => provider.deleteProfile(profile.id!),
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
