import 'package:flutter/material.dart';

class IconPickerWidget extends StatelessWidget {
  final IconData selectedIcon;
  final Function(IconData) onIconChanged;

  const IconPickerWidget({
    super.key,
    required this.selectedIcon,
    required this.onIconChanged,
  });

  static const List<IconData> _icons = [
    Icons.shopping_basket,
    Icons.shopping_cart,
    Icons.local_grocery_store,
    Icons.store,
    Icons.local_mall,
    Icons.local_offer,
    Icons.local_dining,
    Icons.restaurant,
    Icons.fastfood,
    Icons.local_cafe,
    Icons.local_bar,
    Icons.local_drink,
    Icons.local_florist,
    Icons.local_pharmacy,
    Icons.local_hospital,
    Icons.school,
    Icons.create,
    Icons.brush,
    Icons.sports_baseball,
    Icons.sports_basketball,
    Icons.sports_football,
    Icons.sports_soccer,
    Icons.sports_tennis,
    Icons.sports_volleyball,
    Icons.laptop,
    Icons.phone_android,
    Icons.tablet_android,
    Icons.desktop_windows,
    Icons.tv,
    Icons.headset,
    Icons.music_note,
    Icons.movie,
    Icons.games,
    Icons.toys,
    Icons.pets,
    Icons.child_care,
    Icons.face,
    Icons.accessibility,
    Icons.airline_seat_flat,
    Icons.beach_access,
    Icons.business_center,
    Icons.casino,
    Icons.fitness_center,
    Icons.golf_course,
    Icons.hot_tub,
    Icons.kitchen,
    Icons.meeting_room,
    Icons.pool,
    Icons.room_service,
    Icons.spa,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _icons.length,
        itemBuilder: (context, index) {
          final icon = _icons[index];
          final isSelected = icon.codePoint == selectedIcon.codePoint;
          
          return InkWell(
            onTap: () => onIconChanged(icon),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                    : null,
                borderRadius: BorderRadius.circular(8),
                border: isSelected
                    ? Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      )
                    : null,
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).iconTheme.color,
              ),
            ),
          );
        },
      ),
    );
  }
}