import 'dart:typed_data';

import 'package:control_app/models/readings.dart';
import 'package:control_app/services/service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:control_app/widgets/strip_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class Home extends StatefulWidget {
  const Home({Key? key, this.server}) : super(key: key);
  final BluetoothDevice? server;
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Readings readings = Readings(
    status: 4,
    dialysateLvl: 84,
    dialysateTemp: 37,
    bloodFlow: 256,
    dialysateFlow: 782,
    drainLvl: 100,
  );
  BluetoothConnection? connection;
  String prevString = '';

  String _messageBuffer = '';

  bool isConnecting = true;
  bool get isConnected => connection != null && connection!.isConnected;

  bool isDisconnecting = false;
  String level = '0.0';

  List<String> dataList = [];
  List<String> getData = [];

  String msg(int status) {
    switch (status) {
      case 0:
        return 'Connecting ..';
      case 1:
        return 'Adjusting conditions';
      case 2:
        return 'Machine is working';
      case 3:
        return 'Dialysate Container is empty, please fill it';
      case 4:
        return 'Drain Container is full, please empty it';

      default:
        return 'Waiting ...';
    }
  }

  String statusMsg(int status) {
    switch (status) {
      case 0:
        return 'Offline';
      case 1:
        return 'Online';
      case 2:
        return 'Online';
      case 3:
        return 'Warning !';
      case 4:
        return 'Warning !';

      default:
        return 'Waiting ...';
    }
  }

  Color statusColor(int status) {
    switch (status) {
      case 0:
        return Colors.grey;
      case 1:
        return Colors.blue;
      case 2:
        return Colors.green;
      case 3:
        return Colors.amber;
      case 4:
        return Colors.amber;

      default:
        return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();

    BluetoothConnection.toAddress(widget.server!.address).then((_connection) {
      debugPrint('Connected to the device');
      connection = _connection;
      setState(() {
        isConnecting = false;
        isDisconnecting = false;
      });

      connection!.input!.listen(_onDataReceived).onData((data) {
        // Allocate buffer for parsed data
        int backspacesCounter = 0;
        for (var byte in data) {
          if (byte == 8 || byte == 127) {
            backspacesCounter++;
          }
        }
        Uint8List buffer = Uint8List(data.length - backspacesCounter);
        int bufferIndex = buffer.length;

        // Apply backspace control character
        backspacesCounter = 0;
        for (int i = data.length - 1; i >= 0; i--) {
          if (data[i] == 8 || data[i] == 127) {
            backspacesCounter++;
          } else {
            if (backspacesCounter > 0) {
              backspacesCounter--;
            } else {
              buffer[--bufferIndex] = data[i];
            }
          }
        }
        // Create message if there is new line character
        String dataString = String.fromCharCodes(buffer);
        dataList.add(dataString);

        debugPrint('data ${dataList.join()}');
        try {
          String x = dataList.join().split("@")[dataList.join().split("@").length - 2];
          List<String> data = x.split('*');
          if (data.length == 6) {
            setState(() {
              readings = Readings(
                  dialysateLvl: ((int.parse(data[0]) ~/ 10) - 100).abs(),
                  dialysateTemp: int.parse(data[1]) ~/ 10,
                  bloodFlow: int.parse(data[2]),
                  dialysateFlow: int.parse(data[3]),
                  drainLvl: int.parse(data[4]) ~/ 10,
                  status: int.parse(data[5]));
              debugPrint(readings.toString());
            });
          } else {
            debugPrint("Waiting ${data.length} ....");
            debugPrint(x.toString());
          }
        } catch (e) {
          debugPrint("Error $e");
        }

        if (isDisconnecting) {
          debugPrint('Disconnecting locally!');
        } else {
          debugPrint('Disconnected remotely!');
        }
        if (mounted) {
          setState(() {});
        }
      });
      setState(() {});
    }).catchError((error) {
      debugPrint('Cannot connect, exception occured');
      debugPrint(error);
    });
  }

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection!.dispose();
      connection = null;
    }

    super.dispose();
  }

  void _onDataReceived(Uint8List data) {
    // Allocate buffer for parsed data
    int backspacesCounter = 0;
    for (var byte in data) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    }
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    // Apply backspace control character
    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }

    // Create message if there is new line character
    String dataString = String.fromCharCodes(buffer);
    int index = buffer.indexOf(13);
    if (~index != 0) {
      setState(() {
        _messageBuffer = dataString.substring(index);
      });
    } else {
      _messageBuffer = (backspacesCounter > 0
          ? _messageBuffer.substring(0, _messageBuffer.length - backspacesCounter)
          : _messageBuffer + dataString);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      debugPrint("Hello Web");
    }
    double widths = 0;
    double heights = 0;
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      widths = MediaQuery.of(context).size.width;
      heights = MediaQuery.of(context).size.height;
    } else if (kIsWeb || MediaQuery.of(context).orientation == Orientation.landscape) {
      widths = MediaQuery.of(context).size.height;
      heights = MediaQuery.of(context).size.width;
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart Hemodialysis"),
        backgroundColor: Colors.grey[900],
        leading: Padding(
          padding: const EdgeInsets.only(
            left: 15,
          ),
          child: Image.asset('assets/akwa.png'),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
                onPressed: () {
                  try {
                    connection!.close();
                  } catch (e) {}
                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const Services()));
                },
                icon: Icon(
                  Icons.restart_alt_rounded,
                  color: Colors.red,
                )),
          )
        ],
      ),
      body: Container(
        color: Colors.grey[200],
        child: Column(
          children: [
            Container(
              child: Center(
                  child: Text(
                      statusMsg(
                        readings.status,
                      ),
                      style: const TextStyle(color: Colors.white))),
              color: statusColor(readings.status),
              width: double.infinity,
              height: 25,
            ),
            Expanded(
                child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Strip(
                        isWarning: readings.status == 3 || readings.status == 1 || readings.status == 0,
                        icon: null,
                        txt: readings.dialysateLvl.toString() + ' %',
                        type: 'Dialysate Level'),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Strip(
                        isWarning: readings.status == 1 || readings.status == 0,
                        icon: Icon(
                          Icons.thermostat,
                          size: 30,
                          color: Colors.grey[800],
                        ),
                        txt: readings.dialysateTemp.toString() + ' ℃',
                        type: 'Temperature'),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Strip(
                        isWarning: readings.status == 1 || readings.status == 0,
                        icon: null,
                        txt: readings.bloodFlow.toString(),
                        type: 'Blood Flow (ml/min)'),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Strip(
                        isWarning: readings.status == 1 || readings.status == 0,
                        icon: null,
                        txt: readings.dialysateFlow.toString(),
                        type: 'Dialysate Flow (ml/min)'),
                  ),
                  // Padding(
                  //   padding: const EdgeInsets.all(8.0),
                  //   child: Strip(
                  //       isWarning: readings.status == 5,
                  //       icon: null,
                  //       txt: readings.status == 5 ? 'PH isn\'t in range' : 'PH is in range',
                  //       type: 'PH'),
                  // ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Strip(
                        isWarning: readings.status == 4 || readings.status == 1 || readings.status == 0,
                        icon: null,
                        txt: (readings.drainLvl == 0 ? '<50' : readings.drainLvl.toString()) + ' %',
                        type: 'Drain Level'),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: statusColor(readings.status), width: 2)),
                        width: widths * 0.85,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Center(
                              child: Text(
                            msg(readings.status),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 25, color: Colors.grey[800]),
                          )),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
