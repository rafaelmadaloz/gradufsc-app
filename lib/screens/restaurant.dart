import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gradufsc/constants.dart';
import 'package:gradufsc/functions/notifications.dart';
import 'package:gradufsc/screens/pdf_view.dart';
import 'package:gradufsc/widgets/title.dart';
import 'package:url_launcher/url_launcher.dart';

class RestaurantScreen extends StatefulWidget {
  const RestaurantScreen({super.key});

  @override
  _RestaurantScreenState createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends State<RestaurantScreen>
    with SingleTickerProviderStateMixin {
  FirebaseAuth auth = FirebaseAuth.instance;
  late TabController _tabController;
  late Future<Map<String, dynamic>?> _menuData;
  String _campus = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 7, vsync: this, initialIndex: DateTime.now().weekday - 1);
    _menuData = _fetchMenuData();
  }

  Future<Map<String, dynamic>> _fetchMenuData() async {
    String campusKey = 'trindade';
    DocumentSnapshot usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(auth.currentUser?.uid)
        .get();

    if (usersSnapshot.exists) {
      Map<String, dynamic>? data =
          usersSnapshot.data() as Map<String, dynamic>?;
      if (data != null && data.containsKey('campus')) {
        if (campusOptions[data['campus']] != null) {
          campusKey = data['campus'];
        }
      }
    }

    setState(() {
      _campus = campusOptions[campusKey] as String;
    });

    DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
        .instance
        .collection('restaurant')
        .doc(campusKey)
        .get();

    if (!snapshot.exists) {
      return Future.value({});
    }

    final menuData = snapshot.data() as Map<String, dynamic>;

    return menuData;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _menuData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erro ao carregar dados do cardápio'));
        }

        Map<String, dynamic> menuData = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text('RU ${_campus}'),
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: 'Segunda'),
                Tab(text: 'Terça'),
                Tab(text: 'Quarta'),
                Tab(text: 'Quinta'),
                Tab(text: 'Sexta'),
                Tab(text: 'Sábado'),
                Tab(text: 'Domingo'),
              ],
            ),
            actions: [
              Row(
                children: [
                  IconButton(
                      onPressed: () async {
                        var url =
                            Uri.parse(menuData['url']).replace(scheme: 'https');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url,
                              mode: LaunchMode.externalApplication);
                        } else {
                          throw 'Não foi possível acessar';
                        }
                      },
                      icon: const Icon(Icons.picture_as_pdf)),
                ],
              )
            ],
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildMenuCard(menuData['monday'], _campus, menuData['url']),
              _buildMenuCard(menuData['tuesday'], _campus, menuData['url']),
              _buildMenuCard(menuData['wednesday'], _campus, menuData['url']),
              _buildMenuCard(menuData['thursday'], _campus, menuData['url']),
              _buildMenuCard(menuData['friday'], _campus, menuData['url']),
              _buildMenuCard(menuData['saturday'], _campus, menuData['url']),
              _buildMenuCard(menuData['sunday'], _campus, menuData['url']),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuCard(
      Map<String, dynamic>? menuItems, String campus, String? url) {
    List<String> lunchItems = [];
    List<String> dinnerItems = [];
    List<String> commonItems = [];

    List<String> accompaniments = [];
    List<String> dessert = [];
    List<String> salads = [];
    List<String> meat = [];
    // Separa os itens do menu com base no tipo (lunch, dinner, common)

    if (menuItems != null) {
      menuItems.forEach((key, value) {
        if (key.contains('lunch')) {
          lunchItems.addAll(value.cast<String>());
        } else if (key.contains('dinner')) {
          dinnerItems.addAll(value.cast<String>());
        } else if (key.contains('accompaniments')) {
          accompaniments.addAll(value.cast<String>());
        } else if (key.contains('dessert')) {
          dessert.addAll(value.cast<String>());
        } else if (key.contains('salads')) {
          salads.addAll(value.cast<String>());
        } else if (key.contains('meat')) {
          meat.addAll(value.cast<String>());
        } else {
          commonItems.addAll(value.cast<String>());
        }
      });
    } else {
      if (campus == 'CCA')
        return Center(
          child: Text('Fechado'),
        );
      if (url != null)
        return Center(
          child: ElevatedButton(
            child: Text('Acessar PDF'),
            onPressed: () async {
              var uri = Uri.parse(url).replace(scheme: 'https');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                throw 'Não foi possível acessar';
              }
            },
          ),
        );
      return Center(
        child: Text('Cardápio indiponível no momento'),
      );
    }

    return ListView(
      children: [
        if (salads.isNotEmpty)
          Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: title("Saladas"),
              ),
              ...salads.map((item) => ListTile(title: Text(item))).toList(),
            ],
          ),
        if (accompaniments.isNotEmpty)
          Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: title("Acompanhamentos"),
              ),
              ...accompaniments
                  .map((item) => ListTile(title: Text(item)))
                  .toList(),
            ],
          ),
        if (meat.isNotEmpty)
          Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: title("Carne"),
              ),
              ...meat.map((item) => ListTile(title: Text(item))).toList(),
            ],
          ),
        if (dessert.isNotEmpty)
          Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: title("Sobremesa"),
              ),
              ...dessert.map((item) => ListTile(title: Text(item))).toList(),
            ],
          ),
        if (lunchItems.isNotEmpty)
          Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: title("Almoço"),
              ),
              ...lunchItems.map((item) => ListTile(title: Text(item))).toList(),
            ],
          ),
        if (dinnerItems.isNotEmpty)
          Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: title("Jantar"),
              ),
              ...dinnerItems
                  .map((item) => ListTile(title: Text(item)))
                  .toList(),
            ],
          ),
        if (commonItems.isNotEmpty)
          Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: title("Pratos do Dia"),
              ),
              ...commonItems
                  .map((item) => ListTile(title: Text(item)))
                  .toList(),
            ],
          ),
      ],
    );
  }
}
