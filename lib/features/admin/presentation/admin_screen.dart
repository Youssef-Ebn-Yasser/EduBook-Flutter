import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/admin_provider.dart';
import 'tabs/admin_dashboard_tab.dart';
import 'tabs/admin_orders_tab.dart';
import 'tabs/admin_books_tab.dart';
import 'tabs/admin_categories_tab.dart';
import 'tabs/admin_grade_levels_tab.dart';
import 'tabs/admin_users_tab.dart';
import '../../auth/providers/auth_provider.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  int _currentIndex = 0;

  static const _tabTitles = [
    'لوحة التحكم',
    'الطلبات',
    'الكتب',
    'الأقسام',
    'الصفوف الدراسية',
    'المستخدمين',
  ];

  void _navigateTo(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ordersState = ref.watch(adminOrdersProvider);
    final pendingCount = ordersState.orders
        .where((o) => o.status.value == 0)
        .length;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'logo.jpeg',
                height: 32,
                width: 32,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.admin_panel_settings_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tabTitles[_currentIndex],
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'EduBook Admin',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Notification bell for pending orders
          if (pendingCount > 0)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => _navigateTo(1),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$pendingCount',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          // Logout
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                    SizedBox(width: 10),
                    Text('تسجيل الخروج',
                        style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (v) async {
              if (v == 'logout') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('تسجيل الخروج'),
                    content: const Text(
                        'هل أنت متأكد من رغبتك في تسجيل الخروج من لوحة التحكم؟'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('إلغاء'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: Colors.red),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('خروج'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && mounted) {
                  await ref.read(authProvider.notifier).logout();
                  if (mounted) context.go('/login');
                }
              }
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          AdminDashboardTab(onNavigateTab: _navigateTo),
          const AdminOrdersTab(),
          const AdminBooksTab(),
          const AdminCategoriesTab(),
          const AdminGradeLevelsTab(),
          const AdminUsersTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: pendingCount > 0,
              label: Text('$pendingCount'),
              child: const Icon(Icons.receipt_long_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: pendingCount > 0,
              label: Text('$pendingCount'),
              child: const Icon(Icons.receipt_long_rounded),
            ),
            label: 'الطلبات',
          ),
          const NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'الكتب',
          ),
          const NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category_rounded),
            label: 'الأقسام',
          ),
          const NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school_rounded),
            label: 'الصفوف',
          ),
          const NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'المستخدمين',
          ),
        ],
      ),
    );
  }
}
