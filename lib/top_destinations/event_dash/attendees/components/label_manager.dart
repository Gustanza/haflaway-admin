import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:haflaway/components/sheets.dart';
import 'package:haflaway/models/event.dart';
import 'package:haflaway/utils/colors.dart';
import 'package:haflaway/utils/globalfns.dart';

class LabelManager extends StatefulWidget {
  final Event event;
  const LabelManager({super.key, required this.event});

  @override
  State<LabelManager> createState() => _LabelManagerState();
}

class _LabelManagerState extends State<LabelManager> {
  final TextEditingController _nameController = TextEditingController();
  int _selectedColorValue = 0xFFC9A84C; // Default Gold
  bool _isSaving = false;

  final List<int> _colorPalette = [
    0xFFC9A84C, // Gold
    0xFF4CAF50, // Green
    0xFF2196F3, // Blue
    0xFFF44336, // Red
    0xFFFF9800, // Orange
    0xFF9C27B0, // Purple
    0xFF00BCD4, // Cyan
    0xFFE91E63, // Pink
    0xFF795548, // Brown
    0xFF607D8B, // Blue Grey
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Manage Lists",
              style: Teme.f(size: 20, weight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Teme.grey1),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildLabelList(),
        const Divider(color: Teme.grey3, height: 32),
        _buildAddLabelForm(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildLabelList() {
    final labels = widget.event.labels ?? [];
    if (labels.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text("No lists created yet", style: Teme.f(color: Teme.grey1)),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: labels.length,
        itemBuilder: (context, index) {
          final label = labels[index];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: Color(label.colorValue),
              radius: 8,
            ),
            title: Text(label.name, style: Teme.f()),
            trailing: IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
                size: 20,
              ),
              onPressed: () => _deleteLabel(label),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddLabelForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Create New List",
          style: Teme.f(size: 14, weight: FontWeight.w600, color: Teme.lime),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _nameController,
          style: Teme.f(),
          decoration: InputDecoration(
            hintText: "List Name (e.g. VIP)",
            hintStyle: Teme.f(color: Teme.grey2),
            filled: true,
            fillColor: Teme.card2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text("Select Color", style: Teme.f(size: 12, color: Teme.grey1)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children:
              _colorPalette.map((colorVal) {
                final isSelected = _selectedColorValue == colorVal;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColorValue = colorVal),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(colorVal),
                      shape: BoxShape.circle,
                      border:
                          isSelected
                              ? Border.all(color: Colors.white, width: 2)
                              : null,
                      boxShadow:
                          isSelected
                              ? [
                                BoxShadow(
                                  color: Color(colorVal).withOpacity(0.5),
                                  blurRadius: 8,
                                ),
                              ]
                              : null,
                    ),
                    child:
                        isSelected
                            ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            )
                            : null,
                  ),
                );
              }).toList(),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _createLabel,
            style: ElevatedButton.styleFrom(
              backgroundColor: Teme.lime,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child:
                _isSaving
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                    : Text(
                      "Add List",
                      style: Teme.f(
                        color: Colors.black,
                        weight: FontWeight.bold,
                      ),
                    ),
          ),
        ),
      ],
    );
  }

  Future<void> _createLabel() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showToast(isGood: false, msg: "Please enter a list name");
      return;
    }

    setState(() => _isSaving = true);

    try {
      final newLabel = AttendeeLabel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        colorValue: _selectedColorValue,
      );

      final updatedLabels = List<AttendeeLabel>.from(widget.event.labels ?? [])
        ..add(newLabel);

      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.event.id)
          .update({'labels': updatedLabels.map((e) => e.toMap()).toList()});

      widget.event.labels = updatedLabels;
      _nameController.clear();
      showToast(isGood: true, msg: "List created");
    } catch (e) {
      showToast(isGood: false, msg: "Failed to create list: $e");
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteLabel(AttendeeLabel label) async {
    try {
      final updatedLabels = List<AttendeeLabel>.from(widget.event.labels ?? [])
        ..removeWhere((l) => l.id == label.id);

      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.event.id)
          .update({'labels': updatedLabels.map((e) => e.toMap()).toList()});

      setState(() {
        widget.event.labels = updatedLabels;
      });
      showToast(isGood: true, msg: "List deleted");
    } catch (e) {
      showToast(isGood: false, msg: "Failed to delete list: $e");
    }
  }
}

void showLabelManager(BuildContext context, Event event) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder:
        (context) => modalBtmSheet(
          bdrdm: 28,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: LabelManager(event: event),
          ),
        ),
  );
}
