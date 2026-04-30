import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import '../providers/piece_provider.dart';
import '../utils/constants.dart';

const String _kProductId = 'unlock_unlimited';

class PaywallSheet extends StatefulWidget {
  const PaywallSheet({super.key});

  @override
  State<PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends State<PaywallSheet> {
  ProductDetails? _product;
  bool _isLoading = true;
  bool _isPurchasing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProduct();
    InAppPurchase.instance.purchaseStream.listen(_handlePurchase);
  }

  Future<void> _loadProduct() async {
    final available = await InAppPurchase.instance.isAvailable();
    if (!available) {
      setState(() { _isLoading = false; _error = 'Store not available'; });
      return;
    }
    final response = await InAppPurchase.instance.queryProductDetails({_kProductId});
    setState(() {
      _isLoading = false;
      if (response.productDetails.isNotEmpty) {
        _product = response.productDetails.first;
      } else {
        _error = 'Product not found';
      }
    });
  }

  void _handlePurchase(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.productID == _kProductId) {
        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          InAppPurchase.instance.completePurchase(purchase);
          context.read<PieceProvider>().setPremium(true);
          if (mounted) Navigator.pop(context);
        }
      }
    }
  }

  Future<void> _purchase() async {
    if (_product == null) return;
    setState(() => _isPurchasing = true);
    final param = PurchaseParam(productDetails: _product!);
    await InAppPurchase.instance.buyNonConsumable(purchaseParam: param);
    setState(() => _isPurchasing = false);
  }

  Future<void> _restore() async {
    setState(() => _isPurchasing = true);
    await InAppPurchase.instance.restorePurchases();
    setState(() => _isPurchasing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48, height: 4,
            decoration: BoxDecoration(
              color: kDividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Icon(Icons.lock_outline, color: kGoldColor, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Unlock Unlimited Pieces',
            style: TextStyle(color: kTextPrimary, fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            "You've used your 3 free pieces",
            style: TextStyle(color: kTextSecondary, fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Unlock unlimited pieces with a one-time purchase.',
            style: TextStyle(color: kTextSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (_isLoading)
            const CircularProgressIndicator(color: kGoldColor)
          else if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.redAccent))
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isPurchasing ? null : _purchase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGoldColor,
                  foregroundColor: const Color(0xFF1A1200),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                child: _isPurchasing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: kGoldColor, strokeWidth: 2),
                      )
                    : Text(_product != null
                        ? 'Unlock for ${_product!.price}'
                        : 'Unlock for \$2.00'),
              ),
            ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _isPurchasing ? null : _restore,
            child: const Text(
              'Restore Purchase',
              style: TextStyle(color: kTextSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
