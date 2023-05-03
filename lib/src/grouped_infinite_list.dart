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
  });

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

  /// Scroll controller
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

  /// Center list key
  Key get _centerKey => const ValueKey('center-list-key');

  @override
  State<GroupedInfiniteList<T, G>> createState() =>
      _GroupedInfiniteListState<T, G>();
}

class _GroupedInfiniteListState<T, G> extends State<GroupedInfiniteList<T, G>> {
  late List<T> _positiveItems;
  late List<T> _negativeItems;

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void didUpdateWidget(covariant GroupedInfiniteList<T, G> oldWidget) {
    super.didUpdateWidget(oldWidget);
    init();
  }

  void init() {
    sortItems();
  }

  void sortItems() {
    _positiveItems = List.of(widget.positiveItems);
    _negativeItems = List.of(widget.negativeItems);
    // Sort items
    if (_positiveItems.isNotEmpty) {
      _positiveItems.sort(sorter);
    }
    // Sort negative items in reverse order
    if (_negativeItems.isNotEmpty) {
      _negativeItems.sort((b, a) => sorter(a, b));
    }
  }

  int sorter(T a, T b) {
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
      final notEmptyList =
          widget.positiveItems.isNotEmpty && widget.negativeItems.isNotEmpty;

      // Check if we need to add group separator between positive and negative
      // items, show separator if they are not in the same group
      if (index == 0 && notEmptyList) {
        final firstPositiveGroup = widget.groupBy(_positiveItems[0]);
        final firstNegativeGroup = widget.groupBy(_negativeItems[0]);
        if (firstPositiveGroup != firstNegativeGroup) {
          return widget.groupSeparatorBuilder(items[0]);
        } else {
          return widget.separator;
        }
      }
    }

    // Show group separator on top of the list
    if (index == hiddenIndex) {
      return widget.groupSeparatorBuilder(items[actualIndex]);
    }

    if (isSeparator) {
      // Check if we need to add group separator between items
      final current = widget.groupBy(items[actualIndex]);
      final previous = widget.groupBy(items[actualIndex + (reverse ? 1 : -1)]);
      if (current != previous) {
        return widget.groupSeparatorBuilder(items[actualIndex]);
      }
      return widget.separator;
    }

    // Item builder
    final item = items[actualIndex];
    return widget.itemBuilder(context, item);
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: widget.key,
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
            childCount: widget.negativeItems.length * 2,
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
            childCount: widget.positiveItems.length * 2,
          ),
        ),
        if (widget.suffix != null)
          SliverToBoxAdapter(
            child: widget.suffix,
          ),
      ],
    );
  }
}
