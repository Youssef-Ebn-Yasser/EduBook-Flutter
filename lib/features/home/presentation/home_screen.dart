import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../app/theme/theme_provider.dart';
import '../../../features/books/presentation/books_screen.dart';
import '../../../features/books/presentation/my_books_screen.dart';
import '../../../features/profile/presentation/profile_screen.dart';
import '../../books/data/book_models.dart';
import '../../books/providers/books_provider.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = const [
      _HomeTab(),
      BooksScreen(),
      MyBooksScreen(),
      ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
            width: 0.5,
          )),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              label: l.home,
            ),
            NavigationDestination(
              icon: const Icon(Icons.menu_book_outlined),
              selectedIcon: const Icon(Icons.menu_book_rounded),
              label: l.books,
            ),
            NavigationDestination(
              icon: const Icon(Icons.library_books_outlined),
              selectedIcon: const Icon(Icons.library_books_rounded),
              label: l.myBooks,
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline_rounded),
              selectedIcon: const Icon(Icons.person_rounded),
              label: l.profile,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Home Tab ─────────────────────────────────────────────────────────────────

class _HomeTab extends ConsumerStatefulWidget {
  const _HomeTab();

  @override
  ConsumerState<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<_HomeTab> {
  int? _selectedGradeId;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final gradeLevelsAsync = ref.watch(publicGradeLevelsProvider);
    final booksAsync = ref.watch(homeBooksProvider(_selectedGradeId));

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => context.push('/settings'),
            child: CircleAvatar(
              backgroundColor: colors.primarySurface,
              child: Icon(Icons.person_rounded,
                  color: colors.primary, size: 20),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined,
                color: colors.textPrimary),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.search_rounded,
                color: colors.textPrimary),
            onPressed: () => context.push('/books'),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 8),
            child: GestureDetector(
              onTap: () {},
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset('logo.jpeg', width: 38, height: 38,
                    fit: BoxFit.cover),
              ),
            ),
          ),
        ],
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'المنارة التعليمية',
              style: TextStyle(
                fontSize: 12,
                color: colors.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              l.home,
              style: TextStyle(
                fontSize: 16,
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // ── Search bar ─────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    readOnly: true,
                    onTap: () => context.push('/books'),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن كتاب، مادة، أو مؤلف...',
                      prefixIcon:
                          Icon(Icons.search_rounded, color: colors.textHint),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      hintStyle: TextStyle(
                          color: colors.textHint, fontSize: 13),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push('/books'),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.tune_rounded,
                        color: colors.primary, size: 18),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Grade filter chips ──────────────────────────────────────────
          gradeLevelsAsync.when(
            data: (grades) {
              if (grades.isEmpty) return const SizedBox.shrink();
              return SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _GradeFilterChip(
                      label: 'الكل',
                      selected: _selectedGradeId == null,
                      onTap: () => setState(() => _selectedGradeId = null),
                    ),
                    const SizedBox(width: 8),
                    ...grades.map((g) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _GradeFilterChip(
                            label: g.name,
                            selected: _selectedGradeId == g.id,
                            onTap: () =>
                                setState(() => _selectedGradeId = g.id),
                          ),
                        )),
                  ],
                ),
              );
            },
            loading: () => SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _GradeFilterChip(
                      label: 'الكل', selected: true, onTap: () {}),
                ],
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 20),

          // ── Section Title ───────────────────────────────────────────────
          _CategorySection(
            color: colors.primary,
            title: _selectedGradeId == null
                ? 'الكتب المتوفرة'
                : 'كتب الصف المختار',
            onSeeAll: () => context.push('/books'),
          ),
          const SizedBox(height: 12),

          // ── Real Books from API ─────────────────────────────────────────
          booksAsync.when(
            data: (books) {
              if (books.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.menu_book_outlined,
                            size: 48,
                            color: colors.textSecondary
                                .withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text(
                          'لا توجد كتب متوفرة في هذا الصف حالياً',
                          style: TextStyle(
                              color: colors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: books.map((book) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _BookListItem(
                      book: book,
                      onBuy: () => context.push('/books/${book.id}'),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 36, color: Colors.red),
                    const SizedBox(height: 8),
                    const Text('تعذر تحميل الكتب',
                        style: TextStyle(fontSize: 13)),
                    const SizedBox(height: 10),
                    FilledButton.tonal(
                      onPressed: () => ref.invalidate(
                          homeBooksProvider(_selectedGradeId)),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Quick actions ───────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.explore_rounded,
                  label: l.browseBooks,
                  color: colors.primary,
                  onTap: () => context.push('/books'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: Icons.library_books_rounded,
                  label: l.myBooks,
                  color: colors.secondary,
                  onTap: () => context.push('/my-books'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: Icons.receipt_long_rounded,
                  label: 'طلباتي',
                  color: colors.accent,
                  onTap: () => context.push('/orders'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Components ───────────────────────────────────────────────────────────────

class _GradeFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _GradeFilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? colors.primary : colors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check_rounded, size: 14, color: Colors.white),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final Color color;
  final String title;
  final VoidCallback onSeeAll;
  const _CategorySection(
      {required this.color, required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
        ),
        TextButton(
          onPressed: onSeeAll,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: const Size(0, 0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('عرض الكل',
                  style: TextStyle(
                      fontSize: 12,
                      color: colors.primary,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 2),
              Icon(Icons.arrow_back_ios_rounded,
                  size: 12, color: colors.primary),
            ],
          ),
        ),
      ],
    );
  }
}

class _BookListItem extends StatelessWidget {
  final BookListItem book;
  final VoidCallback onBuy;

  const _BookListItem({
    required this.book,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onBuy,
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Book cover
                Container(
                  width: 84,
                  decoration: BoxDecoration(
                    color: colors.primarySurface,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    child: book.coverUrl != null
                        ? Image.network(
                            book.coverUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _coverPlaceholder(colors),
                          )
                        : _coverPlaceholder(colors),
                  ),
                ),
                // Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Grade and category badges
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (book.gradeLevelName.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colors.primarySurface,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  book.gradeLevelName,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: colors.primary,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            if (book.semesterName != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Colors.purple.shade200),
                                ),
                                child: Text(
                                  book.semesterName!,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.purple.shade700,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            if (book.categoryName.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  book.categoryName,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: colors.textSecondary,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          book.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (book.publisherName.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            book.publisherName,
                            style: TextStyle(
                                fontSize: 11, color: colors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text('السعر',
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: colors.textHint)),
                                      if (book.hasDiscount) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade50,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            border: Border.all(
                                                color: Colors.red.shade200),
                                          ),
                                          child: Text(
                                            'خصم ${book.discountPercentage}%',
                                            style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red.shade800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: AlignmentDirectional.centerStart,
                                    child: Row(
                                      children: [
                                        Text(
                                          '${book.price.toStringAsFixed(3)} ر.ع.',
                                          maxLines: 1,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: colors.primary,
                                          ),
                                        ),
                                        if (book.hasDiscount) ...[
                                          const SizedBox(width: 6),
                                          Text(
                                            '${book.originalPrice!.toStringAsFixed(3)} ر.ع.',
                                            style: TextStyle(
                                              fontSize: 10,
                                              decoration:
                                                  TextDecoration.lineThrough,
                                              color: colors.textHint,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            SizedBox(
                              height: 32,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  textStyle: const TextStyle(fontSize: 11),
                                  elevation: 0,
                                ),
                                onPressed: onBuy,
                                child: const Text('تفاصيل الكتاب'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _coverPlaceholder(AppColorSet colors) {
    return Center(
      child: Icon(Icons.menu_book_rounded,
          size: 36, color: colors.primary.withValues(alpha: 0.5)),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}