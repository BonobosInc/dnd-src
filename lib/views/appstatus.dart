import 'package:dnd/configs/colours.dart';
import 'package:dnd/configs/version.dart';
import 'package:flutter/material.dart';
import 'package:dnd/l10n/app_localizations.dart';

class AppStatusDialog extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback onImageTap;

  const AppStatusDialog({
    super.key,
    required this.title,
    required this.content,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(title),
      content: GestureDetector(
        onTap: onImageTap,
        child: Text(
          content,
          style: TextStyle(
            color: AppColors.textColorDark,
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(loc.close),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

void showAppStatusDialog(BuildContext context) {
  final loc = AppLocalizations.of(context)!;
  String version = appVersion;

  String content = "${loc.bonodnd}\nVersion: $version\n";

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AppStatusDialog(
        title: 'BonoDND',
        content: content,
        onImageTap: () {
          _showImageDialog(context);
        },
      );
    },
  );
}

void _showImageDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: ClipOval(
          child: Image.asset(
            'assets/images/bonobo.png',
            width: 300,
            height: 300,
            fit: BoxFit.cover,
          ),
        ),
      );
    },
  );
}
