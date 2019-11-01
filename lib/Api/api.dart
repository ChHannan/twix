import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';

class Api {
  // AUTH
  static const String _registerToken =
      'Token	949251c663b71f8b27afd37a10af87f3e8ed6a95';
  static const String _contentType = 'application/json';

  static String _authToken = '';

  static setAuthToken(String token) => _authToken = 'Token ' + token;

  // URLS
  static const String _authority = 'api.knctu.com';
  static const String _link = 'https://api.knctu.com/api/';

  static const String _userView = '${_link}user/';
  static const String _userList = '${_link}users/';

  static String _userDetail(String id) => '$_userView$id/';

  static String _createDevice = '${_link}devices/';

  static const String _tokenView = '${_link}token/';

  static const String _groupView = '${_link}twix/group/';

  static String _groupDetail(String id) => '$_groupView$id/';

  static String _groupAdd(String id) => '${_groupDetail(id)}add/';

  static String _groupRemove(String id) => '${_groupDetail(id)}remove/';

  static const String _boardView = '${_link}twix/board/';

  static String _boardDetail(String id) => '$_boardView$id/';

  static const String _taskView = '${_link}twix/task/';

  static String _taskDetail(String id) => '$_taskView$id/';

  static const String _assignedTaskView = '${_link}twix/tasks/assigned/';

  static String _assignedTaskDetail(String id) => '$_assignedTaskView$id';

  // General
  static Future<Response> ping() {
    return get(_link);
  }

  // User App

  static Future<Response> createUser(
      String id, String name, String email, String password) {
    return post(_userView,
        body: jsonEncode(
            {'id': id, 'name': name, 'email': email, 'password': password}),
        headers: {
          HttpHeaders.authorizationHeader: _registerToken,
          HttpHeaders.contentTypeHeader: 'application/json'
        });
  }

  static Future<Response> getToken(String email, String password) {
    return post(_tokenView, body: {'email': email, 'password': password});
  }

  static Future<Response> getAllUsers({String email = ''}) {
    Uri uri = Uri.https(_authority, 'api/users', {'email': email});
    return get(uri, headers: {
      HttpHeaders.authorizationHeader: _authToken,
      HttpHeaders.contentTypeHeader: 'application/json'
    });
  }

  // Twix App

  static Future<Response> createDevice(String name, String registrationId) {
    return post(_createDevice,
        body: jsonEncode({
          'name': name,
          'registration_id': registrationId,
          'type': 'android'
        }),
        headers: {
          HttpHeaders.authorizationHeader: _authToken,
          HttpHeaders.contentTypeHeader: 'application/json'
        });
  }

  static Future<Response> createBoard(
      {String id, String name, String userId, bool isPersonal}) {
    return post(_boardView,
        body: jsonEncode({
          'id': id,
          'name': name,
          'user': userId,
          'is_personal': isPersonal
        }),
        headers: {
          HttpHeaders.authorizationHeader: _authToken,
          HttpHeaders.contentTypeHeader: 'application/json'
        });
  }

  static Future<Response> deleteBoard(String id) {
    return delete(_boardDetail(id));
  }

  static Future<Response> createTask(
      {String id,
      String name,
      bool isDone,
      DateTime dueDate,
      DateTime remindMe,
      String boardId,
      bool isAssigned,
      String groupId}) {
    return post(_taskView,
        body: jsonEncode({
          'id': id,
          'name': name,
          'is_done': isDone,
          'due_date': dueDate,
          'remind_me': remindMe,
          'board_id': boardId,
          'is_assigned': isAssigned,
          'group_id': groupId
        }),
        headers: {
          HttpHeaders.authorizationHeader: _authToken,
          HttpHeaders.contentTypeHeader: 'application/json'
        });
  }

  static Future<Response> deleteTask(String id) {
    return delete(_taskDetail(id), headers: {
      HttpHeaders.authorizationHeader: _authToken,
      HttpHeaders.contentTypeHeader: 'application/json'
    });
  }

  static Future<Response> viewAssignedTask() {
    return get(_assignedTaskView, headers: {
      HttpHeaders.authorizationHeader: _authToken,
      HttpHeaders.contentTypeHeader: 'application/json'
    });
  }

  static Future<Response> updateAssignedTask(String id, bool isDone) {
    return patch(_assignedTaskDetail(id),
        body: jsonEncode({'is_done': isDone}),
        headers: {
          HttpHeaders.authorizationHeader: _authToken,
          HttpHeaders.contentTypeHeader: 'application/json'
        });
  }

  static Future<Response> createGroup(String id, String name, String adminId) {
    return post(_groupView,
        body: jsonEncode({'id': id, 'name': name, 'admin_id': adminId}),
        headers: {
          HttpHeaders.authorizationHeader: _authToken,
          HttpHeaders.contentTypeHeader: 'application/json'
        });
  }

  static Future<Response> addToGroup(String id, String user) {
    return post(_groupAdd(id), body: jsonEncode({'user': user}), headers: {
      HttpHeaders.authorizationHeader: _authToken,
      HttpHeaders.contentTypeHeader: 'application/json'
    });
  }

  static Future<Response> removeFromGroup(String id, String user) {
    return post(_groupRemove(id), body: jsonEncode({'user': user}), headers: {
      HttpHeaders.authorizationHeader: _authToken,
      HttpHeaders.contentTypeHeader: 'application/json'
    });
  }
}

class Connect {
  static bool _isConnected;

  static bool get getConnection => _isConnected;

  static Future<bool> isConnected() async {
    _isConnected = (await Api.ping()).statusCode == 200;
    return _isConnected;
  }
}
