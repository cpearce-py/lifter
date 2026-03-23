// import 'package:flutter/material.dart';
// import 'ble_service.dart';
// 
// // ─── BLE Widgets ──────────────────────────────────────────────────────────────
// // Public widgets that can be dropped into any screen.
// //
// //   BleBanner   — full-width status banner; tapping opens BleBottomSheet
// //   BleBottomSheet — scan / connect / disconnect sheet
// //   BlePulseDot — animated status dot (reusable anywhere)
// 
// // ─── BleBanner ────────────────────────────────────────────────────────────────
// 
// class BleBanner extends StatelessWidget {
//   const BleBanner({super.key, required this.service});
// 
//   final BleService service;
// 
//   void _openSheet(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       isScrollControlled: true,
//       builder: (_) => BleBottomSheet(service: service),
//     );
//   }
// 
//   @override
//   Widget build(BuildContext context) {
//     final isConnected = service.isConnected;
//     final accentColor =
//         isConnected ? const Color(0xFF47FF8A) : const Color(0xFF47C8FF);
//     final label =
//         isConnected ? (service.connectedDeviceName ?? 'Weiheng') : 'Connect Weiheng';
//     final sublabel = isConnected ? 'Sensor connected' : 'No sensor detected';
// 
//     return GestureDetector(
//       onTap: () => _openSheet(context),
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 400),
//         curve: Curves.easeOut,
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//         decoration: BoxDecoration(
//           color: accentColor.withOpacity(0.07),
//           borderRadius: BorderRadius.circular(18),
//           border: Border.all(color: accentColor.withOpacity(0.25), width: 1),
//         ),
//         child: Row(
//           children: [
//             BlePulseDot(isConnected: isConnected, color: accentColor),
//             const SizedBox(width: 14),
//             Icon(Icons.bluetooth_rounded, color: accentColor, size: 20),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     label,
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w700,
//                       color: accentColor,
//                       letterSpacing: 0.1,
//                     ),
//                   ),
//                   const SizedBox(height: 2),
//                   Text(
//                     sublabel,
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: accentColor.withOpacity(0.55),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//               decoration: BoxDecoration(
//                 color: accentColor.withOpacity(0.12),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Text(
//                 isConnected ? 'Manage' : 'Scan',
//                 style: TextStyle(
//                   fontSize: 12,
//                   fontWeight: FontWeight.w700,
//                   color: accentColor,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
// 
// // ─── BleBottomSheet ───────────────────────────────────────────────────────────
// 
// class BleBottomSheet extends StatelessWidget {
//   const BleBottomSheet({super.key, required this.service});
// 
//   final BleService service;
// 
//   @override
//   Widget build(BuildContext context) {
//     return ListenableBuilder(
//       listenable: service,
//       builder: (context, _) {
//         return Container(
//           decoration: const BoxDecoration(
//             color: Color(0xFF111118),
//             borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
//             border: Border(top: BorderSide(color: Color(0xFF1E1E2A))),
//           ),
//           padding: EdgeInsets.fromLTRB(
//               24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Drag handle
//               Center(
//                 child: Container(
//                   width: 36,
//                   height: 4,
//                   decoration: BoxDecoration(
//                     color: Colors.white.withOpacity(0.15),
//                     borderRadius: BorderRadius.circular(2),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 24),
// 
//               // Title row
//               Row(
//                 children: [
//                   const Icon(Icons.bluetooth_rounded,
//                       color: Color(0xFF47C8FF), size: 20),
//                   const SizedBox(width: 10),
//                   const Text(
//                     'Weiheng Sensor',
//                     style: TextStyle(
//                       fontSize: 17,
//                       fontWeight: FontWeight.w800,
//                       color: Color(0xFFF0F0F0),
//                     ),
//                   ),
//                   const Spacer(),
//                   if (service.isConnected)
//                     _BlePillButton(
//                       label: 'Disconnect',
//                       color: const Color(0xFFFF6B6B),
//                       onTap: service.disconnect,
//                     )
//                   else
//                     _BlePillButton(
//                       label: service.isScanning ? 'Scanning…' : 'Scan',
//                       color: const Color(0xFF47C8FF),
//                       onTap: service.isScanning ? null : service.startScan,
//                     ),
//                 ],
//               ),
//               const SizedBox(height: 20),
// 
//               // Device list / status
//               if (service.isConnected) ...[
//                 _BleDeviceTile(
//                   name: service.connectedDeviceName!,
//                   isConnected: true,
//                   onTap: service.disconnect,
//                 ),
//               ] else if (service.isScanning) ...[
//                 const _BleScanningIndicator(),
//               ] else ...[
//                 if (service.scannedDevices.isEmpty)
//                   Padding(
//                     padding: const EdgeInsets.only(bottom: 12),
//                     child: Text(
//                       'Tap Scan to find nearby devices.',
//                       style: TextStyle(
//                         fontSize: 13,
//                         color: Colors.white.withOpacity(0.35),
//                       ),
//                     ),
//                   ),
//                 ...service.scannedDevices.map(
//                   (name) => Padding(
//                     padding: const EdgeInsets.only(bottom: 8),
//                     child: _BleDeviceTile(
//                       name: name,
//                       isConnected: false,
//                       onTap: () => service.connect(name),
//                     ),
//                   ),
//                 ),
//               ],
//             ],
//           ),
//         );
//       },
//     );
//   }
// }
// 
// // ─── BlePulseDot ──────────────────────────────────────────────────────────────
// 
// class BlePulseDot extends StatefulWidget {
//   const BlePulseDot({super.key, required this.isConnected, required this.color});
// 
//   final bool isConnected;
//   final Color color;
// 
//   @override
//   State<BlePulseDot> createState() => _BlePulseDotState();
// }
// 
// class _BlePulseDotState extends State<BlePulseDot>
//     with SingleTickerProviderStateMixin {
//   late final AnimationController _pulse;
// 
//   @override
//   void initState() {
//     super.initState();
//     _pulse = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1400),
//     );
//     if (widget.isConnected) _pulse.repeat(reverse: true);
//   }
// 
//   @override
//   void didUpdateWidget(BlePulseDot old) {
//     super.didUpdateWidget(old);
//     if (widget.isConnected) {
//       _pulse.repeat(reverse: true);
//     } else {
//       _pulse.stop();
//       _pulse.value = 0;
//     }
//   }
// 
//   @override
//   void dispose() {
//     _pulse.dispose();
//     super.dispose();
//   }
// 
//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: _pulse,
//       builder: (_, __) => Container(
//         width: 9,
//         height: 9,
//         decoration: BoxDecoration(
//           shape: BoxShape.circle,
//           color: widget.color.withOpacity(
//             widget.isConnected ? 0.5 + 0.5 * _pulse.value : 0.4,
//           ),
//           boxShadow: widget.isConnected
//               ? [
//                   BoxShadow(
//                     color: widget.color.withOpacity(0.5 * _pulse.value),
//                     blurRadius: 8,
//                     spreadRadius: 2,
//                   )
//                 ]
//               : null,
//         ),
//       ),
//     );
//   }
// }
// 
// // ─── Private helpers ──────────────────────────────────────────────────────────
// 
// class _BlePillButton extends StatelessWidget {
//   const _BlePillButton(
//       {required this.label, required this.color, this.onTap});
// 
//   final String label;
//   final Color color;
//   final VoidCallback? onTap;
// 
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
//         decoration: BoxDecoration(
//           color: color.withOpacity(onTap == null ? 0.05 : 0.12),
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(color: color.withOpacity(0.3)),
//         ),
//         child: Text(
//           label,
//           style: TextStyle(
//             fontSize: 12,
//             fontWeight: FontWeight.w700,
//             color: color.withOpacity(onTap == null ? 0.4 : 1.0),
//           ),
//         ),
//       ),
//     );
//   }
// }
// 
// class _BleDeviceTile extends StatelessWidget {
//   const _BleDeviceTile(
//       {required this.name, required this.isConnected, required this.onTap});
// 
//   final String name;
//   final bool isConnected;
//   final VoidCallback onTap;
// 
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//         decoration: BoxDecoration(
//           color: isConnected
//               ? const Color(0xFF47FF8A).withOpacity(0.06)
//               : Colors.white.withOpacity(0.04),
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(
//             color: isConnected
//                 ? const Color(0xFF47FF8A).withOpacity(0.25)
//                 : Colors.white.withOpacity(0.08),
//           ),
//         ),
//         child: Row(
//           children: [
//             Icon(
//               Icons.scale_rounded,
//               size: 18,
//               color: isConnected
//                   ? const Color(0xFF47FF8A)
//                   : Colors.white.withOpacity(0.4),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Text(
//                 name,
//                 style: TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w600,
//                   color: isConnected
//                       ? const Color(0xFF47FF8A)
//                       : const Color(0xFFF0F0F0),
//                 ),
//               ),
//             ),
//             Text(
//               isConnected ? 'Connected' : 'Tap to connect',
//               style: TextStyle(
//                 fontSize: 11,
//                 color: isConnected
//                     ? const Color(0xFF47FF8A).withOpacity(0.6)
//                     : Colors.white.withOpacity(0.25),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
// 
// class _BleScanningIndicator extends StatelessWidget {
//   const _BleScanningIndicator();
// 
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 20),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const SizedBox(
//             width: 16,
//             height: 16,
//             child: CircularProgressIndicator(
//               strokeWidth: 2,
//               color: Color(0xFF47C8FF),
//             ),
//           ),
//           const SizedBox(width: 12),
//           Text(
//             'Looking for devices…',
//             style: TextStyle(
//               fontSize: 13,
//               color: Colors.white.withOpacity(0.4),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
