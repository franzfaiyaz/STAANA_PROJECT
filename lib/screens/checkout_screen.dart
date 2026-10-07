import 'package:ctadmobl_project/models/user_profile.dart';
import 'package:ctadmobl_project/providers/cart_provider.dart';
import 'package:ctadmobl_project/providers/order_provider.dart';
import 'package:ctadmobl_project/screens/orders_screen.dart';
import 'package:ctadmobl_project/services/auth_service.dart';
import 'package:ctadmobl_project/widgets/app_error_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum PaymentMethod { card, gcash, cod }

extension on PaymentMethod {
  String get label => switch (this) {
    PaymentMethod.card => 'Credit/Debit Card',
    PaymentMethod.gcash => 'GCash',
    PaymentMethod.cod => 'Cash on Delivery',
  };
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _cardNumber = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();
  final _gcashNumber = TextEditingController();
  PaymentMethod _paymentMethod = PaymentMethod.card;
  bool _loading = true;
  bool _paying = false;
  String? _loadError;
  String? _submitError;
  bool _profileLoadFailed = false;

  @override
  void initState() {
    super.initState();
    _fillProfile();
  }

  Future<void> _fillProfile() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _loadError = null;
        _profileLoadFailed = false;
      });
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
        _loadError = 'Sign in to checkout.';
      });
      return;
    }
    try {
      final UserProfile? profile = await context
          .read<AuthService>()
          .watchProfile(user.uid)
          .first;
      if (profile != null) {
        _name.text = profile.name;
        _phone.text = profile.phone;
        _address.text = profile.address;
      }
    } catch (error) {
      debugPrint('Unable to load saved checkout profile: $error');
      _loadError = appErrorMessage;
      _profileLoadFailed = true;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    final cart = context.read<CartProvider>();
    if (user == null || cart.items.isEmpty) {
      setState(() => _submitError = 'Sign in and add an item before checkout.');
      return;
    }
    final orderProvider = context.read<OrderProvider>();
    final navigator = Navigator.of(context);
    final paymentMethod = _paymentMethod;
    final shippingAddress =
        '${_name.text.trim()}\n${_phone.text.trim()}\n${_address.text.trim()}';

    setState(() {
      _paying = true;
      _submitError = null;
    });
    try {
      await Future<void>.delayed(const Duration(seconds: 2));
      final orderId = await orderProvider.createOrder(
        uid: user.uid,
        items: cart.items.map((item) => item.toMap()).toList(),
        total: cart.total,
        paymentMethod: paymentMethod.label,
        status: paymentMethod == PaymentMethod.cod ? 'Pending (COD)' : 'Paid',
        shippingAddress: shippingAddress,
      );
      await cart.clear();
      if (!mounted) return;
      await navigator.pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => OrderSuccessScreen(
            orderId: orderId,
            paymentMethod: paymentMethod.label,
          ),
        ),
      );
    } catch (error) {
      debugPrint('Unable to place order: $error');
      if (mounted) setState(() => _submitError = appErrorMessage);
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _cardNumber.dispose();
    _expiry.dispose();
    _cvv.dispose();
    _gcashNumber.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? _profileLoadFailed
                ? AppErrorState(onRetry: _fillProfile)
                : Center(child: Text(_loadError!))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'Shipping information',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _requiredField(_name, 'Full name'),
                  const SizedBox(height: 12),
                  _requiredField(
                    _phone,
                    'Phone number',
                    keyboardType: TextInputType.phone,
                    minLength: 7,
                  ),
                  const SizedBox(height: 12),
                  _requiredField(_address, 'Shipping address', maxLines: 3),
                  const SizedBox(height: 24),
                  Text(
                    'Demo payment',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  RadioGroup<PaymentMethod>(
                    groupValue: _paymentMethod,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _paymentMethod = value);
                      }
                    },
                    child: Column(
                      children: PaymentMethod.values
                          .map(
                            (method) => RadioListTile<PaymentMethod>(
                              contentPadding: EdgeInsets.zero,
                              title: Text(method.label),
                              value: method,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  if (_paymentMethod == PaymentMethod.card) ...[
                    const SizedBox(height: 8),
                    _requiredField(
                      _cardNumber,
                      'Demo card number',
                      keyboardType: TextInputType.number,
                      minLength: 12,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _requiredField(_expiry, 'MM/YY', minLength: 4),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _requiredField(
                            _cvv,
                            'CVV',
                            keyboardType: TextInputType.number,
                            minLength: 3,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (_paymentMethod == PaymentMethod.gcash) ...[
                    const SizedBox(height: 8),
                    _requiredField(
                      _gcashNumber,
                      'GCash mobile number',
                      keyboardType: TextInputType.phone,
                      minLength: 7,
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text('Total: \$${cart.total.toStringAsFixed(2)}'),
                  if (_submitError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _submitError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _paying ? null : _placeOrder,
                        child: const Text('Retry'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _paying ? null : _placeOrder,
                      child: Text(
                        _paying ? 'Processing demo payment...' : 'Pay Now',
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _requiredField(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    int minLength = 1,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
      validator: (value) => value == null || value.trim().length < minLength
          ? 'Enter a valid ${label.toLowerCase()}'
          : null,
    );
  }
}

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({
    required this.orderId,
    required this.paymentMethod,
    super.key,
  });

  final String orderId;
  final String paymentMethod;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 56,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                'Order placed!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text('Order reference: $orderId'),
              const SizedBox(height: 8),
              Text('Payment method: $paymentMethod'),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute<void>(
                      builder: (_) => const OrdersScreen(),
                    ),
                    (route) => route.isFirst,
                  ),
                  child: const Text('View orders'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
