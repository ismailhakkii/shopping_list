import 'package:flutter/material.dart';

/// IconPickerWidget: Kategori ikonlarını seçmek için kullanılan özel widget.
/// Material Design ikonlarını kullanır ve seçilen ikonu görsel olarak belirtir.
class IconPickerWidget extends StatelessWidget {
  final IconData selectedIcon;
  final Function(IconData) onIconChanged;

  const IconPickerWidget({
    super.key,
    required this.selectedIcon,
    required this.onIconChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemCount: _icons.length,
        itemBuilder: (context, index) {
          final icon = _icons[index];
          final isSelected = selectedIcon == icon;
          
          return InkWell(
            onTap: () => onIconChanged(icon),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).dividerColor,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.primary.withAlpha(179), // 0.7 opacity = 179
                size: 28,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Önceden tanımlanmış kategoriler için uygun ikonlar
  static const List<IconData> _icons = [
    Icons.shopping_cart,
    Icons.local_grocery_store,
    Icons.shopping_basket,
    Icons.store,
    Icons.fastfood,
    Icons.restaurant,
    Icons.local_cafe,
    Icons.local_pizza,
    Icons.local_dining,
    Icons.bakery_dining,
    Icons.local_bar,
    Icons.sports,
    Icons.fitness_center,
    Icons.sports_esports,
    Icons.devices,
    Icons.phone_android,
    Icons.laptop,
    Icons.headphones,
    Icons.face,
    Icons.brush,
    Icons.pets,
    Icons.child_care,
    Icons.school,
    Icons.book,
    Icons.medical_services,
    Icons.local_hospital,
    Icons.cleaning_services,
    Icons.build,
    Icons.construction,
    Icons.home,
    Icons.chair,
    Icons.weekend,
  ];
}

class IconPickerDialog extends StatelessWidget {
  const IconPickerDialog({super.key});

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
              'Simge Seç',
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
                itemCount: IconPickerWidget._icons.length,
                itemBuilder: (context, index) {
                  final icon = IconPickerWidget._icons[index];
                  return InkWell(
                    onTap: () => Navigator.pop(context, icon),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        size: 32,
                        color: Theme.of(context).primaryColor,
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