import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gradufsc/screens/cagr_auth.dart';
import 'package:gradufsc/screens/initial.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _hasAuthCode = false;
  final currentUser = FirebaseAuth.instance.currentUser;
  final firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _checkAuthCode();
  }

  Future<void> _checkAuthCode() async {
    var hasAuthCode = false;
    var snapshot =
        await firestore.collection('users').doc(currentUser?.uid).get();
    if (snapshot.exists) {
      hasAuthCode = true;
    } else {}

    setState(() {
      _hasAuthCode = hasAuthCode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _hasAuthCode ? const InitialScreen() : const AuthCAGRPage();
    // return AuthCAGRPage();
    // return _hasAuthCode ? const MoodleAuthPage() : const AuthCAGRPage();
  }
}
