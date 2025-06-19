// import 'package:flutter/material.dart';
// import 'package:haflaway/top_destinations/event_dash/admin_panel/inv_rems/reusables/stuff.dart';
// import 'package:haflaway/utils/dimensions.dart';

// buildFlChips(sttses, groupValue, onSelected}) {
//   return SingleChildScrollView(
//     scrollDirection: Axis.horizontal,
//     child: Row(
//       children:
//           sttses.values.map((e) {
//             bool isSelected = e == groupValue;
//             return Padding(
//               padding: const EdgeInsets.only(right: psm * 0.75),
//               child: FilterChip(
//                 label: Text(e.name.toUpperCase()),
//                 selected: isSelected,
//                 onSelected: (val) {
//                   onSelected(e);
//                 },
//               ),
//             );
//           }).toList(),
//     ),
//   );
// }
