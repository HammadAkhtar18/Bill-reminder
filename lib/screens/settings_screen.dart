import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Preferences', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Notifications'),
                subtitle: const Text('Get reminders 3 days, 1 day, and on due date.'),
                value: settings.notificationsEnabled,
                onChanged: (value) async {
                  await settings.updateNotifications(value);
                  if (value) {
                    await NotificationService.instance.requestPermissions();
                  }
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                title: const Text('Default currency'),
                subtitle: Text(settings.currencyCode),
                trailing: const Icon(Icons.arrow_drop_down),
                onTap: () => _showCurrencyPicker(context, settings),
              ),
              const SizedBox(height: 8),
              ListTile(
                title: const Text('Theme'),
                subtitle: Text(settings.themeMode.name),
                trailing: const Icon(Icons.color_lens),
                onTap: () => _showThemePicker(context, settings),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCurrencyPicker(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          children: supportedCurrencies.map((currency) {
            return RadioListTile<String>(
              title: Text(currency),
              value: currency,
              groupValue: settings.currencyCode,
              onChanged: (value) {
                if (value != null) {
                  settings.updateCurrency(value);
                  Navigator.of(context).pop();
                }
              },
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _showThemePicker(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values.map((mode) {
            return RadioListTile<ThemeMode>(
              title: Text(mode.name),
              value: mode,
              groupValue: settings.themeMode,
              onChanged: (value) {
                if (value != null) {
                  settings.updateThemeMode(value);
                  Navigator.of(context).pop();
                }
              },
            );
          }).toList(),
        );
      },
    );
  }
}
