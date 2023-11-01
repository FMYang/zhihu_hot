
import 'package:flutter/foundation.dart';

class Model {
  final String title;
  final String url;

  const Model({
    required this.title,
    required this.url,
  });

  factory Model.fromJson(Map<String, dynamic> json) {
    return Model(title: json['title'], url: json['url']);
  }
}