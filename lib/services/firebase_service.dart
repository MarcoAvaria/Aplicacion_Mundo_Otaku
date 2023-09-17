import 'package:cloud_firestore/cloud_firestore.dart';

FirebaseFirestore db = FirebaseFirestore.instance;

Future<List> getUsers() async {
  
  List usersDB = [];

  CollectionReference collectionReferenceUsers = db.collection('users');

  QuerySnapshot queryUser = await collectionReferenceUsers.get();

  queryUser.docs.forEach( (document)  {
    usersDB.add(document.data());
  });

  return usersDB;
}