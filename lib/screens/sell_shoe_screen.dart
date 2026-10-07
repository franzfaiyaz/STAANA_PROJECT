import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctadmobl_project/models/listing.dart';
import 'package:ctadmobl_project/providers/listing_provider.dart';
import 'package:ctadmobl_project/services/auth_service.dart';
import 'package:ctadmobl_project/widgets/product_image.dart';
import 'package:ctadmobl_project/widgets/app_error_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class SellShoeScreen extends StatefulWidget {
  const SellShoeScreen({super.key});

  @override
  State<SellShoeScreen> createState() => _SellShoeScreenState();
}

class _SellShoeScreenState extends State<SellShoeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _brand = TextEditingController();
  final _picker = ImagePicker();
  XFile? _photo;
  List<int>? _photoBytes;
  String _category = 'Men';
  final Set<int> _sizes = {};
  String? _error;
  Future<void> Function()? _retry;
  bool _busy = false;

  Future<void> _pickPhoto() async {
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        imageQuality: 60,
      );
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        if (mounted) {
          setState(() {
            _photo = photo;
            _photoBytes = bytes;
          });
        }
      }
    } catch (error) {
      debugPrint('Unable to select listing photo: $error');
      if (mounted) {
        setState(() {
          _error = appErrorMessage;
          _retry = _pickPhoto;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_photo == null) {
      setState(() => _error = 'Choose a shoe photo.');
      return;
    }
    if (_sizes.isEmpty) {
      setState(() => _error = 'Select at least one available size.');
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _error = 'Sign in to submit a listing.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _retry = null;
    });
    final authService = context.read<AuthService>();
    final listingProvider = context.read<ListingProvider>();
    try {
      final profile = await authService.watchProfile(user.uid).first;
      final listing = Listing(
        id: FirebaseFirestore.instance.collection('listings').doc().id,
        sellerId: user.uid,
        sellerName: profile?.name.isNotEmpty == true
            ? profile!.name
            : user.displayName ?? 'Seller',
        title: _title.text.trim(),
        description: _description.text.trim(),
        price: double.parse(_price.text.trim()),
        brand: _brand.text.trim(),
        category: _category,
        sizes: _sizes.toList()..sort(),
        imageBase64: base64Encode(_photoBytes!),
        status: 'pending',
        rejectReason: null,
        createdAt: DateTime.now(),
      );
      await listingProvider.createListing(listing);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submitted for admin approval.')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      debugPrint('Unable to submit listing: $error');
      if (mounted) {
        setState(() {
          _error = appErrorMessage;
          _retry = _submit;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    _brand.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Sell a shoe')),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (_photo == null)
            OutlinedButton.icon(
              onPressed: _pickPhoto,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Choose photo'),
            )
          else
            Column(
              children: [
                SizedBox(
                  height: 200,
                  child: ProductImage(
                    value: '',
                    base64Image: base64Encode(_photoBytes!),
                    fit: BoxFit.contain,
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickPhoto,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Change photo'),
                ),
              ],
            ),
          const SizedBox(height: 12),
          _field(_title, 'Title'),
          const SizedBox(height: 12),
          _field(_description, 'Description', maxLines: 4),
          const SizedBox(height: 12),
          _field(
            _price,
            'Price',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              final price = double.tryParse(value?.trim() ?? '');
              return price == null || price <= 0 ? 'Enter a valid price' : null;
            },
          ),
          const SizedBox(height: 12),
          _field(_brand, 'Brand'),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: const [
              DropdownMenuItem(value: 'Men', child: Text('Men')),
              DropdownMenuItem(value: 'Women', child: Text('Women')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _category = value);
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Available sizes (EU)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Wrap(
            spacing: 8,
            children: List.generate(8, (index) {
              final size = index + 38;
              return FilterChip(
                label: Text('$size'),
                selected: _sizes.contains(size),
                selectedColor: Theme.of(context).colorScheme.primary,
                labelStyle: TextStyle(
                  color: _sizes.contains(size)
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                ),
                onSelected: (selected) => setState(
                  () => selected ? _sizes.add(size) : _sizes.remove(size),
                ),
              );
            }),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            if (_retry != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _busy ? null : () => _retry!(),
                  child: const Text('Retry'),
                ),
              ),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const CircularProgressIndicator()
                : const Text('Submit listing'),
          ),
        ],
      ),
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
      validator:
          validator ??
          (value) =>
              value == null || value.trim().isEmpty ? 'Enter $label' : null,
    );
  }
}
