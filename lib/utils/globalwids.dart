import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:haflaway/models/attendee.dart';
import 'package:haflaway/models/event.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/strings.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import 'dimensions.dart';
import 'refs.dart';

showProgress({context}) {
  return showDialog(
    context: context,
    builder: (context) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    },
  );
}

buildLoader() {
  return const Center(child: CircularProgressIndicator());
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
    errorWidget: (context, url, error) => const Icon(Clarity.error_line),
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
    baseColor: primaryColor,
    highlightColor: primaryColor.withOpacity(0.7),
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

buildCard(Kard card, Function() tapd) {
  return Container(
    margin: const EdgeInsets.only(bottom: psm * 0.5),
    decoration: BoxDecoration(
      color: primaryColor,
      borderRadius: BorderRadius.circular(brsm),
    ),
    child: Column(
      children: [
        Expanded(
          child: FutureBuilder(
            future:
                FirebaseFirestore.instance
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
                          Positioned.fill(
                            child: buildImage(url: dt[tempccurl]),
                          ),
                          Positioned(
                            top: psm,
                            right: psm,
                            child: MaterialButton(
                              color: primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(brsm),
                              ),
                              onPressed: () {
                                tapd();
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
    label: Text("$lbl"),
    controller: controller,
    width: double.maxFinite,
    onSelected: onSelected,
    dropdownMenuEntries:
        entries.map<DropdownMenuEntry>((e) {
          return DropdownMenuEntry(value: e.key, label: e.value);
        }).toList(),
  );
}

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
  var border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: Colors.white.withOpacity(0.4), width: 0.5),
  );
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
      suffixIcon: suff,
      filled: true,
      fillColor: Colors.white.withOpacity(0.15),
      enabledBorder: border,
      border: border,
      focusedBorder: border,
      disabledBorder: border,
    ),
    textCapitalization: TextCapitalization.sentences,
    keyboardType: type,
  );
}

validator({lbl, value}) {
  switch (lbl) {
    case cardart:
      if (value.isEmpty) {
        return "$cardart is required";
      } else {
        return null;
      }
    case cardname:
      if (value.isEmpty) {
        return "$cardname is required";
      } else {
        return null;
      }
    case cardprice:
      if (value.isEmpty) {
        return "$cardprice is required";
      } else {
        return null;
      }
    case cardcap:
      if (value.isEmpty) {
        return "$cardcap is required";
      } else {
        return null;
      }

    case cardcount:
      if (value.isEmpty) {
        return "$cardcount is required";
      } else {
        return null;
      }
    case cardchecks:
      if (value.isEmpty) {
        return "$cardchecks are required";
      } else {
        return null;
      }

    case atlblname:
      if (value.isEmpty) {
        return "$atlblname is required";
      } else {
        return null;
      }

    case atlblphone:
      if (value.isEmpty) {
        return "$atlblphone is required";
      } else {
        return null;
      }

    // case atlblemail:
    //   if (value.isEmpty) {
    //     return "$atlblemail is required";
    //   } else {
    //     return null;
    //   }

    default:
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
