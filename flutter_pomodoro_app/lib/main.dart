import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MultiplicationAdventureApp());
}

class MultiplicationAdventureApp extends StatelessWidget {
  const MultiplicationAdventureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Çarpım Macerası',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF7F2FF),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      home: const MultiplicationHomePage(),
    );
  }
}

class MultiplicationHomePage extends StatefulWidget {
  const MultiplicationHomePage({super.key});

  @override
  State<MultiplicationHomePage> createState() => _MultiplicationHomePageState();
}

class _MultiplicationHomePageState extends State<MultiplicationHomePage> {
  final Random _random = Random();
  late SharedPreferences _prefs;

  bool _isLoading = true;
  int _factorA = 0;
  int _factorB = 0;
  late List<int> _answerOptions;
  int? _selectedAnswer;
  int _totalCorrect = 0;
  int _totalQuestions = 0;
  int _coins = 0;
  int _currentStreak = 0;
  int _bestStreak = 0;
  Set<String> _unlockedBadges = {};
  String? _feedbackMessage;
  bool _wasLastAnswerCorrect = false;

  static const List<_Badge> _availableBadges = [
    _Badge('Meraklı Öğrenci', Icons.lightbulb, 10),
    _Badge('Çarpım Ustası', Icons.star, 30),
    _Badge('Süper Kahraman', Icons.emoji_events, 60),
    _Badge('Efsane Çarpan', Icons.workspace_premium, 100),
  ];

  static const List<String> _celebrationMessages = [
    'Harika! Çarpım kahramanı oluyorsun!',
    'Süpersin! Sayılar seni seviyor!',
    'Başardın! Yeni yıldızlar yakında senin.',
    'Çarpım gezegenine bir adım daha!',
  ];

  static const List<String> _encouragementMessages = [
    'Olur böyle şeyler! Tekrar dene, başaracaksın.',
    'Matematik sabır ister, yeniden dene!',
    'Hatalar öğretmenimizdir, devam!',
    'Bir dahaki sefere mutlaka olacak!',
  ];

  @override
  void initState() {
    super.initState();
    _initialiseGame();
  }

  Future<void> _initialiseGame() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _totalCorrect = _prefs.getInt('totalCorrect') ?? 0;
      _totalQuestions = _prefs.getInt('totalQuestions') ?? 0;
      _coins = _prefs.getInt('coins') ?? 0;
      _currentStreak = _prefs.getInt('currentStreak') ?? 0;
      _bestStreak = _prefs.getInt('bestStreak') ?? 0;
      _unlockedBadges = _prefs.getStringList('unlockedBadges')?.toSet() ?? {};
      _isLoading = false;
    });
    _generateNewQuestion();
  }

  Future<void> _saveProgress() async {
    await _prefs.setInt('totalCorrect', _totalCorrect);
    await _prefs.setInt('totalQuestions', _totalQuestions);
    await _prefs.setInt('coins', _coins);
    await _prefs.setInt('currentStreak', _currentStreak);
    await _prefs.setInt('bestStreak', _bestStreak);
    await _prefs.setStringList('unlockedBadges', _unlockedBadges.toList());
  }

  int get _currentLevel {
    return (_totalCorrect ~/ 10) + 1;
  }

  void _generateNewQuestion() {
    final maxTable = min(12, _currentLevel + 4);
    _factorA = _random.nextInt(maxTable - 1) + 1;
    _factorB = _random.nextInt(maxTable - 1) + 1;
    final correctAnswer = _factorA * _factorB;

    final Set<int> options = {correctAnswer};
    while (options.length < 4) {
      final delta = _random.nextInt(5) + 1;
      final sign = _random.nextBool() ? 1 : -1;
      final option = max(1, correctAnswer + sign * delta * _factorA);
      options.add(option);
    }
    _answerOptions = options.toList()..shuffle(_random);
    _selectedAnswer = null;
    _feedbackMessage = null;
    setState(() {});
  }

  Future<void> _submitAnswer(int answer) async {
    if (_selectedAnswer != null) return;
    setState(() {
      _selectedAnswer = answer;
      _totalQuestions++;
    });

    final isCorrect = answer == _factorA * _factorB;
    if (isCorrect) {
      _totalCorrect++;
      _currentStreak++;
      _bestStreak = max(_bestStreak, _currentStreak);
      _coins += 5;
      _wasLastAnswerCorrect = true;
      _feedbackMessage = _celebrationMessages[_random.nextInt(_celebrationMessages.length)];
      await _checkForNewBadges();
    } else {
      _currentStreak = 0;
      _wasLastAnswerCorrect = false;
      _feedbackMessage = _encouragementMessages[_random.nextInt(_encouragementMessages.length)];
    }

    await _saveProgress();
    setState(() {});
  }

  Future<void> _checkForNewBadges() async {
    for (final badge in _availableBadges) {
      if (_totalCorrect >= badge.unlockAt && _unlockedBadges.add(badge.label)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tebrikler! "${badge.label}" rozetini kazandın!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _resetProgress() {
    setState(() {
      _totalCorrect = 0;
      _totalQuestions = 0;
      _coins = 0;
      _currentStreak = 0;
      _bestStreak = 0;
      _unlockedBadges.clear();
      _feedbackMessage = null;
    });
    _saveProgress();
  }

  double get _successRate {
    if (_totalQuestions == 0) return 0;
    return _totalCorrect / _totalQuestions;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Çarpım Macerası'),
        actions: [
          IconButton(
            tooltip: 'İlerlemeni sıfırla',
            onPressed: () async {
              final shouldReset = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sıfırlansın mı?'),
                  content: const Text(
                    'Tüm puanlarını, rozetlerini ve ilerlemeni silmek istediğine emin misin?\nBu işlem geri alınamaz.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Vazgeç'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Evet, Sıfırla'),
                    ),
                  ],
                ),
              );
              if (shouldReset == true) {
                _resetProgress();
                _generateNewQuestion();
              }
            },
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProgressOverview(context),
            const SizedBox(height: 16),
            _buildQuestionCard(context),
            const SizedBox(height: 16),
            _buildBadgeCarousel(),
            const SizedBox(height: 16),
            _buildTipsCard(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generateNewQuestion,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Yeni Soru'),
      ),
    );
  }

  Widget _buildProgressOverview(BuildContext context) {
    final level = _currentLevel;
    final successPercentage = (_successRate * 100).round();
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.explore, size: 32, color: Colors.deepPurple),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Seviye $level', style: Theme.of(context).textTheme.titleLarge),
                      Text('Başarı oranı: %$successPercentage'),
                    ],
                  ),
                ),
                Chip(
                  label: Text('$_coins ⭐'),
                  backgroundColor: Colors.amber.shade100,
                  avatar: const Icon(Icons.stars, color: Colors.amber),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ProgressStat(title: 'Doğru', value: _totalCorrect.toString(), color: Colors.green),
                _ProgressStat(title: 'Toplam', value: _totalQuestions.toString(), color: Colors.blue),
                _ProgressStat(title: 'Seri', value: _currentStreak.toString(), color: Colors.purple),
                _ProgressStat(title: 'Rekor', value: _bestStreak.toString(), color: Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: _wasLastAnswerCorrect ? Colors.green.shade50 : Colors.white,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '$_factorA × $_factorB = ?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _answerOptions
                  .map((option) => _AnswerOption(
                        value: option,
                        isSelected: _selectedAnswer == option,
                        isCorrectAnswer: option == _factorA * _factorB,
                        isLocked: _selectedAnswer != null,
                        onTap: () => _submitAnswer(option),
                      ))
                  .toList(),
            ),
            if (_feedbackMessage != null) ...[
              const SizedBox(height: 16),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: 1,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _wasLastAnswerCorrect
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _wasLastAnswerCorrect ? Icons.emoji_events : Icons.refresh,
                        color: _wasLastAnswerCorrect ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _feedbackMessage!,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeCarousel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rozet Koleksiyonu',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _availableBadges.map((badge) {
            final isUnlocked = _unlockedBadges.contains(badge.label);
            return AnimatedOpacity(
              duration: const Duration(milliseconds: 400),
              opacity: isUnlocked ? 1 : 0.4,
              child: Chip(
                avatar: CircleAvatar(
                  backgroundColor: isUnlocked ? Colors.deepPurple : Colors.grey.shade400,
                  child: Icon(
                    badge.icon,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                label: Text('${badge.label}\n(${badge.unlockAt} doğru)'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTipsCard() {
    final tips = [
      'Kazanılan her 5 puanla yeni yıldızlar seni bekliyor.',
      'Uzun doğru serileri yeni rozetlerin kilidini açar!',
      'Farklı çarpım sonuçlarını incelemek için soruyu değiştir.',
      'Arkadaşlarınla yarış: En yüksek seriyi kim yapacak?'
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Eğlenceli İpuçları',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...tips.map(
              (tip) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.deepPurple),
                    const SizedBox(width: 8),
                    Expanded(child: Text(tip)),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _Badge {
  const _Badge(this.label, this.icon, this.unlockAt);

  final String label;
  final IconData icon;
  final int unlockAt;
}

class _ProgressStat extends StatelessWidget {
  const _ProgressStat({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(title),
      ],
    );
  }
}

class _AnswerOption extends StatelessWidget {
  const _AnswerOption({
    required this.value,
    required this.isSelected,
    required this.isCorrectAnswer,
    required this.isLocked,
    required this.onTap,
  });

  final int value;
  final bool isSelected;
  final bool isCorrectAnswer;
  final bool isLocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool showResult = isLocked;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    Color backgroundColor = Colors.white;
    Color borderColor = Colors.deepPurple.shade100;
    Color textColor = Colors.deepPurple;

    if (showResult) {
      if (isCorrectAnswer) {
        backgroundColor = Colors.green.shade100;
        borderColor = Colors.green;
        textColor = Colors.green.shade900;
      } else if (isSelected) {
        backgroundColor = Colors.red.shade100;
        borderColor = Colors.red;
        textColor = Colors.red.shade900;
      } else {
        backgroundColor = Colors.grey.shade100;
        borderColor = Colors.grey.shade400;
        textColor = Colors.grey.shade600;
      }
    } else if (isSelected) {
      backgroundColor = colorScheme.primaryContainer;
      borderColor = colorScheme.primary;
      textColor = colorScheme.onPrimaryContainer;
    }

    return GestureDetector(
      onTap: showResult ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Text(
          value.toString(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: textColor),
        ),
      ),
    );
  }
}
