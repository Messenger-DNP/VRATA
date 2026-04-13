import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/app/router/app_router.dart';
import 'package:frontend/features/auth/presentation/controllers/login_controller.dart';
import 'package:frontend/features/auth/presentation/widgets/auth_flow_scaffold.dart';
import 'package:frontend/features/auth/presentation/widgets/auth_panel.dart';
import 'package:frontend/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(loginControllerProvider, (previous, next) {
      if (previous?.session == next.session || next.session == null) {
        return;
      }

      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Logged in as ${next.session!.username}.'),
          ),
        );

      log(
        'Login success for ${next.session!.username} (userId=${next.session!.userId})',
        name: 'vrata.auth',
      );
    });

    final state = ref.watch(loginControllerProvider);
    final controller = ref.read(loginControllerProvider.notifier);

    return AuthFlowScaffold(
      child: AuthPanel(
        eyebrow: 'Welcome back',
        title: 'Log in to your space',
        subtitle: 'Enter your username and password to continue.',
        topAction: TextButton.icon(
          onPressed: () => context.go(AppRoutes.welcome),
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('Welcome'),
        ),
        footer: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Need an account?'),
            TextButton(
              onPressed: () => context.go(AppRoutes.register),
              child: const Text('Register'),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthTextField(
              controller: _usernameController,
              label: 'Username',
              hintText: 'Enter your username',
              helperText: '3-50 chars. Letters, numbers, and underscores only.',
              textInputAction: TextInputAction.next,
              enabled: !state.isLoading,
              errorText: state.usernameError,
              onChanged: (_) => controller.onFormChanged(),
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _passwordController,
              label: 'Password',
              hintText: 'Enter your password',
              helperText:
                  '8-128 chars. Include letters and numbers. No spaces.',
              obscureText: true,
              enabled: !state.isLoading,
              errorText: state.passwordError,
              onChanged: (_) => controller.onFormChanged(),
              onSubmitted: (_) => _submit(controller),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: state.isLoading ? null : () => _submit(controller),
              child: state.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : Text(state.isSuccess ? 'Logged in' : 'Log in'),
            ),
          ],
        ),
      ),
    );
  }

  void _submit(LoginController controller) {
    controller.submit(
      username: _usernameController.text,
      password: _passwordController.text,
    );
  }
}
