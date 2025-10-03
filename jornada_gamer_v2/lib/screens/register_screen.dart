// lib/screens/register_screen.dart

import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _avatarBase64;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Lida com a seleção da imagem da galeria
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 400, // Redimensiona a imagem para ser leve
      maxHeight: 400,
      imageQuality: 85, // Comprime a imagem para otimizar o tamanho
    );

    if (pickedFile != null) {
      final imageBytes = await pickedFile.readAsBytes();
      final base64String = base64Encode(imageBytes);
      if (mounted) {
        setState(() {
          _avatarBase64 = base64String;
        });
      }
    }
  }

  /// Lida com o processo completo de cadastro
  Future<void> _handleSignUp() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    // Validações
    if (_usernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O nome de utilizador é obrigatório!'), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('As senhas não coincidem!'), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      // 1. Cria o utilizador no Firebase Authentication
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception("Não foi possível criar o utilizador.");
      }

      final newUsername = _usernameController.text.trim();

      // 2. Atualiza o perfil do Firebase Auth com o nome de exibição
      await user.updateDisplayName(newUsername);

      // 3. Cria o documento do utilizador no Firestore com os dados do perfil
      Map<String, dynamic> userData = {
        'username': newUsername,
        'email': user.email,
      };
      if (_avatarBase64 != null) {
        userData['avatarBase64'] = _avatarBase64;
      }
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(userData);

      // 4. Fecha as telas de autenticação (o AuthGate fará o resto)
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      
    } on FirebaseAuthException catch (e) {
      String message = 'Ocorreu um erro.';
      if (e.code == 'weak-password') {
        message = 'A senha fornecida é muito fraca (mínimo 6 caracteres).';
      } else if (e.code == 'email-already-in-use') {
        message = 'Este email já está em uso por outra conta.';
      } else if (e.code == 'invalid-email') {
        message = 'O email fornecido não é válido.';
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

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    Uint8List? imageBytes;
    if (_avatarBase64 != null) {
      imageBytes = base64Decode(_avatarBase64!);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Crie Sua Conta', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Mona Sans', fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 32),
                
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white12,
                          backgroundImage: imageBytes != null ? MemoryImage(imageBytes) : null,
                          child: imageBytes == null 
                              ? Icon(Icons.person_add_alt_1_outlined, size: 50, color: primaryColor)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: primaryColor,
                            child: const Icon(Icons.add_a_photo_outlined, color: Colors.black, size: 20),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                TextField(
                  controller: _usernameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Nome de Utilizador (obrigatório)',
                    prefixIcon: const Icon(Icons.person_outline, color: Colors.white54),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor)),
                  ),
                ),
                const SizedBox(height: 16),

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
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.white54),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.white54),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor)),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Confirmar Senha',
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.white54),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.white54),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor)),
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
                        onPressed: _handleSignUp,
                        child: const Text('Cadastrar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                      ),
                const SizedBox(height: 24),

                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Já tem uma conta? ', style: TextStyle(color: Colors.white54)),
                      Text('Faça login', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
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