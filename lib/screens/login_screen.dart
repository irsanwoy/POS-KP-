import 'package:flutter/material.dart';
import 'package:pos/db/database_helper.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  setState(() {
    _isLoading = true;
  });

  try {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [_usernameController.text.trim(), _passwordController.text],
    );

    if (result.isNotEmpty) {
      final user = result.first;
      // Login berhasil
      _showSuccessSnackBar('Login berhasil!');
      
      if (user['role'] == 'pemilik') {
        Navigator.pushReplacementNamed(context, '/owner_dashboard');
      } else if (user['role'] == 'kasir') {
        Navigator.pushReplacementNamed(context, '/cashier_dashboard');
      }
    } else {
      _showErrorSnackBar('Username atau password salah!');
    }
  } catch (e) {
    _showErrorSnackBar('Terjadi kesalahan: $e');
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  
                  const SizedBox(height: 60),
                  
                  _buildLoginForm(),
                  
                  const SizedBox(height: 24),
                  
                  _buildLoginButton(),
                  
                  const SizedBox(height: 20),
                  
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.store,
            color: Colors.white,
            size: 40,
          ),
        ),
        
        const SizedBox(height: 16),
        
        const Text(
          'SRC Rudi',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        
        const SizedBox(height: 8),
        
        const Text(
          'Sistem Kasir Toko Kelontong',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        // Username Field
        TextFormField(
          controller: _usernameController,
          decoration: InputDecoration(
            labelText: 'Username',
            hintText: 'Masukkan username',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Username tidak boleh kosong';
            }
            return null;
          },
          textInputAction: TextInputAction.next,
        ),
        
        const SizedBox(height: 16),
        
        // Password Field
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: 'Masukkan password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Password tidak boleh kosong';
            }
            return null;
          },
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _login(),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }



  Widget _buildUserInfo(String role, String username, String password) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$role: $username / $password',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            _usernameController.text = username;
            _passwordController.text = password;
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Gunakan',
              style: TextStyle(
                fontSize: 10,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}