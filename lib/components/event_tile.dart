import 'package:flutter/material.dart';
import 'package:haflaway/top_destinations/create_event.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:intl/intl.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/utils/dimensions.dart';
import 'package:haflaway/utils/globalwids.dart';
import 'package:haflaway/utils/styles.dart';

class EventTile extends StatefulWidget {
  final Event eventData;
  const EventTile({super.key, required this.eventData});

  @override
  State<EventTile> createState() => _EventTileState();
}

class _EventTileState extends State<EventTile> {
  final DateFormat tformtr = DateFormat('HH:mm');
  final DateFormat dformtr = DateFormat('EEEE, d\'th\', MMMM, yyyy');
  @override
  Widget build(BuildContext context) {
    var dt = widget.eventData.calendar.first.eventDate;
    var evDate = dformtr.format(dt);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.3), width: 1),
      ),
      margin: const EdgeInsets.only(bottom: psm * 0.5),
      child: Padding(
        padding: const EdgeInsets.only(bottom: psm * 0.25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(bsm),
                topRight: Radius.circular(bsm),
              ),
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.width * 0.5,
                child: buildImage(url: widget.eventData.eventThumbnail),
              ),
            ),
            Divider(height: 0, color: primaryColor.withOpacity(0.3)),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: psm),
              title: Text(
                widget.eventData.title,
                maxLines: 2,
                style: normalBold(),
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                evDate,
                maxLines: 1,
                style: normal(),
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton.outlined(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) {
                        return CreateEvent(event: widget.eventData);
                      },
                    ),
                  );
                },
                icon: const Icon(Clarity.edit_line),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
