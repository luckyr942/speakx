import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shimmer/shimmer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paginated List',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Paginated List'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<dynamic> _items = [];
  String? _nextId;
  String? _prevId;
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchData(direction: 'down');
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchData({required String direction}) async {
    setState(() => _isLoading = true);

    try {
      String endpoint = 'YOUR_API_ENDPOINT?direction=$direction';
      if (direction == 'down' && _nextId != null) {
        endpoint += '&id=$_nextId';
      } else if (direction == 'up' && _prevId != null) {
        endpoint += '&id=$_prevId';
      }

      final response = await http.get(Uri.parse(endpoint));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newData = data['data'] as List<dynamic>;

        setState(() {
          if (direction == 'down') {
            _items.addAll(newData);
            _nextId = newData.isNotEmpty ? newData.last['id'] : null;
          } else {
            _items.insertAll(0, newData);
            _prevId = newData.isNotEmpty ? newData.first['id'] : null;
          }
          _isLoading = false;
        });
      } else {
        // Handle API error
        print('Failed to load data: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      // Handle network error
      print('Error: $e');
      setState(() => _isLoading = false);
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (_nextId != null) {
        _fetchData(direction: 'down');
      }
    } else if (_scrollController.position.pixels == 0) {
      if (_prevId != null) {
        _fetchData(direction: 'up');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _isLoading
          ? _buildShimmer()
          : ListView.builder(
              controller: _scrollController,
              itemCount: _items.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_items[index]['title']),
                );
              },
            ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return ListTile(
            title: SizedBox(
              width: 100,
              height: 10,
              child: Container(
                color: Colors.grey,
              ),
            ),
          );
        },
      ),
    );
  }
}
