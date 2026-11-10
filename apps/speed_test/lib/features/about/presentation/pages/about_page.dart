import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Static information about the speed test: what it measures, how it works,
/// and what happens to the data.
class AboutPage extends StatelessWidget {
  /// Creates the page.
  const new({super.key});

  /// The displayed version. Keep in sync with `pubspec.yaml`.
  static const String version = '1.0.0';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppScaffold(
      title: 'About',
      leading: BackButton(onPressed: () => Navigator.of(context).maybePop()),
      body: ListView(
        key: const Key('about-list'),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.speed,
                    size: 40,
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 16),
                Text('Speed Test', style: context.text.emphasisLarge),
                const SizedBox(height: 4),
                Text(
                  'Version $version',
                  style: context.text.scale.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'A Material 3 Expressive network speed test for Linux, built '
                  'on the shared workspace. Not affiliated with Netflix; '
                  'Fast.com is used only to measure the connection.',
                  textAlign: TextAlign.center,
                  style: context.text.scale.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('How a test works', style: context.text.emphasisMedium),
                const SizedBox(height: 12),
                const _StepRow(
                  number: '1',
                  title: 'Ping and jitter',
                  message:
                      'A short round trip warms the TLS connection, '
                      'then several timed requests report the median '
                      'latency and the average variation between samples.',
                ),
                const _StepRow(
                  number: '2',
                  title: 'Download',
                  message:
                      'Several parallel ranged requests fetch the selected '
                      'amount of data from the nearest server while combined '
                      'throughput is sampled every 100 ms. Ramp-up samples are '
                      'discarded.',
                ),
                const _StepRow(
                  number: '3',
                  title: 'Upload',
                  message:
                      'A random payload is written to the endpoint at the pace '
                      'the socket accepts, measured the same way.',
                ),
                const _StepRow(
                  number: '4',
                  title: 'Save',
                  message:
                      'The averages, ping, jitter, and server details are '
                      'stored on this device, newest first.',
                  last: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Under the hood', style: context.text.emphasisMedium),
                const SizedBox(height: 12),
                const _FeatureRow(
                  icon: Icons.cloud_outlined,
                  title: 'Fast.com and Netflix Open Connect',
                  message:
                      'The app asks Fast.com for nearby Netflix Open Connect '
                      'appliances, probes them, and keeps the lowest-latency '
                      'one. If that bootstrap fails, Cloudflare takes over.',
                ),
                const _FeatureRow(
                  icon: Icons.timer_outlined,
                  title: 'Real transfers',
                  message:
                      'Speeds come from actual bytes moving over the socket, '
                      'not from estimates or cached values.',
                ),
                const _FeatureRow(
                  icon: Icons.palette_outlined,
                  title: 'Shared design system',
                  message:
                      'Colors, type, shapes, and motion all come from '
                      'design_system; the app hardcodes none of them.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, size: 20, color: colors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Privacy', style: context.text.emphasisSmall),
                      const SizedBox(height: 4),
                      Text(
                        'No account is required and no analytics are sent. '
                        'Fast.com, Netflix, and the fallback Cloudflare '
                        'network necessarily see the test traffic and your '
                        'public IP; results and preferences stay in this '
                        "device's local store.",
                        style: context.text.scale.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: EdgeInsets.zero,
            child: AppListTile(
              title: 'Open-source licenses',
              subtitle: 'Packages bundled with this app',
              leadingIcon: Icons.description_outlined,
              trailing: const Icon(Icons.open_in_new),
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'Speed Test',
                applicationVersion: version,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const new({
    required this.number,
    required this.title,
    required this.message,
    this.last = false,
  });

  final String number;
  final String title;
  final String message;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: context.text.scale.labelMedium?.copyWith(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.emphasisSmall),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: context.text.scale.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const new({required this.icon, required this.title, required this.message});

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.emphasisSmall),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: context.text.scale.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
