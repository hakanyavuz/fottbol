import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../services/health_check_service.dart';

/// Veri Hatları Canlı Sağlık ve Kesintisiz Akış Durum Rozeti
class ServiceHealthBadge extends StatelessWidget {
  const ServiceHealthBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, ServiceHealthReport>>(
      stream: HealthCheckService.stream,
      initialData: HealthCheckService.reports,
      builder: (context, snapshot) {
        final reports = snapshot.data ?? {};
        if (reports.isEmpty) return const SizedBox.shrink();

        final hasDown = reports.values.any((r) => r.status == ServiceHealthStatus.down);
        final hasMirror = reports.values.any((r) => r.status == ServiceHealthStatus.mirrorActive);

        final Color dotColor = hasDown
            ? Colors.orangeAccent
            : (hasMirror ? Colors.amberAccent : Colors.greenAccent);

        final String labelText = hasDown
            ? 'Bazı Hatlar Yedekte'
            : (hasMirror ? 'Yedek Ayna Devrede' : 'Kotasız Canlı Hatlar Aktif');

        return InkWell(
          onTap: () => _showHealthDetailsDialog(context, reports),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: dotColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: dotColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: dotColor.withValues(alpha: 0.6), blurRadius: 4, spreadRadius: 1),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  labelText,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: dotColor),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showHealthDetailsDialog(
    BuildContext context,
    Map<String, ServiceHealthReport> reports,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161922),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.hub_outlined, color: AppColors.premiumGold, size: 22),
                  const SizedBox(width: 10),
                  const Text(
                    'Veri Hatları Sağlık Raporu',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 18, color: Colors.white70),
                    tooltip: 'Yeniden Yokla',
                    onPressed: () {
                      HealthCheckService.probeAll();
                      Navigator.of(ctx).pop();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Program açılışında tüm kotasız servisler test edilir; bir hat yanıt vermezse otomatik sigorta devreye girer.',
                style: TextStyle(fontSize: 11.5, color: Colors.white60),
              ),
              const SizedBox(height: 16),
              ...reports.values.map((rep) {
                final statusColor = rep.status == ServiceHealthStatus.healthy
                    ? Colors.greenAccent
                    : (rep.status == ServiceHealthStatus.mirrorActive
                        ? Colors.amberAccent
                        : (rep.status == ServiceHealthStatus.degraded ? Colors.orangeAccent : Colors.redAccent));

                final statusLabel = rep.status == ServiceHealthStatus.healthy
                    ? 'Aktif (Birincil)'
                    : (rep.status == ServiceHealthStatus.mirrorActive
                        ? 'Yedek Ayna Devrede'
                        : (rep.status == ServiceHealthStatus.degraded ? 'Yavaş' : 'Kapalı'));

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        rep.status == ServiceHealthStatus.healthy
                            ? Icons.check_circle_outline
                            : (rep.status == ServiceHealthStatus.mirrorActive
                                ? Icons.sync_problem
                                : Icons.error_outline),
                        color: statusColor,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rep.providerName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              rep.activeUrl,
                              style: const TextStyle(fontSize: 10.5, color: Colors.white38),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            statusLabel,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                          ),
                          Text(
                            '${rep.latencyMs} ms',
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
