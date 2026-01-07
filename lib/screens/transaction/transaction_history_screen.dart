import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../models/transaction.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/custom_app_bar.dart';
import 'transaction_detail_screen.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Start listening to transactions after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startListening();
    });
  }

  void _startListening() {
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    if (user != null) {
      Provider.of<TransactionProvider>(context, listen: false)
          .startListening(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final currentUser = userProvider.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        appBar: CustomAppBar(
          title: 'Transaction History',
          showBackButton: true,
        ),
        body: Center(child: Text('Please log in to view transactions')),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Transaction History',
        showBackButton: true,
      ),
      body: Column(
        children: [
          // Filter Section
          _buildFilterSection(transactionProvider),

          // Transaction List
          Expanded(
            child: _buildTransactionList(transactionProvider, currentUser.uid),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(TransactionProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Type Filter
          Expanded(
            child: DropdownButtonFormField<String>(
              value: provider.selectedTypeFilter ?? '',
              decoration: const InputDecoration(
                labelText: 'Type',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
              items: TransactionProvider.typeOptions.map((option) {
                return DropdownMenuItem(
                  value: option['value'],
                  child: Text(
                    option['label']!,
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (value) => provider.setTypeFilter(value),
            ),
          ),
          const SizedBox(width: 12),
          // Status Filter
          Expanded(
            child: DropdownButtonFormField<String>(
              value: provider.selectedStatusFilter ?? '',
              decoration: const InputDecoration(
                labelText: 'Status',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
              items: TransactionProvider.statusOptions.map((option) {
                return DropdownMenuItem(
                  value: option['value'],
                  child: Text(
                    option['label']!,
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (value) => provider.setStatusFilter(value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(
      TransactionProvider provider, String currentUserId) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              provider.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _startListening,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final transactions = provider.filteredTransactions;

    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No transactions yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your job applications, service bookings,\nand rental requests will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _startListening();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          return _buildTransactionCard(transactions[index], currentUserId);
        },
      ),
    );
  }

  Widget _buildTransactionCard(
      TransactionModel transaction, String currentUserId) {
    final isInitiator = transaction.initiatedBy == currentUserId;
    final otherPartyName = isInitiator
        ? (transaction.targetUserName ?? 'Loading...')
        : (transaction.initiatedByName ?? 'Loading...');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  TransactionDetailScreen(transaction: transaction),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Type Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getTypeColor(transaction.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getTypeIcon(transaction.type),
                  color: _getTypeColor(transaction.type),
                ),
              ),
              const SizedBox(width: 16),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.relatedName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          isInitiator ? Icons.arrow_forward : Icons.arrow_back,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${isInitiator ? "To" : "From"}: $otherPartyName',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(transaction.createdAt),
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Amount & Status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (transaction.transactionAmount > 0)
                    Text(
                      '${kCurrencySymbol}${transaction.transactionAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: kPrimaryColor,
                      ),
                    ),
                  const SizedBox(height: 8),
                  _buildStatusBadge(transaction.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'Pending':
        bgColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange[700]!;
        break;
      case 'Accepted':
        bgColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue[700]!;
        break;
      case 'In Progress':
        bgColor = Colors.purple.withOpacity(0.1);
        textColor = Colors.purple[700]!;
        break;
      case 'Completed':
        bgColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green[700]!;
        break;
      case 'Cancelled':
        bgColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red[700]!;
        break;
      default:
        bgColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'job_application':
        return Icons.work_outline;
      case 'service_booking':
        return Icons.build_outlined;
      case 'rental_request':
        return Icons.handyman_outlined;
      default:
        return Icons.receipt_long;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'job_application':
        return Colors.blue;
      case 'service_booking':
        return Colors.orange;
      case 'rental_request':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
