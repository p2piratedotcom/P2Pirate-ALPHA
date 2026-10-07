import 'package:flutter/material.dart';
import 'mm_engine_amount.dart';

class MmEngineSharedCoverage extends StatelessWidget {
  const MmEngineSharedCoverage(
    this.snapshot, {
    this.confirmed = true,
    super.key,
  });
  final Map snapshot;
  final bool confirmed;
  @override
  Widget build(BuildContext context) {
    final assets = (snapshot['assets'] as List? ?? const [])
        .whereType<Map>()
        .toList();
    if (assets.isEmpty) return const SizedBox.shrink();
    final fresh = confirmed && snapshot['lease_fresh'] == true;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: const Text('Shared hedge coverage'),
        subtitle: Text(
          fresh
              ? 'Existing older makers retain priority. Automatic quantities may shrink; fixed makers are withdrawn when required.'
              : 'Awaiting verified CEX balances. Unknown is not zero.',
        ),
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Reservations include maker UUIDs, uncertain publications/updates and unsettled hedge inventory. Makers without hedging do not reserve CEX funds. Wallet funds remain shared by every maker.',
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Asset / CEX')),
                DataColumn(label: Text('Free')),
                DataColumn(label: Text('Committed')),
                DataColumn(label: Text('Uncommitted')),
                DataColumn(label: Text('Missing')),
              ],
              rows: [
                for (final row in assets)
                  DataRow(
                    cells: [
                      DataCell(
                        Text(
                          '${row['asset']}'.contains(':')
                              ? '${row['asset']}'
                              : 'MEXC · ${row['asset']}',
                        ),
                      ),
                      DataCell(MmEngineAmount(fresh ? row['free'] : null)),
                      DataCell(MmEngineAmount(row['required'])),
                      DataCell(
                        MmEngineAmount(fresh ? row['uncommitted'] : null),
                      ),
                      DataCell(MmEngineAmount(fresh ? row['missing'] : null)),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
