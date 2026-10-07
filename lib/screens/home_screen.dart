import 'package:ctadmobl_project/providers/navigation_provider.dart';
import 'package:ctadmobl_project/providers/cart_provider.dart';
import 'package:ctadmobl_project/providers/favorites_provider.dart';
import 'package:ctadmobl_project/screens/chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ctadmobl_project/screens/tab_screens.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    this.userId,
    this.bindSessionData = true,
    this.profileScreen,
    super.key,
  });

  final String? userId;
  final bool bindSessionData;
  final Widget? profileScreen;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const List<String> _titles = ['Shop', 'Cart', 'Chat', 'Profile'];

  static const List<BottomNavigationBarItem> _navigationItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.storefront_outlined),
      label: 'Shop',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.shopping_bag_outlined),
      label: 'Cart',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.chat_bubble_outline),
      label: 'Chat',
    ),
    BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
  ];

  String? _boundUid;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.bindSessionData) return;
    final uid = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (_boundUid == uid) return;
    _boundUid = uid;
    context.read<CartProvider>().bindUser(uid);
    context.read<FavoritesProvider>().bindUser(uid);
  }

  @override
  Widget build(BuildContext context) {
    final navigation = context.watch<NavigationProvider>();
    final cart = context.watch<CartProvider>();
    final screens = [
      const ShopScreen(),
      const CartScreen(),
      const ChatScreen(),
      widget.profileScreen ?? const ProfileScreen(),
    ];
    final items = List<BottomNavigationBarItem>.of(_navigationItems);
    items[1] = BottomNavigationBarItem(
      icon: Badge(
        isLabelVisible: cart.itemCount > 0,
        label: Text('${cart.itemCount}'),
        child: const Icon(Icons.shopping_bag_outlined),
      ),
      label: 'Cart',
    );

    return Scaffold(
      appBar: AppBar(title: Text(_titles[navigation.selectedIndex])),
      body: IndexedStack(index: navigation.selectedIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigation.selectedIndex,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: items,
        onTap: navigation.selectTab,
      ),
    );
  }
}
