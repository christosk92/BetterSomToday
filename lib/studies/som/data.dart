// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio_http_cache/dio_http_cache.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:json_annotation/json_annotation.dart';
import 'package:intl/intl.dart';

dynamic authData;
dynamic userItem;
List<LesTijd> lesTijden;

class LesTijd {
  const LesTijd({this.nummer, this.begintijd, this.eindtijd});

  final String nummer;
  final String begintijd;
  final String eindtijd;
}

class UserStorage {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/userdata.txt');
  }

  Future<List<String>> readUserdata() async {
    try {
      final file = await _localFile;

      // Read the file
      var contents = await file.readAsLines();

      return contents;
    } catch (e) {
      // If encountering an error, return 0
      return null;
    }
  }

  Future<File> writeUserData(
      String username, String password, String uuid) async {
    final file = await _localFile;
    var contents = """
      $username
      $password
      $uuid
      """;
    // Write the file
    return file.writeAsString('$contents');
  }
}

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

Future<Map<String, dynamic>> tryAuthenticate(
    String username, String password) async {
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
  lesTijden = new List<LesTijd>();
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
  var returnMap = new Map<String, dynamic>();
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

      final leerlingCall = await dio.get(
          userItem["persoon"]["links"][0]["href"] + '?additional=lestijden',
          options: buildCacheOptions(Duration(days: 7)));
      var lesTijdenTemp = leerlingCall.data["additionalObjects"]["lestijden"]["lesuren"];
      lesTijdenTemp.forEach((k) => lesTijden.add(LesTijd(
          begintijd: k["begintijd"].toString(),
          eindtijd: k["eindtijd"].toString(),
          nummer: k["nummer"].toString())));
      print(lesTijden);
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
  } catch (err) {
    returnMap["error"] = err;
    print(err);
  }
}

String currentDate() {
  var now = new DateTime.now();
  var formatter = new DateFormat('yyyy-MM-dd');
  String formattedDate = formatter.format(now);
  return formattedDate;
}

String averageLatestGrades(List<QuickItemData> initList, int shown) {
  var items = initList.where((element) => element.caption != null);
  List<double> projectedGrades =
      items.map((value) => double.parse(value.caption)).take(shown).toList();
  var sumOfGrades =
      projectedGrades.map<double>((m) => m).reduce((a, b) => a + b);
  var average = sumOfGrades / projectedGrades.length;
  var roundedAverage = average.toStringAsFixed(1);
  return roundedAverage.toString();
}

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
class QuickItemData {
  const QuickItemData(
      {this.name, this.caption, this.subtitle, this.date = null});

  final String name;
  final DateTime date;
  final String subtitle;

  final String caption;
}

class SchoolListItem {
  const SchoolListItem({this.uuid, this.naam});

  final String uuid;

  final String naam;
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
class SomDataService {
  static Future<List<List<QuickItemData>>> getQuickItemsAsync(
      BuildContext context) async {
    var itemsToReturn = new List<List<QuickItemData>>();

    Dio dio = new Dio();
    dio.interceptors.add(DioCacheManager(CacheConfig()).interceptor);
    var authToken = authData["access_token"];
    dio.options.headers["Authorization"] = "Bearer " + authToken;
    dio.options.headers["accept"] = "application/json";
    DateTime today = DateTime.now();
    var _firstDayOfTheweek = today
        .subtract(new Duration(days: today.weekday))
        .add(new Duration(days: 1));
    //var startDate = DateFormat('yyyy-MM-dd').format(_firstDayOfTheweek);
    //var endDate = DateFormat('yyyy-MM-dd')
    //.format(_firstDayOfTheweek.add(new Duration(days: 6)));
    var startDate = DateFormat('yyyy-MM-dd').format(today);
    var endDate =
        DateFormat('yyyy-MM-dd').format(today.add(new Duration(days: 1)));
    var additionalObjects =
        "sort=asc-id&additional=vak&additional=docentAfkortingen&additional=leerlingen&begindatum=" +
            startDate +
            "&einddatum=" +
            endDate;
    var roosterQuickItems = new List<QuickItemData>();
    try {
      final response = await dio.get(
          authData['somtoday_api_url'] +
              '/rest/v1/afspraken?' +
              additionalObjects,
          options: buildCacheOptions(Duration(seconds: 120)));
      if (response.statusCode == 200 || response.statusCode == 206) {
        var data = response.data["items"];
        data.forEach((k) => roosterQuickItems.add(QuickItemData(
            name: k["additionalObjects"]["vak"]["naam"],
            subtitle: k["additionalObjects"]["docentAfkortingen"] +
                " - " +
                k["locatie"],
            caption: lesTijden.firstWhere((element) => element.nummer == k["beginLesuur"].toString()).begintijd.replaceAll(":00", ""))));
      }
    } on DioError catch (e) {
      print("error " + e.message);
    }
    roosterQuickItems.sort((a, b) {
      return int.parse(a.caption.split(":")[0]).compareTo(int.parse(b.caption.split(":")[0]));
    });
    itemsToReturn.add(roosterQuickItems);
    var quickGrades = await getQuickGradeItem();
    itemsToReturn.add(quickGrades);
    return itemsToReturn;
  }

  Future<List<QuickItemData>> initGradesLoad() async {
    for (int i = 0; i < 1000; i += 10) {}
  }

  static void setCacheNull() {
    cachedGrades = null;
  }

  static List<QuickItemData> cachedGrades;
  static Future<List<QuickItemData>> getQuickGradeItem() async {
    if (cachedGrades == null) {
      Dio dio = new Dio();
      dio.interceptors.add(DioCacheManager(CacheConfig()).interceptor);
      var authToken = authData["access_token"];
      dio.options.headers["Authorization"] = "Bearer " + authToken;
      dio.options.headers["accept"] = "application/json";

      var additionalObjects =
          "additional=berekendRapportCijfer&additional=samengesteldeToetskolomId&additional=resultaatkolomId&additional=cijferkolomId&additional=toetssoortnaam&additional=huidigeAnderVakKolommen";
      var gradesQuickItems = new List<QuickItemData>();
      for (int i = 0; i < 500; i += 60) {
        try {
          dio.options.headers["Range"] = "items=${i}-${i + 61}";
          final response = await dio.get(authData['somtoday_api_url'] +
              '/rest/v1/resultaten/huidigVoorLeerling/' +
              userItem["persoon"]["links"][0]["id"].toString() +
              '?' +
              additionalObjects);
          if (response.statusCode == 200 || response.statusCode == 206) {
            var data = response.data["items"];
            print(data.length);
            var _f = List.from(data)
                .where((element) => element["type"] == "Toetskolom");
            _f.forEach((k) => gradesQuickItems.add(QuickItemData(
                name: k["vak"]["naam"],
                date: DateTime.parse(DateFormat("yyyy-MM-dd")
                    .format(DateTime.parse(k["datumInvoer"]))),
                subtitle: k["omschrijving"],
                caption: k["resultaat"].toString())));
            cachedGrades = gradesQuickItems;
          }
        } on DioError catch (e) {
          print("error " + e.message);
        }
      }
    }
    var distinctGrades = cachedGrades.toSet().toList();
    distinctGrades.sort((a, b) {
      return b.date.compareTo(a.date);
    });
    return distinctGrades
        .where((element) => element.caption != "null")
        .toList();
  }

  static List<String> getSettingsTitles(BuildContext context) {
    return <String>['Uitloggen'];
  }
}
