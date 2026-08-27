import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/wallet_provider.dart';
import '../home/home_screen.dart';
import '../bookings/my_bookings_screen.dart';
import '../wallet/wallet_screen.dart';
import '../profile/profile_screen.dart';
import '../../widgets/common/premium_bottom_nav.dart';
import '../../widgets/common/premium_background.dart';

class MainShell extends StatefulWidget {
  final int initialTab;

  const MainShell({super.key, this.initialTab = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;
  final Set<int> _visitedTabs = {0};

  final _screens = const [
    HomeScreen(),
    MyBookingsScreen(),
    WalletScreen(),
    ProfileScreen(),
  ];

  static const _navItems = [
    PremiumNavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: AppStrings.home,
    ),
    PremiumNavItem(
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today_rounded,
      label: AppStrings.bookings,
    ),
    PremiumNavItem(
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet_rounded,
      label: AppStrings.wallet,
    ),
    PremiumNavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: AppStrings.profile,
    ),
  ];

  @override
  void initState() {
    super.initState();
    final tab = widget.initialTab.clamp(0, _screens.length - 1);
    _currentIndex = tab;
    _visitedTabs.add(tab);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadTabData(tab);
      _syncAccountDataFromServer();
    });
  }

  /// After login or reinstall, pull bookings & favorites from the server (not local storage).
  void _syncAccountDataFromServer() {
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      context.read<BookingProvider>().loadBookings(forceRefresh: true);
    });
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      context.read<FavoritesProvider>().loadFavorites(forceRefresh: true);
    });
  }

  void _loadTabData(int index) {
    switch (index) {
      case 1:
        context.read<BookingProvider>().loadBookings();
        break;
      case 2:
        context.read<WalletProvider>().loadWallet();
        break;
    }
  }

  void _onTabSelected(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
    if (!_visitedTabs.add(index)) return;
    _loadTabData(index);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || _currentIndex == 0) return;
        setState(() => _currentIndex = 0);
      },
      child: PremiumBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: IndexedStack(index: _currentIndex, children: _screens),
          bottomNavigationBar: PremiumBottomNav(
            currentIndex: _currentIndex,
            onTap: _onTabSelected,
            items: _navItems,
          ),
        ),
      ),
    );
  }
}
