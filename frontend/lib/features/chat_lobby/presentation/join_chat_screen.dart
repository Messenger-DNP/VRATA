import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/app/router/app_router.dart';
import 'package:frontend/features/chat_lobby/presentation/controllers/join_chat_controller.dart';
import 'package:frontend/features/chat_lobby/presentation/widgets/chat_lobby_text_field.dart';
import 'package:go_router/go_router.dart';

class JoinChatScreen extends ConsumerStatefulWidget {
  const JoinChatScreen({super.key});

  @override
  ConsumerState<JoinChatScreen> createState() => _JoinChatScreenState();
}

class _JoinChatScreenState extends ConsumerState<JoinChatScreen> {
  final _inviteCodeController = TextEditingController();

  @override
  void dispose() {
    _inviteCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(joinChatControllerProvider, (previous, next) {
      final room = next.room;
      if (room == null || previous?.room?.id == room.id) {
        return;
      }

      context.go(AppRoutes.chatPath(room.id), extra: room);
    });

    final theme = Theme.of(context);
    final state = ref.watch(joinChatControllerProvider);
    final controller = ref.read(joinChatControllerProvider.notifier);
    const contentPadding = EdgeInsets.fromLTRB(24, 42, 24, 36);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Join chat'),
        leading: IconButton(
          onPressed: state.isLoading ? null : () => context.go(AppRoutes.lobby),
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final minHeight = constraints.maxHeight > contentPadding.vertical
                ? constraints.maxHeight - contentPadding.vertical
                : 0.0;

            return ListView(
              padding: contentPadding,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: minHeight),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Center(
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withAlpha(18),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Icon(
                                Icons.hub_rounded,
                                color: theme.colorScheme.primary,
                                size: 34,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'Enter the stream',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Enter a unique invite code to join the conversation.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface.withAlpha(155),
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 38),
                          ChatLobbyTextField(
                            controller: _inviteCodeController,
                            label: 'Chat code',
                            hintText: 'ABCDEF',
                            enabled: !state.isLoading,
                            textCapitalization: TextCapitalization.characters,
                            textInputAction: TextInputAction.done,
                            errorText: state.inviteCodeError,
                            onChanged: (_) => controller.onFormChanged(),
                            onSubmitted: (_) => _submit(controller),
                          ),
                          if (state.submissionError != null) ...[
                            const SizedBox(height: 16),
                            _InlineFeedback(message: state.submissionError!),
                          ],
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: state.isLoading
                                ? null
                                : () => _submit(controller),
                            icon: state.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.login_rounded),
                            label: Text(state.isSuccess ? 'Joined' : 'Join'),
                          ),
                          const SizedBox(height: 84),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.help_rounded,
                                size: 18,
                                color: theme.colorScheme.onSurface.withAlpha(
                                  125,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Ask the room creator for the code',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withAlpha(
                                    145,
                                  ),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _submit(JoinChatController controller) {
    controller.submit(inviteCode: _inviteCodeController.text);
  }
}

class _InlineFeedback extends StatelessWidget {
  const _InlineFeedback({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withAlpha(18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: theme.colorScheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
