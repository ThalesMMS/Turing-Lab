import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/presentation/widgets/mobile_navigation.dart';
import 'package:turing_lab/presentation/widgets/workspace_selector.dart';

const _testItems = [
  NavigationItem(
    label: 'FSA',
    icon: Icons.route,
    description: 'Finite State Automata',
  ),
  NavigationItem(
    label: 'Grammar',
    icon: Icons.account_tree,
    description: 'Context-Free Grammars',
  ),
  NavigationItem(
    label: 'PDA',
    icon: Icons.layers,
    description: 'Pushdown Automata',
  ),
  NavigationItem(
    label: 'TM',
    icon: Icons.memory,
    description: 'Turing Machines',
  ),
  NavigationItem(
    label: 'Regex',
    icon: Icons.text_fields,
    description: 'Regular Expressions',
  ),
];

void main() {
  group('MobileNavigation', () {
    testWidgets('renders all navigation items with correct labels and icons', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: MobileNavigation(
              currentIndex: 0,
              onTap: (_) {},
              items: _testItems,
            ),
          ),
        ),
      );

      expect(find.byType(MobileNavigation), findsOneWidget);
      expect(find.text('FSA'), findsOneWidget);
      expect(find.text('Grammar'), findsOneWidget);
      expect(find.text('PDA'), findsOneWidget);
      expect(find.text('TM'), findsOneWidget);
      expect(find.text('Regex'), findsOneWidget);
      expect(find.byIcon(Icons.route), findsOneWidget);
      expect(find.byIcon(Icons.account_tree), findsOneWidget);
      expect(find.byIcon(Icons.layers), findsOneWidget);
      expect(find.byIcon(Icons.memory), findsOneWidget);
      expect(find.byIcon(Icons.text_fields), findsOneWidget);
    });

    testWidgets('highlights the selected item correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: MobileNavigation(
              currentIndex: 2,
              onTap: (_) {},
              items: _testItems,
            ),
          ),
        ),
      );

      final pdaText = tester.widget<Text>(
        find.descendant(
          of: find
              .ancestor(of: find.text('PDA'), matching: find.byType(InkWell))
              .first,
          matching: find.byType(Text),
        ),
      );

      expect(pdaText.style?.fontWeight, FontWeight.w600);

      final fsaText = tester.widget<Text>(
        find.descendant(
          of: find
              .ancestor(of: find.text('FSA'), matching: find.byType(InkWell))
              .first,
          matching: find.byType(Text),
        ),
      );

      expect(fsaText.style?.fontWeight, FontWeight.normal);
    });

    testWidgets('calls onTap with correct index when item is tapped', (
      tester,
    ) async {
      int? tappedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: MobileNavigation(
              currentIndex: 0,
              onTap: (index) => tappedIndex = index,
              items: _testItems,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Grammar'));
      await tester.pumpAndSettle();

      expect(tappedIndex, 1);

      await tester.tap(find.text('TM'));
      await tester.pumpAndSettle();

      expect(tappedIndex, 3);
    });

    testWidgets('renders within SafeArea with expandable minimum height', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: MobileNavigation(
              currentIndex: 0,
              onTap: (_) {},
              items: _testItems,
            ),
          ),
        ),
      );

      expect(find.byType(SafeArea), findsOneWidget);

      final minHeights = tester
          .widgetList<ConstrainedBox>(
            find.descendant(
              of: find.byType(MobileNavigation),
              matching: find.byType(ConstrainedBox),
            ),
          )
          .map((box) => box.constraints.minHeight);

      expect(minHeights, contains(80));
    });

    testWidgets('applies correct styling to items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: MobileNavigation(
              currentIndex: 0,
              onTap: (_) {},
              items: _testItems,
            ),
          ),
        ),
      );

      final inkWells = find.byType(InkWell);
      expect(inkWells, findsNWidgets(_testItems.length));

      final firstInkWell = tester.widget<InkWell>(inkWells.first);
      expect(firstInkWell.borderRadius, BorderRadius.circular(12));
      expect(tester.getSize(inkWells.first).height, greaterThanOrEqualTo(44));
    });

    testWidgets('updates when currentIndex changes', (tester) async {
      int currentIndex = 0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                bottomNavigationBar: MobileNavigation(
                  currentIndex: currentIndex,
                  onTap: (index) => setState(() => currentIndex = index),
                  items: _testItems,
                ),
              ),
            );
          },
        ),
      );

      var firstText = tester.widget<Text>(
        find.descendant(
          of: find
              .ancestor(of: find.text('FSA'), matching: find.byType(InkWell))
              .first,
          matching: find.byType(Text),
        ),
      );
      expect(firstText.style?.fontWeight, FontWeight.w600);

      await tester.tap(find.text('Regex'));
      await tester.pumpAndSettle();

      final regexText = tester.widget<Text>(
        find.descendant(
          of: find
              .ancestor(of: find.text('Regex'), matching: find.byType(InkWell))
              .first,
          matching: find.byType(Text),
        ),
      );
      expect(regexText.style?.fontWeight, FontWeight.w600);

      firstText = tester.widget<Text>(
        find.descendant(
          of: find
              .ancestor(of: find.text('FSA'), matching: find.byType(InkWell))
              .first,
          matching: find.byType(Text),
        ),
      );
      expect(firstText.style?.fontWeight, FontWeight.normal);
    });

    testWidgets('expands for larger text scales on narrow widths', (
      tester,
    ) async {
      const dynamicTypeItems = [
        NavigationItem(
          label: 'Finite State',
          icon: Icons.route,
          description: 'Finite State Automata',
        ),
        NavigationItem(
          label: 'Regular Expressions',
          icon: Icons.text_fields,
          description: 'Regular Expressions',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(2),
            ),
            child: Scaffold(
              bottomNavigationBar: MobileNavigation(
                currentIndex: 0,
                onTap: (_) {},
                items: dynamicTypeItems,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final navigationSize = tester.getSize(find.byType(MobileNavigation));
      final navLabel = tester.widget<Text>(find.text('Regular Expressions'));

      expect(tester.takeException(), isNull);
      expect(navigationSize.height, greaterThan(80));
      expect(navLabel.maxLines, 2);
    });

    testWidgets('exposes semantic labels for navigation items', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: MobileNavigation(
              currentIndex: 0,
              onTap: (_) {},
              items: _testItems,
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Navigate to FSA'), findsOneWidget);
      expect(find.bySemanticsLabel('Navigate to Regex'), findsOneWidget);

      handle.dispose();
    });
  });

  group('WorkspaceSelector', () {
    Future<void> pumpSelector(
      WidgetTester tester, {
      int currentIndex = 0,
      ValueChanged<int>? onSelected,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              leadingWidth: WorkspaceSelector.leadingWidth,
              leading: WorkspaceSelector(
                items: _testItems,
                currentIndex: currentIndex,
                onSelected: onSelected ?? (_) {},
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('shows only the active workspace until it is opened', (
      tester,
    ) async {
      await pumpSelector(tester);

      expect(find.text('FSA'), findsOneWidget);
      expect(find.text('Grammar'), findsNothing);
      expect(find.text('PDA'), findsNothing);
      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
    });

    testWidgets('lists every workspace once opened', (tester) async {
      await pumpSelector(tester);

      await tester.tap(find.byIcon(Icons.arrow_drop_down));
      await tester.pumpAndSettle();

      // The active workspace also stays visible on the closed anchor.
      expect(find.text('FSA'), findsNWidgets(2));
      expect(find.text('Grammar'), findsOneWidget);
      expect(find.text('PDA'), findsOneWidget);
      expect(find.text('TM'), findsOneWidget);
      expect(find.text('Regex'), findsOneWidget);
      expect(find.text('Pushdown Automata'), findsOneWidget);
    });

    testWidgets('reports the tapped workspace index', (tester) async {
      int? selectedIndex;
      await pumpSelector(tester, onSelected: (index) => selectedIndex = index);

      await tester.tap(find.byIcon(Icons.arrow_drop_down));
      await tester.pumpAndSettle();
      await tester.tap(find.text('PDA'));
      await tester.pumpAndSettle();

      expect(selectedIndex, 2);
    });

    testWidgets('marks the active workspace in the menu', (tester) async {
      await pumpSelector(tester, currentIndex: 3);

      expect(find.text('TM'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_drop_down));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('exposes semantic labels for every workspace', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpSelector(tester);

      expect(find.bySemanticsLabel('Workspace: FSA'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_drop_down));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Navigate to FSA'), findsOneWidget);
      expect(find.bySemanticsLabel('Navigate to PDA'), findsOneWidget);

      handle.dispose();
    });

    testWidgets('clamps an out-of-range index to the last workspace', (
      tester,
    ) async {
      await pumpSelector(tester, currentIndex: 42);

      expect(find.text('Regex'), findsOneWidget);
    });
  });

  group('NavigationItem', () {
    test('creates instance with all required properties', () {
      const item = NavigationItem(
        label: 'Test',
        icon: Icons.star,
        description: 'Test Description',
      );

      expect(item.label, 'Test');
      expect(item.icon, Icons.star);
      expect(item.description, 'Test Description');
    });

    test('is const constructable', () {
      const item1 = NavigationItem(
        label: 'Test',
        icon: Icons.star,
        description: 'Test Description',
      );

      const item2 = NavigationItem(
        label: 'Test',
        icon: Icons.star,
        description: 'Test Description',
      );

      expect(identical(item1, item2), isTrue);
    });
  });
}
