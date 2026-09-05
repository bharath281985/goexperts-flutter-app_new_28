import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CredentialsGeneratedDialog extends StatelessWidget {
  const CredentialsGeneratedDialog({
    super.key,
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Credentials Generated'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Please copy these credentials and send them securely to the team member. They will only be shown once.'),
          const SizedBox(height: 24),
          Text('Email', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
          Row(
            children: [
              Expanded(child: SelectableText(email, style: Theme.of(context).textTheme.titleMedium)),
              IconButton(
                icon: const Icon(Icons.copy, size: 20),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: email));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email copied')));
                },
              )
            ],
          ),
          const SizedBox(height: 16),
          Text('Temporary Password', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
          Row(
            children: [
              Expanded(child: SelectableText(password, style: Theme.of(context).textTheme.titleMedium)),
              IconButton(
                icon: const Icon(Icons.copy, size: 20),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: password));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password copied')));
                },
              )
            ],
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        )
      ],
    );
  }
}
