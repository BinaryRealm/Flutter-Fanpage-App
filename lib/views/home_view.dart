import 'package:fanpage_app/driver.dart';
import 'package:fanpage_app/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage /*extends StatelessWidget {
  HomePage({Key? key}) : super(key: key);*/
    extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _textController;
  String _text = "";
  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: StreamBuilder<QuerySnapshot>(
            stream: _db
                .collection("messages")
                .orderBy("timestamp", descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: Text("Loading..."),
                );
              } else {
                return ListView(
                    //scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    children: snapshot.data!.docs.map((e) {
                      return Card(
                          child: ListTile(title: Text(e.get("content"))));
                    }).toList());
              }
            }),
        appBar: AppBar(
          title: const Text("Jack's Fanpage"),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) =>
                      _buildLogoutDialog(context),
                );
              },
              tooltip: 'Log Out',
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        floatingActionButton: FutureBuilder<DocumentSnapshot>(
            future: _db.collection("users").doc(_auth.currentUser!.uid).get(),
            builder:
                (context, AsyncSnapshot<DocumentSnapshot> documentSnapshot) {
              if (documentSnapshot.hasData) {
                if (documentSnapshot.data!.get("role") == "admin") {
                  return FloatingActionButton(
                      heroTag: "btn1",
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) =>
                              _buildPostDialog(context),
                        );
                        //_signOut(context);
                      },
                      tooltip: 'Admin Button',
                      child: const Icon(Icons.add));
                }
              } else {
                return const SomethingWentWrong();
              }
              return Container();
            }));
  }

  Widget _buildPostDialog(BuildContext context) {
    return AlertDialog(
        title: const Text("Write a Post"),
        content: Form(
          key: _formKey,
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextFormField(
                  autocorrect: false,
                  controller: _textController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter some text';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.all(Radius.circular(10.0))),
                      hintText: 'Enter Post'),
                ),
                OutlinedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _text = _textController.text;
                      _textController.clear();
                      setState(() {
                        postMessage();
                        Navigator.of(context).pop();
                      });
                    }
                  },
                  child: const Text('Post Message'),
                ),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Close'),
                )
              ]),
        ));
  }

  Widget _buildLogoutDialog(BuildContext context) {
    return AlertDialog(
        title: const Text("Do you want to log out?"),
        content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              OutlinedButton(
                onPressed: () {
                  _signOut(context);
                },
                child: const Text('Log out'),
              ),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              )
            ]));
  }

  Future<void> postMessage() async {
    try {
      _db
          .collection("messages")
          .doc()
          .set({
            "content": _text,
            "timestamp": DateTime.now(),
          })
          .then((value) => null)
          .onError((error, stackTrace) => null);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }

    setState(() {});
  }

  void _signOut(BuildContext context) async {
    ScaffoldMessenger.of(context).clearSnackBars();
    await _auth.signOut();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('User logged out.')));
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (con) => AppDriver()));
  }
}
