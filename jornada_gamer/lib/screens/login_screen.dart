// lib/screens/login_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscureText = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Ocorreu um erro ao fazer login.';
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'Email ou senha incorretos.';
      } else if (e.code == 'invalid-email') {
        message = 'O formato do email é inválido.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ocorreu um erro inesperado: $e'), backgroundColor: Colors.red),
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // --- NOVA FUNÇÃO PARA O "ESQUECI MINHA SENHA" ---
  Future<void> _showForgotPasswordDialog() async {
    final emailDialogController = TextEditingController();
    
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF181818),
          title: const Text('Redefinir Senha', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: emailDialogController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Digite o seu email de cadastro',
              hintStyle: TextStyle(color: Colors.white38),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Enviar', style: TextStyle(color: Theme.of(context).primaryColor)),
              onPressed: () async {
                if (emailDialogController.text.isEmpty) return;
                
                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(
                    email: emailDialogController.text.trim(),
                  );
                  Navigator.of(context).pop(); // Fecha o diálogo
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Email de redefinição enviado! Verifique sua caixa de entrada.'),
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                  );
                } on FirebaseAuthException catch (e) {
                   Navigator.of(context).pop(); // Fecha o diálogo
                   String message = 'Ocorreu um erro.';
                   if (e.code == 'user-not-found' || e.code == 'invalid-email') {
                     message = 'Nenhum utilizador encontrado para este email.';
                   }
                   ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(message), backgroundColor: Colors.red),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
  // --- FIM DA NOVA FUNÇÃO ---

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.gamepad_outlined, size: 80, color: primaryColor),
                const SizedBox(height: 16),
                const Text('Sua jornada de gamer, decodificada.', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Mona Sans', fontSize: 18, color: Colors.white70)),
                const SizedBox(height: 48),

                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined, color: Colors.white54),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor)),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _passwordController,
                  obscureText: _obscureText,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.white54),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.white54),
                      onPressed: () => setState(() => _obscureText = !_obscureText),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor)),
                  ),
                ),
                const SizedBox(height: 8),

                // AQUI ESTÁ A MUDANÇA: O TEXTO AGORA É CLICÁVEL
                GestureDetector(
                  onTap: _showForgotPasswordDialog,
                  child: const Align(
                    alignment: Alignment.centerRight,
                    child: Text('Esqueci minha senha', style: TextStyle(color: Colors.white54)),
                  ),
                ),
                const SizedBox(height: 32),

                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _handleSignIn,
                        child: const Text('Entrar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                      ),
                const SizedBox(height: 24),
                
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterScreen()),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Não tem uma conta? ', style: TextStyle(color: Colors.white54)),
                      Text('Crie uma agora', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}