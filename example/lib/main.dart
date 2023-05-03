import 'package:flutter/material.dart';
import 'package:grouped_infinite_list/grouped_infinite_list.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final dateFormat = DateFormat('dd MMM yyyy HH:mm:ss');
  final List<ChatPost> positiveItems = [];
  final List<ChatPost> negativeItems = [];
  final ScrollController _scrollController = ScrollController();
  bool _isPositiveLoading = false;
  bool _isNegativeLoading = false;

  @override
  void initState() {
    _addPositiveItem(10);
    _addNegativeItem(10);
    _scrollController.addListener(_scrollListener);
    super.initState();
  }

  void _scrollListener() {
    var thresholdPixels = 120;
    var nextPageTrigger =
        _scrollController.position.maxScrollExtent - thresholdPixels;
    var previousPageTrigger =
        _scrollController.position.minScrollExtent + thresholdPixels;

    if (_scrollController.position.pixels > nextPageTrigger) {
      _addPositiveItemAsync(10);
    }

    if (_scrollController.position.pixels < previousPageTrigger) {
      _addNegativeItemAsync(10);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grouped Infinite List'),
      ),
      body: GroupedInfiniteList(
        controller: _scrollController,
        positiveItems: positiveItems,
        negativeItems: negativeItems,
        groupBy: (item) => item.dateOnly,
        groupSeparatorBuilder: (item) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                DateFormat('dd MMMM yyyy').format(item.date),
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
        itemComparator: (item1, item2) => item1.date.compareTo(item2.date),
        // separator: const Divider(),
        suffix: _isPositiveLoading
            ? const Center(child: CircularProgressIndicator())
            : null,
        negativeSuffix: _isNegativeLoading
            ? const Center(child: CircularProgressIndicator())
            : null,
        itemBuilder: (context, item) {
          return ChatBubble(
            message: item.message,
            isMe: item.isMe,
          );
        },
      ),
    );
  }

  Future<void> _addPositiveItemAsync(int count) async {
    if (_isPositiveLoading) return;
    setState(() => _isPositiveLoading = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    _addPositiveItem(count);
    setState(() => _isPositiveLoading = false);
  }

  Future<void> _addNegativeItemAsync(int count) async {
    if (_isNegativeLoading) return;
    setState(() => _isNegativeLoading = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    _addNegativeItem(count);
    setState(() => _isNegativeLoading = false);
  }

  void _addPositiveItem(int count) {
    final int startIndex = positiveItems.length;
    final ChatPost? lastItem =
        positiveItems.isNotEmpty ? positiveItems.last : null;
    final date = lastItem?.date ?? DateTime.now();
    positiveItems.addAll(
      List<ChatPost>.generate(
        count,
        (index) => ChatPost(
          message:
              'Message ${startIndex + index} ${dummyMessageList[index % dummyMessageList.length]}',
          date: date.add(Duration(hours: (index + 1) * 2)),
          isMe: index % 2 == 0,
        ),
      ),
    );
  }

  void _addNegativeItem(int count) {
    final int startIndex = negativeItems.length;
    final ChatPost? lastItem =
        negativeItems.isNotEmpty ? negativeItems.last : null;
    final date =
        lastItem?.date ?? DateTime.now().subtract(const Duration(days: 1));

    negativeItems.addAll(
      List<ChatPost>.generate(
        count,
        (index) => ChatPost(
          message:
              'Message ${(startIndex + index + 1) * -1} ${dummyMessageList[index % dummyMessageList.length]}',
          date: date.subtract(Duration(hours: (index + 1) * 2)),
          isMe: index % 2 == 1,
        ),
      ),
    );
  }
}

class ChatPost {
  ChatPost({
    required this.message,
    required this.date,
    required this.isMe,
  });

  final String message;
  final DateTime date;
  final bool isMe;

  DateTime get dateOnly => DateTime(date.year, date.month, date.day);
}

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isMe;

  const ChatBubble({super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, sizingInformation) {
      final maxWidth = sizingInformation.maxWidth;
      return Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: maxWidth * 0.8),
            decoration: BoxDecoration(
              color: isMe ? Colors.blue : Colors.grey.shade300,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft:
                    isMe ? const Radius.circular(12) : const Radius.circular(0),
                bottomRight:
                    isMe ? const Radius.circular(0) : const Radius.circular(12),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              message,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      );
    });
  }
}

List<String> dummyMessageList = [
  'Lorem ipsum',
  'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
  'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
  'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.',
  'Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
];
