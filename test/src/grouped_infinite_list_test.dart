// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grouped_infinite_list/grouped_infinite_list.dart';

void main() {
  group('GroupedInfiniteList', () {
    test('can be instantiated', () {
      expect(
        GroupedInfiniteList(
          itemBuilder: (context, index) => Container(),
          groupBy: (item) => item,
          groupSeparatorBuilder: (item) => Container(),
          positiveItems: const [],
        ),
        isNotNull,
      );
    });

    testWidgets('updates sticky header when controller is not provided',
        (tester) async {
      final items = [0, 1, 2, 3];
      await tester.pumpWidget(
        MaterialApp(
          home: GroupedInfiniteList<int, int>(
            positiveItems: items,
            groupBy: (item) => item ~/ 2,
            groupSeparatorBuilder: (item) => Text('Group ${item ~/ 2}'),
            itemBuilder: (_, item) => SizedBox(
              height: 50,
              child: Text('$item'),
            ),
            useStickyGroupSeparators: true,
          ),
        ),
      );

      expect(find.text('Group 0'), findsOneWidget);

      await tester.drag(
        find.byType(CustomScrollView),
        const Offset(0, -200),
      );
      await tester.pump();

      expect(find.text('Group 1'), findsOneWidget);
    });
  });
}
