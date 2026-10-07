import 'package:ctadmobl_project/models/shop_order.dart';
import 'package:ctadmobl_project/providers/order_provider.dart';
import 'package:ctadmobl_project/widgets/app_error_state.dart';
import 'package:ctadmobl_project/widgets/product_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  int _streamKey = 0;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: uid == null
          ? const Center(child: Text('Sign in to view orders.'))
          : StreamBuilder<List<ShopOrder>>(
              key: ValueKey(_streamKey),
              stream: context.read<OrderProvider>().watchOrders(uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  debugPrint('Unable to load orders: ${snapshot.error}');
                  return AppErrorState(
                    onRetry: () => setState(() => _streamKey++),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final orders = snapshot.data ?? const <ShopOrder>[];
                if (orders.isEmpty) {
                  return const Center(child: Text('No orders yet.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: orders.length,
                  separatorBuilder: (_, _) => const Divider(height: 20),
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Order ${order.id.substring(0, 6)}'),
                      subtitle: Text(
                        '${order.paymentMethod} · ${order.status}\n'
                        '${MaterialLocalizations.of(context).formatShortDate(order.createdAt)}',
                      ),
                      isThreeLine: true,
                      trailing: Text('\$${order.total.toStringAsFixed(2)}'),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => OrderDetailScreen(order: order),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({required this.order, super.key});
  final ShopOrder order;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Order details')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Order ${order.id}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text('Status: ${order.status}'),
        Text('Payment: ${order.paymentMethod}'),
        Text('Shipping address:\n${order.shippingAddress}'),
        const Divider(height: 32),
        Text('Items', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        if (order.items.isEmpty) const Text('No item details for this order.'),
        ...order.items.map(
          (item) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 56,
                height: 56,
                child: ProductImage(value: item.thumbnail),
              ),
            ),
            title: Text(item.title),
            subtitle: Text('EU ${item.size} · Quantity ${item.quantity}'),
            trailing: Text(
              '\$${(item.price * item.quantity).toStringAsFixed(2)}',
            ),
          ),
        ),
        const Divider(height: 32),
        Row(
          children: [
            const Text('Total'),
            const Spacer(),
            Text('\$${order.total.toStringAsFixed(2)}'),
          ],
        ),
      ],
    ),
  );
}
