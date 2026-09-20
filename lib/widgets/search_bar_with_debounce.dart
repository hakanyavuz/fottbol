import 'package:flutter/material.dart';
import '../core/utils/debouncer.dart';

/// Kullanıcı yazdıkça filtreleyen, 300ms gecikmeli (debounce) arama çubuğu
class SearchBarWithDebounce extends StatefulWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final String initialValue;

  const SearchBarWithDebounce({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.initialValue = '',
  });

  @override
  State<SearchBarWithDebounce> createState() => _SearchBarWithDebounceState();
}

class _SearchBarWithDebounceState extends State<SearchBarWithDebounce> {
  late TextEditingController _controller;
  late Debouncer _debouncer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _debouncer = Debouncer(delay: const Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    _controller.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: widget.hintText,
          prefixIcon: const Icon(Icons.search, size: 22),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                    setState(() {});
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          isDense: true,
        ),
        onChanged: (text) {
          setState(() {});
          _debouncer.run(() {
            widget.onChanged(text);
          });
        },
      ),
    );
  }
}
