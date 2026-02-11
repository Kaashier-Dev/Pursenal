import 'package:flutter/material.dart';
import 'package:pursenal/l10n/app_localizations.dart';

class ExportButton extends StatelessWidget {
  /// Button to export given data to several document formats
  const ExportButton({
    super.key,
    required this.pdfExportFn,
    required this.xlsxExportFn,
  });

  /// Function that will generate PDF file
  final Function pdfExportFn;

  /// Function that will generate spreadsheet file
  final Function xlsxExportFn;

  @override
  Widget build(BuildContext context) {
    return IconButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => SimpleDialog(
              title: Text(AppLocalizations.of(context)!.export),
              children: [
                ListTile(
                  title: Text(
                    "PDF",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  onTap: () {
                    pdfExportFn();
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: Text(
                    "Spreadsheet",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  onTap: () {
                    xlsxExportFn();
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
                const SizedBox(
                  height: 12,
                )
              ],
            ),
          );
        },
        icon: const Icon(Icons.file_download_outlined));
  }
}
