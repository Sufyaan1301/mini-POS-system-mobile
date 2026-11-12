import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../pos/presentation/pages/home_shell_page.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_form_card.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<AuthBloc>().add(
          AuthLoginSubmitted(
            username: _usernameController.text,
            password: _passwordController.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthFailure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
        } else if (state is AuthAuthenticated) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => HomeShellPage(cashier: state.cashier),
            ),
            (_) => false,
          );
        }
      },
      builder: (context, state) {
        final isSubmitting = state is AuthSubmitting;

        return AuthFormCard(
          title: 'Login Kasir',
          subtitle: 'Masuk secara offline menggunakan akun kasir lokal.',
          footer: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Belum punya akun kasir?'),
              TextButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final registeredUsername =
                            await Navigator.of(context).push<String>(
                          MaterialPageRoute(
                            builder: (_) => const RegisterPage(),
                          ),
                        );
                        if (registeredUsername != null && mounted) {
                          _usernameController.text = registeredUsername;
                          _passwordController.clear();
                        }
                      },
                child: const Text('Daftar Sekarang'),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _usernameController,
                  label: 'Username',
                  hint: 'Masukkan username kasir',
                  prefixIcon: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Username wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Masukkan password',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: 'Masuk',
                  icon: Icons.login_rounded,
                  isLoading: isSubmitting,
                  onPressed: _onSubmit,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
