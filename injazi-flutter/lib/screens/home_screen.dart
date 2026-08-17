import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../models/evidence.dart';
import '../widgets/coverage_card.dart';
import '../widgets/evidence_tile.dart';
import 'portfolio_screen.dart';
import 'sources_screen.dart';

class HomeScreen extends StatefulWidget {
const HomeScreen({super.key});

@override
State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
int currentIndex = 0;

static const List<Widget> tabs = [
DashboardTab(),
SourcesScreen(),
PortfolioScreen(),
];

@override
Widget build(BuildContext context) {
return Directionality(
textDirection: TextDirection.rtl,
child: Scaffold(
body: SafeArea(
child: IndexedStack(
index: currentIndex,
children: tabs,
),
),
bottomNavigationBar: NavigationBar(
selectedIndex: currentIndex,
onDestinationSelected: (index) {
setState(() {
currentIndex = index;
});
},
destinations: const [
NavigationDestination(
icon: Icon(Icons.home_outlined),
selectedIcon: Icon(Icons.home),
label: '\u0627\u0644\u0631\u0626\u064a\u0633\u064a\u0629',
),
NavigationDestination(
icon: Icon(Icons.sync_alt_outlined),
selectedIcon: Icon(Icons.sync_alt),
label: '\u0627\u0644\u0645\u0635\u0627\u062f\u0631',
),
NavigationDestination(
icon: Icon(Icons.folder_outlined),
selectedIcon: Icon(Icons.folder),
label: '\u0645\u0644\u0641\u064a',
),
],
),
floatingActionButton: currentIndex == 0
? FloatingActionButton.extended(
onPressed: () {},
icon: const Icon(Icons.add),
label: const Text(
'\u0625\u0636\u0627\u0641\u0629 \u062f\u0644\u064a\u0644',
),
)
: null,
),
);
}
}

class DashboardTab extends StatelessWidget {
const DashboardTab({super.key});

static const List<Evidence> sampleEvidence = [
Evidence(
id: '1',
title: '\u0646\u0634\u0627\u0637 \u0627\u0644\u062a\u0639\u0644\u0645 \u0627\u0644\u062a\u0639\u0627\u0648\u0646\u064a',
type: '\u0646\u0634\u0627\u0637',
source: '\u0645\u062f\u0631\u0633\u062a\u064a',
confidence: 0.96,
status: 'APPROVED',
),
Evidence(
id: '2',
title: '\u0627\u062e\u062a\u0628\u0627\u0631 \u0642\u0635\u064a\u0631 \u0641\u064a \u0627\u0644\u0623\u0645\u0646 \u0627\u0644\u0633\u064a\u0628\u0631\u0627\u0646\u064a',
type: '\u0627\u062e\u062a\u0628\u0627\u0631',
source: '\u0645\u062f\u0631\u0633\u062a\u064a',
confidence: 0.92,
status: 'APPROVED',
),
Evidence(
id: '3',
title: '\u0634\u0647\u0627\u062f\u0629 \u062f\u0648\u0631\u0629 \u0627\u0644\u0630\u0643\u0627\u0621 \u0627\u0644\u0627\u0635\u0637\u0646\u0627\u0639\u064a',
type: '\u0634\u0647\u0627\u062f\u0629',
source: 'Google Drive',
confidence: 0.99,
status: 'SUGGESTED',
),
];

@override
Widget build(BuildContext context) {
return SingleChildScrollView(
padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
const Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'\u0623\u0647\u0644\u0627\u064b \u0628\u0643',
style: TextStyle(
color: Color(0xFF64748B),
fontSize: 15,
),
),
SizedBox(height: 4),
Text(
'\u062f. \u0641\u064a\u0635\u0644',
style: TextStyle(
fontSize: 28,
fontWeight: FontWeight.w800,
),
),
],
),
),
Container(
width: 48,
height: 48,
decoration: BoxDecoration(
color: const Color(0xFFE6FFFB),
borderRadius: BorderRadius.circular(16),
),
child: const Icon(
Icons.person_outline,
color: Color(0xFF0F766E),
),
),
],
),
const SizedBox(height: 18),
const CoverageCard(
value: 0.86,
complete: 39,
needsSupport: 8,
missing: 6,
),
const SizedBox(height: 22),
const SectionTitle(
title: '\u0644\u0627 \u062a\u062d\u062a\u0627\u062c \u0625\u0644\u0649 \u0641\u0639\u0644 \u0634\u064a\u0621 \u0627\u0644\u0622\u0646',
action: '\u0639\u0631\u0636 \u0627\u0644\u0645\u0644\u0641',
),
const SizedBox(height: 10),
Card(
child: Padding(
padding: const EdgeInsets.all(18),
child: Row(
children: [
Container(
width: 44,
height: 44,
decoration: BoxDecoration(
color: const Color(0xFFDCFCE7),
borderRadius: BorderRadius.circular(14),
),
child: const Icon(
Icons.check_circle_outline,
color: Color(0xFF15803D),
),
),
const SizedBox(width: 14),
const Expanded(
child: Text(
'\u062a\u0645\u062a \u0625\u0636\u0627\u0641\u0629 9 \u0623\u062f\u0644\u0629 \u062c\u062f\u064a\u062f\u0629 \u0645\u0646 \u0645\u0635\u0627\u062f\u0631\u0643 \u062e\u0644\u0627\u0644 \u0647\u0630\u0627 \u0627\u0644\u0623\u0633\u0628\u0648\u0639.',
style: TextStyle(
height: 1.5,
fontWeight: FontWeight.w600,
),
),
),
],
),
),
),
const SizedBox(height: 22),
const SectionTitle(
title: '\u0648\u062c\u062f\u0646\u0627 \u0623\u062f\u0644\u0629 \u062c\u062f\u064a\u062f\u0629',
action: '\u0639\u0631\u0636 \u0627\u0644\u0643\u0644',
),
const SizedBox(height: 10),
...sampleEvidence.map(
(evidence) => Padding(
padding: const EdgeInsets.only(bottom: 8),
child: EvidenceTile(
evidence: evidence,
),
),
),
],
),
);
}
}

class SectionTitle extends StatelessWidget {
final String title;
final String action;

const SectionTitle({
super.key,
required this.title,
required this.action,
});

@override
Widget build(BuildContext context) {
return Row(
children: [
Expanded(
child: Text(
title,
style: const TextStyle(
fontSize: 18,
fontWeight: FontWeight.w800,
),
),
),
TextButton(
onPressed: () {},
child: Text(action),
),
],
);
}
}

