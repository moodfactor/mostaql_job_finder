// settings_page.dart
// This file defines the SettingsPage widget for managing app settings.     


import 'package:flutter/material.dart';
import 'package:mostaql_job_finder/main.dart';
import 'dart:ui'; // Import for ImageFilter

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Settings'),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).appBarTheme.backgroundColor?.withAlpha((0.3 * 255).round()) ?? Colors.blue.withAlpha((0.3 * 255).round()),
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Theme',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (_, mode, __) {
                return Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      title: const Text('Light'),
                      value: ThemeMode.light,
                      groupValue: mode,
                      onChanged: (value) => themeNotifier.value = value!,
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('Dark'),
                      value: ThemeMode.dark,
                      groupValue: mode,
                      onChanged: (value) => themeNotifier.value = value!,
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('System'),
                      value: ThemeMode.system,
                      groupValue: mode,
                      onChanged: (value) => themeNotifier.value = value!,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
