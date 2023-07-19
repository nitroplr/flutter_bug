import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  try {
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: false);
  } catch (e) {
    log(e.toString());
  }
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  int _counter = 0;
  final _db = FirebaseFirestore.instance;

  void _incrementCounter() {
    _db.collection('counter').doc('counter').set({'counter': ++_counter});
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final counterAsyncValue = ref.watch(countProvider('counter'));
    return counterAsyncValue.when(
        error: (_, __) {
          print(_.toString());
          print(__.toString());
          return const Center(child: Text('Error loading counter.'));
        },
        loading: () => const SizedBox(),
        data: (counter) {
          _counter = counter;
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              title: Text(widget.title),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    'You have pushed the button this many times:',
                  ),
                  Text(
                    '$_counter',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: _incrementCounter,
              tooltip: 'Increment',
              child: const Icon(Icons.add),
            ),
          );
        });
  }
}

int streamCounter = 0;

class DB {
  final _db = FirebaseFirestore.instance;

  Stream<int> streamCount({required String docName}) {
    return _db.collection(docName).doc(docName).snapshots().map((event) {
      print(++streamCounter);
      return event.data()!['counter'];
    });
  }
}

final _dBProvider = Provider<DB>((ref) => DB());
final countProvider = StreamProvider.autoDispose.family<int, String>((ref, docName) {
  final db = ref.watch(_dBProvider);
  return db.streamCount(docName: docName);
});
