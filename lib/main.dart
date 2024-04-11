import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        buttonTheme: const ButtonThemeData(
          buttonColor: Colors.blueAccent,
          textTheme: ButtonTextTheme.primary,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25.0),
            borderSide: const BorderSide(color: Colors.blueGrey),
          ),
          filled: true,
          fillColor: Colors.grey[200],
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('TERRATHON 3.0'),
          centerTitle: true,
          elevation: 4,
        ),
        body: const FirestoreInputWidget(),
      ),
    );
  }
}

class FirestoreInputWidget extends StatefulWidget {
  const FirestoreInputWidget({super.key});

  @override
  _FirestoreInputWidgetState createState() => _FirestoreInputWidgetState();
}

class _FirestoreInputWidgetState extends State<FirestoreInputWidget> {
  final TextEditingController _controller = TextEditingController();
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;

  void _fetchAndPrintStudentData(String docId) async {
    await controller?.pauseCamera();
    try {
      DocumentSnapshot studentDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(docId)
          .get();
      if (studentDoc.exists) {
        Map<String, dynamic>? data = studentDoc.data() as Map<String, dynamic>?;
        if (data != null) {
          Navigator.of(context)
              .push(MaterialPageRoute(
                  builder: (context) =>
                      StudentDataScreen(studentData: data, docId: docId)))
              .then((_) => controller?.resumeCamera());
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No student found with ID $docId')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching student data: $e')));
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
      });
      if (result != null) {
        _fetchAndPrintStudentData(result!.code!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      reverse: true,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Scan QR Code or Enter ID',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.3,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: Colors.blue,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: MediaQuery.of(context).size.width * 0.6,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    labelText: 'Enter Student ID',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blueAccent,
                  ),
                  onPressed: () => _fetchAndPrintStudentData(
                      _controller.text.trim().toUpperCase()),
                  child: const Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Text('Fetch Student Data',
                        style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 20), // Add some spacing
                // Acknowledgement Text
                const Text(
                    'Developed with ❤️ by Avishek Agarwal (The Alcoding Club)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    _controller.dispose();
    super.dispose();
  }
}

class StudentDataScreen extends StatefulWidget {
  final Map<String, dynamic> studentData;
  final String docId;

  const StudentDataScreen(
      {super.key, required this.studentData, required this.docId});

  @override
  _StudentDataScreenState createState() => _StudentDataScreenState();
}

class _StudentDataScreenState extends State<StudentDataScreen> {
  late Map<String, dynamic> studentData;

  @override
  void initState() {
    super.initState();
    studentData = widget.studentData;
  }

  void _toggleBooleanValue(String key, bool value) async {
    // If the current value is true, do not allow changing it back to false.
    if (studentData[key] == true) {
      return; // Exit the method if the current value is true.
    }

    setState(() {
      studentData[key] = value;
    });

    DocumentReference studentRef =
        FirebaseFirestore.instance.collection('students').doc(widget.docId);

    try {
      await studentRef.update({key: value});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> orderedKeys = [
      'checkIn',
      'snacks',
      'dinner',
      'snacks2',
      'breakfast',
      'lunch',
      'snacks3',
    ];

    List<Widget> detailWidgets = [
      Card(
        elevation: 4,
        child: ListTile(
          title: const Text('Name'),
          subtitle: Text(studentData['name'] ?? 'N/A'),
        ),
      ),
      Card(
        elevation: 4,
        child: ListTile(
          title: const Text('SRN'),
          subtitle: Text(studentData['srn'] ?? 'N/A'),
        ),
      ),
      Card(
        elevation: 4,
        child: ListTile(
          title: const Text('Team Name'),
          subtitle: Text(studentData['teamName'] ?? 'N/A'),
        ),
      ),
    ];

    List<Widget> boolWidgets = orderedKeys
        .where(
            (key) => studentData.containsKey(key) && studentData[key] is bool)
        .map((key) => SwitchListTile(
              title: Text(key,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              value: studentData[key] as bool,
              onChanged: (bool newValue) {
                _toggleBooleanValue(key, newValue);
              },
            ))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Data'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('DETAILS',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ...detailWidgets,
            const SizedBox(height: 20),
            ...boolWidgets,
          ],
        ),
      ),
    );
  }
}
