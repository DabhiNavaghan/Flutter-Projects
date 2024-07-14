import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/people/v1.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}


class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      PeopleServiceApi.contactsReadonlyScope,
      PeopleServiceApi.contactsOtherReadonlyScope,
    ],
  );

  List<Person> _otherContacts = [];

  Future<void> _getOtherContacts() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // The user canceled the sign-in
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthClient client = authenticatedClient(
        http.Client(),
        AccessCredentials(
          AccessToken(
            'Bearer',
            googleAuth.accessToken!,
            DateTime.now().toUtc().add(Duration(hours: 1)),
          ),
          null, // No refresh token available
          // ['https://www.googleapis.com/auth/contacts.readonly'],
          ['https://people.googleapis.com/v1/otherContacts?readMask=names,emailAddresses,phoneNumbers'],
        ),
      );

      final PeopleServiceApi peopleService = PeopleServiceApi(client);
      ListOtherContactsResponse response = await peopleService.otherContacts.list(
        readMask: 'names,emailAddresses,phoneNumbers',
      );
      ListConnectionsResponse regularContactsResponse = await peopleService.people.connections.list(
        'people/me',
        personFields: 'names,emailAddresses',
      );

      setState(() {
        _otherContacts = response.otherContacts ?? [];
        _otherContacts.addAll(regularContactsResponse.connections ?? []);
      });
    } catch (e) {
      print('Error fetching contacts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Contacts'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _getOtherContacts,
              child: Text('Get Other Contacts'),
            ),
            _otherContacts.isNotEmpty
                ? Expanded(
              child: ListView.builder(
                itemCount: _otherContacts.length,
                itemBuilder: (context, index) {
                  final person = _otherContacts[index];
                  final name = person.names?.first?.displayName ?? 'No name';
                  final email = person.emailAddresses?.first?.value ?? 'No email';
                  return ListTile(
                    title: Text(name),
                    subtitle: Text(email),
                  );
                },
              ),
            )
                : Text('No contacts to display'),
          ],
        ),
      ),
    );
  }
}
