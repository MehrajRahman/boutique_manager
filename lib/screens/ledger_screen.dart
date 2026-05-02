import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:boutique_manager/providers/ledger_provider.dart';
import 'package:intl/intl.dart';

class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<LedgerProvider>();
      if (provider.hasMore && !provider.isLoading) {
        provider.loadEntries();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ledger = context.watch<LedgerProvider>();
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Ledger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ledger.loadEntries(refresh: true),
          ),
        ],
      ),
      body: ledger.entries.isEmpty && !ledger.isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 64, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text('No stock changes yet',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: theme.colorScheme.outline)),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => ledger.loadEntries(refresh: true),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount:
                    ledger.entries.length + (ledger.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == ledger.entries.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final entry = ledger.entries[index];
                  final isAdd = entry.quantityChange > 0;

                  // Show date header
                  final showDate = index == 0 ||
                      dateFormat.format(ledger.entries[index - 1].createdAt) !=
                          dateFormat.format(entry.createdAt);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showDate) ...[
                        if (index > 0) const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            dateFormat.format(entry.createdAt),
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isAdd
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                            child: Icon(
                              isAdd ? Icons.arrow_upward : Icons.arrow_downward,
                              color: isAdd ? Colors.green : Colors.red,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            entry.productName,
                            style: theme.textTheme.titleSmall,
                          ),
                          subtitle: entry.reason.isNotEmpty
                              ? Text(entry.reason,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)
                              : null,
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${isAdd ? '+' : ''}${entry.quantityChange}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: isAdd ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                timeFormat.format(entry.createdAt),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }
}
