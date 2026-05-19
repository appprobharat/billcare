import 'package:flutter/material.dart';

class OverlayDropdown extends StatefulWidget {
  final String label;
  final String? value;
  final List<String> items;
  final Function(String) onSelect;

  const OverlayDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onSelect,
  });

  @override
  State<OverlayDropdown> createState() => _OverlayDropdownState();
}

class _OverlayDropdownState extends State<OverlayDropdown> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_overlayEntry == null) {
      _overlayEntry = _createOverlay();
      Overlay.of(context).insert(_overlayEntry!);
    } else {
      _removeOverlay();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlay() {
    RenderBox box = context.findRenderObject() as RenderBox;
    final size = box.size;
    final offset = box.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // 🔥 BACKGROUND TAP DETECTOR (outside click)
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeOverlay,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox(),
            ),
          ),

          // 🔽 DROPDOWN
          Positioned(
            width: size.width,
            left: offset.dx,
            top: offset.dy + size.height + 5,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  children: widget.items.map((e) {
                    return ListTile(
                      dense: true,
                      title: Text(e, style: const TextStyle(fontSize: 13)),
                      onTap: () {
                        widget.onSelect(e);
                        _removeOverlay();
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.label.isNotEmpty) ...[
              Text(widget.label, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
            ],
            Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.value ?? "Select",
                    style: const TextStyle(fontSize: 13),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
