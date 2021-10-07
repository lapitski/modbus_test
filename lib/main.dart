import 'package:flutter/material.dart';
import 'package:modbus/modbus.dart' as modbus;
import 'dart:typed_data';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Modbus'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _address = '192.168.8.1';
  int _port = 502;
  TextEditingController _addressCtrl =
      TextEditingController(text: '192.168.8.1');
  TextEditingController _portCtrl = TextEditingController(text: '502');
  Uint8List? _slaveIdResponse;
  TextEditingController _registerCtrl = TextEditingController(text: '20');
  int _register = 20;
  modbus.ModbusClient? _client;
  var _readResp;
  bool _isConnected = false;
  bool _isConnecting = false;

  connect() async {
    _toggleIsConnecting();
    _client = modbus.createTcpClient(
      _address,
      port: _port,
      mode: modbus.ModbusMode.rtu,
    );

    try {
      bool error = false;
      await _client!.connect().timeout(Duration(seconds: 10), onTimeout: () {
        error = true;
        _client!.close();
        _toggleIsConnecting();
        _showInfo('Error on connection');
      });
      if (!error) {
        _isConnected = true;
        _toggleIsConnecting();
      }
    } catch (e) {
      _toggleIsConnecting();
      _showInfo(e.toString());
      print(e);
    }
  }

  disconnect() {
    _client!.close();
    setState(() {
      _client = null;
      _isConnected = false;
      _readResp = null;
    });
  }

  _toggleIsConnecting() {
    setState(() {
      _isConnecting = !_isConnecting;
    });
  }

  read() async {
    var resp = await _client!.readHoldingRegisters(_register, 1);
    setState(() {
      _readResp = resp;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _isConnecting
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    TextField(
                      keyboardType: TextInputType.number,
                      controller: _addressCtrl,
                      onChanged: (val) {
                        _address = val;
                      },
                    ),
                    TextField(
                      keyboardType: TextInputType.number,
                      controller: _portCtrl,
                      onChanged: (val) {
                        _port = int.parse(val);
                      },
                    ),
                    ElevatedButton(
                      onPressed: connect,
                      child: const Text('Connect'),
                    ),
                    if (_isConnected)
                      ElevatedButton(
                        onPressed: disconnect,
                        child: const Text('Disconnect'),
                      ),
                    if (_isConnected) const Text('Connected'),
                    const SizedBox(
                      height: 10.0,
                    ),
                    const Divider(),
                    const SizedBox(
                      height: 10.0,
                    ),
                    const Text('Read holding registers'),
                    TextField(
                      keyboardType: TextInputType.number,
                      controller: _registerCtrl,
                      onChanged: (val) {
                        _register = int.parse(val);
                      },
                    ),
                    ElevatedButton(
                      onPressed: _isConnected ? read : null,
                      child: const Text('Read'),
                    ),
                    if (_readResp != null) Text('Responce: $_readResp'),
                  ],
                ),
              ),
            ),
    );
  }

  _showInfo(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
