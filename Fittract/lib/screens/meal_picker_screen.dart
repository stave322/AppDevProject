import 'package:flutter/material.dart';

import '../store/store.dart';
import '../widgets/shared_widgets.dart';

class _MealOption {
  final String name;
  final String type;
  final String description;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final IconData icon;

  const _MealOption(
    this.name,
    this.type,
    this.description,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.icon,
  );

  Map<String, dynamic> toMeal() => {
    't': type,
    'n': name,
    'desc': description,
    'k': calories,
    'p': protein,
    'c': carbs,
    'f': fat,
  };
}

const _mealOptions = [
  _MealOption(
    'Oatmeal with berries',
    'Breakfast',
    'Rolled oats with milk, blueberries, and a spoonful of honey.',
    320,
    12,
    54,
    7,
    Icons.breakfast_dining_outlined,
  ),
  _MealOption(
    'Egg and avocado toast',
    'Breakfast',
    'Two eggs and sliced avocado served over whole-grain toast.',
    390,
    20,
    35,
    20,
    Icons.egg_alt_outlined,
  ),
  _MealOption(
    'Greek yogurt parfait',
    'Breakfast',
    'Greek yogurt layered with granola, strawberries, and chia seeds.',
    280,
    18,
    38,
    7,
    Icons.icecream_outlined,
  ),
  _MealOption(
    'Chicken rice bowl',
    'Lunch',
    'Grilled chicken breast with brown rice, broccoli, and lemon.',
    520,
    42,
    58,
    12,
    Icons.rice_bowl_outlined,
  ),
  _MealOption(
    'Salmon and roasted vegetables',
    'Lunch',
    'Baked salmon with roasted seasonal vegetables and quinoa.',
    610,
    38,
    46,
    29,
    Icons.set_meal_outlined,
  ),
  _MealOption(
    'Turkey avocado wrap',
    'Lunch',
    'Whole-wheat wrap filled with turkey, avocado, lettuce, and tomato.',
    450,
    32,
    42,
    17,
    Icons.lunch_dining_outlined,
  ),
  _MealOption(
    'Apple with peanut butter',
    'Snack',
    'A crisp apple with one tablespoon of natural peanut butter.',
    190,
    5,
    26,
    9,
    Icons.energy_savings_leaf_outlined,
  ),
  _MealOption(
    'Cottage cheese and fruit',
    'Snack',
    'Cottage cheese served with pineapple and a handful of walnuts.',
    230,
    20,
    22,
    8,
    Icons.local_cafe_outlined,
  ),
  _MealOption(
    'Banana protein smoothie',
    'Snack',
    'Blended banana, milk, and protein powder with a little cinnamon.',
    260,
    24,
    34,
    5,
    Icons.blender_outlined,
  ),
  _MealOption(
    'Beef and vegetable stir-fry',
    'Dinner',
    'Lean beef with mixed vegetables and rice in a light soy-ginger sauce.',
    570,
    39,
    61,
    18,
    Icons.dinner_dining_outlined,
  ),
  _MealOption(
    'Lentil curry',
    'Dinner',
    'Red lentils simmered with tomato, spinach, and mild curry spices.',
    490,
    24,
    72,
    11,
    Icons.soup_kitchen_outlined,
  ),
  _MealOption(
    'Tofu quinoa bowl',
    'Dinner',
    'Crispy tofu and quinoa with edamame, greens, and sesame dressing.',
    530,
    27,
    56,
    21,
    Icons.ramen_dining_outlined,
  ),
  _MealOption(
    'Shomai With Rice',
    'Lunch',
    'Shomai with rice and vegetables in a light sauce.',
    250,
    4,
    30,
    1,
    Icons.rice_bowl_outlined,
  ),
];

const _mealTypes = ['All', 'Breakfast', 'Lunch', 'Snack', 'Dinner'];

class MealPickerScreen extends StatefulWidget {
  const MealPickerScreen({super.key});

  @override
  State<MealPickerScreen> createState() => _MealPickerScreenState();
}

class _MealPickerScreenState extends State<MealPickerScreen> {
  final _search = TextEditingController();
  String _type = 'All';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => live((c) {
    final query = _search.text.trim().toLowerCase();
    final options = _mealOptions.where((meal) {
      final matchesType = _type == 'All' || meal.type == _type;
      final matchesSearch =
          query.isEmpty ||
          meal.name.toLowerCase().contains(query) ||
          meal.description.toLowerCase().contains(query);
      return matchesType && matchesSearch;
    }).toList();

    return screen([
      hdr(c, 'Add food', 'Choose a meal or add your own.', back: true),
      card(
        color: tintOf(c),
        child: Row(
          children: [
            Icon(Icons.restaurant_menu, color: primaryOf(c), size: 30),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Pick something you ate',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
            Text('${store.kcal()} kcal today', style: muted),
          ],
        ),
      ),
      TextField(
        controller: _search,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search meals or ingredients',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _search.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  onPressed: () {
                    _search.clear();
                    setState(() {});
                  },
                  icon: const Icon(Icons.close),
                ),
        ),
      ),
      const SizedBox(height: 12),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final type in _mealTypes)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(type),
                  selected: _type == type,
                  onSelected: (_) => setState(() => _type = type),
                  selectedColor: tintOf(c),
                  labelStyle: TextStyle(
                    color: _type == type ? primaryOf(c) : null,
                    fontWeight: _type == type ? FontWeight.w700 : null,
                  ),
                  side: BorderSide(
                    color: _type == type
                        ? primaryOf(c)
                        : Theme.of(c).colorScheme.outlineVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
      h3(
        'Ready-made meals',
        trailing: Text('${options.length} options', style: muted),
      ),
      if (options.isEmpty)
        card(
          child: const Text(
            'No meals match that search. Try another name or add your meal manually.',
            textAlign: TextAlign.center,
            style: muted,
          ),
        )
      else
        for (final meal in options) _optionCard(c, meal),
      card(
        color: tintOf(c),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Not on the list?',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Enter the meal name and nutrition details yourself.',
              style: muted,
            ),
            const SizedBox(height: 12),
            btn('＋  Add food manually', () => go(c, const ManualMealScreen())),
          ],
        ),
      ),
    ]);
  });

  Widget _optionCard(BuildContext context, _MealOption meal) => card(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: tintOf(context),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(meal.icon, color: primaryOf(context)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      meal.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    '${meal.calories} kcal',
                    style: TextStyle(
                      color: primaryOf(context),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(meal.description, style: muted),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 5,
                children: [
                  tag(meal.type),
                  _macroChip(context, 'P', meal.protein),
                  _macroChip(context, 'C', meal.carbs),
                  _macroChip(context, 'F', meal.fat),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 38,
                child: FilledButton.tonalIcon(
                  onPressed: () => _addMeal(context, meal),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add to today'),
                  style: FilledButton.styleFrom(
                    foregroundColor: primaryOf(context),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _macroChip(BuildContext context, String label, int value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: tintOf(context),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text('$label $value g', style: muted),
  );

  void _addMeal(BuildContext context, _MealOption meal) {
    store.meals.add(meal.toMeal());
    store.save();
    snack(context, '${meal.name} added to today.');
  }
}

class ManualMealScreen extends StatefulWidget {
  const ManualMealScreen({super.key});

  @override
  State<ManualMealScreen> createState() => _ManualMealScreenState();
}

class _ManualMealScreenState extends State<ManualMealScreen> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _calories = TextEditingController();
  final _protein = TextEditingController(text: '0');
  final _carbs = TextEditingController(text: '0');
  final _fat = TextEditingController(text: '0');
  String _type = 'Breakfast';

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _calories.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => screen([
    hdr(context, 'Manual entry', 'Add your meal details.', back: true),
    card(
      color: tintOf(context),
      child: const Row(
        children: [
          Icon(Icons.edit_note_outlined, color: kPri, size: 28),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Enter what you ate and its nutrition. It will be added to today’s food log.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    ),
    h3('Meal details'),
    DropdownButtonFormField<String>(
      initialValue: _type,
      decoration: const InputDecoration(
        labelText: 'Meal type',
        prefixIcon: Icon(Icons.restaurant_outlined),
      ),
      items: [
        for (final type in _mealTypes.skip(1))
          DropdownMenuItem(value: type, child: Text(type)),
      ],
      onChanged: (value) {
        if (value != null) setState(() => _type = value);
      },
    ),
    const SizedBox(height: 12),
    TextField(
      controller: _name,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(
        labelText: 'Meal name',
        hintText: 'e.g. Homemade vegetable pasta',
        prefixIcon: Icon(Icons.dinner_dining_outlined),
      ),
    ),
    const SizedBox(height: 12),
    TextField(
      controller: _description,
      textCapitalization: TextCapitalization.sentences,
      minLines: 2,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Description (optional)',
        hintText: 'Ingredients or serving details',
        alignLabelWithHint: true,
        prefixIcon: Icon(Icons.notes_outlined),
      ),
    ),
    h3('Nutrition'),
    TextField(
      controller: _calories,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'Calories',
        suffixText: 'kcal',
        prefixIcon: Icon(Icons.local_fire_department_outlined),
      ),
    ),
    const SizedBox(height: 12),
    Row(
      children: [
        Expanded(
          child: _macroInput(_protein, 'Protein', Icons.egg_alt_outlined),
        ),
        const SizedBox(width: 8),
        Expanded(child: _macroInput(_carbs, 'Carbs', Icons.grain)),
        const SizedBox(width: 8),
        Expanded(child: _macroInput(_fat, 'Fat', Icons.water_drop_outlined)),
      ],
    ),
    const SizedBox(height: 18),
    btn('Add to food log', _save),
  ]);

  Widget _macroInput(
    TextEditingController controller,
    String label,
    IconData icon,
  ) => TextField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(
      labelText: label,
      suffixText: 'g',
      prefixIcon: Icon(icon, size: 18),
    ),
  );

  void _save() {
    final name = _name.text.trim();
    final calories = _parseAmount(_calories.text);
    final protein = _parseAmount(_protein.text);
    final carbs = _parseAmount(_carbs.text);
    final fat = _parseAmount(_fat.text);
    if (name.isEmpty) {
      snack(context, 'Enter a name for your meal.');
      return;
    }
    if (calories == null || calories <= 0 || calories > 10000) {
      snack(
        context,
        'Enter valid calories greater than 0 and no more than 10000.',
      );
      return;
    }
    if (protein == null ||
        carbs == null ||
        fat == null ||
        [protein, carbs, fat].any((value) => value < 0 || value > 1000)) {
      snack(context, 'Enter valid macro amounts from 0 to 1000 g.');
      return;
    }

    store.meals.add({
      't': _type,
      'n': name,
      'desc': _description.text.trim(),
      'k': calories.round(),
      'p': protein.round(),
      'c': carbs.round(),
      'f': fat.round(),
    });
    store.save();
    Navigator.pop(context);
    snack(context, '$name added to today.');
  }

  double? _parseAmount(String value) {
    final text = value.trim();
    return text.isEmpty ? 0 : double.tryParse(text);
  }
}
