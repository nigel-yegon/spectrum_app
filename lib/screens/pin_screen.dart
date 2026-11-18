
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import 'dashboard_screen.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final AuthService _auth = AuthService();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _loading = true;
  bool _firstSetup = false;
  bool _submitting = false;
  String? _error;

  static const _green = Color(0xFF1E3A2F);

  @override
  void initState() {
    super.initState();
    _checkSetup();
  }

  Future<void> _checkSetup() async {
    final configured = await _auth.hasPin;
    if (!mounted) return;

    setState(() {
      _firstSetup = !configured;
      _loading = false;
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;

    final pin = _pinController.text.trim();

    setState(() {
      _error = null;
    });

    if (!RegExp(r'^\d{4,6}$').hasMatch(pin)) {
      setState(() => _error = 'Enter a PIN containing 4 to 6 digits.');
      return;
    }

    if (_firstSetup && pin != _confirmController.text.trim()) {
      setState(() => _error = 'The PINs do not match.');
      return;
    }

    setState(() => _submitting = true);

    try {
      if (_firstSetup) {
        await _auth.setPin(pin);
      } else {
        final valid = await _auth.verifyPin(pin);

        if (!valid) {
          setState(() => _error = 'Incorrect PIN. Please try again.');
          return;
        }
      }

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F6),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _loading
                  ? const CircularProgressIndicator()
                  : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: _green,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.apartment_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    _firstSetup ? 'Secure your Spectrum account' : 'Welcome back',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _green,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _firstSetup
                        ? 'Create a PIN to protect your property management data.'
                        : 'Enter your PIN to continue.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _pinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      letterSpacing: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '••••',
                      labelText: _firstSetup ? 'Create PIN' : 'Enter PIN',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onSubmitted: (_) {
                      if (!_firstSetup) _submit();
                    },
                  ),
                  if (_firstSetup) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _confirmController,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        letterSpacing: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '••••',
                        labelText: 'Confirm PIN',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: _submitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: _green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _submitting
                          ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                          : Text(
                        _firstSetup ? 'Create PIN' : 'Unlock Spectrum',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
