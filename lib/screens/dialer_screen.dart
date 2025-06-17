import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:phone_number/phone_number.dart';

class DialerScreen extends StatefulWidget {
  const DialerScreen({super.key});

  @override
  State<DialerScreen> createState() => _DialerScreenState();
}

class _DialerScreenState extends State<DialerScreen> {
  String _phoneNumber = '';
  final PhoneNumberUtil _phoneUtil = PhoneNumberUtil();

  void _onDigitPress(String digit) {
    setState(() {
      _phoneNumber += digit;
    });
  }

  void _onDeletePress() {
    if (_phoneNumber.isNotEmpty) {
      setState(() {
        _phoneNumber = _phoneNumber.substring(0, _phoneNumber.length - 1);
      });
    }
  }

  Future<void> _makeCall() async {
    if (_phoneNumber.isNotEmpty) {
      await FlutterPhoneDirectCaller.callNumber(_phoneNumber);
    }
  }

  Widget _buildDialPadButton(String digit) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
          ),
          onPressed: () => _onDigitPress(digit),
          child: Text(
            digit,
            style: const TextStyle(
              fontSize: 32,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dialer'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              child: Text(
                _phoneNumber.isEmpty ? 'Enter number' : _phoneNumber,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildDialPadButton('1'),
                      _buildDialPadButton('2'),
                      _buildDialPadButton('3'),
                    ],
                  ),
                  Row(
                    children: [
                      _buildDialPadButton('4'),
                      _buildDialPadButton('5'),
                      _buildDialPadButton('6'),
                    ],
                  ),
                  Row(
                    children: [
                      _buildDialPadButton('7'),
                      _buildDialPadButton('8'),
                      _buildDialPadButton('9'),
                    ],
                  ),
                  Row(
                    children: [
                      _buildDialPadButton('*'),
                      _buildDialPadButton('0'),
                      _buildDialPadButton('#'),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.all(16),
                            ),
                            onPressed: _onDeletePress,
                            child: const Icon(
                              Icons.backspace,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.all(16),
                            ),
                            onPressed: _makeCall,
                            child: const Icon(
                              Icons.call,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 