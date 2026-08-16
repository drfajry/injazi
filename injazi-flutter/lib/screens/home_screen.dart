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
label: 'الرئيسية',
),
NavigationDestination(
icon: Icon(Icons.sync_alt_outlined),
selectedIcon: Icon(Icons.sync_alt),
label: 'المصادر',
),
NavigationDestination(
icon: Icon(Icons.folder_outlined),
selectedIcon: Icon(Icons.folder),
label: 'ملفي',
),
],
),
floatingActionButton: currentIndex == 0
? FloatingActionButton.extended(
onPressed: () {},
icon: const Icon(Icons.add),
label: const Text('إضافة دليل'),
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
title: 'نشاط التعلم التعاوني',
type: 'نشاط',
source: 'مدرستي',
confidence: 0.96,
status: 'APPROVED',
),
Evidence(
id: '2',
title: 'اختبار قصير في الأمن السيبراني',
type: 'اختبار',
source: 'مدرستي',
confidence: 0.92,
status: 'APPROVED',
),
Evidence(
id: '3',
title: 'شهادة دورة الذكاء الاصطناعي',
type: 'شهادة',
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
'أهلًا بك 👋',
style: TextStyle(
color: Color(0xFF64748B),
fontSize: 15,
),
),
SizedBox(height: 4),
Text(
'د. فيصل',
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
title: 'لا تحتاج إلى فعل شيء الآن',
action: 'عرض الملف',
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
'تمت إضافة 9 أدلة جديدة من مصادرك خلال هذا الأسبوع.',
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
title: 'وجدنا أدلة جديدة',
action: 'عرض الكل',
),
const SizedBox(height: 10),
...sampleEvidence.map(
(evidence) => Padding(
padding: const EdgeInsets.only(bottom: 8),
child: EvidenceTile(evidence: evidence),
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
