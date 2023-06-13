import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:gradufsc/cagr_options.dart';
import 'package:gradufsc/functions/notifications.dart';
import 'package:gradufsc/models/course.dart';
import 'package:gradufsc/models/databaseHelper.dart';
import 'dart:async';

import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

import 'package:uni_links/uni_links.dart';

const _apiUrl = 'https://ws.ufsc.br/rest/CAGRUsuarioService/';
const _userTimeGrid = 'getGradeHorarioAluno';
const _userInfo = 'getInformacaoAluno';

class CagrAuth {
  final dbHelper = DatabaseHelper();
  final currentUser = FirebaseAuth.instance.currentUser;
  final firestore = FirebaseFirestore.instance;

  Future<String?> _getAuthCode(String? authCode) async {
    String? code;

    if (authCode == null) {
      Uri url = Uri.parse(CAGROptions.authURL);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }

      final urlBack = await linkStream.first;

      if (urlBack != null) {
        code = Uri.parse(urlBack).queryParameters['code'];
      }
    } else {
      code = authCode;
    }

    if (code != null) {
      return _getAccessToken(code);
    }

    return null;
  }

  Future<String?> _getAccessToken(String authorizationCode) async {
    final response = await http.post(
      Uri.parse(CAGROptions.accessTokenUrl),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'authorization_code',
        'client_id': CAGROptions.clientId,
        'client_secret': CAGROptions.clientSecret,
        'redirect_uri': 'tccleal://tccleal.setic_oauth.ufsc.br',
        'code': authorizationCode,
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);

      return jsonResponse['access_token'];
    } else {
      throw Exception('Failed to get access token');
    }
  }

  Future<bool> updateData({String? authCode}) async {
    DocumentSnapshot snapshot =
        await firestore.collection('users').doc(currentUser?.uid).get();
    if (snapshot.exists) {
      Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
      if (data != null && data.containsKey('cagr_auth_token')) {
        bool updated = await _fetchSchedule(data['cagr_auth_token']);
        if (updated) {
          return true;
        }
      }
    }

    String? tokenAccess = await _getAuthCode(authCode);

    if (tokenAccess != null) {
      firestore
          .collection('users')
          .doc(currentUser?.uid)
          .set({'cagr_auth_token': tokenAccess});
      return _fetchSchedule(tokenAccess);
    }
    return false;
  }

  Future<bool> _fetchUserData(
      String authCode, String semester, List<dynamic>? schedules) async {
    Map<String, dynamic> data = {};
    final response =
        await http.get(Uri.parse("$_apiUrl$_userInfo?access_token=$authCode"));
    if (response.statusCode == 200) {
      final res = json.decode(response.body);
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(currentUser?.uid);

      if (res['disciplinas'] != null) {
        List<Map> courses = [];
        for (var courseJson in res['disciplinas']) {
          List<String> professorsNames = [];

          if (courseJson['professores'] != null) {
            for (var professor in courseJson['professores']) {
              professorsNames.add(professor['nomeProfessor'].trim());
            }
          }

          courses.add(Course(
                  courseJson['nomeDisciplina'].trim(),
                  professorsNames,
                  courseJson['codigoTurma'].trim(),
                  courseJson['codigoDisciplina'].trim(),
                  semester.trim())
              .toMap());
        }

        data['courses'] = courses;
      }

      Map<String, dynamic> userInfo = {};

      if (res['matricula'] != null) {
        userInfo["registration_code"] = res["matricula"];
      }

      if (res['nome'] != null) {
        userInfo['name'] = res['nome'];
      }

      if (res['nomeCurso'] != null) {
        userInfo['course_name'] = res['nomeCurso'];
      }

      userInfo['semester'] = semester;

      data['info'] = userInfo;

      if (schedules != null) {
        List<Map<String, dynamic>> scheduleList = [];

        for (var schedule in schedules) {
          scheduleList.add({
            'course_code': schedule['codigoDisciplina'].trim(),
            'class_code': schedule['codigoTurma'].trim(),
            'location_center': schedule['localizacaoCentro'].trim(),
            'location_room': schedule['localizacaoEspacoFisico'].trim(),
            'week_day': schedule['diaSemana'],
            'time': schedule['horario'],
          });
        }

        data['schedule'] = scheduleList;
      }

      data['cagr_auth_token'] = authCode;
      data['last_update'] = DateTime.now();

      FirebaseMessaging messaging = FirebaseMessaging.instance;
      String? fmcToken = await messaging.getToken();

      if (fmcToken != null) {
        data['fmc_token'] = fmcToken;
      }

      NotificationHelper notificationHelper = NotificationHelper();
      notificationHelper.scheduleUserGrade(data);

      await userRef.update(data);
      return true;
    } else {
      return false;
    }
  }

  Future<bool> _fetchSchedule(String authCode) async {
    final response = await http
        .get(Uri.parse("$_apiUrl$_userTimeGrid?access_token=$authCode"));
    if (response.statusCode == 200) {
      final res = json.decode(response.body);
      String semester = res["semestre"].toString();
      List<dynamic>? schedule = res["horarios"];
      return _fetchUserData(authCode, semester, schedule);
    } else {
      return false;
    }
  }
}
