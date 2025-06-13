import 'package:flutter/material.dart';
import '../../widgets/App.header.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _acceptedTerms = false;
  String? _error;

  void _validateAndProceed() {
    String phone = _phoneController.text.trim();

    // Vérification : 10 chiffres et commence par 06, 05 ou 07
    final validPrefixes = ['06', '05', '07'];
    final isValid =
        RegExp(r'^\d{10}$').hasMatch(phone) &&
        validPrefixes.contains(phone.substring(0, 2));

    if (!_acceptedTerms) {
      setState(() => _error = 'Vous devez accepter les conditions.');
      return;
    }

    if (!isValid) {
      setState(() => _error = 'Numéro invalide. Format requis: 06XXXXXXXX');
    } else {
      setState(() => _error = null);
      _showChannelChoiceMenu(context);
    }
  }

  void _showChannelChoiceMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(color: Colors.black45, blurRadius: 12, spreadRadius: 2),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Comment voulez-vous recevoir le code ?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.chat, color: Colors.green),
                title: const Text('WhatsApp'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/otp');
                },
              ),
              ListTile(
                leading: const Icon(Icons.sms, color: Colors.green),
                title: const Text('SMS'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/otp');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const AppHeader(title: 'Rakib'),
          const SizedBox(height: 30),
          const Text('Hello nice to meet you !'),
          const SizedBox(height: 10),
          const Text(
            'Get moving with Rakeb',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: _error != null ? Colors.red : Colors.grey,
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Num téléphone: 06XXXXXXXX',
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _validateAndProceed,
                    child: Container(
                      height: 50,
                      width: 50,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF32C156),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Row(
              children: [
                Checkbox(
                  value: _acceptedTerms,
                  onChanged: (val) => setState(() => _acceptedTerms = val!),
                  activeColor: Colors.black,
                  checkColor: Colors.white,
                  shape: const CircleBorder(),
                ),
                const Expanded(
                  child: Text("Accepter les termes et conditions"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
