import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AddParentsScreen extends StatefulWidget {
  const AddParentsScreen({super.key});

  @override
  State<AddParentsScreen> createState() => _AddParentsScreenState();
}

class _AddParentsScreenState extends State<AddParentsScreen> {
  static const _green = Color(0xFF0DA64A);
  static const _characters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  final _friendCodeController = TextEditingController();
  String? _myFriendCode;
  bool _isLoading = true;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _loadOrCreateFriendCode();
  }

  @override
  void dispose() {
    _friendCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadOrCreateFriendCode() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final userReference = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    try {
      final userSnapshot = await userReference.get();
      final existingCode = userSnapshot.data()?['friendCode'];
      if (existingCode is String && existingCode.isNotEmpty) {
        if (mounted) {
          setState(() {
            _myFriendCode = existingCode;
            _isLoading = false;
          });
        }
        return;
      }

      // The friendCodes document reserves the generated value globally.
      // A transaction failure means another user reserved it first, so retry.
      for (var attempt = 0; attempt < 8; attempt++) {
        final code = _generateFriendCode();
        final codeReference = FirebaseFirestore.instance
            .collection('friendCodes')
            .doc(code);
        try {
          await FirebaseFirestore.instance.runTransaction((transaction) async {
            final latestUser = await transaction.get(userReference);
            final latestCode = latestUser.data()?['friendCode'];
            if (latestCode is String && latestCode.isNotEmpty) return;

            final reservation = await transaction.get(codeReference);
            if (reservation.exists) {
              throw StateError('Friend code already reserved');
            }

            transaction.set(codeReference, {
              'userId': user.uid,
              'createdAt': FieldValue.serverTimestamp(),
            });
            transaction.set(userReference, {
              'friendCode': code,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          });

          final refreshedUser = await userReference.get();
          final savedCode = refreshedUser.data()?['friendCode'];
          if (savedCode is String && savedCode.isNotEmpty) {
            if (mounted) {
              setState(() {
                _myFriendCode = savedCode;
                _isLoading = false;
              });
            }
            return;
          }
        } catch (_) {
          if (attempt == 7) rethrow;
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not create your friend code.')),
      );
    }
  }

  String _generateFriendCode() {
    final random = Random.secure();
    return List.generate(
      8,
      (_) => _characters[random.nextInt(_characters.length)],
    ).join();
  }

  Future<void> _addParent() async {
    final user = FirebaseAuth.instance.currentUser;
    final code = _friendCodeController.text.trim().toUpperCase();
    if (user == null || code.isEmpty || _isAdding) return;
    if (code == _myFriendCode) {
      _showMessage('Enter another parent’s friend code.');
      return;
    }

    setState(() => _isAdding = true);
    try {
      final codeSnapshot = await FirebaseFirestore.instance
          .collection('friendCodes')
          .doc(code)
          .get();
      final parentId = codeSnapshot.data()?['userId'];
      if (!codeSnapshot.exists || parentId is! String) {
        _showMessage('Friend code not found.');
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('parents')
          .doc(parentId)
          .set({
            'userId': parentId,
            'friendCode': code,
            'addedAt': FieldValue.serverTimestamp(),
          });
      _friendCodeController.clear();
      _showMessage('Parent added successfully.');
    } catch (_) {
      _showMessage('Could not add this parent. Try again.');
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.white,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              const Divider(height: 1, color: Color(0xFFE7E7E7)),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 48, 28, 32),
                  child: Column(
                    children: [
                      Text(
                        'Add parents you’ve met',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lato(
                          color: const Color(0xFF171717),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'For your privacy and safety, only add parents you’ve '
                        'met at a Classmates experience or event. This helps '
                        'keep your community connected to people you know.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lato(
                          color: const Color(0xFF444444),
                          fontSize: 16,
                          height: 1.42,
                        ),
                      ),
                      const SizedBox(height: 42),
                      TextField(
                        controller: _friendCodeController,
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 8,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: 'Enter friend code',
                          counterText: '',
                          filled: true,
                          fillColor: const Color(0xFFF5F5F7),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: _isAdding ? null : _addParent,
                          style: FilledButton.styleFrom(
                            backgroundColor: _green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isAdding
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Add a parent',
                                  style: GoogleFonts.lato(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 46),
                      Text(
                        'Your friend code',
                        style: GoogleFonts.lato(
                          color: _green,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_isLoading)
                        const CircularProgressIndicator(
                          color: _green,
                          strokeWidth: 2,
                        )
                      else if (_myFriendCode case final code?)
                        InkWell(
                          onTap: () async {
                            await Clipboard.setData(ClipboardData(text: code));
                            _showMessage('Friend code copied.');
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FAF4),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _green),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  code,
                                  style: GoogleFonts.lato(
                                    color: _green,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 3,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Icon(Icons.copy_outlined, color: _green),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        'Share this code with another parent so they can add you.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lato(
                          color: const Color(0xFF737373),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: () => Navigator.maybePop(context),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 18),
                child: Icon(Icons.chevron_left, size: 24),
              ),
            ),
          ),
          Text(
            'Add parents',
            style: GoogleFonts.lato(
              color: const Color(0xFF222222),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
