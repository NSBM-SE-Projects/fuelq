import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../booking/models/booking_model.dart';
import '../../booking/providers/booking_provider.dart';
import '../../dashboard/providers/quota_provider.dart';
import '../models/card_model.dart';
import '../providers/payment_provider.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final String stationId;
  final String stationName;
  final String vehicleId;
  final String vehicleNumber;
  final String fuelType;
  final DateTime slotStart;
  final double litresBooked;

  const PaymentScreen({
    super.key,
    required this.stationId,
    required this.stationName,
    required this.vehicleId,
    required this.vehicleNumber,
    required this.fuelType,
    required this.slotStart,
    required this.litresBooked,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  bool _payByCard = false;
  bool _isProcessing = false;
  CardModel? _selectedCard;
  bool _showNewCardForm = false;

  final _cardNumberCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  bool _saveCard = true;
  String _detectedBank = '';

  @override
  void initState() {
    super.initState();
    _cardNumberCtrl.addListener(() {
      final cleaned = _cardNumberCtrl.text.replaceAll(' ', '');
      String bank = '';
      if (cleaned.isNotEmpty) {
        if (cleaned.startsWith('4')) {
          bank = 'Visa';
        } else if (cleaned.startsWith('5')) {
          bank = 'Mastercard';
        } else if (cleaned.startsWith('3')) {
          bank = 'Amex';
        }
      }
      if (bank != _detectedBank) setState(() => _detectedBank = bank);
    });
  }

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _nameCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  double _calculateAmount(BookingConfig cfg, double remainingQuota) {
    final pricePerLiter = widget.fuelType == 'diesel'
        ? cfg.dieselPricePerLiter
        : cfg.petrolPricePerLiter;
    return remainingQuota * pricePerLiter;
  }

  Future<void> _confirm() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isProcessing = true);

    try {
      String? cardLast4;
      String paymentStatus = 'pending';

      if (_payByCard) {
        if (_showNewCardForm) {
          // Validate new card
          if (_cardNumberCtrl.text.replaceAll(' ', '').length < 16 ||
              _nameCtrl.text.isEmpty ||
              _expiryCtrl.text.length < 5 ||
              _cvvCtrl.text.length < 3) {
            throw Exception('invalid_card');
          }

          final parts = _expiryCtrl.text.split('/');
          final month = int.parse(parts[0]);
          final year = 2000 + int.parse(parts[1]);

          if (_saveCard) {
            await ref.read(paymentServiceProvider).saveCard(
              userId: user.uid,
              cardNumber: _cardNumberCtrl.text,
              cardholderName: _nameCtrl.text.trim(),
              expiryMonth: month,
              expiryYear: year,
              setAsDefault: true,
            );
          }

          cardLast4 = _cardNumberCtrl.text.replaceAll(' ', '').substring(
              _cardNumberCtrl.text.replaceAll(' ', '').length - 4);
        } else if (_selectedCard != null) {
          cardLast4 = _selectedCard!.last4;
        }

        // Simulate payment
        final success = await ref.read(paymentServiceProvider).processPayment(
          amount: 0,
          cardId: _selectedCard?.id ?? 'new',
        );
        if (!success) throw Exception('payment_failed');
        paymentStatus = 'paid';
      }

      final cfg = ref.read(bookingConfigProvider).valueOrNull;
      final quotas = ref.read(quotasProvider);
      final vehicleQuota = quotas.where((q) => q.vehicleId == widget.vehicleId).firstOrNull;
      final amount = _calculateAmount(
        cfg ?? const BookingConfig(
          slotDurationMinutes: 30, maxVehiclesPerSlot: 15,
          cancelWindowMinutes: 30, arrivalWindowMinutes: 15,
          maxBookingsPerVehiclePerDay: 1,
          petrolPricePerLiter: 366, dieselPricePerLiter: 336,
        ),
        vehicleQuota?.remaining ?? 0,
      );

      final booking = await ref.read(bookingServiceProvider).createBooking(
        userId: user.uid,
        stationId: widget.stationId,
        stationName: widget.stationName,
        vehicleId: widget.vehicleId,
        vehicleNumber: widget.vehicleNumber,
        fuelType: widget.fuelType,
        slotStart: widget.slotStart,
        litresBooked: widget.litresBooked,
        paymentMethod: _payByCard ? 'card' : 'cash',
        paymentStatus: paymentStatus,
        amount: _payByCard ? amount : 0,
        cardLast4: cardLast4,
      );

      if (mounted) {
        context.go('/booking-confirmed', extra: {
          'booking': booking,
          'slotDuration': cfg?.slotDuration ?? const Duration(minutes: 30),
        });
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString();
        String title = 'Payment Failed';
        String body = 'Something went wrong. Please try again.';
        if (msg.contains('invalid_card')) {
          title = 'Invalid Card Details';
          body = 'Please check your card number, expiry date, and CVV.';
        } else if (msg.contains('already has a booking')) {
          title = 'Vehicle Already Booked';
          body = 'This vehicle already has a fuel slot booked for today.';
        }
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Text(body),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(bookingConfigProvider);
    final cardsAsync = ref.watch(savedCardsProvider);
    final quotas = ref.watch(quotasProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: configAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (cfg) {
          final vehicleQuota = quotas.where((q) => q.vehicleId == widget.vehicleId).firstOrNull;
          final remaining = vehicleQuota?.remaining ?? 0;
          final pricePerLiter = widget.fuelType == 'diesel' ? cfg.dieselPricePerLiter : cfg.petrolPricePerLiter;
          final estimatedAmount = remaining * pricePerLiter;

          return Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 12,
                  bottom: 20, left: 24, right: 24,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Payment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(widget.stationName, style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7))),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Booking summary
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Column(
                          children: [
                            _SummaryRow(label: 'Vehicle', value: widget.vehicleNumber),
                            _SummaryRow(label: 'Fuel Type', value: '${widget.fuelType[0].toUpperCase()}${widget.fuelType.substring(1)}'),
                            _SummaryRow(label: 'Remaining Quota', value: '${remaining.toStringAsFixed(1)}L'),
                            _SummaryRow(label: 'Price per Liter', value: 'Rs. ${pricePerLiter.toStringAsFixed(0)}'),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Estimated Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                Text('Rs. ${estimatedAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Payment method toggle
                      const Text('Payment Method', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() { _payByCard = false; _showNewCardForm = false; }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: !_payByCard ? AppColors.primary : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: !_payByCard ? AppColors.primary : AppColors.divider),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.money_rounded, size: 20, color: !_payByCard ? Colors.white : AppColors.textSecondary),
                                    const SizedBox(width: 8),
                                    Text('Cash', style: TextStyle(fontWeight: FontWeight.w700, color: !_payByCard ? Colors.white : AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _payByCard = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: _payByCard ? AppColors.primary : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: _payByCard ? AppColors.primary : AppColors.divider),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.credit_card_rounded, size: 20, color: _payByCard ? Colors.white : AppColors.textSecondary),
                                    const SizedBox(width: 8),
                                    Text('Card', style: TextStyle(fontWeight: FontWeight.w700, color: _payByCard ? Colors.white : AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      if (!_payByCard)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline_rounded, color: AppColors.success, size: 20),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'You will pay at the fuel station when you arrive for your slot.',
                                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Card section
                      if (_payByCard) ...[
                        cardsAsync.when(
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Text('$e'),
                          data: (cards) {
                            if (cards.isEmpty && !_showNewCardForm) {
                              _showNewCardForm = true;
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (cards.isNotEmpty && !_showNewCardForm) ...[
                                  ...cards.map((card) => GestureDetector(
                                    onTap: () => setState(() => _selectedCard = card),
                                    child: Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: _selectedCard?.id == card.id
                                            ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: _selectedCard?.id == card.id ? AppColors.primary : AppColors.divider,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          _BankBadge(bank: card.bank),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(card.maskedNumber, style: TextStyle(
                                                  fontSize: 15, fontWeight: FontWeight.w700,
                                                  color: _selectedCard?.id == card.id ? AppColors.primary : AppColors.textPrimary,
                                                )),
                                                Text('${card.bank} · ${card.expiryDisplay}',
                                                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                              ],
                                            ),
                                          ),
                                          if (_selectedCard?.id == card.id)
                                            const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                                          if (card.isDefault)
                                            Container(
                                              margin: const EdgeInsets.only(left: 8),
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Text('Default', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary)),
                                            ),
                                        ],
                                      ),
                                    ),
                                  )),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () => setState(() => _showNewCardForm = true),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: AppColors.divider, style: BorderStyle.solid),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add_rounded, size: 18, color: AppColors.primary),
                                          SizedBox(width: 8),
                                          Text('Add New Card', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],

                                if (_showNewCardForm) ...[
                                  if (cards.isNotEmpty)
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: TextButton.icon(
                                        onPressed: () => setState(() => _showNewCardForm = false),
                                        icon: const Icon(Icons.arrow_back_rounded, size: 16),
                                        label: const Text('Use saved card'),
                                      ),
                                    ),
                                  _buildCardForm(),
                                ],
                              ],
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Confirm button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (_isProcessing || (_payByCard && _selectedCard == null && !_showNewCardForm))
                        ? null : _confirm,
                    child: _isProcessing
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(
                            _payByCard ? 'Pay & Confirm Booking' : 'Confirm Booking',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCardForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Card Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textLight)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _cardNumberCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
              _CardNumberFormatter(),
            ],
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: '0000 0000 0000 0000',
              prefixIcon: const Icon(Icons.credit_card_rounded, color: AppColors.primarySoft),
              suffixIcon: _detectedBank.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _BankBadge(bank: _detectedBank),
                    )
                  : null,
              suffixIconConstraints: const BoxConstraints(minHeight: 24, minWidth: 24),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Cardholder Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textLight)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Name on card',
              prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.primarySoft),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Expiry', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textLight)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _expiryCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                        _ExpiryFormatter(),
                      ],
                      decoration: const InputDecoration(hintText: 'MM/YY'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CVV', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textLight)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _cvvCtrl,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      decoration: const InputDecoration(hintText: '•••'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => setState(() => _saveCard = !_saveCard),
            child: Row(
              children: [
                Icon(
                  _saveCard ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                  color: _saveCard ? AppColors.primary : AppColors.textLight,
                  size: 22,
                ),
                const SizedBox(width: 10),
                const Text('Save card for future payments', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(text[i]);
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(text[i]);
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class _BankBadge extends StatelessWidget {
  final String bank;

  const _BankBadge({required this.bank});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    switch (bank) {
      case 'Visa':
        bgColor = const Color(0xFF1A1F71);
        textColor = Colors.white;
      case 'Mastercard':
        bgColor = const Color(0xFFEB001B);
        textColor = Colors.white;
      case 'Amex':
        bgColor = const Color(0xFF2E77BC);
        textColor = Colors.white;
      default:
        bgColor = AppColors.divider;
        textColor = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        bank,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
