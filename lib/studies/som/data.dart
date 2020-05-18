// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio_http_cache/dio_http_cache.dart';

dynamic authData;
dynamic userItem;

class CacheInterceptor extends Interceptor {
  CacheInterceptor();

  var _cache = new Map<Uri, Response>();

  @override
  onRequest(RequestOptions options) async {
    return options;
  }

  @override
  onResponse(Response response) async {
    _cache[response.request.uri] = response;
  }

  @override
  onError(DioError e) async {
    print('onError: $e');
    if (e.type == DioErrorType.CONNECT_TIMEOUT ||
        e.type == DioErrorType.DEFAULT) {
      var cachedResponse = _cache[e.request.uri];
      if (cachedResponse != null) {
        return cachedResponse;
      }
    }
    return e;
  }
}

Future<Map<String, String>> tryAuthenticate(String username, String password) async {
  Dio dio = new Dio();
  dio.interceptors.add(DioCacheManager(CacheConfig()).interceptor);
  try {
    final result = await InternetAddress.lookup('google.com');
    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      print('connected');
    }
  } on SocketException catch (_) {
    print('not connected');
    throw Exception('You are currently not connected to the internet.');
  }
  String basicAuth = 'Basic ' +
      base64Encode(utf8.encode(
          'D50E0C06-32D1-4B41-A137-A9A850C892C2:vDdWdKwPNaPCyhCDhaCnNeydyLxSGNJX'));

  Map<String, String> headers = {
    'content-type': 'application/x-www-form-urlencoded',
    'accept': 'application/json',
    'authorization': basicAuth
  };
  Map<String, dynamic> body = {
    'username': username,
    'password': password,
    'scope': 'openid',
    'grant_type': 'password'
  };
  dio.options.headers.addAll(headers);
  var returnMap = new Map<String, String>();
  try {
    final response = await dio.post('https://somtoday.nl/oauth2/token',
        data: body, options: buildCacheOptions(Duration(seconds: 3500)));
    if (response.statusCode == 200) {
      // If the call to the server was successful, parse the JSON
      print(response.data);

      var data = response.data;
      authData = data;
      var authToken = authData["access_token"];
      dio.options.headers["Authorization"] = "Bearer " + authToken;
      dio.options.headers["accept"] = "application/json";
      final forcedResponse = await dio.get(
          authData["somtoday_api_url"] + '/rest/v1/account/me',
          options: buildCacheOptions(Duration(days: 7)));
      returnMap["auth"] = forcedResponse.data;
      userItem = forcedResponse.data;
      return returnMap;
    } else {
      // If that call was not successful, throw an error.
      returnMap["error"] = response.statusCode.toString();
      throw Exception('Failed to load post');
    }
  } on DioError catch (e) {
    if (e.response.statusCode == 400) {
      returnMap["error"] = "400";
    } else {
      returnMap["error"] = e.message;
    }
    return returnMap;
  }
}

String currentDate() {
  var now = new DateTime.now();
  var formatter = new DateFormat('yyyy-MM-dd');
  String formattedDate = formatter.format(now);
  return formattedDate;
}

String averageLatestGrades(List<CijferData> items) => '7.4';

/// Utility function to sum up values in a list.
double sumOf<T>(List<T> list, double Function(T elt) getValue) {
  var sum = 0.0;
  for (var elt in list) {
    sum += getValue(elt);
  }
  return sum;
}

/// A data model for an item
///
class QuickRoosterData {
  const QuickRoosterData({this.name, this.time, this.teacher});

  final String name;

  final String time;

  final String teacher;
}

class SchoolListItem {
  const SchoolListItem({this.uuid, this.naam});

  final String uuid;

  final String naam;
}

/// A data model for a grade
///
class CijferData {
  const CijferData({
    this.name,
    this.grade,
    this.date,
    this.isVoldoende,
  });

  /// The display name of this entity.
  final String name;

  /// The primary amount or value of this entity.
  final double grade;

  /// The due date of this bill.
  final String date;

  /// If this bill has been paid.
  final bool isVoldoende;
}

class DetailedEventData {
  const DetailedEventData({
    this.title,
    this.date,
    this.amount,
  });

  final String title;
  final DateTime date;
  final double amount;
}

/// A data model for data displayed to the user.
class UserDetailData {
  UserDetailData({this.title, this.value});

  /// The display name of this entity.
  final String title;

  /// The value of this entity.
  final String value;
}

/// Class to return dummy data lists.
///
/// In a real app, this might be replaced with some asynchronous service.
class DummyDataService {
  static List<QuickRoosterData> getQuickRoosterItem(BuildContext context) {
    return <QuickRoosterData>[
      QuickRoosterData(
        name: 'Wiskunde B',
        teacher: 'Dhr. R. Stokking',
        time: '09:30 - 10:15',
      ),
      QuickRoosterData(
        name: 'Natuurkunde',
        teacher: 'K. Roeleveld',
        time: '10:30 - 11:15',
      ),
      QuickRoosterData(
        name: 'Natuurkunde',
        teacher: 'K. Roeleveld',
        time: '11:15 - 12:00',
      ),
    ];
  }

  static List<CijferData> getQuickGradeItem(BuildContext context) {
    return <CijferData>[
      CijferData(
        name: 'Wiskunde B',
        grade: 9.5,
        date: '2020-01-01',
      ),
      CijferData(
        name: 'Wiskunde B',
        grade: 10.0,
        date: '2020-01-01',
      ),
      CijferData(
        name: 'Wiskunde B',
        grade: 7.5,
        date: '2020-01-01',
      ),
    ];
  }

  static List<DetailedEventData> getDetailedEventItems() {
    // The following titles are not localized as they're product/brand names.
    return <DetailedEventData>[
      DetailedEventData(
        title: 'Genoe',
        date: DateTime.utc(2019, 1, 24),
        amount: -16.54,
      ),
      DetailedEventData(
        title: 'Fortnightly Subscribe',
        date: DateTime.utc(2019, 1, 5),
        amount: -12.54,
      ),
      DetailedEventData(
        title: 'Circle Cash',
        date: DateTime.utc(2019, 1, 5),
        amount: 365.65,
      ),
      DetailedEventData(
        title: 'Crane Hospitality',
        date: DateTime.utc(2019, 1, 4),
        amount: -705.13,
      ),
      DetailedEventData(
        title: 'ABC Payroll',
        date: DateTime.utc(2018, 12, 15),
        amount: 1141.43,
      ),
      DetailedEventData(
        title: 'Shrine',
        date: DateTime.utc(2018, 12, 15),
        amount: -88.88,
      ),
      DetailedEventData(
        title: 'Foodmates',
        date: DateTime.utc(2018, 12, 4),
        amount: -11.69,
      ),
    ];
  }

  static List<String> getSettingsTitles(BuildContext context) {
    return <String>['Uitloggen'];
  }
}
