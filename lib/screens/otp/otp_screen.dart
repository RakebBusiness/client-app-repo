import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../widgets/App.header.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  int remaining = 30;
  Timer? timer;
  String otpCode = '';

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    remaining = 30;
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remaining > 0) {
        setState(() => remaining--);
      } else {
        t.cancel();
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void onSubmit(String code) {
    //print("Code OTP entré : $code");
    // TODO : Ajouter vérification réelle
  }

  void _resendCode() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Code renvoyé')));
    _startTimer(); // redémarre le timer
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const AppHeader(title: 'Rakib'),
          const SizedBox(height: 30),
          const Text(
            'Entrer votre code de confirmation',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),

          // 🔐 Champ OTP sécurisé
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50),
            child: PinCodeTextField(
              appContext: context,
              length: 4,
              obscureText: true,
              obscuringCharacter: '●',
              animationType: AnimationType.fade,
              keyboardType: TextInputType.number,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(10),
                fieldHeight: 60,
                fieldWidth: 50,
                activeFillColor: Colors.white,
                selectedColor: Colors.green,
                activeColor: Colors.green,
                inactiveColor: Colors.grey,
              ),
              animationDuration: const Duration(milliseconds: 300),
              enableActiveFill: false,
              onChanged: (value) {
                setState(() => otpCode = value);
              },
              onCompleted: onSubmit,
            ),
          ),

          const SizedBox(height: 10),
          if (remaining > 0)
            Text(
              'Renvoyer dans $remaining sec',
              style: const TextStyle(fontSize: 12),
            ),
          if (remaining == 0)
            TextButton(
              onPressed: _resendCode,
              child: const Text(
                'Renvoyer le code',
                style: TextStyle(color: Colors.green),
              ),
            ),

          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (otpCode.length == 4) {
                onSubmit(otpCode);
              } else {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Code incomplet')));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF32C156),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            child: const Text(
              'Vérifier',
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
