import 'package:cloud_firestore/cloud_firestore.dart';

FirebaseFirestore db = FirebaseFirestore.instance;

Future<List> getUsers() async {
  
  List usersDB = [];

  CollectionReference collectionReferenceUsers = db.collection('users');

  QuerySnapshot queryUser = await collectionReferenceUsers.get();

  for (var document in queryUser.docs) {
    usersDB.add(document.data());
  }

  return usersDB;
}