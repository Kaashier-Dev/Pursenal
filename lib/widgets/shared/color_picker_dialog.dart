import 'package:flutter/material.dart';
import 'package:pursenal/app/global/colors.dart';
import 'package:pursenal/app/global/dimensions.dart';
import 'package:pursenal/l10n/app_localizations.dart';

class ColorPickerDialog extends StatelessWidget {
  /// Dialog that sets a material color
  const ColorPickerDialog({
    super.key,
    required this.setColorFn,
    this.selectedColor,
  });

  /// Viewmodel function that sets the color
  final Function(MaterialColor?) setColorFn;

  /// Initial color
  final MaterialColor? selectedColor;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: smallWidth - 100,
          height: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!.selectAColor,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: primaryColors.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {
                    final pColor = primaryColors[index];
                    return Stack(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            setColorFn(pColor);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: pColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        if (selectedColor == pColor)
                          const Center(
                            child: Icon(
                              Icons.check,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
