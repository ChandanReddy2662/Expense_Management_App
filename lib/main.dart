import 'package:expense_management_app/models/income.dart';
import 'package:expense_management_app/screens/analytics_screen.dart';
import 'package:expense_management_app/screens/category_manager_screen.dart';
import 'package:expense_management_app/screens/income_screen.dart';
import 'package:expense_management_app/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/expense.dart';
import 'screens/home_screen.dart';
import 'models/category.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(ExpenseAdapter());
  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(IncomeAdapter());

  await Hive.openBox<Category>('categories');
  await Hive.openBox<Expense>('expenses');
  await Hive.openBox<Income>('incomes');
  createDefaultCategories();
  runApp(const ExpenseManagerApp());
}

void createDefaultCategories() {
  final box = Hive.box<Category>('categories');
  if (box.isEmpty) {
    final defaultCategories = [
      Category(name: 'General', iconCode: Icons.category.codePoint),
      Category(name: 'Food', iconCode: Icons.fastfood.codePoint),
      Category(name: 'Travel', iconCode: Icons.flight.codePoint),
      Category(name: 'Shopping', iconCode: Icons.shopping_bag.codePoint),
      Category(name: 'Bills', iconCode: Icons.receipt.codePoint),
    ];
    for (final cat in defaultCategories) {
      box.add(cat);
    }
    print(box.values);
  }
}

class ExpenseManagerApp extends StatefulWidget {
  const ExpenseManagerApp({super.key});

  @override
  State<ExpenseManagerApp> createState() => _ExpenseManagerAppState();
}

class _ExpenseManagerAppState extends State<ExpenseManagerApp> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const AnalyticsScreen(),
    const CategoryManagerScreen(),
    const ProfileScreen(),
    const IncomeScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Manager',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (int index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.list), label: 'Expenses'),
            NavigationDestination(
              icon: Icon(Icons.pie_chart),
              label: 'Analytics',
            ),
            NavigationDestination(
              icon: Icon(Icons.category),
              label: 'Categories',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_pin),
              label: "Profile",
            ),
            NavigationDestination(icon: Icon(Icons.wallet), label: "Wallet"),
          ],
        ),
      ),
    );
  }
}
