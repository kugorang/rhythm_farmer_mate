import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:rhythm_farmer_mate/my_app.dart'; // themeModeNotifier 접근을 위해

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onPlaylistPressed;
  final VoidCallback onMetronomeSettingsPressed;

  const AppBarWidget({
    Key? key,
    required this.title,
    required this.onPlaylistPressed,
    required this.onMetronomeSettingsPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return AppBar(
      backgroundColor: theme.colorScheme.primary,
      title: Text(
        title.isNotEmpty ? title : '리듬농부 메이트',
        style: theme.textTheme.h4.copyWith(
          color: theme.colorScheme.primaryForeground,
          fontWeight: FontWeight.bold,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        ShadButton.ghost(
          icon: Icon(
            Icons.queue_music,
            color: theme.colorScheme.primaryForeground,
          ),
          onPressed: onPlaylistPressed,
        ),
        ShadButton.ghost(
          icon: Icon(
            Icons.music_note_outlined,
            color: theme.colorScheme.primaryForeground,
          ),
          onPressed: onMetronomeSettingsPressed,
        ),
        ValueListenableBuilder<ThemeMode>(
          valueListenable: themeModeNotifier,
          builder: (context, currentMode, child) {
            return ShadButton.ghost(
              icon: Icon(
                currentMode == ThemeMode.dark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                color: theme.colorScheme.primaryForeground,
              ),
              onPressed: () {
                themeModeNotifier.value =
                    currentMode == ThemeMode.light
                        ? ThemeMode.dark
                        : currentMode == ThemeMode.dark
                        ? ThemeMode.system
                        : ThemeMode.light;
              },
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
