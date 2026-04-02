import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:haflaway/utils/strings.dart';
import 'package:url_launcher/url_launcher.dart';
import 'create_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design Tokens (Matching AdminPanel)
// ─────────────────────────────────────────────────────────────────────────────

class _T {
  static const bg = Color(0xFF0A0A0A);
  static const card = Color(0xFF141414);
  static const lime = Color(0xFFC9A84C);
  static const white = Color(0xFFFFFFFF);
  static const grey1 = Color(0xFFAAAAAA);
  static const grey2 = Color(0xFF555555);
  static const grey3 = Color(0xFF333333);

  static TextStyle f({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = white,
    double letterSpacing = 0,
    double? height,
  }) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );
}

class Cards extends StatefulWidget {
  final String eId;

  const Cards({super.key, required this.eId});

  @override
  State<Cards> createState() => _CardsState();
}

class _CardsState extends State<Cards> {
  FirebaseStorage storage = FirebaseStorage.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: _T.lime,
        foregroundColor: _T.bg,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.add_rounded, size: 28),
        onPressed: () async {
          var url = Uri.parse(
            "https://haflaway-designer.web.app/designer/${widget.eId}/create",
          );
          try {
            await launchUrl(url);
          } catch (e) {
            showToast(isGood: false, msg: "$e");
          }
        },
      ),
      body: SafeArea(
        child: StreamBuilder(
          stream:
              firestore
                  .collection(ecol)
                  .doc(widget.eId)
                  .collection(cardcol)
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              var docs = (snapshot.data as dynamic).docs;
              List<Kard> cList =
                  docs.map<Kard>((doc) {
                    return Kard.fromMap(doc.id, doc.data());
                  }).toList();

              return CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [_topBar(), _heroHeader()],
                      ),
                    ),
                  ),
                  if (docs.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          'No Templates Found',
                          style: _T.f(color: _T.grey2),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          return _buildCardItem(cList[index]);
                        }, childCount: cList.length),
                      ),
                    ),
                ],
              );
            } else if (snapshot.hasError) {
              return buildErr();
            } else {
              return const Center(
                child: CupertinoActivityIndicator(color: _T.lime),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: _T.lime,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Event Details',
                  style: _T.f(
                    size: 15,
                    weight: FontWeight.w500,
                    color: _T.white,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _heroHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Text(
        'Card Templates',
        style: _T.f(
          size: 32,
          weight: FontWeight.w800,
          color: _T.white,
          letterSpacing: -0.5,
          height: 1.1,
        ),
      ),
    );
  }

  Widget _buildCardItem(Kard card) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _T.grey3.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Whispered PURPOSE (Name) - Switched to TOP TAG
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _T.lime.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  card.purpose.toUpperCase(),
                  style: _T.f(
                    size: 9,
                    weight: FontWeight.w700,
                    color: _T.lime,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Row(
                children: [
                  _actionIcon(
                    icon: Icons.edit_note_rounded,
                    onTap: () async {
                      var url = Uri.parse(
                        "https://haflaway-designer.web.app/designer/${widget.eId}/${card.id}/edit",
                      );
                      try {
                        await launchUrl(url);
                      } catch (e) {
                        showToast(isGood: false, msg: "$e");
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  _actionIcon(
                    icon: Icons.delete_outline_rounded,
                    color: Colors.redAccent.withOpacity(0.8),
                    onTap: () => cdelete(card),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Loud TYPE - Switched to MAIN TITLE
          Text(
            card.type,
            style: _T.f(
              size: 16,
              weight: FontWeight.w900,
              color: _T.white,
              letterSpacing: -1.0,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _stat(Icons.people_alt_outlined, 'Capacity: ${card.capacity}'),
              const SizedBox(width: 20),
              _stat(
                Icons.door_sliding_outlined,
                '${card.clearAt.length} Checkpoints',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _T.grey1),
        const SizedBox(width: 6),
        Text(value, style: _T.f(size: 13, color: _T.grey1)),
      ],
    );
  }

  Widget _actionIcon({
    required IconData icon,
    required VoidCallback onTap,
    Color color = _T.lime,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: color, size: 22),
    );
  }

  cdelete(Kard kard) async {
    return await showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text("Delete Template?", style: _T.f(weight: FontWeight.bold)),
          content: Text(
            "This will permanently remove this card template. This action cannot be undone.",
            style: _T.f(size: 13),
          ),
          actions: [
            CupertinoButton(
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
              onPressed: () async {
                try {
                  showProgress(context: context);

                  var cref = firestore
                      .collection(ecol)
                      .doc(widget.eId)
                      .collection(cardcol)
                      .doc(kard.id);

                  await cref.delete();

                  popper();
                  popper();
                  showToast(msg: "Template deleted", isGood: true);
                } catch (e) {
                  showToast(msg: "$e", isGood: false);
                  popper();
                  popper();
                }
              },
            ),
            CupertinoButton(
              child: Text("Cancel", style: _T.f()),
              onPressed: () {
                popper();
              },
            ),
          ],
        );
      },
    );
  }

  popper() {
    Navigator.of(context).pop();
  }
}
