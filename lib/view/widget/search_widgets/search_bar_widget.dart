import 'package:flutter/material.dart';

class SearchBarWidget extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSearch;
  final VoidCallback onClear;
  final Animation<Offset> slideAnimation;
  final Animation<double> fadeAnimation;
  final String
  initialQuery; //! this is parameter that will recieve the query title to perform search from notification(trending phonk notification)

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSearch,
    required this.onClear,
    required this.slideAnimation,
    required this.fadeAnimation,
    this.initialQuery = '',
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  @override
  void initState() {
    super.initState();
    // ✅ If initialQuery is provided, set it into the controller once
    if (widget.initialQuery.isNotEmpty) {
      widget.controller.text = widget.initialQuery;
    } else {
      debugPrint("No initial query provided(from trending phonk notification): ${widget.initialQuery}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: widget.slideAnimation,
      child: FadeTransition(
        opacity: widget.fadeAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ListenableBuilder(
            listenable: widget.controller,
            builder: (context, child) {
              return TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                autofocus: false,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Search for phonks... (Artist - Title)',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.purple,
                    size: 24,
                  ),
                  suffixIcon: widget.controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white70),
                          onPressed: widget.onClear,
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(
                      color: Colors.purple,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => widget.onSearch(),
              );
            },
          ),
        ),
      ),
    );
  }
}
