// import 'dart:ui';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:haflaway/models/attendee.dart';
// import 'package:haflaway/models/card.dart';
// import 'package:haflaway/models/checkpoint.dart';
// import 'package:haflaway/models/event.dart';
// import 'package:haflaway/top_destinations/event_dash/admin_panel/admin_pane_pub.dart';
// import 'package:haflaway/top_destinations/event_dash/admin_panel/checkpoint/index.dart';
// import 'package:haflaway/top_destinations/event_dash/admin_panel/event_tools/inv_editor.dart';
// import 'package:haflaway/top_destinations/event_dash/admin_panel/settings/event_settings.dart';
// import 'package:haflaway/top_destinations/event_dash/admin_panel/users_perms/users.dart';
// import 'package:haflaway/top_destinations/event_dash/cards/cards.dart';
// import 'package:haflaway/top_destinations/eventz/create_event.dart';
// import 'package:haflaway/components/gus_scaffold.dart';
// import 'package:haflaway/utils/globalfns.dart';
// import 'package:haflaway/utils/gus_theme.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:haflaway/utils/colors.dart';
// import 'package:haflaway/utils/globalfns.dart';
// import 'package:haflaway/top_destinations/event_dash/attendees/attendees.dart';
// import 'package:haflaway/components/moving_gradient_border.dart';
// import 'package:icons_plus/icons_plus.dart';
// import 'package:intl/intl.dart';

// class AdminPanel extends StatefulWidget {
//   final Event eventO;
//   final bool isAdmin;
//   const AdminPanel({super.key, required this.eventO, required this.isAdmin});

//   @override
//   State<AdminPanel> createState() => _AdminPanelState();
// }

// class _AdminPanelState extends State<AdminPanel> with TickerProviderStateMixin {
//   Event? event;
//   bool isLoading = false;
//   bool hasError = false;
//   int invsCount = 0;
//   int contsCount = 0;
//   int adminsCount = 0;
//   int scannersCount = 0;
//   int cardTempsNo = 0;
//   int evMsgTmpCount = 0;
//   GlobalKey<FormState> key = GlobalKey<FormState>();
//   FirebaseFirestore firestore = FirebaseFirestore.instance;
//   FirebaseAuth firebaseAuth = FirebaseAuth.instance;

//   @override
//   void initState() {
//     super.initState();
//     loadData();
//   }

//   loadData() async {
//     safeState(() {
//       isLoading = true;
//       hasError = false;
//     });
//     try {
//       DocumentReference<Map<String, dynamic>> eventRef = firestore
//           .collection(ecol)
//           .doc(widget.eventO.id);
//       CollectionReference<Map<String, dynamic>> attsRef = firestore
//           .collection(ecol)
//           .doc(widget.eventO.id)
//           .collection(atcol);
//       CollectionReference<Map<String, dynamic>> cardsRef = firestore
//           .collection(ecol)
//           .doc(widget.eventO.id)
//           .collection(cardcol);
//       CollectionReference<Map<String, dynamic>> msgsRef = firestore
//           .collection(ecol)
//           .doc(widget.eventO.id)
//           .collection(evMsgTmpCol);
//       var result = await Future.wait([
//         eventRef.get(),
//         attsRef.get(),
//         cardsRef.count().get(),
//         msgsRef.count().get(),
//       ]);
//       var eventSnapshot = result[0] as DocumentSnapshot<Map<String, dynamic>>;
//       var attsSnapshot = result[1] as QuerySnapshot<Map<String, dynamic>>;
//       var crdsSnapshot = result[2] as AggregateQuerySnapshot;
//       var msgsSnapshot = result[3] as AggregateQuerySnapshot;
//       invsCount =
//           attsSnapshot.docs.where((t) {
//             Attendee attendee = Attendee.fromMap(t.id, t.data());
//             return attendee.cards.containsKey(KardType.invitation.name);
//           }).length;

//       contsCount =
//           attsSnapshot.docs.where((t) {
//             Attendee attendee = Attendee.fromMap(t.id, t.data());
//             return attendee.cards.containsKey(KardType.contribution.name);
//           }).length;

//       event = Event.fromMap(eventSnapshot.id, eventSnapshot.data()!);
//       cardTempsNo = crdsSnapshot.count ?? 0;
//       evMsgTmpCount = msgsSnapshot.count ?? 0;
//       adminsCount = event?.adminsIds?.length ?? 0;
//       scannersCount = event?.usersIds?.length ?? 0;
//       safeState(() {
//         isLoading = false;
//         hasError = false;
//       });
//     } catch (e) {
//       safeState(() {
//         isLoading = false;
//         hasError = true;
//       });
//       debugPrint("Error is: $e");
//     }
//   }

//   // ── Helpers ──────────────────────────────────────────────

//   String _formattedDate() {
//     try {
//       if (event?.startDate != null) {
//         final dt = DateTime.parse(event!.startDate!);
//         return DateFormat('EEE, MMM d · h:mm a').format(dt);
//       }
//     } catch (_) {}
//     return "";
//   }

//   // ── Floating glass icon button (back / settings / edit) ─
//   Widget _floatingButton({
//     required IconData icon,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(22),
//         child: BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
//           child: Container(
//             width: 40,
//             height: 40,
//             decoration: BoxDecoration(
//               color: Colors.black.withOpacity(0.35),
//               borderRadius: BorderRadius.circular(22),
//               border: Border.all(
//                 color: Colors.white.withOpacity(0.15),
//                 width: 0.5,
//               ),
//             ),
//             child: Icon(icon, color: Colors.white, size: 20),
//           ),
//         ),
//       ),
//     );
//   }

//   // ── Single action row (iOS-settings style) ──────────────
//   Widget _buildActionRow({
//     required IconData icon,
//     required List<Color> iconGradient,
//     required String title,
//     required String count,
//     required VoidCallback onTap,
//     bool isLast = false,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(16),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//         child: Row(
//           children: [
//             // Slick Dark Glass Icon Pill
//             Container(
//               width: 44,
//               height: 44,
//               decoration: BoxDecoration(
//                 color: Colors.black.withValues(alpha: 0.45),
//                 borderRadius: BorderRadius.circular(14),
//                 border: Border.all(
//                   color: Colors.white.withValues(alpha: 0.1),
//                   width: 0.5,
//                 ),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withValues(alpha: 0.2),
//                     blurRadius: 10,
//                     offset: const Offset(0, 4),
//                   ),
//                 ],
//               ),
//               child: Center(
//                 child: ShaderMask(
//                   shaderCallback:
//                       (bounds) => const LinearGradient(
//                         colors: [GusTheme.gold, GusTheme.goldLight],
//                         begin: Alignment.topLeft,
//                         end: Alignment.bottomRight,
//                       ).createShader(bounds),
//                   child: Icon(icon, color: Colors.white, size: 22),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 16),
//             // Title
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     title,
//                     style: GoogleFonts.inter(
//                       color: GusTheme.textPrimary.withValues(alpha: 0.95),
//                       fontSize: 15,
//                       fontWeight: FontWeight.w600,
//                       letterSpacing: -0.2,
//                     ),
//                   ),
//                   if (count.isNotEmpty) ...[
//                     const SizedBox(height: 4),
//                     Text(
//                       "$count items recorded",
//                       style: GoogleFonts.inter(
//                         color: GusTheme.textMuted,
//                         fontSize: 11,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//             const Icon(
//               Icons.chevron_right_rounded,
//               color: GusTheme.textMuted,
//               size: 20,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ── Section card (frosted glass container) ──────────────
//   Widget _buildSectionCard({
//     required String title,
//     required List<Widget> rows,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.only(left: 4, bottom: 12),
//           child: Text(
//             title.toUpperCase(),
//             style: GoogleFonts.inter(
//               color: GusTheme.textMuted,
//               fontSize: 11,
//               fontWeight: FontWeight.w600,
//               letterSpacing: 1.5,
//             ),
//           ),
//         ),
//         MovingGradientBorder(
//           borderRadius: 24,
//           borderWidth: 1.0,
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(24),
//             child: BackdropFilter(
//               filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: GusTheme.surface.withValues(alpha: 0.5),
//                   borderRadius: BorderRadius.circular(24),
//                   border: Border.all(
//                     color: Colors.white.withValues(alpha: 0.08),
//                     width: 0.5,
//                   ),
//                 ),
//                 child: Column(
//                   children: List.generate(rows.length * 2 - 1, (i) {
//                     if (i.isOdd) {
//                       return Divider(
//                         height: 1,
//                         thickness: 0.5,
//                         color: Colors.white.withValues(alpha: 0.08),
//                         indent: 72,
//                       );
//                     }
//                     return rows[i ~/ 2];
//                   }),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   // ── Error view ──────────────────────────────────────────
//   Widget _buildErrorView() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(32.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(24),
//               decoration: BoxDecoration(
//                 color: Colors.red.withValues(alpha: 0.1),
//                 shape: BoxShape.circle,
//               ),
//               child: const Icon(
//                 Icons.wifi_off_rounded,
//                 color: Colors.redAccent,
//                 size: 64,
//               ),
//             ),
//             const SizedBox(height: 24),
//             Text(
//               "Something went wrong",
//               style: GoogleFonts.cormorantGaramond(
//                 color: GusTheme.textPrimary,
//                 fontSize: 24,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               "We encountered an error while loading the event data. Please try again.",
//               textAlign: TextAlign.center,
//               style: GoogleFonts.inter(color: GusTheme.textMuted, fontSize: 14),
//             ),
//             const SizedBox(height: 32),
//             ElevatedButton(
//               onPressed: () => loadData(),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: GusTheme.gold,
//                 foregroundColor: Colors.black,
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 32,
//                   vertical: 16,
//                 ),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//               ),
//               child: const Text(
//                 "Retry Now",
//                 style: TextStyle(fontWeight: FontWeight.w700),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ═══════════════════════════════════════════════════════════
//   // ── BUILD ─────────────────────────────────────────────────
//   // ═══════════════════════════════════════════════════════════

//   @override
//   Widget build(BuildContext context) {
//     if (hasError) return GusScaffold(title: "", body: _buildErrorView());
//     if (isLoading && event == null) {
//       return const GusScaffold(
//         title: "",
//         body: Center(child: CupertinoActivityIndicator(color: GusTheme.gold)),
//       );
//     }

//     return GusScaffold(
//       title: "",
//       titleWidget: MovingGradientBorder(
//         borderRadius: 8,
//         borderWidth: 1.2,
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//           child: Text(
//             "Admin Panel",
//             style: GoogleFonts.cormorantGaramond(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: GusTheme.textPrimary,
//               letterSpacing: 1.2,
//             ),
//           ),
//         ),
//       ),
//       actions: [
//         // Extra Button
//         _floatingButton(
//           icon: Icons.event,
//           onTap: () async {
//             await Navigator.of(
//               context,
//             ).push(MaterialPageRoute(builder: (context) => DashboardScreen()));
//             loadData();
//           },
//         ),
//         const SizedBox(width: 8),
//         _floatingButton(
//           icon: Icons.settings_rounded,
//           onTap: () async {
//             await Navigator.of(context).push(
//               MaterialPageRoute(
//                 builder: (context) => EventSettings(event: event),
//               ),
//             );
//             loadData();
//           },
//         ),
//         const SizedBox(width: 8),
//         _floatingButton(
//           icon: Icons.edit_rounded,
//           onTap: () async {
//             await Navigator.of(context).push(
//               MaterialPageRoute(
//                 builder: (context) => CreateEvent(event: event),
//               ),
//             );
//             loadData();
//           },
//         ),
//         const SizedBox(width: 12),
//       ],
//       body: RefreshIndicator(
//         onRefresh: () async => loadData(),
//         color: GusTheme.gold,
//         backgroundColor: GusTheme.surface,
//         child: CustomScrollView(
//           physics: const BouncingScrollPhysics(
//             parent: AlwaysScrollableScrollPhysics(),
//           ),
//           slivers: [
//             // ── Hero Section ───────────────────
//             SliverToBoxAdapter(
//               child: Padding(
//                 padding: const EdgeInsets.all(20.0),
//                 child: Column(
//                   children: [
//                     // Premium Hero Image with Glittering Border
//                     MovingGradientBorder(
//                       borderRadius: 32,
//                       borderWidth: 1.2,
//                       child: Container(
//                         height: 300,
//                         width: double.infinity,
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(32),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withValues(alpha: 0.4),
//                               blurRadius: 40,
//                               offset: const Offset(0, 20),
//                             ),
//                           ],
//                         ),
//                         child: ClipRRect(
//                           borderRadius: BorderRadius.circular(32),
//                           child: Stack(
//                             fit: StackFit.expand,
//                             children: [
//                               CachedNetworkImage(
//                                 imageUrl: event?.eventThumbnail ?? "",
//                                 fit: BoxFit.cover,
//                                 placeholder:
//                                     (context, url) => Container(
//                                       color: GusTheme.surface,
//                                       child: const Center(
//                                         child: CupertinoActivityIndicator(
//                                           color: GusTheme.gold,
//                                         ),
//                                       ),
//                                     ),
//                                 errorWidget:
//                                     (context, url, error) => Container(
//                                       color: GusTheme.surface,
//                                       child: const Icon(
//                                         Clarity.image_line,
//                                         color: GusTheme.textMuted,
//                                         size: 48,
//                                       ),
//                                     ),
//                               ),
//                               // Deeper Gradient Overlay for Vault-like feel
//                               Container(
//                                 decoration: BoxDecoration(
//                                   gradient: LinearGradient(
//                                     begin: Alignment.topCenter,
//                                     end: Alignment.bottomCenter,
//                                     colors: [
//                                       Colors.transparent,
//                                       Colors.black.withValues(alpha: 0.2),
//                                       Colors.black.withValues(alpha: 0.85),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                               // Event Details Overlay
//                               Positioned(
//                                 bottom: 24,
//                                 left: 24,
//                                 right: 24,
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     if (_formattedDate().isNotEmpty)
//                                       Container(
//                                         padding: const EdgeInsets.symmetric(
//                                           horizontal: 8,
//                                           vertical: 4,
//                                         ),
//                                         decoration: BoxDecoration(
//                                           color: GusTheme.gold.withValues(
//                                             alpha: 0.15,
//                                           ),
//                                           borderRadius: BorderRadius.circular(
//                                             6,
//                                           ),
//                                         ),
//                                         child: Text(
//                                           _formattedDate().toUpperCase(),
//                                           style: GoogleFonts.inter(
//                                             color: GusTheme.gold,
//                                             fontSize: 10,
//                                             fontWeight: FontWeight.w800,
//                                             letterSpacing: 1.5,
//                                           ),
//                                         ),
//                                       ),
//                                     const SizedBox(height: 12),
//                                     Text(
//                                       event?.title ?? "",
//                                       style: GoogleFonts.cormorantGaramond(
//                                         color: Colors.white,
//                                         fontSize: 32,
//                                         fontWeight: FontWeight.w700,
//                                         height: 1.0,
//                                         letterSpacing: -0.5,
//                                       ),
//                                       maxLines: 2,
//                                       overflow: TextOverflow.ellipsis,
//                                     ),
//                                     if ((event?.location ?? "").isNotEmpty) ...[
//                                       const SizedBox(height: 10),
//                                       Row(
//                                         children: [
//                                           const Icon(
//                                             Icons.location_on_rounded,
//                                             color: GusTheme.gold,
//                                             size: 14,
//                                           ),
//                                           const SizedBox(width: 6),
//                                           Expanded(
//                                             child: Text(
//                                               event!.location!,
//                                               style: GoogleFonts.inter(
//                                                 color: Colors.white.withValues(
//                                                   alpha: 0.6,
//                                                 ),
//                                                 fontSize: 13,
//                                                 fontWeight: FontWeight.w500,
//                                               ),
//                                               maxLines: 1,
//                                               overflow: TextOverflow.ellipsis,
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ],
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                   ],
//                 ),
//               ),
//             ),

//             // ── Dashboard Sections ────────────
//             SliverPadding(
//               padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
//               sliver: SliverList(
//                 delegate: SliverChildListDelegate([
//                   // ─ Invitations & Scanning ──────
//                   _buildSectionCard(
//                     title: "Mialiko ya Digital",
//                     rows: [
//                       _buildActionRow(
//                         icon: Clarity.email_line,
//                         iconGradient: const [
//                           Color(0xFF6366F1),
//                           Color(0xFF818CF8),
//                         ],
//                         title: "Kadi Zote",
//                         count: "$invsCount",
//                         onTap: () async {
//                           try {
//                             await Navigator.of(context).push(
//                               MaterialPageRoute(
//                                 builder:
//                                     (context) => Attendees(
//                                       edata: event!,
//                                       kardType: KardType.invitation,
//                                     ),
//                               ),
//                             );
//                             loadData();
//                           } catch (e) {
//                             showToast(isGood: false, msg: e.toString());
//                           }
//                         },
//                       ),
//                       _buildActionRow(
//                         icon: Clarity.qr_code_line,
//                         iconGradient: const [
//                           Color(0xFF8B5CF6),
//                           Color(0xFFA78BFA),
//                         ],
//                         title: "Skani Kadi",
//                         count: "",
//                         onTap: () {
//                           Navigator.of(context).push(
//                             MaterialPageRoute(
//                               builder:
//                                   (context) =>
//                                       CheckPoints(edata: widget.eventO),
//                             ),
//                           );
//                         },
//                         isLast: true,
//                       ),
//                     ],
//                   ),

//                   const SizedBox(height: 28),

//                   // ─ Contributions & Budget ──────
//                   _buildSectionCard(
//                     title: "Michango & Bajeti",
//                     rows: [
//                       _buildActionRow(
//                         icon: Icons.monetization_on_outlined,
//                         iconGradient: const [
//                           Color(0xFF10B981),
//                           Color(0xFF34D399),
//                         ],
//                         title: "Michango",
//                         count: "$contsCount",
//                         onTap: () async {
//                           try {
//                             await Navigator.of(context).push(
//                               MaterialPageRoute(
//                                 builder:
//                                     (context) => Attendees(
//                                       edata: event!,
//                                       kardType: KardType.contribution,
//                                       title: "Ratibu Michango",
//                                     ),
//                               ),
//                             );
//                             loadData();
//                           } catch (e) {
//                             showToast(isGood: false, msg: e.toString());
//                           }
//                         },
//                       ),
//                       _buildActionRow(
//                         icon: Icons.account_balance_wallet_outlined,
//                         iconGradient: const [
//                           Color(0xFF059669),
//                           Color(0xFF10B981),
//                         ],
//                         title: "Bajeti",
//                         count: "",
//                         onTap: () {
//                           showToast(
//                             isGood: true,
//                             msg: "Feature inakuja hivi karibuni!",
//                           );
//                         },
//                         isLast: true,
//                       ),
//                     ],
//                   ),

//                   const SizedBox(height: 28),

//                   // ─ Card & SMS Design ───────────
//                   _buildSectionCard(
//                     title: "Dizaini Kadi & SMS",
//                     rows: [
//                       _buildActionRow(
//                         icon: Icons.style_outlined,
//                         iconGradient: const [
//                           Color(0xFFF59E0B),
//                           Color(0xFFFBBF24),
//                         ],
//                         title: "Temp za Kadi",
//                         count: "$cardTempsNo",
//                         onTap: () {
//                           Navigator.of(context).push(
//                             MaterialPageRoute(
//                               builder:
//                                   (context) =>
//                                       Cards(eId: widget.eventO.id ?? ""),
//                             ),
//                           );
//                         },
//                       ),
//                       _buildActionRow(
//                         icon: Icons.sms_outlined,
//                         iconGradient: const [
//                           Color(0xFFEF4444),
//                           Color(0xFFF87171),
//                         ],
//                         title: "Temp za SMS",
//                         count: "$evMsgTmpCount",
//                         onTap: () {
//                           Navigator.of(context).push(
//                             MaterialPageRoute(
//                               builder:
//                                   (context) =>
//                                       InvEditor(eId: widget.eventO.id ?? ""),
//                             ),
//                           );
//                         },
//                         isLast: true,
//                       ),
//                     ],
//                   ),

//                   const SizedBox(height: 28),

//                   // ─ Admins & Vendors ────────────
//                   _buildSectionCard(
//                     title: "Wasimamizi & Vendors",
//                     rows: [
//                       _buildActionRow(
//                         icon: Icons.storefront_outlined,
//                         iconGradient: const [
//                           Color(0xFFEC4899),
//                           Color(0xFFF472B6),
//                         ],
//                         title: "Vendors",
//                         count: "$scannersCount",
//                         onTap: () {
//                           showToast(isGood: true, msg: "Inakuja hivi karibuni");
//                         },
//                       ),
//                       _buildActionRow(
//                         icon: Clarity.users_line,
//                         iconGradient: const [
//                           Color(0xFF3B82F6),
//                           Color(0xFF60A5FA),
//                         ],
//                         title: "Wasimamizi",
//                         count: "$adminsCount",
//                         onTap: () async {
//                           await Navigator.of(context).push(
//                             MaterialPageRoute(
//                               builder: (context) => Users(eId: event?.id ?? ""),
//                             ),
//                           );
//                           loadData();
//                         },
//                         isLast: true,
//                       ),
//                     ],
//                   ),
//                 ]),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   safeState(runnable) {
//     if (mounted) {
//       setState(() {
//         runnable();
//       });
//     }
//   }

//   popper() {
//     Navigator.of(context).pop();
//   }
// }

// class ChkpnForm extends StatefulWidget {
//   final String eId;
//   const ChkpnForm({super.key, required this.eId});

//   @override
//   State<ChkpnForm> createState() => _ChkpnFormState();
// }

// class _ChkpnFormState extends State<ChkpnForm> {
//   List selCrdsIds = [];
//   bool isLoading = false;
//   GlobalKey<FormState> key = GlobalKey<FormState>();
//   FirebaseFirestore firestore = FirebaseFirestore.instance;
//   TextEditingController controller = TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder(
//       future:
//           firestore.collection(ecol).doc(widget.eId).collection(cardcol).get(),
//       builder: (context, snapshot) {
//         if (snapshot.hasData) {
//           List<Kard> fcards =
//               (snapshot.data as dynamic).docs.map<Kard>((doc) {
//                 return Kard.fromMap(doc.id, doc.data());
//               }).toList();

//           return Form(
//             key: key,
//             child: ListView(
//               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//               children: [
//                 Text(
//                   "Checkpoint Name",
//                   style: GoogleFonts.cormorantGaramond(
//                     fontWeight: FontWeight.w700,
//                     fontSize: 22,
//                     color: GusTheme.textPrimary,
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 TextFormField(
//                   controller: controller,
//                   style: const TextStyle(
//                     color: GusTheme.textPrimary,
//                     fontWeight: FontWeight.w500,
//                   ),
//                   decoration: InputDecoration(
//                     hintText: "Enter checkpoint name",
//                     filled: true,
//                     fillColor: GusTheme.surface,
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(14),
//                       borderSide: BorderSide.none,
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(14),
//                       borderSide: const BorderSide(
//                         color: GusTheme.gold,
//                         width: 2,
//                       ),
//                     ),
//                     contentPadding: const EdgeInsets.symmetric(
//                       horizontal: 20,
//                       vertical: 18,
//                     ),
//                     prefixIcon: const Icon(
//                       Icons.edit_rounded,
//                       color: GusTheme.textMuted,
//                     ),
//                     hintStyle: const TextStyle(color: GusTheme.textMuted),
//                   ),
//                   validator:
//                       (value) =>
//                           value == null || value.isEmpty
//                               ? "Name is required"
//                               : null,
//                   textCapitalization: TextCapitalization.sentences,
//                 ),
//                 const SizedBox(height: 32),
//                 if (fcards.isNotEmpty)
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Icon(
//                             Icons.credit_card_rounded,
//                             size: 24,
//                             color: GusTheme.gold,
//                           ),
//                           const SizedBox(width: 12),
//                           Text(
//                             "Accepted Cards",
//                             style: GoogleFonts.cormorantGaramond(
//                               fontSize: 18,
//                               fontWeight: FontWeight.w700,
//                               color: GusTheme.textPrimary,
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 20),
//                       ...List.generate(fcards.length, (idx) {
//                         bool isSelected = selCrdsIds.contains(fcards[idx].id);
//                         return AnimatedContainer(
//                           duration: const Duration(milliseconds: 200),
//                           margin: const EdgeInsets.only(bottom: 12),
//                           decoration: BoxDecoration(
//                             color:
//                                 isSelected
//                                     ? GusTheme.gold.withOpacity(0.1)
//                                     : GusTheme.surface,
//                             borderRadius: BorderRadius.circular(14),
//                             border: Border.all(
//                               color:
//                                   isSelected
//                                       ? GusTheme.gold.withOpacity(0.5)
//                                       : GusTheme.glassBorder,
//                             ),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(
//                                   isSelected ? 0.15 : 0.1,
//                                 ),
//                                 blurRadius: 6,
//                                 offset: const Offset(0, 2),
//                               ),
//                             ],
//                           ),
//                           child: CheckboxListTile(
//                             value: isSelected,
//                             title: Text(
//                               fcards[idx].type,
//                               style: TextStyle(
//                                 fontWeight:
//                                     isSelected
//                                         ? FontWeight.w700
//                                         : FontWeight.w500,
//                                 color: Colors.black87,
//                               ),
//                             ),
//                             secondary: Icon(
//                               isSelected
//                                   ? Icons.check_circle_rounded
//                                   : Icons.circle_outlined,
//                               color:
//                                   isSelected ? GusTheme.gold : Colors.grey[600],
//                               size: 28,
//                             ),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(14),
//                             ),
//                             contentPadding: const EdgeInsets.symmetric(
//                               horizontal: 20,
//                             ),
//                             onChanged: (val) {
//                               setState(() {
//                                 if (isSelected) {
//                                   selCrdsIds.remove(fcards[idx].id);
//                                 } else {
//                                   selCrdsIds.add(fcards[idx].id);
//                                 }
//                               });
//                             },
//                           ),
//                         );
//                       }),
//                     ],
//                   )
//                 else
//                   _buildEmptyCardsState(),
//                 const SizedBox(height: 40),
//                 ElevatedButton(
//                   onPressed:
//                       !isLoading
//                           ? () async {
//                             if (key.currentState?.validate() ?? false) {
//                               await crtActn(selCrdsIds: selCrdsIds);
//                             }
//                           }
//                           : null,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: GusTheme.gold,
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(vertical: 18),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(14),
//                     ),
//                     elevation: 0,
//                     shadowColor: Colors.black.withOpacity(0.2),
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       if (isLoading)
//                         SizedBox(
//                           width: 24,
//                           height: 24,
//                           child: CircularProgressIndicator(
//                             color: Colors.white,
//                             strokeWidth: 3,
//                           ),
//                         )
//                       else
//                         const Icon(Icons.save_rounded, size: 24),
//                       const SizedBox(width: 12),
//                       Text(
//                         isLoading ? "Saving..." : "Save Checkpoint",
//                         style: const TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.w700,
//                           letterSpacing: 0.5,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 24),
//               ],
//             ),
//           );
//         } else if (snapshot.hasError) {
//           return Center();
//         }
//         return Center();
//       },
//     );
//   }

//   Widget _buildEmptyCardsState() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 40),
//       child: Center(
//         child: Column(
//           children: [
//             Icon(
//               Icons.credit_card_off_rounded,
//               size: 60,
//               color: Colors.grey[400],
//             ),
//             const SizedBox(height: 20),
//             Text(
//               "No Cards Available",
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w700,
//                 color: Colors.grey[600],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> crtActn({selCrdsIds}) async {
//     setState(() => isLoading = true);
//     try {
//       WriteBatch batch = firestore.batch();
//       var chkpnRef =
//           firestore
//               .collection(ecol)
//               .doc(widget.eId)
//               .collection(echecksub)
//               .doc();
//       List<DocumentReference<Map<String, dynamic>>> crdRefs = [];
//       for (var selCrdsId in selCrdsIds) {
//         var tmp = firestore
//             .collection(ecol)
//             .doc(widget.eId)
//             .collection(cardcol)
//             .doc(selCrdsId);
//         crdRefs.add(tmp);
//       }
//       CheckPoint checkPoint = CheckPoint(
//         id: chkpnRef.id,
//         name: controller.text,
//       );
//       batch.set(chkpnRef, checkPoint.toMap());
//       for (var crdRef in crdRefs) {
//         batch.update(crdRef, {
//           crdClrnc: FieldValue.arrayUnion([chkpnRef.id]),
//         });
//       }
//       await batch.commit();
//       setState(() => isLoading = false);
//       Navigator.pop(context);
//       showToast(isGood: true, msg: "Checkpoint created successfully");
//     } catch (e) {
//       setState(() => isLoading = false);
//       showToast(isGood: false, msg: "$e");
//     }
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/models/checkpoint.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/checkpoint/index.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/event_tools/inv_editor.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/settings/event_settings.dart';
import 'package:haflaway/top_destinations/event_dash/admin_panel/users_perms/users.dart';
import 'package:haflaway/top_destinations/event_dash/cards/cards.dart';
import 'package:haflaway/top_destinations/eventz/create_event.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/top_destinations/event_dash/attendees/attendees.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design Tokens
// ─────────────────────────────────────────────────────────────────────────────

class _T {
  static const bg = Color(0xFFF0EDE8);
  static const surface = Color(0xFFFAFAF8);
  static const ink = Color(0xFF181614);
  static const ink2 = Color(0xFF4A4540);
  static const ink3 = Color(0xFF9A9088);
  static const ink4 = Color(0xFFC8C0B8);
  static const border = Color(0xFFE8E4DF);
  static const accent = Color(0xFFC4622D);
  static const accentBg = Color(0xFFFAF0EB);
  static const accent2 = Color(0xFF2D6B5A);
  static const accent2Bg = Color(0xFFE8F4F0);
  static const gold = Color(0xFFB8903A);

  static TextStyle garamond({
    double size = 16,
    FontWeight weight = FontWeight.w300,
    Color color = ink,
    FontStyle style = FontStyle.normal,
    double? height,
    double letterSpacing = 0,
  }) => GoogleFonts.cormorantGaramond(
    fontSize: size,
    fontWeight: weight,
    color: color,
    fontStyle: style,
    height: height,
    letterSpacing: letterSpacing,
  );

  static TextStyle grotesk({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = ink,
    double letterSpacing = 0,
    double? height,
  }) => GoogleFonts.spaceGrotesk(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );

  static TextStyle eyebrow({Color color = ink3}) => grotesk(
    size: 10,
    weight: FontWeight.w700,
    color: color,
    letterSpacing: 1.8,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// AdminPanel
// ─────────────────────────────────────────────────────────────────────────────

class AdminPanel extends StatefulWidget {
  final Event eventO;
  final bool isAdmin;
  const AdminPanel({super.key, required this.eventO, required this.isAdmin});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  Event? event;
  bool isLoading = false;
  bool hasError = false;
  int invsCount = 0;
  int contsCount = 0;
  int adminsCount = 0;
  int scannersCount = 0;
  int cardTempsNo = 0;
  int evMsgTmpCount = 0;

  final firestore = FirebaseFirestore.instance;
  final firebaseAuth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // ── Data ─────────────────────────────────────────────────────────────────────

  Future<void> loadData() async {
    safeState(() {
      isLoading = true;
      hasError = false;
    });
    try {
      final eventRef = firestore.collection(ecol).doc(widget.eventO.id);
      final attsRef = firestore
          .collection(ecol)
          .doc(widget.eventO.id)
          .collection(atcol);
      final cardsRef = firestore
          .collection(ecol)
          .doc(widget.eventO.id)
          .collection(cardcol);
      final msgsRef = firestore
          .collection(ecol)
          .doc(widget.eventO.id)
          .collection(evMsgTmpCol);

      final result = await Future.wait([
        eventRef.get(),
        attsRef.get(),
        cardsRef.count().get(),
        msgsRef.count().get(),
      ]);

      final eventSnapshot = result[0] as DocumentSnapshot<Map<String, dynamic>>;
      final attsSnapshot = result[1] as QuerySnapshot<Map<String, dynamic>>;
      final crdsSnapshot = result[2] as AggregateQuerySnapshot;
      final msgsSnapshot = result[3] as AggregateQuerySnapshot;

      invsCount =
          attsSnapshot.docs
              .where(
                (t) => Attendee.fromMap(
                  t.id,
                  t.data(),
                ).cards.containsKey(KardType.invitation.name),
              )
              .length;
      contsCount =
          attsSnapshot.docs
              .where(
                (t) => Attendee.fromMap(
                  t.id,
                  t.data(),
                ).cards.containsKey(KardType.contribution.name),
              )
              .length;

      event = Event.fromMap(eventSnapshot.id, eventSnapshot.data()!);
      cardTempsNo = crdsSnapshot.count ?? 0;
      evMsgTmpCount = msgsSnapshot.count ?? 0;
      adminsCount = event?.adminsIds?.length ?? 0;
      scannersCount = event?.usersIds?.length ?? 0;

      safeState(() {
        isLoading = false;
        hasError = false;
      });
    } catch (e) {
      safeState(() {
        isLoading = false;
        hasError = true;
      });
      debugPrint('AdminPanel error: $e');
    }
  }

  String _formattedDate() {
    try {
      if (event?.startDate != null) {
        return DateFormat(
          'EEE, MMM d · h:mm a',
        ).format(DateTime.parse(event!.startDate!));
      }
    } catch (_) {}
    return '';
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (hasError) return _buildErrorScaffold();
    if (isLoading && event == null) return _buildLoadingScaffold();
    return _buildMainScaffold();
  }

  // ── Loading scaffold ──────────────────────────────────────────────────────────

  Widget _buildLoadingScaffold() {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _T.ink,
        body: Column(
          children: [
            // keep the dark top bar visible during load
            _rawAppBar(),
            Expanded(
              child: Container(
                color: _T.surface,
                child: const Center(
                  child: CupertinoActivityIndicator(color: _T.accent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Main scaffold ─────────────────────────────────────────────────────────────

  Widget _buildMainScaffold() {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _T.surface,
        body: RefreshIndicator(
          onRefresh: loadData,
          color: _T.accent,
          backgroundColor: _T.surface,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(child: _buildTickerBar()),
              SliverToBoxAdapter(child: _buildEventSpread()),
              SliverToBoxAdapter(child: _divider()),
              SliverToBoxAdapter(child: _sectionRule('Scan Checkpoints')),
              SliverToBoxAdapter(child: _buildCheckpointStrip()),
              SliverToBoxAdapter(child: _sectionRule('Event Tools')),
              SliverToBoxAdapter(child: _buildToolTiles()),
              SliverToBoxAdapter(child: _sectionRule('Management Team')),
              SliverToBoxAdapter(child: _buildTeamRow()),
              SliverToBoxAdapter(child: _sectionRule('Contributions')),
              SliverToBoxAdapter(child: _buildContributionTile()),
              SliverToBoxAdapter(child: _buildPublishButton()),
              const SliverToBoxAdapter(child: SizedBox(height: 48)),
            ],
          ),
        ),
      ),
    );
  }

  // ── SliverAppBar ──────────────────────────────────────────────────────────────
  //
  // Dark ink top bar, pinned. Logo centre-left, three icon buttons right,
  // back chevron far left.  Uses SliverAppBar so it scrolls with the header
  // then pins once collapsed.

  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      snap: false,
      floating: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: _T.ink,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      toolbarHeight: 56,
      title: _rawAppBar(),
    );
  }

  // Shared bar content used in both the SliverAppBar and the loading scaffold
  Widget _rawAppBar() {
    return Container(
      height: 56,
      color: _T.ink,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Back chevron
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(
              Icons.chevron_left_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 6),

          // Logo
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Hafla',
                  style: _T.garamond(
                    size: 20,
                    weight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                TextSpan(
                  text: 'way',
                  style: _T.garamond(
                    size: 20,
                    weight: FontWeight.w600,
                    color: const Color(0xFFE8C97A),
                    style: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Action icons
          _appBarBtn(
            icon: Icons.calendar_today_rounded,
            onTap: () async {
              // await Navigator.of(
              //   context,
              // ).push(MaterialPageRoute(builder: (_) => DashboardScreen()));
              loadData();
            },
          ),
          const SizedBox(width: 8),
          _appBarBtn(
            icon: Icons.settings_rounded,
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => EventSettings(event: event)),
              );
              loadData();
            },
          ),
          const SizedBox(width: 8),
          _appBarBtn(
            icon: Icons.edit_rounded,
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => CreateEvent(event: event)),
              );
              loadData();
            },
          ),
        ],
      ),
    );
  }

  Widget _appBarBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 33,
        height: 33,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 0.5),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }

  // ── Ticker bar ────────────────────────────────────────────────────────────────

  Widget _buildTickerBar() {
    final items = [
      ('Event', 'LIVE'),
      ('Invitations', '$invsCount sent'),
      ('Contributions', '$contsCount'),
      ('Admins', '$adminsCount'),
    ];

    return Container(
      color: _T.ink,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children:
              items.asMap().entries.expand((e) {
                final isLast = e.key == items.length - 1;
                return [
                  _tickerChip(label: e.value.$1, value: e.value.$2),
                  if (!isLast) ...[
                    const SizedBox(width: 14),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 14),
                  ],
                ];
              }).toList(),
        ),
      ),
    );
  }

  Widget _tickerChip({required String label, required String value}) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: _T.grotesk(
            size: 10,
            weight: FontWeight.w500,
            color: Colors.white38,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: _T.grotesk(
            size: 10,
            weight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // ── Event spread ──────────────────────────────────────────────────────────────

  Widget _buildEventSpread() {
    return Container(
      color: _T.surface,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Eyebrow + rule
          Row(
            children: [
              Text('Admin Panel', style: _T.eyebrow(color: _T.accent)),
              const SizedBox(width: 8),
              Expanded(
                child: Container(height: 1, color: _T.accent.withOpacity(0.25)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Headline
          Text(
            event?.title ?? widget.eventO.title ?? '',
            style: _T.garamond(
              size: 40,
              weight: FontWeight.w300,
              height: 1.0,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),

          // Date
          if (_formattedDate().isNotEmpty)
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 12,
                  color: _T.ink3,
                ),
                const SizedBox(width: 5),
                Text(
                  _formattedDate(),
                  style: _T.grotesk(size: 12, color: _T.ink3),
                ),
              ],
            ),

          // Location
          if ((event?.location ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 12, color: _T.ink3),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    event!.location!,
                    style: _T.grotesk(size: 12, color: _T.ink3),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),

          // Two-column stat spread
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _statBlock(
                        micro: 'Invitations',
                        number: '$invsCount',
                        desc: 'cards sent out',
                        progressValue: invsCount > 0 ? 0.7 : 0.0,
                        progressColor: _T.accent2,
                      ),
                      const SizedBox(height: 18),
                      _statBlock(
                        micro: 'Confirmed',
                        number: '${(invsCount * 0.7).round()}',
                        desc: '${invsCount > 0 ? "70" : "0"}% of invitations',
                      ),
                    ],
                  ),
                ),
                // Vertical hairline
                Container(
                  width: 1,
                  color: _T.border,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _statBlock(
                        micro: 'Contributions',
                        number: '$contsCount',
                        desc: 'guests contributed',
                        progressValue: contsCount > 0 ? 0.78 : 0.0,
                        progressColor: _T.gold,
                      ),
                      const SizedBox(height: 18),
                      _statBlock(
                        micro: 'Card Templates',
                        number: '$cardTempsNo',
                        desc: 'active templates',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBlock({
    required String micro,
    required String number,
    required String desc,
    double? progressValue,
    Color? progressColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(micro.toUpperCase(), style: _T.eyebrow()),
        const SizedBox(height: 2),
        Text(
          number,
          style: _T.garamond(size: 48, weight: FontWeight.w600, height: 1.0),
        ),
        const SizedBox(height: 2),
        Text(desc, style: _T.grotesk(size: 11, color: _T.ink3, height: 1.4)),
        if (progressValue != null) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(1),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 2,
              backgroundColor: _T.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                progressColor ?? _T.accent,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Layout helpers ────────────────────────────────────────────────────────────

  Widget _divider() => Container(height: 1, color: _T.border);

  Widget _sectionRule(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
      child: Row(
        children: [
          Text(label.toUpperCase(), style: _T.eyebrow()),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: _T.border)),
        ],
      ),
    );
  }

  // ── Checkpoint strip (horizontal scroll) ──────────────────────────────────────

  Widget _buildCheckpointStrip() {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        children: [
          GestureDetector(
            onTap:
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CheckPoints(edata: widget.eventO),
                  ),
                ),
            child: Row(
              children: [
                _cpCard(label: 'Main Gate', name: 'Main Entrance', count: '—'),
                const SizedBox(width: 8),
                _cpCard(label: 'Lounge', name: 'VIP Lounge', count: '—'),
                const SizedBox(width: 8),
              ],
            ),
          ),
          _cpAddCard(),
        ],
      ),
    );
  }

  Widget _cpCard({
    required String label,
    required String name,
    required String count,
  }) {
    return Container(
      width: 112,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _T.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _T.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: _T.eyebrow()),
          const SizedBox(height: 6),
          Text(
            name,
            style: _T.grotesk(size: 13, weight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(count, style: _T.garamond(size: 22, weight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _cpAddCard() {
    return GestureDetector(
      onTap:
          () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CheckPoints(edata: widget.eventO),
            ),
          ),
      child: Container(
        width: 64,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _T.ink4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _T.ink4),
              ),
              child: const Icon(Icons.add, size: 13, color: _T.ink4),
            ),
            const SizedBox(height: 4),
            Text('Add', style: _T.grotesk(size: 10, color: _T.ink4)),
          ],
        ),
      ),
    );
  }

  // ── Tool tiles ────────────────────────────────────────────────────────────────

  Widget _buildToolTiles() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _toolTile(
            number: '$cardTempsNo',
            title: 'Card Templates',
            subtitle: 'Design & manage invitation cards',
            tag: 'Active',
            isComingSoon: false,
            onTap:
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => Cards(eId: widget.eventO.id ?? ''),
                  ),
                ),
          ),
          const SizedBox(height: 2),
          _toolTile(
            number: '$evMsgTmpCount',
            title: 'SMS Templates',
            subtitle: 'Guest notification messages',
            tag: 'Active',
            isComingSoon: false,
            onTap:
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => InvEditor(eId: widget.eventO.id ?? ''),
                  ),
                ),
          ),
          const SizedBox(height: 2),
          _toolTile(
            number: '—',
            title: 'Vendors',
            subtitle: 'Service providers & suppliers',
            tag: 'Coming Soon',
            isComingSoon: true,
            onTap: () => showToast(isGood: true, msg: 'Coming soon!'),
          ),
          const SizedBox(height: 2),
          _toolTile(
            number: '—',
            title: 'Event MCs',
            subtitle: 'Masters of ceremony & hosts',
            tag: 'Coming Soon',
            isComingSoon: true,
            onTap: () => showToast(isGood: true, msg: 'Coming soon!'),
          ),
          const SizedBox(height: 2),
          _toolTile(
            number: '—',
            title: 'Venue',
            subtitle: 'Hall & venue management',
            tag: 'Coming Soon',
            isComingSoon: true,
            onTap: () => showToast(isGood: true, msg: 'Coming soon!'),
          ),
          const SizedBox(height: 2),
          _toolTile(
            number: '—',
            title: 'Budget',
            subtitle: 'Plan & track event expenses',
            tag: 'Coming Soon',
            isComingSoon: true,
            onTap: () => showToast(isGood: true, msg: 'Coming soon!'),
          ),
        ],
      ),
    );
  }

  Widget _toolTile({
    required String number,
    required String title,
    required String subtitle,
    required String tag,
    required bool isComingSoon,
    required VoidCallback onTap,
  }) {
    return Opacity(
      opacity: isComingSoon ? 0.55 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: _T.bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 38,
                  child: Text(
                    number,
                    style: _T.garamond(
                      size: 28,
                      weight: FontWeight.w600,
                      color: isComingSoon ? _T.ink4 : _T.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: _T.grotesk(size: 13, weight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: _T.grotesk(size: 11, color: _T.ink3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _tagChip(label: tag, isComingSoon: isComingSoon),
                const SizedBox(width: 8),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _T.border),
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    size: 14,
                    color: _T.ink3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tagChip({required String label, required bool isComingSoon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isComingSoon ? _T.bg : _T.accent2Bg,
        borderRadius: BorderRadius.circular(4),
        border: isComingSoon ? Border.all(color: _T.border) : null,
      ),
      child: Text(
        label.toUpperCase(),
        style: _T.grotesk(
          size: 9,
          weight: FontWeight.w700,
          color: isComingSoon ? _T.ink4 : _T.accent2,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // ── Team row ──────────────────────────────────────────────────────────────────

  Widget _buildTeamRow() {
    const avatarData = [
      ('FA', Color(0xFFFAF0EB), _T.accent),
      ('JK', Color(0xFFE8EFF8), Color(0xFF2D5A8A)),
      ('AM', Color(0xFFE8F4F0), _T.accent2),
      ('SK', Color(0xFFF4E8F8), Color(0xFF6B2D8A)),
    ];
    const avatarSize = 34.0;
    const overlap = 10.0;
    final stackWidth =
        avatarSize + (avatarData.length - 1) * (avatarSize - overlap);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          SizedBox(
            width: stackWidth,
            height: avatarSize,
            child: Stack(
              children:
                  avatarData.asMap().entries.map((e) {
                    final d = e.value;
                    return Positioned(
                      left: e.key * (avatarSize - overlap),
                      child: Container(
                        width: avatarSize,
                        height: avatarSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: d.$2,
                          border: Border.all(color: _T.surface, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            d.$1,
                            style: _T.grotesk(
                              size: 11,
                              weight: FontWeight.w700,
                              color: d.$3,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$adminsCount administrators',
              style: _T.grotesk(size: 12, color: _T.ink3),
            ),
          ),
          GestureDetector(
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => Users(eId: event?.id ?? '')),
              );
              loadData();
            },
            child: Text(
              'Manage →',
              style: _T.grotesk(
                size: 11,
                weight: FontWeight.w600,
                color: _T.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Contribution tile ─────────────────────────────────────────────────────────

  Widget _buildContributionTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _toolTile(
        number: '$contsCount',
        title: 'Contributions',
        subtitle: 'Manage guest contributions',
        tag: 'Active',
        isComingSoon: false,
        onTap: () async {
          try {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (_) => Attendees(
                      edata: event!,
                      kardType: KardType.contribution,
                      title: 'Manage Contributions',
                    ),
              ),
            );
            loadData();
          } catch (e) {
            showToast(isGood: false, msg: e.toString());
          }
        },
      ),
    );
  }

  // ── Publish button ────────────────────────────────────────────────────────────

  Widget _buildPublishButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () async {
            // await Navigator.of(
            //   context,
            // ).push(MaterialPageRoute(builder: (_) => DashboardScreen()));
            loadData();
          },
          icon: const Icon(Icons.upload_rounded, size: 18),
          label: Text(
            'Publish Event',
            style: _T.grotesk(
              size: 14,
              weight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _T.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  // ── Error scaffold ────────────────────────────────────────────────────────────

  Widget _buildErrorScaffold() {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _T.surface,
        body: Column(
          children: [
            _rawAppBar(),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: const BoxDecoration(
                          color: _T.accentBg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.wifi_off_rounded,
                          color: _T.accent,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Something went wrong',
                        style: _T.garamond(size: 24, weight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We encountered an error loading the event data. '
                        'Please try again.',
                        textAlign: TextAlign.center,
                        style: _T.grotesk(size: 14, color: _T.ink3),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: loadData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _T.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Retry Now',
                          style: _T.grotesk(
                            size: 14,
                            weight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Utils ─────────────────────────────────────────────────────────────────────

  void safeState(VoidCallback fn) {
    if (mounted) setState(fn);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ChkpnForm — untouched logic, styled to match
// ─────────────────────────────────────────────────────────────────────────────

class ChkpnForm extends StatefulWidget {
  final String eId;
  const ChkpnForm({super.key, required this.eId});

  @override
  State<ChkpnForm> createState() => _ChkpnFormState();
}

class _ChkpnFormState extends State<ChkpnForm> {
  List selCrdsIds = [];
  bool isLoading = false;
  final key = GlobalKey<FormState>();
  final firestore = FirebaseFirestore.instance;
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future:
          firestore.collection(ecol).doc(widget.eId).collection(cardcol).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center();
        if (snapshot.hasError) return const Center();

        final fcards =
            (snapshot.data as dynamic).docs
                .map<Kard>((doc) => Kard.fromMap(doc.id, doc.data()))
                .toList();

        return Form(
          key: key,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            children: [
              Text(
                'Checkpoint Name',
                style: _T.garamond(size: 22, weight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: controller,
                style: _T.grotesk(size: 15, weight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'Enter checkpoint name',
                  hintStyle: _T.grotesk(color: _T.ink4),
                  filled: true,
                  fillColor: _T.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _T.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _T.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _T.accent, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  prefixIcon: const Icon(
                    Icons.edit_rounded,
                    color: _T.ink3,
                    size: 18,
                  ),
                ),
                validator:
                    (v) => (v == null || v.isEmpty) ? 'Name is required' : null,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 28),

              if (fcards.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.credit_card_rounded,
                      size: 20,
                      color: _T.accent,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Accepted Cards',
                      style: _T.garamond(size: 18, weight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...fcards.map((card) {
                  final isSelected = selCrdsIds.contains(card.id);
                  return GestureDetector(
                    onTap:
                        () => setState(() {
                          isSelected
                              ? selCrdsIds.remove(card.id)
                              : selCrdsIds.add(card.id);
                        }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? _T.accentBg : _T.bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color:
                              isSelected
                                  ? _T.accent.withOpacity(0.4)
                                  : _T.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            color: isSelected ? _T.accent : _T.ink4,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            card.type,
                            style: _T.grotesk(
                              size: 14,
                              weight:
                                  isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                              color: isSelected ? _T.accent : _T.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ] else
                _emptyCards(),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      !isLoading
                          ? () async {
                            if (key.currentState?.validate() ?? false) {
                              await crtActn(selCrdsIds: selCrdsIds);
                            }
                          }
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _T.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child:
                      isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                          : Text(
                            'Save Checkpoint',
                            style: _T.grotesk(
                              size: 14,
                              weight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _emptyCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Icon(Icons.credit_card_off_rounded, size: 48, color: _T.ink4),
          const SizedBox(height: 16),
          Text(
            'No Cards Available',
            style: _T.grotesk(
              size: 16,
              weight: FontWeight.w500,
              color: _T.ink3,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> crtActn({required List selCrdsIds}) async {
    setState(() => isLoading = true);
    try {
      final batch = firestore.batch();
      final chkpnRef =
          firestore
              .collection(ecol)
              .doc(widget.eId)
              .collection(echecksub)
              .doc();

      final crdRefs =
          selCrdsIds
              .map(
                (id) => firestore
                    .collection(ecol)
                    .doc(widget.eId)
                    .collection(cardcol)
                    .doc(id as String),
              )
              .toList();

      batch.set(
        chkpnRef,
        CheckPoint(id: chkpnRef.id, name: controller.text).toMap(),
      );
      for (final ref in crdRefs) {
        batch.update(ref, {
          crdClrnc: FieldValue.arrayUnion([chkpnRef.id]),
        });
      }

      await batch.commit();
      setState(() => isLoading = false);
      if (mounted) Navigator.pop(context);
      showToast(isGood: true, msg: 'Checkpoint created successfully');
    } catch (e) {
      setState(() => isLoading = false);
      showToast(isGood: false, msg: '$e');
    }
  }
}
