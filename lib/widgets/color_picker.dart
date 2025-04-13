import 'package:flutter/material.dart';

class ColorPickerDialog extends StatelessWidget {
  const ColorPickerDialog({super.key});

  static final List<Color> _colors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Renk Seç',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: _colors.length,
                itemBuilder: (context, index) {
                  final color = _colors[index];
                  return InkWell(
                    onTap: () => Navigator.pop(context, color),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: color.withAlpha(255),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
          ],
        ),
      ),
    );
  }
}

/// ColorPickerWidget: Renk seçimi için kullanılan özel widget.
/// Material Design renk paletini kullanır ve seçilen rengi görsel olarak belirtir.
class ColorPickerWidget extends StatelessWidget {
  final Color selectedColor;
  final Function(Color) onColorChanged;

  const ColorPickerWidget({
    super.key,
    required this.selectedColor,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _predefinedColors.length,
        itemBuilder: (context, index) {
          final color = _predefinedColors[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => onColorChanged(color),
              borderRadius: BorderRadius.circular(25),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selectedColor == color 
                      ? color
                      : color.withAlpha(179), // 0.7 opacity = 179 in alpha (255 * 0.7)
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selectedColor == color 
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: [
                    if (selectedColor == color)
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: selectedColor == color
                    ? Icon(
                        Icons.check,
                        color: color.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white,
                        size: 20,
                      )
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Önceden tanımlanmış Material Design renk paleti
  static const List<Color> _predefinedColors = [
    Color(0xFF1E88E5), // Modern Mavi
    Color(0xFF26A69A), // Turkuaz
    Color(0xFF66BB6A), // Yeşil
    Color(0xFFFFCA28), // Amber
    Color(0xFFEF5350), // Kırmızı
    Color(0xFF8E24AA), // Mor
    Color(0xFF5E35B1), // Derin Mor
    Color(0xFFFB8C00), // Turuncu
    Color(0xFF43A047), // Koyu Yeşil
    Color(0xFF3949AB), // İndigo
    Color(0xFFD81B60), // Pembe
    Color(0xFF00ACC1), // Siyah
    Color(0xFF546E7A), // Mavi Gri
  ];
}