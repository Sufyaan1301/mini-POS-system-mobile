import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_form_card.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<AuthBloc>().add(
          AuthRegisterSubmitted(
            name: _nameController.text,
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
        } else if (state is AuthRegisterSuccess) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text(
                  'Registrasi berhasil! Silakan login untuk mendapatkan sesi.',
                ),
                backgroundColor: AppTheme.successColor,
              ),
            );
          Navigator.of(context).pop(state.username);
        }
      },
      builder: (context, state) {
        final isSubmitting = state is AuthSubmitting;

        return AuthFormCard(
          title: 'Registrasi Kasir',
          subtitle: 'Buat akun kasir baru untuk disimpan secara lokal.',
          footer: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Sudah punya akun?'),
              TextButton(
                onPressed:
                    isSubmitting ? null : () => Navigator.of(context).pop(),
                child: const Text('Kembali ke Login'),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _nameController,
                  label: 'Nama Kasir',
                  hint: 'Contoh: Budi Santoso',
                  prefixIcon: Icons.badge_outlined,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama kasir wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _usernameController,
                  label: 'Username',
                  hint: 'Minimal 3 karakter',
                  prefixIcon: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) {
                      return 'Username wajib diisi';
                    }
                    if (trimmed.length < 3) {
                      return 'Username minimal 3 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Minimal 6 karakter',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
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
                    if (value.length < 6) {
                      return 'Password minimal 6 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _confirmPasswordController,
                  label: 'Konfirmasi Password',
                  hint: 'Ulangi password',
                  prefixIcon: Icons.lock_reset_outlined,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Konfirmasi password wajib diisi';
                    }
                    if (value != _passwordController.text) {
                      return 'Konfirmasi password tidak cocok';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: 'Daftar',
                  icon: Icons.person_add_alt_1_rounded,
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
