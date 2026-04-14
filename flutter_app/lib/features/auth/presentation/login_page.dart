import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/features/auth/state/auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = AuthProvider.of(context);
      if (_isSignUp) {
        await authProvider.signUpWithEmail(
          _emailController.text,
          _passwordController.text,
          _nicknameController.text,
        );
      } else {
        await authProvider.signInWithEmail(
          _emailController.text,
          _passwordController.text,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isSignUp ? '注册' : '登录'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isSignUp)
                TextFormField(
                  controller: _nicknameController,
                  decoration: const InputDecoration(labelText: '昵称'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入昵称';
                    }
                    return null;
                  },
                ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: '邮箱'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入邮箱';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: '密码'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入密码';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              if (authProvider.errorMessage != null)
                Text(
                  authProvider.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: authProvider.isLoading ? null : _submit,
                child: authProvider.isLoading
                    ? const CircularProgressIndicator()
                    : Text(_isSignUp ? '注册' : '登录'),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isSignUp = !_isSignUp;
                  });
                },
                child: Text(_isSignUp ? '已有账号？去登录' : '没有账号？去注册'),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
