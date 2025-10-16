// import 'package:flutter/services.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';

// class BarcodeScannerService {
//   final MobileScannerController _controller = MobileScannerController();

//   Future<String?> scanBarcode() async {
//     try {
//       final capture = await _controller.start();
//       String? barcode;
      
//       if (capture != null && capture.barcodes.isNotEmpty) {
//         barcode = capture.barcodes.first.rawValue;
//         // Provide haptic feedback on successful scan
//         await HapticFeedback.mediumImpact();
//       }
      
//       await _controller.stop();
//       return barcode;
//     } on PlatformException catch (e) {
//       if (e.code == 'PERMISSION_DENIED') {
//         throw 'Camera permission denied';
//       }
//       throw 'Failed to scan barcode: ${e.message}';
//     }
//   }

//   void dispose() {
//     _controller.dispose();
//   }
// }