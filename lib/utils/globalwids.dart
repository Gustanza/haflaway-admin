import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/utils/constants.dart';
import 'package:haflaway/models/card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/strings.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import 'dimensions.dart';
import 'refs.dart';

showProgress({context, String message = "Loading..."}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Center(child: GusLoader(message: message));
    },
  );
}

buildLoader({String message = "Loading..."}) {
  return Center(child: GusLoader(message: message));
}

buildErr() {
  return Center(child: Text(gDErrMsg));
}

buildImage({url}) {
  return CachedNetworkImage(
    imageUrl: url,
    fit: BoxFit.cover,
    placeholder:
        (context, url) => Shimmer.fromColors(
          baseColor: primaryColor,
          highlightColor: primaryColor.withOpacity(0.85),
          child: Container(color: primaryColor),
        ),
    errorWidget: (context, url, error) => const Icon(Icons.error_outline),
  );
}

colorPreviewer({color}) {
  return Container(
    width: psm * 1.35,
    height: psm * 1.35,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(bmd * 10),
      border: Border.all(width: 1, color: Colors.grey),
    ),
  );
}

customSmBtn(Function() callback) {
  return GestureDetector(
    onTap: callback,
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: psm,
        vertical: psm * 0.25,
      ),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(bmd * 2),
      ),
      child: const Text("Edit", style: TextStyle()),
    ),
  );
}

buildShimmer() {
  return Shimmer.fromColors(
    baseColor: lqassgradBaseColor,
    highlightColor: lqassbdrColor,
    child: Container(color: Colors.green),
  );
}

class BuildNoDt extends StatelessWidget {
  final String string;
  final Function()? isTapped;
  final Future<void> Function()? isRefreshed;
  const BuildNoDt({
    super.key,
    required this.string,
    this.isTapped,
    this.isRefreshed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RefreshIndicator(
        onRefresh: isRefreshed ?? () async {},
        child: ListView(
          shrinkWrap: true,
          children: [
            LottieBuilder.asset(noDtLt, height: 200),
            SizedBox(
              // width: MediaQuery.of(context).size.width * 0.8,
              child: MaterialButton(
                onPressed: () {
                  if (isTapped != null) {
                    isTapped!();
                  }
                },
                child: const Text("Try again"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

buildCard(Kard card, Function() dTapd, edTapd) {
  return Container(
    margin: const EdgeInsets.only(bottom: psm * 0.5),
    decoration: BoxDecoration(
      gradient: lqassgrad,
      borderRadius: BorderRadius.circular(brsm),
    ),
    child: Column(
      children: [
        Expanded(
          child: FutureBuilder(
            future:
                FirebaseFirestore.instance
                    .collection(ecol)
                    .doc(card.eventId)
                    .collection(cardcol)
                    .doc(card.id)
                    .get(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                var dt = (snapshot.data as dynamic).data();
                if (dt != null) {
                  return ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(brsm),
                      topRight: Radius.circular(brsm),
                    ),
                    child: SizedBox(
                      width: double.maxFinite,
                      child: Stack(
                        children: [
                          // Positioned.fill(
                          //   child: buildImage(url: dt[tempccurl]),
                          // ),
                          Positioned(
                            top: psm,
                            right: psm,
                            child: MaterialButton(
                              color: destructiveColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(brsm),
                              ),
                              onPressed: () {
                                dTapd();
                              },
                              child: const Text(
                                "Delete",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: psm,
                            left: psm,
                            child: MaterialButton(
                              color: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(brsm),
                              ),
                              onPressed: () {
                                edTapd();
                              },
                              child: const Text(
                                "Edit",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  return buildErr();
                }
              } else {
                return buildShimmer();
              }
            },
          ),
        ),
        ListTile(
          title: Text(
            "Name: ${card.type}",
            maxLines: 1,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            "Capacity: ${card.capacity} person(s)",
            maxLines: 1,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

bldDrdDwn({
  lbl,
  entries,
  controller,
  onSelected,
  DropdownMenuEntry? initialSelection,
}) {
  return DropdownMenu(
    hintText: "$lbl",
    // label: Text("$lbl"),
    controller: controller,
    width: double.maxFinite,
    onSelected: onSelected,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      enabledBorder: inputBorder,
      border: inputBorder,
      focusedBorder: inputBorder,
      disabledBorder: inputBorder,
      fillColor: lqassgradBaseColor,
    ),
    dropdownMenuEntries:
        entries.map<DropdownMenuEntry>((e) {
          return DropdownMenuEntry(value: e.key, label: e.value);
        }).toList(),
  );
}

var inputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.circular(8),
  borderSide: BorderSide(color: lqassbdrColor, width: bdrWidthGen),
);

Widget buildField({
  String? lbl,
  double? brad,
  Widget? suff,
  bool? filled,
  bool? isReadOnly,
  bool? showCursor,
  Function? isTapped,
  TextInputType? type,
  Function? isChanged,
  TextEditingController? cont,
}) {
  return TextFormField(
    maxLines: null,
    controller: cont,
    validator: (value) {
      return validator(lbl: lbl, value: value);
    },
    onTap: () {
      if (isTapped != null) {
        isTapped();
      }
    },
    onChanged: (value) {
      if (isChanged != null) {
        isChanged();
      }
    },
    readOnly: isReadOnly ?? false,
    showCursor: showCursor ?? true,
    decoration: InputDecoration(
      hintText: lbl,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
      suffixIcon: suff,
      filled: true,
      enabledBorder: inputBorder,
      border: inputBorder,
      focusedBorder: inputBorder,
      disabledBorder: inputBorder,
      fillColor: lqassgradBaseColor,
    ),
    textCapitalization: TextCapitalization.sentences,
    keyboardType: type,
  );
}

validator({lbl, value}) {
  if (value.isEmpty) {
    return "This field is required";
  } else {
    return null;
  }
}

class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final double width;

  const MarqueeText({
    super.key,
    required this.text,
    required this.style,
    required this.width,
  });

  @override
  // ignore: library_private_types_in_public_api
  _MarqueeTextState createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.position.maxScrollExtent > 0) {
        _animationController.repeat();
        _animationController.addListener(_scrollListener);
      }
    });
  }

  void _scrollListener() {
    if (_animationController.isAnimating) {
      _scrollController.jumpTo(
        _animationController.value * _scrollController.position.maxScrollExtent,
      );
    }
  }

  @override
  void dispose() {
    _animationController.removeListener(_scrollListener);
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _scrollController,
        child: Text(widget.text, style: widget.style),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search empty states
// ─────────────────────────────────────────────────────────────────────────────

enum _GusSearchMode { prompt, noResults }

/// Drop-in replacement for search empty states.
/// [GusSearchEmpty.prompt] — shown before the user has typed anything.
/// [GusSearchEmpty.noResults] — shown when a query returns nothing.
class GusSearchEmpty extends StatelessWidget {
  final _GusSearchMode _mode;
  final String? query;

  const GusSearchEmpty.prompt({super.key})
    : _mode = _GusSearchMode.prompt,
      query = null;

  const GusSearchEmpty.noResults({super.key, this.query})
    : _mode = _GusSearchMode.noResults;

  @override
  Widget build(BuildContext context) {
    const lime = Color(0xFFC9A84C);
    const bg = Color(0xFF1C1C1E);
    const sep = Color(0xFF2C2C2E);
    const lbl1 = Color(0xFFFFFFFF);
    const lbl3 = Color(0xFF636366);

    final bool isPrompt = _mode == _GusSearchMode.prompt;

    final IconData icon =
        isPrompt ? Icons.search_rounded : Icons.manage_search_rounded;

    final String title = isPrompt ? "Search" : "No results";

    final String subtitle =
        isPrompt
            ? "Type a name to find someone"
            : query != null && query!.isNotEmpty
            ? "Nothing matched \"$query\""
            : "Try a different keyword";

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: sep, width: 0.8),
            ),
            child: Icon(
              icon,
              size: 28,
              color: isPrompt ? lime : lbl3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: lbl1,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: lbl3,
            ),
          ),
        ],
      ),
    );
  }
}

class GusLoader extends StatelessWidget {
  final String message;
  const GusLoader({super.key, this.message = "Loading..."});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 28),
        constraints: const BoxConstraints(minWidth: 200),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    color: Color(0xFFC9A84C), // Gold
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
