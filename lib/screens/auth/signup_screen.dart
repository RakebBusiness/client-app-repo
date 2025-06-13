import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/App.header.dart';
import '../../services/auth_service.dart';
import '../../models/auth_state.dart';
import '../otp/otp_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _acceptedTerms = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthService>().addListener(_authStateListener);
    });
  }

  @override
  void dispose() {
    context.read<AuthService>().removeListener(_authStateListener);
    _phoneController.dispose();
    super.dispose();
  }

  void _authStateListener() {
    final authState = context.read<AuthService>().state;
    
    if (authState.status == AuthStatus.codeSent) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const OtpScreen()),
      );
    } else if (authState.status == AuthStatus.error) {
      setState(() {
        _error = authState.error;
      });
    }
  }

  void _validateAndProceed() {
    String phone = _phoneController.text.trim();

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
      _requestOTP();
    }
  }

  void _requestOTP() {
    final phoneNumber = '+212${_phoneController.text.trim()}';
    context.read<AuthService>().requestOTP(phoneNumber);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<AuthService>(
        builder: (context, authService, child) {
          final isLoading = authService.state.status == AuthStatus.loading;
          
          return Column(
            children: [
              const AppHeader(title: 'Rakib'),
              const SizedBox(height: 30),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Créer un compte',
                    style: TextStyle(
                      fontSize: 24,
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
                    'Entrez votre numéro de téléphone pour commencer',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
              ),
              const SizedBox(height: 30),
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
                    border: Border.all(
                      color: _error != null ? Colors.red : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            enabled: !isLoading,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Numéro de téléphone',
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: isLoading ? null : _validateAndProceed,
                        child: Container(
                          height: 50,
                          width: 50,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: isLoading 
                                ? Colors.grey 
                                : const Color(0xFF32C156),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
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
                      onChanged: isLoading 
                          ? null 
                          : (val) => setState(() => _acceptedTerms = val!),
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
              const SizedBox(height: 20),
              TextButton(
                onPressed: isLoading 
                    ? null 
                    : () => Navigator.pop(context),
                child: const Text(
                  'Déjà un compte ? Se connecter',
                  style: TextStyle(color: Color(0xFF32C156)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}