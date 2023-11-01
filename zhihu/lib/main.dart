import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'Model.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:url_launcher/link.dart';
import 'package:flutter/foundation.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'zhihu',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('zh', 'CN'), // 设置为中文(简体)
      ],
      home: const MyHomePage(title: '知乎热榜'),
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

  List<Model> _data = [];
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    fetchData(today);
    selectedDate = DateTime.now();
  }

  // 网络请求
  Future<void> fetchData(String date) async {
    setState(() {
      _data = [];
    });
    print('${date}');
    final String url = 'https://gitlab.com/FMYang/zhihu-trending-hot-questions/-/raw/main/raw/${date}.json?ref_type=heads';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      setState(() {
        _data = jsonData.map((item) => Model.fromJson(item)).toList();
      });
    } else {
      throw Exception('failed to load data');
    }
  }

  // 日历组件
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2024),
      locale: const Locale('zh', 'CN'), // 设置为中文(简体)
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        String formatDate = DateFormat('yyyy-MM-dd').format(picked!);
        fetchData(formatDate);
      });
    }
  }

  // 打开webview
  void _launchUrl(String url) async {
    launchUrl(Uri.parse(url));
  }

  void openWebView(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Container(
          child: Column(
            children: [
              Container(
                height: 54.0, // 设置WebView顶部安全距离的高度
                color: Colors.white, // 设置安全距离的白色视图
              ),
              Expanded(
                child: InAppWebView(
                  initialUrlRequest: URLRequest(url: Uri.parse(url)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(icon: Icon(Icons.calendar_today), onPressed: () {
            _selectDate(context);
          },)
        ],
      ),
      body: _data.isEmpty 
          ? Center(child: CircularProgressIndicator())
          : ListView.separated(
            itemCount: _data.length,
            separatorBuilder: (BuildContext context, int index) {
              return Container(
                margin: EdgeInsets.only(left: 15),
                child: const Divider(
                  color: Color.fromARGB(150, 227, 227, 227),  // 分割线的颜色
                  height: 1,          // 分割线的高度
                ),
              );
            },
            // separatorBuilder: (context, index) => Divider(),
            itemBuilder: (context, index) {
              return GestureDetector(
                  onTap: () {
                    if (defaultTargetPlatform == TargetPlatform.iOS || 
                    defaultTargetPlatform == TargetPlatform.android) {
                      openWebView(context, _data[index].url);
                    } else {
                      _launchUrl(_data[index].url);
                    }
                },
                child: ListTile(
                  title: Text(_data[index].title)
                ),
              );
            },
          ),
    );
  }
}

