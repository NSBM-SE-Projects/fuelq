import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../qr/providers/qr_provider.dart';
import '../models/booking_model.dart';

class _ScanRecord {
  final String vehicleNumber;
  final String ownerName;
  final BookingStatus status;
  final DateTime scannedAt;
  final bool success;

  const _ScanRecord({
    required this.vehicleNumber,
    required this.ownerName,
    required this.status,
    required this.scannedAt,
    required this.success,
  });
}

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen>
    with TickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController();
  bool _processing = false;
  bool _flashDetected = false;

  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnimation;

  final List<_ScanRecord> _history = [];

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scanLineController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_processing) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;

    setState(() => _processing = true);
    _controller.stop();
    HapticFeedback.mediumImpact();
    _triggerFlash();
    _handleQrCode(raw);
  }

  void _triggerFlash() {
    setState(() => _flashDetected = true);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _flashDetected = false);
    });
  }

  void _handleQrCode(String raw) {
    final user = ref.read(userProvider).valueOrNull;
    if (user == null) {
      _showError('You must be logged in to scan QR codes.');
      return;
    }
    final stationId = user.stationId;
    if (stationId == null || stationId.isEmpty) {
      _showError('Your account is not linked to a station. Contact your administrator.');
      return;
    }
    _processQrPayload(raw, user.uid, stationId);
  }

  Future<void> _processQrPayload(String raw, String attendantUid, String stationId) async {
    try {
      final qrService = ref.read(qrServiceProvider);
      final booking = await qrService.validateOnly(
        qrPayload: raw,
        attendantStationId: stationId,
      );

      if (!mounted) return;

      final localBooking = BookingModel(
        id: booking.bookingId,
        vehicleNumber: booking.vehicleNumber,
        ownerName: booking.userId,
        fuelType: booking.fuelType,
        litres: booking.litresBooked,
        slotTime: DateTime.now(),
        status: BookingStatus.confirmed,
        isPrepaid: false,
        stationId: stationId,
      );

      _showConfirmationSheet(
        localBooking,
        onConfirmed: () async {
          await qrService.scanAndValidate(
            qrPayload: raw,
            attendantUid: attendantUid,
            attendantStationId: stationId,
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _addHistory(BookingModel booking, {required bool success}) {
    setState(() {
      _history.insert(
        0,
        _ScanRecord(
          vehicleNumber: booking.vehicleNumber,
          ownerName: booking.ownerName,
          status: booking.status,
          scannedAt: DateTime.now(),
          success: success,
        ),
      );
      if (_history.length > 5) _history.removeLast();
    });
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Scan Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _processing = false);
              _controller.start();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _showManualEntry() {
    final textController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manual Booking Entry',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Enter the booking ID from the vehicle owner\'s app',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g. b1, b2, b3...',
                prefixIcon: const Icon(Icons.confirmation_number_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final id = textController.text.trim();
                  if (id.isEmpty) return;
                  Navigator.pop(ctx);
                  setState(() => _processing = true);
                  _handleQrCode(id);
                },
                child: const Text('Look Up Booking'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Recent Scans',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_history.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text('No scans yet',
                      style: TextStyle(color: Colors.black45)),
                ),
              )
            else
              ..._history.map((r) => _HistoryTile(record: r)),
          ],
        ),
      ),
    );
  }

  void _showConfirmationSheet(BookingModel booking, {Future<void> Function()? onConfirmed}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => _ConfirmationSheet(
        booking: booking,
        onConfirm: () async {
          final messenger = ScaffoldMessenger.of(context);
          final nav = Navigator.of(context);
          final sheetNav = Navigator.of(sheetCtx);
          await onConfirmed?.call();
          _addHistory(booking, success: true);
          HapticFeedback.heavyImpact();
          SystemSound.play(SystemSoundType.click);
          if (!mounted) return;
          sheetNav.pop();
          nav.pop();
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                  '${booking.vehicleNumber} — ${booking.litres.toStringAsFixed(0)}L dispensed'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        onCancel: () {
          Navigator.pop(sheetCtx);
          setState(() => _processing = false);
          _controller.start();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan Booking QR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.keyboard_alt_outlined),
            tooltip: 'Manual Entry',
            onPressed: _showManualEntry,
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.history),
                tooltip: 'Scan History',
                onPressed: _showHistory,
              ),
              if (_history.isNotEmpty)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.flashlight_on_outlined),
            onPressed: () => _controller.toggleTorch(),
            tooltip: 'Toggle torch',
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          AnimatedOpacity(
            opacity: _flashDetected ? 0.4 : 0,
            duration: const Duration(milliseconds: 150),
            child: Container(color: Colors.white),
          ),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          // Corner decorations
          Center(
            child: SizedBox(
              width: 240,
              height: 240,
              child: CustomPaint(painter: _CornerPainter()),
            ),
          ),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 234,
                height: 234,
                child: AnimatedBuilder(
                  animation: _scanLineAnimation,
                  builder: (_, child) => Stack(
                    children: [
                      Positioned(
                        top: _scanLineAnimation.value * 220,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppColors.primary.withValues(alpha: 0.8),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Hint text
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Icon(Icons.qr_code_scanner,
                    color: Colors.white54, size: 28),
                const SizedBox(height: 8),
                const Text(
                  'Align the booking QR code within the frame',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _showManualEntry,
                  child: const Text(
                    'QR not working? Enter ID manually',
                    style: TextStyle(
                      color: AppColors.accentLight,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.accentLight,
                    ),
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

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 24.0;
    final corners = [
      [Offset(0, len), Offset.zero, Offset(len, 0)],
      [
        Offset(size.width - len, 0),
        Offset(size.width, 0),
        Offset(size.width, len)
      ],
      [
        Offset(size.width, size.height - len),
        Offset(size.width, size.height),
        Offset(size.width - len, size.height)
      ],
      [
        Offset(len, size.height),
        Offset(0, size.height),
        Offset(0, size.height - len)
      ],
    ];
    for (final pts in corners) {
      final path = Path()
        ..moveTo(pts[0].dx, pts[0].dy)
        ..lineTo(pts[1].dx, pts[1].dy)
        ..lineTo(pts[2].dx, pts[2].dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.record});
  final _ScanRecord record;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: record.success
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              record.success ? Icons.check_circle_outline : Icons.cancel_outlined,
              size: 18,
              color: record.success ? AppColors.success : AppColors.error,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.vehicleNumber,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(
                  record.ownerName,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          Text(
            DateFormat('HH:mm').format(record.scannedAt),
            style: const TextStyle(fontSize: 12, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}

class _ConfirmationSheet extends StatelessWidget {
  const _ConfirmationSheet({
    required this.booking,
    required this.onConfirm,
    required this.onCancel,
  });

  final BookingModel booking;
  final Future<void> Function() onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final isAlreadyArrived = booking.status == BookingStatus.arrived;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.verified,
                    color: AppColors.primary, size: 30),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Booking Verified',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Text(
                    booking.vehicleNumber,
                    style: const TextStyle(
                        color: Colors.black54, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
          if (isAlreadyArrived) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline,
                      size: 16, color: AppColors.warning),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vehicle already marked as arrived — confirm to complete dispensing.',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          _Row('Owner', booking.ownerName),
          _Row('Fuel Type', booking.fuelType),
          _Row('Litres to Dispense',
              '${booking.litres.toStringAsFixed(0)} L'),
          _Row('Payment',
              booking.isPrepaid ? '✓ Prepaid' : 'Collect Cash at pump'),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: onConfirm,
                  icon: const Icon(Icons.local_gas_station, size: 18),
                  label: const Text('Confirm & Dispense'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.black54, fontSize: 14)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}
