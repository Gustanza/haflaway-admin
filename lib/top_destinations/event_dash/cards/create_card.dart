import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:haflaway/components/appbar.dart';
import 'package:haflaway/components/sheets.dart';
import 'package:haflaway/utils/strings.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/models/card.dart';
import 'package:haflaway/top_destinations/event_dash/cards/modalcheckpoints.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/globalfns.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:haflaway/utils/styles.dart';
import '../../../utils/dimensions.dart';

class CreateCard extends StatefulWidget {
  final String eId;
  final dynamic card;
  const CreateCard({super.key, required this.eId, this.card});

  @override
  State<CreateCard> createState() => _CreateCardState();
}

class _CreateCardState extends State<CreateCard> {
  XFile? pic;
  dynamic cardConfig;
  String? cpurpose;
  List checkpoints = [];
  FirebaseFirestore fstr = FirebaseFirestore.instance;
  TextEditingController cArtCont = TextEditingController();
  TextEditingController cTypeCont = TextEditingController();
  TextEditingController cPrpsCont = TextEditingController();
  TextEditingController cPriceCont = TextEditingController();
  TextEditingController cCapCont = TextEditingController();
  TextEditingController cCountCont = TextEditingController();
  TextEditingController cChecksCont = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaback,
      appBar: appBar(
        title: "Create Card",
        leading: appBarActionButton(
          icon: Icons.arrow_back,
          onTap: () {
            Navigator.of(context).pop();
          },
        ),
        actions: Row(
          children: [
            widget.card == null
                ? TextButton(onPressed: crtFn, child: const Text("Create"))
                : TextButton(onPressed: () {}, child: const Text("Edit")),
          ],
        ),
      ),
      body: Container(
        width: double.maxFinite,
        height: double.maxFinite,
        decoration: BoxDecoration(gradient: scagrad),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(psm),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                buildField(
                  lbl: cardart,
                  cont: cArtCont,
                  isReadOnly: true,
                  showCursor: false,
                  isTapped: () async {
                    pic = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                    );
                    if (pic != null) {
                      cardConfig = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) {
                            return CardCustomizer(imagefile: pic!);
                          },
                        ),
                      );
                      if (cardConfig != null) {
                        setState(() {
                          cArtCont.text = pic!.name;
                        });
                      }
                    }
                  },
                ),
                const SizedBox(height: psm),
                bldDrdDwn(
                  lbl: "Card Purpose",
                  controller: cPrpsCont,
                  entries: cardPrps.entries,
                  onSelected: (val) {
                    safeState(() {
                      cpurpose = val;
                    });
                  },
                ),
                const SizedBox(height: psm),
                bldDrdDwn(
                  lbl: "Card Type",
                  controller: cTypeCont,
                  entries: cardType.entries,
                  onSelected: (val) {
                    safeState(() {
                      cCapCont.text = "$val";
                    });
                  },
                ),
                const SizedBox(height: psm),
                buildField(
                  cont: cCapCont,
                  lbl: cardcap,
                  type: TextInputType.number,
                  suff: MaterialButton(
                    onPressed: () {},
                    child: const Text("People"),
                  ),
                ),
                const SizedBox(height: psm),
                buildField(
                  lbl: cardchecks,
                  isReadOnly: true,
                  showCursor: false,
                  cont: cChecksCont,
                  isTapped: () async {
                    await showCheckPoint();
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  crtFn() async {
    bool isGood = formKey.currentState?.validate() ?? false;
    if (isGood) {
      try {
        showProgress(context: context);
        var curl = await cardUploader(file: pic, type: supportedttypes[0]);
        if (curl != null) {
          var batch = fstr.batch();
          var cardRef =
              fstr.collection(ecol).doc(widget.eId).collection(cardcol).doc();
          var cblueRef = fstr.collection(cardcol).doc(cardRef.id);
          CardConfig config = CardConfig(
            templateUrl: curl,
            type: cTypeCont.text,
            purpose: cpurpose ?? "unknown",
            clearAt: checkpoints,
            eventId: widget.eId,
            cardWidth: cardConfig['cardWidth'],
            cardHeight: cardConfig['cardHeight'],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            elements: cardConfig['elements'],
            capacity: int.parse(cleanStr(input: cCapCont.text)),
          );
          batch.set(cblueRef, config.toMap());
          Kard kard = Kard(
            id: cardRef.id,
            type: cTypeCont.text,
            clearAt: checkpoints,
            eventId: widget.eId,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            purpose: cpurpose ?? "unknown",
            capacity: int.parse(cleanStr(input: cCapCont.text)),
          );
          batch.set(cardRef, kard.toMap());
          await batch.commit();
          poper();
          showToast(isGood: true, msg: "Card created successfuly");
          poper();
        } else {
          poper();
          showToast(isGood: true, msg: "Card upload failed");
        }
      } catch (e) {
        poper();
        showToast(isGood: false, msg: "Failed due to: $e");
      }
    }
  }

  safeState(runnable) {
    setState(() {
      runnable();
    });
  }

  poper() {
    Navigator.of(context).pop();
  }

  showCheckPoint() async {
    return await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: FutureBuilder(
            future:
                fstr
                    .collection(ecol)
                    .doc(widget.eId)
                    .collection(echecksub)
                    .get(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                var data = (snapshot.data as dynamic).docs;
                if (data.isEmpty) {
                  return const Text("no data");
                } else {
                  return BuildModalChecks(
                    data: data,
                    checkpoints: checkpoints,
                    isTapped: (p0) {
                      checkpoints = p0;
                      cChecksCont.text = 'CheckPoints ${checkpoints.length}';
                    },
                  );
                }
              } else if (snapshot.hasError) {
                return const Text("error");
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
          actions: [
            MaterialButton(
              onPressed: () {
                poper();
              },
              child: const Text("Continue"),
            ),
          ],
        );
      },
    );
  }
}

class CardCustomizer extends StatefulWidget {
  final XFile imagefile;
  const CardCustomizer({super.key, required this.imagefile});

  @override
  State<CardCustomizer> createState() => _CardCustomizerState();
}

class _CardCustomizerState extends State<CardCustomizer> {
  Size? imageSize;
  late double? pixelRatio;
  GlobalKey imageKey = GlobalKey();
  Size? actualRenderSize;

  late ElementConfig userName;
  late ElementConfig cardType;
  late ElementConfig qrcode;

  @override
  void initState() {
    super.initState();
    userName = ElementConfig(
      size: 20,
      isCentered: false,
      position: const Offset(0.35, 0.3),
      color: const Color(0xff000000),
    );

    cardType = ElementConfig(
      size: 20,
      isCentered: false,
      position: const Offset(0.35, 0.4),
      color: const Color(0xff000000),
    );

    qrcode = ElementConfig(
      size: 80,
      isCentered: false,
      position: const Offset(0.3, 0.6),
      color: const Color(0xffffffff),
    );

    _loadImage();
  }

  Future<void> _loadImage() async {
    final File imageFile = File(widget.imagefile.path);
    final Uint8List bytes = await imageFile.readAsBytes();
    final ui.Image image = await decodeImageFromList(bytes);

    setState(() {
      imageSize = Size(image.width.toDouble(), image.height.toDouble());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaback,
      appBar: appBar(
        title: "Card Settings",
        leading: appBarActionButton(
          icon: Icons.arrow_back,
          onTap: () {
            Navigator.of(context).pop();
          },
        ),
        actions: Row(
          children: [
            IconButton(
              icon: const Icon(Clarity.settings_line),
              onPressed: () async {
                await showSettings();
                if (mounted) {
                  setState(() {});
                }
              },
            ),
            IconButton(
              icon: const Icon(Clarity.floppy_line),
              onPressed: () {
                final config = getCardConfig();
                Navigator.of(context).pop(config);
              },
            ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (imageSize == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final double imageAspectRatio = imageSize!.width / imageSize!.height;

          double renderWidth = constraints.maxWidth;
          double renderHeight = renderWidth / imageAspectRatio;

          // Adjust if height exceeds container
          if (renderHeight > constraints.maxHeight) {
            renderHeight = constraints.maxHeight;
            renderWidth = renderHeight * imageAspectRatio;
          }

          // Store the actual render size for element positioning
          actualRenderSize = Size(renderWidth, renderHeight);

          // Calculate the top offset to center the image vertically
          final double topOffset = (constraints.maxHeight - renderHeight) / 2;

          return Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            decoration: BoxDecoration(gradient: scagrad),
            child: Stack(
              children: [
                Positioned(
                  left: (constraints.maxWidth - renderWidth) / 2,
                  top: topOffset,
                  width: renderWidth,
                  height: renderHeight,
                  child: Image.file(
                    File(widget.imagefile.path),
                    fit: BoxFit.contain,
                  ),
                ),
                if (actualRenderSize != null) ...[
                  Positioned(
                    left: (constraints.maxWidth - renderWidth) / 2,
                    top: topOffset,
                    width: renderWidth,
                    height: renderHeight,
                    child: Stack(
                      children: [
                        buildDraggableText(
                          userName,
                          "Name of Attendee",
                          actualRenderSize!,
                        ),
                        buildDraggableText(
                          cardType,
                          "Double",
                          actualRenderSize!,
                        ),
                        buildDraggableQRCode(qrcode, actualRenderSize!),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildDraggableText(
    ElementConfig config,
    String text,
    Size containerSize,
  ) {
    final screenPosition = config.getScreenPosition(containerSize);

    return Positioned(
      top: screenPosition.dy,
      left: screenPosition.dx,
      child: GestureDetector(
        onScaleStart: (details) {
          // config.baseScale = config.scale;
        },
        onScaleUpdate: (details) {
          setState(() {
            final normalizedDelta = Offset(
              details.focalPointDelta.dx / containerSize.width,
              details.focalPointDelta.dy / containerSize.height,
            );
            config.position = Offset(
              (config.position.dx + normalizedDelta.dx).clamp(0.0, 1.0),
              (config.position.dy + normalizedDelta.dy).clamp(0.0, 1.0),
            );
          });
        },
        child: Text(
          text,
          style: TextStyle(
            height: 1.0,
            color: config.color,
            fontSize: config.size,
          ),
        ),
      ),
    );
  }

  Widget buildDraggableQRCode(ElementConfig config, Size containerSize) {
    final screenPosition = config.getScreenPosition(containerSize);

    return Positioned(
      top: screenPosition.dy,
      left: screenPosition.dx,
      child: GestureDetector(
        onScaleUpdate: (details) {
          setState(() {
            final normalizedDelta = Offset(
              details.focalPointDelta.dx / containerSize.width,
              details.focalPointDelta.dy / containerSize.height,
            );
            config.position = Offset(
              (config.position.dx + normalizedDelta.dx).clamp(0.0, 1.0),
              (config.position.dy + normalizedDelta.dy).clamp(0.0, 1.0),
            );
          });
        },
        child: Image.asset(width: config.size, 'assets/utils/qr.png'),
      ),
    );
  }

  Widget buildSettingsSection(
    String title,
    ElementConfig config,
    Function(Color) onColorChanged, {
    bool isQRCode = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        left: psm * 1.7,
        top: psm * 1.7,
        right: psm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: normalBold()),
          CupertinoListTile(
            title: Text(isQRCode ? "BG color" : "Text color"),
            additionalInfo: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: config.color,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            trailing: MaterialButton(
              color: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(brsm),
              ),
              child: const Text(
                "Change",
                style: TextStyle(color: secondaryColor),
              ),
              onPressed: () async {
                final newColor = await pickColor(curnColor: config.color);
                if (newColor != null) {
                  onColorChanged(newColor);
                }
              },
            ),
          ),
          !isQRCode
              ? TextAlignEditor(
                isCentered: (p0) {
                  config.isCentered = p0;
                },
              )
              : const SizedBox(),
          SizeEditor(
            size: config.size,
            isCreased: (p0) {
              setState(() {
                config.size = p0;
              });
            },
          ),
          const SizedBox(height: psm * 1.25),
        ],
      ),
    );
  }

  Future<Color?> pickColor({required Color curnColor}) async {
    Color pickerColor = curnColor;
    return await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pick Color', textAlign: TextAlign.center),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (color) {
                pickerColor = color;
              },
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Confirm'),
              onPressed: () {
                Navigator.of(context).pop(pickerColor);
                Navigator.of(context).pop(pickerColor);
              },
            ),
          ],
        );
      },
    );
  }

  Map<String, dynamic> getCardConfig() {
    MediaQuery.of(context).devicePixelRatio;
    if (imageSize == null || actualRenderSize == null) return {};
    var scaleFctr = imageSize!.width / actualRenderSize!.width;
    return {
      coriginalW: imageSize!.width,
      coriginalH: imageSize!.height,
      crdelements: {
        crdattname: {
          lmntvalue: "",
          lmntconfig: {
            lmntlvx: userName.position.dx,
            lmntlvy: userName.position.dy,
            lmntcenter: userName.isCentered,
            lmntsize: userName.size * scaleFctr,
            lmntcolor: userName.color.toHexString().substring(2),
          },
        },
        crdtype: {
          lmntvalue: "",
          lmntconfig: {
            lmntlvx: cardType.position.dx,
            lmntlvy: cardType.position.dy,
            lmntcenter: cardType.isCentered,
            lmntsize: cardType.size * scaleFctr,
            lmntcolor: cardType.color.toHexString().substring(2),
          },
        },
        crdQrCode: {
          lmntvalue: "",
          lmntconfig: {
            lmntlvx: qrcode.position.dx,
            lmntlvy: qrcode.position.dy,
            lmntcenter: qrcode.isCentered,
            lmntsize: qrcode.size * scaleFctr,
            lmntcolor: qrcode.color.toHexString().substring(2),
          },
        },
      },
    };
  }

  showSettings() async {
    return await showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.only(
          topLeft: Radius.circular(bmd),
          topRight: Radius.circular(bmd),
        ),
      ),
      context: context,
      builder: (context) {
        return modalBtmSheet(
          bdrdm: bmd,
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.65,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: psm),
                Text(
                  "Adjust Settings",
                  style: TextStyle(
                    fontSize: fsm + 6,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: psm),
                Divider(thickness: 0.5),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        buildSettingsSection(
                          "User name",
                          userName,
                          (color) => setState(() => userName.color = color),
                        ),
                        buildSettingsSection(
                          "Card type",
                          cardType,
                          (color) => setState(() => cardType.color = color),
                        ),
                        buildSettingsSection(
                          "User QR code",
                          qrcode,
                          (color) => setState(() => qrcode.color = color),
                          isQRCode: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ElementConfig {
  double size;
  Color color;
  Offset position;
  bool isCentered = false;
  ElementConfig({
    required this.size,
    required this.color,
    required this.position,
    required this.isCentered,
  });

  Offset getScreenPosition(Size containerSize) {
    return Offset(
      position.dx * containerSize.width,
      position.dy * containerSize.height,
    );
  }
}

class SizeEditor extends StatefulWidget {
  final dynamic size;
  final Function(double) isCreased;
  const SizeEditor({super.key, required this.size, required this.isCreased});

  @override
  State<SizeEditor> createState() => _SizeEditorState();
}

class _SizeEditorState extends State<SizeEditor> {
  late double size;
  @override
  void initState() {
    setState(() {
      size = widget.size;
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            setState(() {
              size = size - 1;
            });
            widget.isCreased(size);
          },
          icon: const Icon(Clarity.minus_circle_line),
        ),
        Text("Size: $size dp"),
        IconButton(
          onPressed: () {
            setState(() {
              size = size + 1;
            });
            widget.isCreased(size);
          },
          icon: const Icon(Clarity.plus_circle_line),
        ),
      ],
    );
  }
}

class TextAlignEditor extends StatefulWidget {
  final Function(bool) isCentered;
  const TextAlignEditor({super.key, required this.isCentered});

  @override
  State<TextAlignEditor> createState() => _TextAlignEditorState();
}

class _TextAlignEditorState extends State<TextAlignEditor> {
  bool isCtrd = false;
  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: isCtrd,
      title: const Text("Center text"),
      onChanged: (value) {
        setState(() {
          isCtrd = value ?? false;
          widget.isCentered(isCtrd);
        });
      },
    );
  }
}
