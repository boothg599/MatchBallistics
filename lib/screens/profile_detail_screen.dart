import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/import_template.dart';
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
  CsvTemplate _template = CsvTemplate.shotView;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _confirmDelete(String subject) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm delete'),
            content: Text('Delete $subject? This cannot be undone.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
            ],
          ),
        ) ??
        false;
  }

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
    if (distance == null || elevation == null) {
      _showMessage('Enter valid numeric distance and elevation.');
      return;
    }
    if (distance <= 0 || distance > 3000) {
      _showMessage('Distance must be between 0 and 3000 yards.');
      return;
    }
    if (elevation.abs() > 100) {
      _showMessage('Elevation adjustment looks unreasonable. Please review.');
      return;
    }

    final duplicate = profile.dopePoints.any((p) => (p.distanceYards - distance).abs() < 0.001);
    if (duplicate) {
      _showMessage('A DOPE point already exists for ${_formatter.format(distance)} yards.');
      return;
    }

    double? mv;
    double? temp;
    double? pressure;
    double? humidity;
    if (profile.advancedMode) {
      if (_mvController.text.isNotEmpty) {
        mv = double.tryParse(_mvController.text);
        if (mv == null) {
          _showMessage('Enter a valid muzzle velocity.');
          return;
        }
      }
      if (_tempController.text.isNotEmpty) {
        temp = double.tryParse(_tempController.text);
        if (temp == null) {
          _showMessage('Enter a valid temperature.');
          return;
        }
      }
      if (_pressureController.text.isNotEmpty) {
        pressure = double.tryParse(_pressureController.text);
        if (pressure == null) {
          _showMessage('Enter a valid pressure.');
          return;
        }
      }
      if (_humidityController.text.isNotEmpty) {
        humidity = double.tryParse(_humidityController.text);
        if (humidity == null) {
          _showMessage('Enter a valid humidity percentage.');
          return;
        }
      }
    }

    try {
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
      _showMessage('Saved DOPE for ${_formatter.format(distance)} yards.');
    } catch (e) {
      _showMessage(e.toString());
    }
  }

  Future<void> _loadSampleCsv(BuildContext context, CsvTemplate template) async {
    try {
      final sample = await rootBundle.loadString(template.assetPath);
      _csvController.text = sample.trim();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loaded example ${template.label} CSV into form')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to load ${template.label} CSV from assets')),
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
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Import CSV'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<CsvTemplate>(
                    value: _template,
                    decoration: const InputDecoration(labelText: 'Source'),
                    items: CsvTemplate.values
                        .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                        .toList(),
                    onChanged: (val) => setModalState(() => _template = val ?? CsvTemplate.shotView),
                  ),
                  const SizedBox(height: 8),
                  if (_template == CsvTemplate.shotView) ...[
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
                  ],
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: () => _loadSampleCsv(context, _template),
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
                    decoration: InputDecoration(
                      labelText: 'Paste CSV contents',
                      hintText: 'Copy from ${_template.label} export and paste here',
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
                      ImportResult? result;
                      int added = 0;
                      if (_template == CsvTemplate.shotView) {
                        result = await provider.importShotViewCsv(
                          profileId: profile.id!,
                          csvText: _csvController.text,
                          defaultDistance: defaultDistance,
                          defaultElevation: defaultElevation,
                          markAsConfirmed: true,
                          sourceLabel: _template.sourceLabel,
                        );
                        added = result.added;
                      } else {
                        result = await provider.importBallisticsCsv(
                          profileId: profile.id!,
                          csvText: _csvController.text,
                          fallbackUnit: profile.unit,
                          sourceLabel: _template.sourceLabel,
                          markAsConfirmed: false,
                        );
                        added = result.added;
                      }
                      if (!mounted) return;
                      Navigator.pop(context);
                      final skippedText = result != null && result.skipped > 0
                          ? ' (${result.skipped} skipped)'
                          : '';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Imported $added shots from ${_template.label}$skippedText')),
                      );
                      _csvController.clear();
                      _csvDistanceController.clear();
                      _csvElevationController.clear();
                    },
                    icon: const Icon(Icons.file_upload_outlined),
                    label: const Text('Import'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Data imported from other ballistics apps is treated as unconfirmed test data until you validate it.',
                    style: TextStyle(fontSize: 12),
                  )
                ],
              ),
            ),
          );
        });
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
    if (p.source != null) {
      parts.add(p.source!);
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
                final chips = <Widget>[];
                if (!p.confirmed) {
                  chips.add(const Chip(label: Text('Unconfirmed test'), visualDensity: VisualDensity.compact));
                }
                if (p.source != null) {
                  chips.add(Chip(label: Text(p.source!), visualDensity: VisualDensity.compact));
                }
                return Card(
                  child: ListTile(
                    title: Row(
                      children: [
                        Expanded(child: Text(_formatter.format(p.distanceYards))),
                        Expanded(child: Text('${_formatter.format(p.elevation)} ${profile.unit.label}')),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (meta.isNotEmpty) Text(meta),
                        if (chips.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Wrap(spacing: 6, runSpacing: -6, children: chips),
                          ),
                      ],
                    ),
                    trailing: p.distanceYards == 100
                        ? const SizedBox(width: 24)
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!p.confirmed)
                                IconButton(
                                  tooltip: 'Mark confirmed',
                                  icon: const Icon(Icons.verified_outlined),
                                  onPressed: () => provider.confirmDopePoint(profile.id!, p),
                                ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  final ok = await _confirmDelete('${_formatter.format(p.distanceYards)} yd entry');
                                  if (ok) {
                                    await provider.deleteDopePoint(profile.id!, p.id!);
                                    if (!mounted) return;
                                    _showMessage('Deleted DOPE at ${_formatter.format(p.distanceYards)} yards.');
                                  }
                                },
                              ),
                            ],
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
                        TextButton.icon(
                          onPressed: () => _showCsvImport(provider, profile),
                          icon: const Icon(Icons.file_upload_outlined),
                          label: const Text('Import CSV'),
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
