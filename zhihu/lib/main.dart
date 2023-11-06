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
        colorScheme: ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 255, 255, 255)),
        useMaterial3: false,
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

// 网络请求状态
enum LoadingState {
  loading,
  error,
  finished,
  empty,
}

class _MyHomePageState extends State<MyHomePage> {

  List<Model> _data = [];
  DateTime? selectedDate;
  LoadingState loadingState = LoadingState.finished;

  @override
  void initState() {
    super.initState();
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    selectedDate = DateTime.now();
    _fetchData(today);
  }

  // 网络请求
  Future<void> _fetchData(String date) async {
    setState(() {
      loadingState = LoadingState.loading;
    });
    final String url = 'https://gitlab.com/FMYang/zhihu-trending-hot-questions/-/raw/main/raw/${date}.json?ref_type=heads';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      setState(() {
        List<Model> result = jsonData.map((item) => Model.fromJson(item)).toList();
        if (result.isEmpty) {
          loadingState = LoadingState.empty;
        } else {
          loadingState = LoadingState.finished;
          _data = result;
        }
      });
    } else {
      setState(() {
        loadingState = LoadingState.error;
      });
    }
  }

  // 设置日历样式
  final ThemeData datePickerTheme = ThemeData(
      colorScheme: ColorScheme.light(
      primary: Colors.amber, // 设置选择按钮颜色
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        // 设置取消和选择按钮的颜色
        foregroundColor: MaterialStateProperty.all(Colors.black),
      ),
    ),
    datePickerTheme: DatePickerThemeData(
      headerBackgroundColor: Colors.white, // 日历头部背景色
      headerForegroundColor: Colors.black, // 日历头部文字色
    ),
  );

  // 日历组件
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2024),
      locale: const Locale('zh', 'CN'), // 设置为中文(简体)
      builder: (context, child) {
        return Theme(data: datePickerTheme, child: child!);
      }, 
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        String formatDate = DateFormat('yyyy-MM-dd').format(picked!);
        _fetchData(formatDate);
      });
    }
  }

  // 打开桌面端webview
  void _launchUrl(String url) async {
    launchUrl(Uri.parse(url));
  }

  // 打开iOS、Android端webview
  void _openWebView(BuildContext context, String url) {
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
    final DateFormat formatter = DateFormat('yyyy-MM-dd');

    Widget contentWidget;
    
    // 根据网络请求状态加载内容
    switch (loadingState) {
      case LoadingState.loading:
      contentWidget = Center(child: CircularProgressIndicator());
      break;

      case LoadingState.error:
      contentWidget = Center(child: Text('Request Failed!'));
      break;

      case LoadingState.empty:
      contentWidget = Center(child: Text('No Data'));
      break;

      case LoadingState.finished:
      contentWidget = Container(color: Colors.white, child:  ListView.separated(
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
            itemBuilder: (context, index) {
              return GestureDetector(
                  onTap: () {
                    if (defaultTargetPlatform == TargetPlatform.iOS || 
                    defaultTargetPlatform == TargetPlatform.android) {
                      _openWebView(context, _data[index].url);
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
      break;
    }

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
        backgroundColor: Colors.white,//Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        elevation: 0.2,
        title: Text(widget.title),
        centerTitle: true,
        foregroundColor: Colors.black,
        actions: <Widget>[
          IconButton(icon: Icon(Icons.calendar_today), color: Colors.black, onPressed: () {
            _selectDate(context);
          },)
        ],
        leading: Row(
            children: [
              SizedBox(width: 18.0), 
              Container(
                width: 150, 
                alignment: Alignment.centerLeft,
                child: Text(
                  formatter.format(selectedDate!), 
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
      ),
      body: contentWidget,
    );
  }
}