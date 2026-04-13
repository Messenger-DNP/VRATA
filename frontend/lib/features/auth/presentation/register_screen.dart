import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/app/router/app_router.dart';
import 'package:frontend/features/auth/presentation/controllers/register_controller.dart';
import 'package:frontend/features/auth/presentation/widgets/auth_flow_scaffold.dart';
import 'package:frontend/features/auth/presentation/widgets/auth_panel.dart';
import 'package:frontend/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(registerControllerProvider, (previous, next) {
      if (previous?.session == next.session || next.session == null) {
        return;
      }

      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Account created for ${next.session!.username}.'),
          ),
        );

      log(
        'Registration success for ${next.session!.username} (userId=${next.session!.userId})',
        name: 'vrata.auth',
      );
    });

    final state = ref.watch(registerControllerProvider);
    final controller = ref.read(registerControllerProvider.notifier);

    return AuthFlowScaffold(
      child: AuthPanel(
        eyebrow: 'New here',
        title: 'Create your account',
        subtitle: 'Set up a username and password to start using VRATA.',
        topAction: TextButton.icon(
          onPressed: () => context.go(AppRoutes.welcome),
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('Welcome'),
        ),
        footer: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Already have an account?'),
            TextButton(
              onPressed: () => context.go(AppRoutes.login),
              child: const Text('Log in'),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthTextField(
              controller: _usernameController,
              label: 'Username',
              hintText: 'Choose a username',
              textInputAction: TextInputAction.next,
              enabled: !state.isLoading,
              errorText: state.usernameError,
              onChanged: (_) => controller.onFormChanged(),
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _passwordController,
              label: 'Password',
              hintText: 'Create a password',
              obscureText: true,
              textInputAction: TextInputAction.next,
              enabled: !state.isLoading,
              errorText: state.passwordError,
              onChanged: (_) => controller.onFormChanged(),
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _confirmPasswordController,
              label: 'Repeat password',
              hintText: 'Repeat your password',
              obscureText: true,
              enabled: !state.isLoading,
              errorText: state.confirmPasswordError,
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
                  : Text(state.isSuccess ? 'Account created' : 'Register'),
            ),
          ],
        ),
      ),
    );
  }

  void _submit(RegisterController controller) {
    controller.submit(
      username: _usernameController.text,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );
  }
}
