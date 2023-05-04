import 'dart:async';
import 'dart:collection';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// {@template grouped_infinite_list}
/// Grouped Infinite List
///
/// This widget use two [SliverList] to make infinite list on both side (scroll
/// up and down) possible with positive items list as the center list.
/// {@endtemplate}
class GroupedInfiniteList<T, G> extends StatefulWidget {
  /// {@macro grouped_infinite_list}
  const GroupedInfiniteList({
    super.key,
    required this.positiveItems,
    required this.itemBuilder,
    required this.groupBy,
    required this.groupSeparatorBuilder,
    EdgeInsetsGeometry? groupSeparatorPadding,
    this.negativeItems = const [],
    this.separator = const SizedBox.shrink(),
    this.controller,
    this.suffix,
    this.negativeSuffix,
    this.reverse = false,
    this.groupComparator,
    this.itemComparator,
    this.anchor = 0.0,
    this.cacheExtent,
    this.clipBehavior = Clip.hardEdge,
    this.dragStartBehavior = DragStartBehavior.start,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.physics,
    this.primary,
    this.restorationId,
    this.scrollBehavior,
    this.scrollDirection = Axis.vertical,
    this.addAutomaticKeepAlives = true,
    this.sort = true,
    this.useStickyGroupSeparators = false,
    this.stickyHeaderPositionOffset = 0.0,
  }) : groupSeparatorPadding = groupSeparatorPadding ?? EdgeInsets.zero;

  /// List of items
  final List<T> positiveItems;

  /// List of negative items
  final List<T> negativeItems;

  /// Item builder for [SliverChildBuilderDelegate]
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// Define how to group item
  final G Function(T item) groupBy;

  /// Group separator builder
  final Widget Function(T item) groupSeparatorBuilder;

  /// Group separator padding
  final EdgeInsetsGeometry groupSeparatorPadding;

  /// Can be used to define a custom sorting for the groups.
  ///
  /// If not set groups will be sorted with their natural sorting order or their
  /// specific [Comparable] implementation.
  final int Function(G value1, G value2)? groupComparator;

  /// Can be used to define a custom sorting for the elements inside each group.
  ///
  /// If not set elements will be sorted with their natural sorting order or
  /// their specific [Comparable] implementation.
  final int Function(T item1, T item2)? itemComparator;

  /// Separator
  final Widget separator;

  /// {@macro flutter.widgets.scroll_view.controller}
  final ScrollController? controller;

  /// Suffix Widget, mostly used for list loading indicator
  final Widget? suffix;

  /// Negative suffix Widget, mostly used for list loading indicator
  final Widget? negativeSuffix;

  /// {@macro flutter.widgets.scroll_view.reverse}
  final bool reverse;

  /// {@macro flutter.widgets.scroll_view.anchor}
  final double anchor;

  /// {@macro flutter.rendering.RenderViewportBase.cacheExtent}
  final double? cacheExtent;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.hardEdge].
  final Clip clipBehavior;

  /// {@macro flutter.widgets.scrollable.dragStartBehavior}
  final DragStartBehavior dragStartBehavior;

  /// {@macro flutter.widgets.scroll_view.keyboardDismissBehavior}
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  /// {@macro flutter.widgets.scroll_view.physics}
  ///
  /// If an explicit [ScrollBehavior] is provided to [scrollBehavior], the
  /// [ScrollPhysics] provided by that behavior will take precedence after
  /// [physics].
  final ScrollPhysics? physics;

  /// {@macro flutter.widgets.scroll_view.primary}
  final bool? primary;

  /// {@macro flutter.widgets.scrollable.restorationId}
  final String? restorationId;

  /// {@macro flutter.widgets.shadow.scrollBehavior}
  ///
  /// [ScrollBehavior]s also provide [ScrollPhysics]. If an explicit
  /// [ScrollPhysics] is provided in [physics], it will take precedence,
  /// followed by [scrollBehavior], and then the inherited ancestor
  /// [ScrollBehavior].
  final ScrollBehavior? scrollBehavior;

  /// {@macro flutter.widgets.scroll_view.scrollDirection}
  final Axis scrollDirection;

  /// Whether to wrap each child in an [AutomaticKeepAlive].
  ///
  /// Typically, children in lazy list are wrapped in [AutomaticKeepAlive]
  /// widgets so that children can use [KeepAliveNotification]s to preserve
  /// their state when they would otherwise be garbage collected off-screen.
  ///
  /// Defaults to true.
  final bool addAutomaticKeepAlives;

  /// Whether the items will be sorted or not. If not it must be done
  /// manually.
  ///
  /// Defauts to `true`.
  final bool sort;

  /// When set to `true` the group header of the current visible group will
  /// stick on top.
  final bool useStickyGroupSeparators;

  /// Used to calculate sticky header position offset
  ///
  /// Usually used if you need your list scroll behind appbar
  /// (Scaffold extendBodyBehindAppBar: true)
  ///
  /// Defaults to `0.0`
  final double stickyHeaderPositionOffset;

  /// Center list key
  Key get _centerKey => const ValueKey('center-list-key');

  @override
  State<GroupedInfiniteList<T, G>> createState() =>
      _GroupedInfiniteListState<T, G>();
}

class _GroupedInfiniteListState<T, G> extends State<GroupedInfiniteList<T, G>> {
  final _stickyGroupIndexStreamController = StreamController<int>();
  late final ScrollController _controller;
  late List<T> _positiveItems;
  late List<T> _negativeItems;

  bool get _isEmpty => _positiveItems.isEmpty && _negativeItems.isEmpty;

  final LinkedHashMap<int, GlobalKey> _keys = LinkedHashMap();
  final GlobalKey _key = GlobalKey();
  GlobalKey? _groupHeaderKey;
  int _topElementIndex = 0;
  RenderBox? _listBox;
  RenderBox? _headerBox;

  @override
  void initState() {
    super.initState();
    _sortItems();
    _controller = widget.controller ?? ScrollController();
    _controller.addListener(_scrollListener);
  }

  @override
  void didUpdateWidget(covariant GroupedInfiniteList<T, G> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sortItems();
  }

  @override
  void dispose() {
    _controller.removeListener(_scrollListener);
    if (widget.controller == null) {
      _controller.dispose();
    }
    _stickyGroupIndexStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: _key,
      alignment: Alignment.topCenter,
      children: [
        CustomScrollView(
          controller: widget.controller,
          center: widget._centerKey,
          reverse: widget.reverse,
          anchor: widget.anchor,
          cacheExtent: widget.cacheExtent,
          clipBehavior: widget.clipBehavior,
          dragStartBehavior: widget.dragStartBehavior,
          keyboardDismissBehavior: widget.keyboardDismissBehavior,
          physics: widget.physics,
          primary: widget.primary,
          restorationId: widget.restorationId,
          scrollBehavior: widget.scrollBehavior,
          scrollDirection: widget.scrollDirection,
          slivers: [
            if (widget.negativeSuffix != null)
              SliverToBoxAdapter(
                child: widget.negativeSuffix,
              ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _itemBuilder(
                    context: context,
                    items: _negativeItems,
                    index: index,
                    isNegative: true,
                  );
                },
                childCount: _negativeItems.length * 2,
                addAutomaticKeepAlives: widget.addAutomaticKeepAlives,
              ),
            ),
            SliverList(
              key: widget._centerKey,
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _itemBuilder(
                    context: context,
                    items: _positiveItems,
                    index: index,
                    isNegative: false,
                  );
                },
                childCount: _positiveItems.length * 2,
                addAutomaticKeepAlives: widget.addAutomaticKeepAlives,
              ),
            ),
            if (widget.suffix != null)
              SliverToBoxAdapter(
                child: widget.suffix,
              ),
          ],
        ),
        Positioned(
          top: widget.stickyHeaderPositionOffset,
          child: StreamBuilder<int>(
            stream: _stickyGroupIndexStreamController.stream,
            initialData: _topElementIndex,
            builder: (context, snapshot) {
              final index = snapshot.data;
              if (index != null) {
                return _stickyHeaderBuilder(index);
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }

  /// sort both items list
  void _sortItems() {
    _positiveItems = List.of(widget.positiveItems);
    _negativeItems = List.of(widget.negativeItems);

    // If sort is false, skip sorting
    if (!widget.sort) return;
    // Sort items
    if (_positiveItems.isNotEmpty) {
      _positiveItems.sort(_sorter);
    }
    // Sort negative items in reverse order
    if (_negativeItems.isNotEmpty) {
      _negativeItems.sort((b, a) => _sorter(a, b));
    }
  }

  int _sorter(T a, T b) {
    var compareResult = 0;
    // Group
    if (widget.groupComparator != null) {
      compareResult = widget.groupComparator!(
        widget.groupBy(a),
        widget.groupBy(b),
      );
    } else if (widget.groupBy(a) is Comparable) {
      // If not provided, use default Comparable implementation
      compareResult = (widget.groupBy(a) as Comparable)
          .compareTo(widget.groupBy(b) as Comparable);
    }

    // Item
    if (compareResult == 0) {
      if (widget.itemComparator != null) {
        compareResult = widget.itemComparator!(a, b);
      } else if (a is Comparable) {
        // If not provided, use default Comparable implementation
        compareResult = a.compareTo(b);
      }
    }
    return compareResult;
  }

  Widget _groupSeparatorBuilder(T item) {
    return Padding(
      padding: widget.groupSeparatorPadding,
      child: widget.groupSeparatorBuilder(item),
    );
  }

  // Item builder for [SliverChildBuilderDelegate]
  Widget _itemBuilder({
    required BuildContext context,
    required List<T> items,
    required int index,
    required bool isNegative,
  }) {
    final actualIndex = index ~/ 2;
    final reverse = isNegative ? !widget.reverse : widget.reverse;

    final hiddenIndex = reverse ? items.length * 2 - 1 : 0;
    final isSeparator = reverse ? index.isOdd : index.isEven;

    if (!reverse) {
      // Check if we need to add group separator between positive and negative
      // items, show separator if they are not in the same group
      if (index == 0 && !_isEmpty) {
        final firstPositiveGroup = widget.groupBy(_positiveItems[0]);
        final firstNegativeGroup = widget.groupBy(_negativeItems[0]);
        if (firstPositiveGroup != firstNegativeGroup) {
          return _groupSeparatorBuilder(items[0]);
        } else {
          return widget.separator;
        }
      }
    }

    // Show group separator on top of the list
    if (index == hiddenIndex) {
      return Opacity(
        opacity: widget.useStickyGroupSeparators ? 0 : 1,
        child: _groupSeparatorBuilder(items[actualIndex]),
      );
    }

    if (isSeparator) {
      // Check if we need to add group separator between items
      final current = widget.groupBy(items[actualIndex]);
      final previous = widget.groupBy(items[actualIndex + (reverse ? 1 : -1)]);
      if (current != previous) {
        return _groupSeparatorBuilder(items[actualIndex]);
      }
      return widget.separator;
    }

    // Item builder
    final item = items[actualIndex];
    final joinIndex = isNegative ? -actualIndex - 1 : actualIndex;
    final key = _keys.putIfAbsent(joinIndex, GlobalKey.new);
    return KeyedSubtree(
      key: key,
      child: widget.itemBuilder(context, item),
    );
  }

  Widget _stickyHeaderBuilder(int index) {
    _groupHeaderKey ??= GlobalKey();

    if (!widget.useStickyGroupSeparators || _isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      key: _groupHeaderKey,
      child: _groupSeparatorBuilder(getElementAt(index)),
    );
  }

  void _scrollListener() {
    _listBox ??= _key.currentContext?.findRenderObject() as RenderBox?;
    final listPos = (_listBox?.localToGlobal(Offset.zero).dy ?? 0) +
        widget.stickyHeaderPositionOffset;
    _headerBox ??=
        _groupHeaderKey?.currentContext?.findRenderObject() as RenderBox?;
    final headerHeight =
        (_headerBox?.size.height ?? 0) - widget.groupSeparatorPadding.vertical;
    var max = double.negativeInfinity;
    var topItemKey = widget.reverse
        ? _positiveItems.length - 1
        : _negativeItems.isEmpty
            ? 0
            : -_negativeItems.length;
    for (final entry in _keys.entries) {
      final key = entry.value;
      if (_isListItemRendered(key)) {
        final itemBox = key.currentContext!.findRenderObject()! as RenderBox;
        // position of the item's top border inside the list view
        final y = itemBox.localToGlobal(Offset(0, -listPos - headerHeight)).dy;
        if (y <= headerHeight && y > max) {
          topItemKey = entry.key;
          max = y;
        }
      }
    }

    final index = topItemKey;
    // print(index);
    if (index != _topElementIndex) {
      final curr = widget.groupBy(getElementAt(index));
      final prev = widget.groupBy(getElementAt(_topElementIndex));

      if (prev != curr) {
        _topElementIndex = index;
        _stickyGroupIndexStreamController.add(_topElementIndex);
      }
    }
  }

  T getElementAt(int index) {
    if (index >= 0) {
      return _positiveItems[index];
    } else {
      return _negativeItems[-index - 1];
    }
  }

  /// Checks if the list item with the given [key] is currently rendered in the
  /// view frame.
  bool _isListItemRendered(GlobalKey<State<StatefulWidget>> key) {
    return key.currentContext != null &&
        key.currentContext!.findRenderObject() != null;
  }
}
