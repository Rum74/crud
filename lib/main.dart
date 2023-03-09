// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      // Remove the debug banner
      debugShowCheckedModeBanner: false,
      title: 'Hướng dẫn CRUD Firebase',
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // text fields' controllers
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _maMHController = TextEditingController();
  final TextEditingController _tenMHController = TextEditingController();
  final TextEditingController _motaController = TextEditingController();

  final CollectionReference _monhoc =
  FirebaseFirestore.instance.collection('monhoc');

  // This function is triggered when the floatting button or one of the edit buttons is pressed
  // Adding a product if no documentSnapshot is passed
  // If documentSnapshot != null then update an existing product
  Future<void> _createOrUpdate([DocumentSnapshot? documentSnapshot]) async {
    String action = 'create';
    if (documentSnapshot != null) {
      action = 'update';
      _idController.text = documentSnapshot['id'].toString();
      _maMHController.text = documentSnapshot['maMH'];
      _tenMHController.text = documentSnapshot['tenMH'];
      _motaController.text = documentSnapshot['mota'];
    }

    await showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (BuildContext ctx) {
          return Padding(
            padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                // prevent the soft keyboard from covering text fields
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _idController,
                  decoration: const InputDecoration(labelText: 'Id'),
                ),
                TextField(
                  // keyboardType:
                  // const TextInputType.numberWithOptions(decimal: true),
                  controller: _maMHController,
                  decoration: const InputDecoration(
                    labelText: 'Mã môn học',
                  ),
                ),
                TextField(
                  controller: _tenMHController,
                  decoration: const InputDecoration(labelText: 'Tên môn học'),
                ),
                TextField(
                  controller: _motaController
                  ,
                  decoration: const InputDecoration(labelText: 'Mô tả'),
                ),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  child: Text(action == 'create' ? 'Create' : 'Update'),
                  onPressed: () async {
                    final String? id = _idController.text;
                    final String? maMH = _maMHController.text;
                    final String? tenMH = _tenMHController.text;
                    final String? mota = _motaController.text;
                    if (id != null && maMH != null) {
                      if (action == 'create') {
                        // Persist a new Mon Hoc to Firestore
                        await _monhoc.add({"id": id, "maMH": maMH, "tenMH": tenMH, "mota": mota,});
                      }

                      if (action == 'update') {
                        // Update the product
                        await _monhoc
                            .doc(documentSnapshot!.id)
                            .update({"id": id, "maMH": maMH, "tenMH": tenMH, "mota": mota,});
                      }

                      // Clear the text fields
                      _idController.text = '';
                      _maMHController.text = '';
                      _tenMHController.text = '';
                      _motaController.text = '';

                      // Hide the bottom sheet
                      Navigator.of(context).pop();
                    }
                  },
                )
              ],
            ),
          );
        });
  }

  // Deleteing a product by id
  Future<void> _deleteMonhoc(String monhocId) async {
    await _monhoc.doc(monhocId).delete();

    // Show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('You have successfully deleted a product')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('crud.com'),
      ),
      // Using StreamBuilder to display all products from Firestore in real-time
      body: StreamBuilder(
        stream: _monhoc.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
          if (streamSnapshot.hasData) {
            return ListView.builder(
              itemCount: streamSnapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final DocumentSnapshot documentSnapshot =
                streamSnapshot.data!.docs[index];

                return Card(
                  color: Colors.green,
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    title: Text(documentSnapshot['id']),
                    textColor: Colors.white,
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 5,),
                        Text(documentSnapshot['maMH']),
                        const SizedBox(height: 5,),
                        Text(documentSnapshot['tenMH']),
                        const SizedBox(height: 5,),
                        Text(documentSnapshot['mota']),
                      ],
                    ),

                    trailing: SizedBox(
                      width: 100,
                      child: Row(
                        children: [
                          // Press this button to edit a single product
                          IconButton(
                              icon: const Icon(Icons.edit, color: Colors.yellow,),
                              onPressed: () =>
                                  _createOrUpdate(documentSnapshot)),
                          // This icon button is used to delete a single product
                          IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red,),
                              onPressed: () =>
                                  _deleteMonhoc(documentSnapshot.id)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }

          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
      // Add new product
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createOrUpdate(),
        child: const Icon(Icons.add),
      ),
    );
  }
}