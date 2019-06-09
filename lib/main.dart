import 'dart:convert';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart/rxdart.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _page = 1;
  bool _isLoading = false;
  String searchTerm;
  CancelableOperation op;

  List<Map<String, dynamic>> _data = new List();

  ScrollController _controller;
  TextEditingController _textController;

  final subject = new PublishSubject<String>();

  @override
  initState() {
    super.initState();
    // op = CancelableOperation.fromFuture(_loadData());
    _controller = new ScrollController()..addListener(_scrollListener);
    _textController = new TextEditingController(text: '');
    subject.stream
        .debounce((_) => TimerStream(true, new Duration(milliseconds: 600)))
        .listen(_textListener);
  }

  _scrollListener() {
    if (_controller.position.pixels == _controller.position.maxScrollExtent) {
      // if (op != null) {
      //   op.cancel();
      // }
      // op = CancelableOperation.fromFuture(_loadData());
      setState(() {
        _isLoading = true;
      });
      _loadData();
    }
  }

  _textListener(String text) {
    // if (op != null) {
    //   op.cancel();
    // }
    // setState(() {
    //   _page = 1;
    //   searchTerm = _textController.text;
    //   _data.clear();
    // });
    // op = CancelableOperation.fromFuture(_loadData());
    print("called for ${text}");
    if (text.isEmpty) {
      setState(() {
        _isLoading = false;
        _data.clear();
      });
      return;
    }
    setState(() {
      _page = 1;
      _isLoading = true;
      _data.clear();
      searchTerm = text;
    });
    _loadData();
  }

  Future _loadData() async {
    // if (searchTerm != null && searchTerm.isNotEmpty) {
    // setState(() {
    //   _isLoading = true;
    // });
    final url =
        "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=3e7cc266ae2b0e0d78e279ce8e361736&format=json&nojsoncallback=1&text=${searchTerm}&page=${_page}";
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final newData = json.decode(response.body)["photos"]["photo"];
      print(newData.runtimeType);
      print(newData[0].runtimeType);
      setState(() {
        _data.addAll((newData as List)
            .map((d) => Map<String, dynamic>.from(d))
            .toList());
        _page += 1;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
    // }
    // else {
    //   setState(() {
    //     _data.clear();
    //     _page = 1;
    //   });
    // }
  }

  String _generateImageUrl(Map<String, dynamic> datum) {
    final farm = datum['farm'];
    final server = datum['server'];
    final id = datum['id'];
    final secret = datum['secret'];
    return "http://farm${farm}.static.flickr.com/${server}/${id}_${secret}.jpg";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: <Widget>[
          TextField(
            autofocus: true,
            controller: _textController,
            decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16.0),
                hintText: 'Search'),
            onChanged: (string) => subject.add(string),
          ),
          Expanded(
            child: GridView.count(
                crossAxisCount: 3,
                controller: _controller,
                children: _data.map((datum) {
                  return FadeInImage.assetNetwork(
                    placeholder: 'assets/loading.png',
                    image: _generateImageUrl(datum),
                    imageScale: 1,
                  );
                }).toList()),
          ),
          _isLoading
              ? Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                )
              : Container()
        ],
      ),
    );
  }
}
