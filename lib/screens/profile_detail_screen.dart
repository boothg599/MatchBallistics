import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/dope_point.dart';
import '../models/profile.dart';
import '../services/profile_provider.dart';
import '../utils/dope_calculator.dart';
import '../widgets/dope_card_table.dart';

class ProfileDetailScreen extends StatefulWidget {
  final int profileId;
  const ProfileDetailScreen({super.key, required this.profileId});

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  final _distanceController = TextEditingController();
  final _elevationController = TextEditingController();
  final _mvController = TextEditingController();
  final _tempController = TextEditingController();
  final _pressureController = TextEditingController();
  final _humidityController = TextEditingController();
  final _targetController = TextEditingController();
  final _angleController = TextEditingController();
  final _csvController = TextEditingController();
  final _csvDistanceController = TextEditingController();
  final _csvElevationController = TextEditingController();
  final _formatter = NumberFormat('##0.00');
  String? _prediction;
  String? _cosine;

  @override
  void dispose() {
    _distanceController.dispose();
    _elevationController.dispose();
    _mvController.dispose();
    _tempController.dispose();
    _pressureController.dispose();
    _humidityController.dispose();
    _targetController.dispose();
    _angleController.dispose();
    _csvController.dispose();
    _csvDistanceController.dispose();
    _csvElevationController.dispose();
    super.dispose();
  }

  void _addDope(ProfileProvider provider, Profile profile) async {
    final distance = double.tryParse(_distanceController.text);
    final elevation = double.tryParse(_elevationController.text);
    if (distance == null || elevation == null) return;
    final mv = profile.advancedMode ? double.tryParse(_mvController.text) : null;
    final temp = profile.advancedMode ? double.tryParse(_tempController.text) : null;
    final pressure = profile.advancedMode ? double.tryParse(_pressureController.text) : null;
    final humidity = profile.advancedMode ? double.tryParse(_humidityController.text) : null;
    await provider.addDopePoint(
      profile.id!,
      distance,
      elevation,
      muzzleVelocity: mv,
      temperatureF: temp,
      pressureInHg: pressure,
      humidityPercent: humidity,
    );
    _distanceController.clear();
    _elevationController.clear();
    _mvController.clear();
    _tempController.clear();
    _pressureController.clear();
    _humidityController.clear();
  }

  Future<void> _loadSampleCsv(BuildContext context) async {
    try {
      final sample = await rootBundle.loadString('assets/shotview_example.csv');
      _csvController.text = sample.trim();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Loaded sample ShotView export into form')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load sample CSV from assets')),
      );
    }
  }

  void _predict(ProfileProvider provider, Profile profile) {
    final distance = double.tryParse(_targetController.text);
    if (distance == null) return;
    final value = provider.predict(profile, distance);
    setState(() {
      _prediction = '${_formatter.format(value)} ${profile.unit.label}';
    });
  }

  void _computeCosine() {
    final angle = double.tryParse(_angleController.text);
    if (angle == null) return;
    final mult = DopeCalculator.cosineMultiplier(angle);
    setState(() {
      _cosine = _formatter.format(mult);
    });
  }

  Future<void> _showCsvImport(ProfileProvider provider, Profile profile) async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Import ShotView CSV'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _csvDistanceController,
                        decoration: const InputDecoration(labelText: 'Default distance (yd)'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _csvElevationController,
                        decoration: InputDecoration(labelText: 'Default elevation (${profile.unit.label})'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: () => _loadSampleCsv(context),
                      icon: const Icon(Icons.file_download_outlined),
                      label: const Text('Load example CSV'),
                    ),
                    TextButton.icon(
                      onPressed: () => _csvController.clear(),
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _csvController,
                  decoration: const InputDecoration(
                    labelText: 'Paste CSV contents',
                    hintText: 'Copy from Garmin ShotView export and paste here',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 8,
                  keyboardType: TextInputType.multiline,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    final defaultDistance = double.tryParse(_csvDistanceController.text);
                    final defaultElevation = double.tryParse(_csvElevationController.text);
                    final added = await provider.importShotViewCsv(
                      profileId: profile.id!,
                      csvText: _csvController.text,
                      defaultDistance: defaultDistance,
                      defaultElevation: defaultElevation,
                    );
                    if (!mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Imported $added shots from CSV')),
                    );
                    _csvController.clear();
                    _csvDistanceController.clear();
                    _csvElevationController.clear();
                  },
                  icon: const Icon(Icons.file_upload_outlined),
                  label: const Text('Import'),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  String _metaForPoint(DopePoint p) {
    final parts = <String>[];
    if (p.muzzleVelocity != null) {
      parts.add('MV ${_formatter.format(p.muzzleVelocity!)} fps');
    }
    if (p.temperatureF != null) {
      parts.add('Temp ${_formatter.format(p.temperatureF!)}°F');
    }
    if (p.pressureInHg != null) {
      parts.add('Pressure ${_formatter.format(p.pressureInHg!)} inHg');
    }
    if (p.humidityPercent != null) {
      parts.add('Humidity ${_formatter.format(p.humidityPercent!)}%');
    }
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final profile = provider.getProfileById(widget.profileId);
    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Profile missing')),
      );
    }
    final points = [...profile.dopePoints]..sort((a, b) => a.distanceYards.compareTo(b.distanceYards));

    return Scaffold(
      appBar: AppBar(
        title: Text(profile.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_vert_circle_outlined),
            tooltip: 'Toggle units',
            onPressed: () async {
              final newUnit = profile.unit == ElevationUnit.mil ? ElevationUnit.moa : ElevationUnit.mil;
              final updated = profile.copyWith(unit: newUnit);
              await provider.updateProfile(updated);
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              value: profile.advancedMode,
              onChanged: (val) => provider.setAdvancedMode(profile, val),
              title: const Text('Advanced mode'),
              subtitle: const Text('Capture muzzle velocity and environmentals per shot'),
            ),
            const Text('Known DOPE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                title: Row(
                  children: const [
                    Expanded(child: Text('Distance (yd)')),
                    Expanded(child: Text('Elevation')),
                    SizedBox(width: 40),
                  ],
                ),
              ),
            ),
            ...points.map(
              (p) {
                final meta = _metaForPoint(p);
                return Card(
                  child: ListTile(
                    title: Row(
                      children: [
                        Expanded(child: Text(_formatter.format(p.distanceYards))),
                        Expanded(child: Text('${_formatter.format(p.elevation)} ${profile.unit.label}')),
                      ],
                    ),
                    subtitle: meta.isEmpty ? null : Text(meta),
                    trailing: p.distanceYards == 100
                        ? const SizedBox(width: 24)
                        : IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => provider.deleteDopePoint(profile.id!, p.id!),
                          ),
                  ),
                );
              },
            ),
            if (points.length < 2)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('Add more DOPE points beyond 100 yd for better predictions.'),
              ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Add DOPE'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _distanceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Distance (yd)'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _elevationController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(labelText: 'Elevation (${profile.unit.label})'),
                          ),
                        ),
                      ],
                    ),
                    if (profile.advancedMode) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _mvController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Muzzle velocity (fps)'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _tempController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Temperature (°F)'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _pressureController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Pressure (inHg)'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _humidityController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Humidity (%)'),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: () => _addDope(provider, profile),
                          child: const Text('Save'),
                        ),
                        if (profile.advancedMode)
                          TextButton.icon(
                            onPressed: () => _showCsvImport(provider, profile),
                            icon: const Icon(Icons.file_upload_outlined),
                            label: const Text('Import ShotView CSV'),
                          )
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Predict'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _targetController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Target distance (yd)'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _predict(provider, profile),
                          child: const Text('Calculate'),
                        ),
                      ],
                    ),
                    if (_prediction != null) ...[
                      const SizedBox(height: 8),
                      Text('Elevation: $_prediction'),
                    ]
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cosine calculator'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _angleController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Angle (degrees)'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _computeCosine,
                          child: const Text('Compute'),
                        ),
                      ],
                    ),
                    if (_cosine != null) ...[
                      const SizedBox(height: 8),
                      Text('Multiplier: $_cosine'),
                    ]
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            DopeCardTable(profile: profile),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                'Windage learning is planned as a future update. Track elevation now and add wind holds later.',
              ),
            )
          ],
        ),
      ),
    );
  }
}
