import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/evidence.dart';
import '../services/api_service.dart';
import '../widgets/coverage_card.dart';
import '../widgets/evidence_tile.dart';

/// The chrome (bottom nav, FAB) shared by the Dashboard, Sources, and
/// Portfolio sections. Used as the `builder` of a StatefulShellRoute, which
/// means each section has its own real URL AND keeps its own state (scroll
/// position, loaded data) when the user switches between them — unlike the
/// old approach of three separate GoRoutes that each rebuilt everything
/// from scratch.
class AppShell extends StatelessWidget {
final StatefulNavigationShell navigationShell;
final GlobalKey<DashboardTabState> dashboardKey;

const AppShell({
super.key,
required this.navigationShell,
required this.dashboardKey,
});

@override
Widget build(BuildContext context) {
return Directionality(
textDirection: TextDirection.rtl,
child: Scaffold(
body: SafeArea(child: navigationShell),
bottomNavigationBar: NavigationBar(
selectedIndex: navigationShell.currentIndex,
onDestinationSelected: (index) {
navigationShell.goBranch(
index,
initialLocation: index == navigationShell.currentIndex,
);
// Refresh the dashboard's data every time the user navigates back
// to it, since evidence/coverage may have changed on another tab
// (e.g. after uploading a file on the Sources tab).
if (index == 0) {
dashboardKey.currentState?.reload();
}
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
floatingActionButton: navigationShell.currentIndex == 0
? FloatingActionButton.extended(
onPressed: () {},
icon: const Icon(Icons.add),
label: const Text(
'إضافة شاهد',
),
)
: null,
),
);
}
}

class DashboardTab extends StatefulWidget {
final ApiService api;
final VoidCallback? onLogout;

const DashboardTab({super.key, required this.api, this.onLogout});

@override
State<DashboardTab> createState() => DashboardTabState();
}

class DashboardTabState extends State<DashboardTab> {
bool _loading = true;
String? _error;
double _coverageValue = 0;
int _complete = 0;
int _needsSupport = 0;
int _missing = 0;
List<Evidence> _evidence = const [];

@override
void initState() {
super.initState();
_load();
}

Future<void> reload() => _load();

Future<void> _load() async {
setState(() {
_loading = true;
_error = null;
});

try {
final results = await Future.wait([
widget.api.getCoverage(),
widget.api.getEvidence(),
]);

final coverage = results[0] as Map<String, dynamic>;
final evidence = results[1] as List<Evidence>;

if (!mounted) return;

setState(() {
_coverageValue = ((coverage['overallCoverage'] ?? 0) as num).toDouble();
_complete = ((coverage['complete'] ?? 0) as num).toInt();
_needsSupport = ((coverage['needsSupport'] ?? 0) as num).toInt();
_missing = ((coverage['missing'] ?? 0) as num).toInt();
_evidence = evidence;
_loading = false;
});
} catch (e) {
if (!mounted) return;
setState(() {
_error = e.toString().replaceFirst('Exception: ', '');
_loading = false;
});
}
}

@override
Widget build(BuildContext context) {
return RefreshIndicator(
onRefresh: _load,
child: SingleChildScrollView(
physics: const AlwaysScrollableScrollPhysics(),
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
'أهلاً بك',
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
if (widget.onLogout != null)
IconButton(
onPressed: () => _confirmLogout(context, widget.onLogout!),
icon: const Icon(Icons.logout_outlined),
tooltip: 'تسجيل الخروج',
color: const Color(0xFF64748B),
),
const SizedBox(width: 4),
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
if (_loading)
const Padding(
padding: EdgeInsets.symmetric(vertical: 40),
child: Center(child: CircularProgressIndicator()),
)
else if (_error != null)
Card(
color: const Color(0xFFFEF2F2),
child: Padding(
padding: const EdgeInsets.all(16),
child: Row(
children: [
const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
const SizedBox(width: 10),
Expanded(child: Text('تعذّر تحميل البيانات: $_error', style: const TextStyle(color: Color(0xFF991B1B)))),
TextButton(onPressed: _load, child: const Text('إعادة المحاولة')),
],
),
),
)
else ...[
CoverageCard(
value: _coverageValue,
complete: _complete,
needsSupport: _needsSupport,
missing: _missing,
),
const SizedBox(height: 22),
SectionTitle(
title: 'شواهدك (${_evidence.length})',
action: 'عرض الكل',
),
const SizedBox(height: 10),
if (_evidence.isEmpty)
Card(
child: Padding(
padding: const EdgeInsets.all(18),
child: Row(
children: [
Container(
width: 44,
height: 44,
decoration: BoxDecoration(
color: const Color(0xFFF1F5F9),
borderRadius: BorderRadius.circular(14),
),
child: const Icon(Icons.inbox_outlined, color: Color(0xFF64748B)),
),
const SizedBox(width: 14),
const Expanded(
child: Text(
'لا توجد شواهد بعد. ابدأ برفع ملف من تبويب المصادر.',
style: TextStyle(height: 1.5, fontWeight: FontWeight.w600),
),
),
],
),
),
)
else
...(_evidence.map(
(evidence) => Padding(
padding: const EdgeInsets.only(bottom: 8),
child: EvidenceTile(
evidence: evidence,
api: widget.api,
onApprove: () async {
await widget.api.approveEvidence(evidence.id);
await _load();
},
onReject: () async {
await widget.api.rejectEvidence(evidence.id);
await _load();
},
onLinked: _load,
onDeleted: _load,
),
),
)),
],
],
),
),
);
}
}

Future<void> _confirmLogout(BuildContext context, VoidCallback onLogout) async {
final confirmed = await showDialog<bool>(
context: context,
builder: (context) => Directionality(
textDirection: TextDirection.rtl,
child: AlertDialog(
title: const Text('\u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u062e\u0631\u0648\u062c'),
content: const Text('\u0647\u0644 \u062a\u0631\u064a\u062f \u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u062e\u0631\u0648\u062c \u0645\u0646 \u062d\u0633\u0627\u0628\u0643\u061f'),
actions: [
TextButton(
onPressed: () => Navigator.of(context).pop(false),
child: const Text('\u0625\u0644\u063a\u0627\u0621'),
),
FilledButton(
onPressed: () => Navigator.of(context).pop(true),
child: const Text('\u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u062e\u0631\u0648\u062c'),
),
],
),
),
);

if (confirmed == true) {
onLogout();
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



