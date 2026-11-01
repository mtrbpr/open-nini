import 'package:flutter/material.dart';

import 'status_views.dart';

class PageSlice<T> {
  const PageSlice({required this.items, required this.lastPage, this.title, this.header, this.locked = false});

  final List<T> items;
  final int lastPage;
  final String? title;
  final Widget? header;
  final bool locked;
}

class PagedList<T> extends StatefulWidget {
  const PagedList({
    required this.load,
    required this.itemBuilder,
    required this.idOf,
    required this.emptyMessage,
    super.key,
    this.onLoaded,
  });

  final Future<PageSlice<T>> Function(int page) load;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final String Function(T item) idOf;
  final String emptyMessage;
  final ValueChanged<PageSlice<T>>? onLoaded;

  @override
  State<PagedList<T>> createState() => _PagedListState<T>();
}

class _PagedListState<T> extends State<PagedList<T>> {
  final _scroll = ScrollController();
  final _items = <T>[];
  final _ids = <String>{};
  int _nextPage = 1;
  int _lastPage = 1;
  Widget? _header;
  bool _loading = false;
  bool _started = false;
  bool _failed = false;
  bool _failedReset = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load(reset: true);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  bool get _hasMore => _nextPage <= _lastPage;

  Future<void> _load({required bool reset}) async {
    if (_loading) return;
    if (!reset && !_hasMore) return;
    final page = reset ? 1 : _nextPage;
    final countBefore = reset ? 0 : _items.length;
    setState(() {
      _started = true;
      _loading = true;
      _failed = false;
    });
    try {
      final slice = await widget.load(page);
      if (!mounted) return;
      setState(() {
        if (reset) {
          _items.clear();
          _ids.clear();
          _header = slice.header;
        }
        for (final item in slice.items) {
          if (_ids.add(widget.idOf(item))) _items.add(item);
        }
        _lastPage = _items.length == countBefore ? page : slice.lastPage;
        _nextPage = page + 1;
        _loading = false;
        _failed = false;
      });
      widget.onLoaded?.call(slice);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
        _failedReset = reset;
      });
    }
  }

  void _onScroll() {
    if (!_scroll.hasClients || _loading || _failed || !_hasMore) return;
    final position = _scroll.position;
    if (position.pixels >= position.maxScrollExtent - 480) {
      _load(reset: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_started || (_items.isEmpty && _loading)) return const LoadingState();
    if (_items.isEmpty && _failed) {
      return ErrorState(onRetry: () => _load(reset: true));
    }
    if (_items.isEmpty && _header == null) return EmptyState(message: widget.emptyMessage);
    if (_items.isEmpty && _header != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _header!,
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(widget.emptyMessage, textAlign: TextAlign.center),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: _items.length + 1 + (_header == null ? 0 : 1),
        itemBuilder: (context, index) {
          final header = _header;
          final offset = header == null ? 0 : 1;
          if (header != null && index == 0) return header;
          if (index == _items.length + offset) return _footer(context);
          return widget.itemBuilder(context, _items[index - offset]);
        },
      ),
    );
  }

  Widget _footer(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_failed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: TextButton(
            onPressed: () => _load(reset: _failedReset),
            child: const Text('ادامه بارگذاری نشد. تلاش دوباره'),
          ),
        ),
      );
    }
    return const SizedBox(height: 12);
  }
}
