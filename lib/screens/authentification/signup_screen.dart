import 'package:flutter/material.dart';
import '../../widgets/App.header.dart';

class UsernameScreen extends StatefulWidget {
  const UsernameScreen({super.key});

  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UsernameScreen> {
  final TextEditingController _nameController = TextEditingController();
  String? _error;

  void _submitName() {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _error = 'Veuillez entrer un nom.');
      return;
    }

    setState(() => _error = null);
    Navigator.pushNamed(context, '/home'); // changer vers ta prochaine page
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const AppHeader(title: 'Rakib'),

          const SizedBox(height: 30),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Veuillez saisir votre nom :',
                style: TextStyle(
                  fontSize: 20,
                  color: Color(0xFF32C156),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Votre nom apparaît lorsque vous effectuez une course',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Champ de nom avec shadow
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Nom complet',
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _submitName,
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
        ],
      ),
    );
  }
}
