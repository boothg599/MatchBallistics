import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/profile.dart';
import '../services/profile_provider.dart';

class DopeCardTable extends StatelessWidget {
  final Profile profile;
  final double start;
  final double end;
  final double step;
  DopeCardTable({super.key, required this.profile, this.start = 100, this.end = 1200, this.step = 50});

  final _formatter = NumberFormat('##0.00');

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ProfileProvider>();
    final entries = provider.dopeCard(profile, start: start, end: end, step: step);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Dope card'),
                Text('Step ${step.toInt()} yd'),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 300,
              child: ListView.separated(
                itemCount: entries.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Expanded(child: Text(_formatter.format(entry['distance']))),
                        Expanded(child: Text('${_formatter.format(entry['elevation'])} ${profile.unit.label}')),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
