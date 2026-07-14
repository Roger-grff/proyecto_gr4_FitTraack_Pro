import 'package:flutter/material.dart';
import 'package:proyecto_gr4/features/auth/presentation/screens/login_screen.dart';
import 'package:proyecto_gr4/features/onboarding/presentation/widgets/onboarding_page.dart';
import 'package:proyecto_gr4/features/onboarding/presentation/widgets/page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pagesData = [
    {
      'title': 'Bienvenido a FitTrack Pro',
      'description':
          'Lleva el control de tu actividad física, alimentación y progreso desde una sola aplicación.',
      'icon': Icons.fitness_center_rounded,
    },
    {
      'title': 'Registra tus actividades',
      'description':
          'Guarda tus recorridos mediante GPS, consulta estadísticas y mantén un historial completo de tus entrenamientos.',
      'icon': Icons.map_rounded,
    },
    {
      'title': 'Alcanza tus metas',
      'description':
          'Visualiza tu progreso, mantente motivado y mejora tus hábitos saludables con FitTrack Pro.',
      'icon': Icons.emoji_events_rounded,
    },
  ];

  void _onSkip() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _onNext() {
    if (_currentPage == _pagesData.length - 1) {
      _onSkip();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pagesData.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final data = _pagesData[index];
                  return OnboardingPageWidget(
                    title: data['title'] as String,
                    description: data['description'] as String,
                    icon: data['icon'] as IconData,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _onSkip,
                    child: Text(
                      'Omitir',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ),
                  PageIndicator(
                    count: _pagesData.length,
                    currentIndex: _currentPage,
                  ),
                  ElevatedButton(
                    onPressed: _onNext,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      _currentPage == _pagesData.length - 1
                          ? 'Comenzar'
                          : 'Siguiente',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
