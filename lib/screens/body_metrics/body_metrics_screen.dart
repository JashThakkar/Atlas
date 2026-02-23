import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/auth_provider.dart';
import '../../providers/fitness_provider.dart';
import '../../models/body_metric_model.dart';
import '../../core/constants.dart';
import 'package:intl/intl.dart';

class BodyMetricsScreen extends ConsumerStatefulWidget {
  const BodyMetricsScreen({super.key});

  @override
  ConsumerState<BodyMetricsScreen> createState() => _BodyMetricsScreenState();
}

class _BodyMetricsScreenState extends ConsumerState<BodyMetricsScreen> {
  String _selectedMetricType = 'Weight';

  void _showAddMetricDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddMetricDialog(metricType: _selectedMetricType),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Body Metrics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddMetricDialog,
          ),
        ],
      ),
      body: currentUserAsync.when(
        data: (user) {
          if (user == null) return const SizedBox();

          return Column(
            children: [
              // Metric Type Selector
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: AppConstants.bodyMetricTypes.map((type) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(type),
                        selected: _selectedMetricType == type,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedMetricType = type);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Chart
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final metricsAsync = ref.watch(
                      bodyMetricsProvider((userId: user.uid, metricType: _selectedMetricType)),
                    );

                    return metricsAsync.when(
                      data: (metrics) {
                        if (metrics.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.monitor_weight, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'No $_selectedMetricType data yet',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap + to add your first measurement',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          );
                        }

                        return Column(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: _MetricChart(metrics: metrics),
                              ),
                            ),
                            Expanded(
                              child: _MetricsList(metrics: metrics),
                            ),
                          ],
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, _) => Center(child: Text('Error: $error')),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                error.toString().contains('unavailable')
                  ? 'Connection issue. Please check your internet and try again.'
                  : 'Error loading data. Please try again.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(currentUserProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricChart extends StatelessWidget {
  const _MetricChart({required this.metrics});

  final List<BodyMetricModel> metrics;

  @override
  Widget build(BuildContext context) {
    final spots = metrics.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < metrics.length) {
                  final date = metrics[value.toInt()].date;
                  return Text(
                    DateFormat.MMMd().format(date),
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: true),
      ),
    );
  }
}

class _MetricsList extends StatelessWidget {
  const _MetricsList({required this.metrics});

  final List<BodyMetricModel> metrics;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final metric = metrics[metrics.length - 1 - index]; // Reverse order
        return Card(
          child: ListTile(
            title: Text('${metric.value} ${metric.unit}'),
            subtitle: Text(DateFormat.yMMMd().format(metric.date)),
            trailing: Icon(
              Icons.circle,
              size: 12,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      },
    );
  }
}

class _AddMetricDialog extends ConsumerStatefulWidget {
  const _AddMetricDialog({required this.metricType});

  final String metricType;

  @override
  ConsumerState<_AddMetricDialog> createState() => _AddMetricDialogState();
}

class _AddMetricDialogState extends ConsumerState<_AddMetricDialog> {
  final _valueController = TextEditingController();
  String _unit = 'kg';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add ${widget.metricType}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _valueController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Value',
              suffixText: _unit,
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'kg', label: Text('kg')),
              ButtonSegment(value: 'lbs', label: Text('lbs')),
              ButtonSegment(value: 'cm', label: Text('cm')),
            ],
            selected: {_unit},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() => _unit = newSelection.first);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            final value = double.tryParse(_valueController.text);
            if (value == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a valid number')),
              );
              return;
            }

            final user = ref.read(currentUserProvider).value;
            if (user == null) return;

            final metric = BodyMetricModel(
              userId: user.uid,
              metricType: widget.metricType,
              value: value,
              unit: _unit,
              date: DateTime.now(),
            );

            final fitnessService = ref.read(fitnessServiceProvider);
            await fitnessService.addBodyMetric(metric);

            if (context.mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Metric added successfully!')),
              );
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
