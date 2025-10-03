import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _usernameController = TextEditingController();
  final _currentUser = FirebaseAuth.instance.currentUser;
  bool _isLoading = true;
  String? _newAvatarBase64;
  String? _currentAvatarBase64;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (_currentUser != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).get();
      if (mounted) {
        setState(() {
          _usernameController.text = userDoc.data()?['username'] ?? _currentUser!.displayName ?? '';
          _currentAvatarBase64 = userDoc.data()?['avatarBase64'];
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      final imageBytes = await pickedFile.readAsBytes();
      final base64String = base64Encode(imageBytes);
      setState(() {
        _newAvatarBase64 = base64String;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_currentUser == null) return;
    setState(() => _isLoading = true);

    try {
      final newUsername = _usernameController.text.trim();
      Map<String, dynamic> dataToUpdate = {'username': newUsername};

      if (_newAvatarBase64 != null) {
        dataToUpdate['avatarBase64'] = _newAvatarBase64;
      }
      
      await _currentUser!.updateDisplayName(newUsername);
      await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).set(
        dataToUpdate,
        SetOptions(merge: true),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado com sucesso!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar o perfil: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Uint8List? imageBytes;
    if (_newAvatarBase64 != null) {
      imageBytes = base64Decode(_newAvatarBase64!);
    } else if (_currentAvatarBase64 != null) {
      imageBytes = base64Decode(_currentAvatarBase64!);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                                ? Icon(Icons.person_outline, size: 50, color: Theme.of(context).primaryColor)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Theme.of(context).primaryColor,
                              child: const Icon(Icons.camera_alt_outlined, color: Colors.black, size: 20),
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
                      labelText: 'Nome de Utilizador',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _saveProfile,
                    // AQUI ESTÁ A CORREÇÃO: O 'child' que estava em falta
                    child: const Text('Salvar Alterações', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            ),
    );
  }
}