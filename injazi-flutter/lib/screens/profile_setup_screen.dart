import 'package:flutter/material.dart';

import '../services/api_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  final VoidCallback onCompleted;

  const ProfileSetupScreen({
    super.key,
    required this.onCompleted,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final nameController = TextEditingController();
  final schoolController = TextEditingController();
  final subjectController = TextEditingController();

  String? selectedStage;
  bool loading = false;

  late final ApiService api;

  final stages = const [
    'الابتدائية',
    'المتوسطة',
    'الثانوية',
  ];

  @override
  void initState() {
    super.initState();

    api = ApiService(
      baseUrl: 'http://localhost:4000',
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    schoolController.dispose();
    subjectController.dispose();
    api.dispose();
    super.dispose();
  }

  Future<void> save() async {
    FocusScope.of(context).unfocus();

    final name = nameController.text.trim();

    if (name.isEmpty) {
      _showMessage(
        '\u064a\u0631\u062c\u0649 \u0625\u062f\u062e\u0627\u0644 \u0627\u0644\u0627\u0633\u0645',
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await api.saveProfile(
        name: name,
        schoolName: schoolController.text.trim().isEmpty
            ? null
            : schoolController.text.trim(),
        stage: selectedStage,
        subject: subjectController.text.trim().isEmpty
            ? null
            : subjectController.text.trim(),
      );

      if (!mounted) return;

      widget.onCompleted();
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 520,
            ),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6FFFB),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        size: 32,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '\u0623\u0643\u0645\u0644 \u0645\u0644\u0641\u0643',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '\u0647\u0630\u0647 \u0627\u0644\u0628\u064a\u0627\u0646\u0627\u062a \u0633\u062a\u0633\u0627\u0639\u062f \u0625\u0646\u062c\u0627\u0632\u064a \u0639\u0644\u0649 \u062a\u062e\u0635\u064a\u0635 \u0645\u0644\u0641 \u0625\u0646\u062c\u0627\u0632\u0643.',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText:
                            '\u0627\u0644\u0627\u0633\u0645 \u0627\u0644\u0643\u0627\u0645\u0644',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: schoolController,
                      decoration: const InputDecoration(
                        labelText: '\u0627\u0644\u0645\u062f\u0631\u0633\u0629',
                        prefixIcon:
                            Icon(Icons.school_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: selectedStage,
                      decoration: const InputDecoration(
                        labelText: '\u0627\u0644\u0645\u0631\u062d\u0644\u0629',
                        prefixIcon:
                            Icon(Icons.layers_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: stages
                          .map(
                            (stage) => DropdownMenuItem<String>(
                              value: stage,
                              child: Text(stage),
                            ),
                          )
                          .toList(),
                      onChanged: loading
                          ? null
                          : (value) {
                              setState(() {
                                selectedStage = value;
                              });
                            },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: subjectController,
                      decoration: const InputDecoration(
                        labelText:
                            '\u0627\u0644\u0645\u0627\u062f\u0629 \u0623\u0648 \u0627\u0644\u062a\u062e\u0635\u0635',
                        prefixIcon:
                            Icon(Icons.menu_book_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: loading ? null : save,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        child: loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                '\u0645\u062a\u0627\u0628\u0639\u0629',
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

