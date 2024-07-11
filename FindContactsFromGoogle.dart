
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: [
    'https://www.googleapis.com/auth/contacts.readonly',
  ],
);

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Google Contacts in Flutter'),
        ),
        body: SignInDemo(),
      ),
    );
  }
}

class SignInDemo extends StatefulWidget {
  @override
  State createState() => SignInDemoState();
}

class SignInDemoState extends State<SignInDemo> {
  GoogleSignInAccount? _currentUser;
  List<Map<String, String>> _contacts = [];

  @override
  void initState() {
    super.initState();
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      setState(() {
        _currentUser = account;
      });
      if (_currentUser != null) {
        _getContacts();
      }
    });
    _googleSignIn.signInSilently();
  }

  Future<void> _getContacts() async {
    final GoogleSignInAccount? account = _googleSignIn.currentUser;
    if (account != null) {
      final GoogleSignInAuthentication auth = await account.authentication;
      final http.Response response = await http.get(
        Uri.parse('https://people.googleapis.com/v1/people/me/connections?personFields=calendarUrls,names,emailAddresses,phoneNumbers,photos,events&pageSize=1000&sortOrder=FIRST_NAME_ASCENDING'),
        headers: await account.authHeaders,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        List connections = data['connections'];
        _contacts = connections
            .map((contact) => {
          'name': contact['names'][0] == null ? 'No name' : contact['names'][0]['displayName'] == null ? 'No name' : contact['names'][0]['displayName'].toString(),
          'email': contact['emailAddresses'] == null ? 'No email' : contact['emailAddresses'][0]['value'].toString(),
          'phone': contact['phoneNumbers'] == null ? 'No phone' : contact['phoneNumbers'][0]['value'].toString(),
          'photo': contact['photos'] == null ? 'No photo' : contact['photos'][0]['url'].toString(),
          'events': contact['events'] == null ? 'No events' : contact['events'][0]['value'].toString(),

     })
            .toList();
log("Contacts: $_contacts");
        setState(() {

        });

      } else {
        print('Error fetching contacts: ${response.statusCode}');
      }
    }
  }



  Future<void> _handleSignOut() async {
    _googleSignIn.disconnect();
  }

  @override
  Widget build(BuildContext context) {
    GoogleSignInAccount? user = _currentUser;
    return Scaffold(
      appBar: AppBar(
        title:user != null? Text(user.displayName ?? '') : Text('Google Contacts'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              log("Contacts: $_contacts");
            },
          )
        ],
      ),
      body: _contacts.isEmpty ? Text( " no found "):
           ListView.builder(
             shrinkWrap: true,
             itemCount: _contacts.length,
             itemBuilder: (context, index) {
               return ListTile(
                 title: Text(_contacts[index]['name'] ?? 'No name'),
                 subtitle: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(_contacts[index]['email'] ?? 'No email'),
                     Text(_contacts[index]['phone'] ?? 'No phone'),
                     Text(_contacts[index]['event'] ?? 'No event'),
                   ],
                 ),
                 leading: CircleAvatar(
                   backgroundImage: NetworkImage(_contacts[index]['photo'] ?? 'No photo'),
                 ),
               );
             },
           ),
      floatingActionButton: user == null ? ElevatedButton(onPressed: () => _googleSignIn.signIn(), child: Text('SIGN IN')) : ElevatedButton(
        child: Text('SIGN OUT'),
        onPressed: _handleSignOut,
      ),
    );
  }
}
