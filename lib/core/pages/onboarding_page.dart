import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_onboarding_slider/flutter_onboarding_slider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinobihaven/core/constants/accent_colors.dart';
import 'package:shinobihaven/core/theme/app_theme.dart';
import 'package:shinobihaven/core/theme/theme_provider.dart';
import 'package:shinobihaven/core/utils/toast.dart';
import 'package:shinobihaven/core/utils/user_box_functions.dart';
import 'package:shinobihaven/features/anime/common/view/pages/landing_page.dart';
import 'package:toastification/toastification.dart';

class OnBoardingPage extends ConsumerStatefulWidget {
  const OnBoardingPage({super.key});

  @override
  ConsumerState<OnBoardingPage> createState() => _OnBoardingPageState();
}

class _OnBoardingPageState extends ConsumerState<OnBoardingPage> {
  late final TextEditingController _nameController;
  late final FocusNode _focusNode;

  final List<String> _assetsPath = [
    'assets/images/hashirama.jpg',
    'assets/images/jiraiya.jpg',
    'assets/images/kakashi.jpg',
    'assets/images/obito.jpg',
    'assets/images/naruto.jpg',
    'assets/images/sasuke.jpg',
    'assets/images/sakura.jpg',
    'assets/images/tenten.jpg',
    'assets/images/rocklee.jpg',
    'assets/images/neji.jpg',
  ];

  final List<String> _namePlaceholders = [
    'Hashirama Senju',
    'Jiraiya Sensei',
    'Kakashi Sensei',
    'Obito Uchiha',
    'Naruto Uzumaki',
    'Sasuke Uchiha',
    'Sakura Haruno',
    'Tenten',
    'Rock Lee',
    'Neji Hyuga',
  ];

  int _currentThemeChoice = 1;
  int _currentProfileChoice = 0;

  bool _userConsent = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _setThemeMode(int mode) {
    ref.read(themeModeProvider.notifier).setTheme(mode);
  }

  void _setAccentColor(Color accentColor) {
    ref.read(themeModeProvider.notifier).setAccentColor(accentColor);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final accentColor = ref.watch(themeModeProvider.notifier).getAccentColor();

    return Scaffold(
      body: OnBoardingSlider(
        headerBackgroundColor: Theme.of(context).scaffoldBackgroundColor,
        controllerColor: AppTheme.gradient1,
        skipIcon: const Icon(
          Icons.arrow_forward_rounded,
          color: Colors.white,
          size: 28,
        ),
        onFinish: () {
          if (!_userConsent) {
            Toast(
              context: context,
              title: 'Sensei, hold on!',
              description:
                  'Please agree to the disclaimer to start your journey.',
              type: ToastificationType.warning,
            );
            return;
          }
          UserBoxFunctions.toggleDarkMode(_currentThemeChoice);
          UserBoxFunctions.setUserName(
            _nameController.text.isEmpty
                ? _namePlaceholders.elementAt(_currentProfileChoice)
                : _nameController.text,
          );
          UserBoxFunctions.setUserProfile(
            _assetsPath.elementAt(_currentProfileChoice),
          );
          UserBoxFunctions.markFirstSetup();

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LandingPage()),
            (route) => false,
          );
        },
        finishButtonText: "Start Journey",
        finishButtonTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
        finishButtonStyle: FinishButtonStyle(
          backgroundColor: AppTheme.gradient1,
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        background: [
          _onboardingBg('assets/images/onboarding_poster.png', size),
          _onboardingBg(_assetsPath[_currentProfileChoice], size),
          const SizedBox.shrink(),
          const SizedBox.shrink(),
        ],
        totalPage: 4,
        speed: 1.5,
        pageBodies: [
          _onboardingPage(
            title: 'Welcome to',
            subtitle: 'ShinobiHaven',
            description:
                'Your ultimate destination for everything anime. Stream, track, and discover with a premium experience designed for true fans.',
            isTitleGradient: true,
          ),
          _buildProfilePage(size),
          _buildThemePage(accentColor),
          _onboardingPage(
            title: 'Just a heads up!',
            subtitle: 'Disclaimer',
            centered: true,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.gradient1.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: AppTheme.gradient1,
                        size: 32,
                      ),
                      const SizedBox(width: 15),
                      const Expanded(
                        child: Text(
                          'ShinobiHaven links to third-party content. We do not host any files on our servers.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                SwitchListTile.adaptive(
                  value: _userConsent,
                  activeThumbColor: AppTheme.gradient1,
                  onChanged: (v) => setState(() => _userConsent = v),
                  title: const Text(
                    'I agree to the terms',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'I will use this app responsibly and follow local laws.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _onboardingBg(String asset, Size size) {
    final isDesktop = size.width > 900;
    final dynamicHeight = isDesktop ? size.height * 0.6 : 500.0;

    return Stack(
      children: [
        Container(
          width: size.width,
          height: dynamicHeight,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(asset),
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
        ),
        // Subtle Blur for depth without losing detail
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Container(
              color: Colors.black.withAlpha(100),
            ),
          ),
        ),
        // Sophisticated Gradient
        Container(
          width: size.width,
          height: dynamicHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withAlpha(150),
                Colors.transparent,
                AppTheme.blackGradient.withAlpha(200),
                AppTheme.blackGradient,
              ],
              stops: const [0.0, 0.3, 0.8, 1.0],
            ),
          ),
        ),
      ],
    );
  }

  Widget _onboardingPage({
    required String title,
    required String subtitle,
    String? description,
    bool isTitleGradient = false,
    Widget? child,
    bool centered = false,
  }) {
    final size = MediaQuery.sizeOf(context);
    final isDesktop = size.width > 900;
    final topSpacing = isDesktop ? size.height * 0.45 : 350.0;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isDesktop ? 800 : double.infinity),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: centered
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!centered) SizedBox(height: topSpacing),
              Text(
                title,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: isDesktop ? 52 : 42,
                  fontWeight: FontWeight.w900,
                  color: isTitleGradient ? AppTheme.gradient1 : null,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              if (description != null)
                Text(
                  description,
                  style: TextStyle(
                    fontSize: isDesktop ? 18 : 16,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
              const SizedBox(height: 20),
              if (child != null) child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePage(Size size) {
    final isDesktop = size.width > 900;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isDesktop ? 800 : double.infinity),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Spacer(),
              Text(
                'IDENTIFY YOURSELF',
                style: TextStyle(
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppTheme.gradient1,
                ),
              ),
              const Text(
                'Custom Profile',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 25),
              // Prominent profile preview with animation
              Align(
                alignment: Alignment.centerLeft,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: Container(
                    key: ValueKey<int>(_currentProfileChoice),
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.gradient1,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.gradient1.withAlpha(100),
                          blurRadius: 25,
                          spreadRadius: 2,
                        ),
                      ],
                      image: DecorationImage(
                        image: AssetImage(_assetsPath[_currentProfileChoice]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              TextField(
                controller: _nameController,
                focusNode: _focusNode,
                onTap: () {
                  setState(() {
                    _focusNode.hasFocus
                        ? _focusNode.unfocus()
                        : _focusNode.requestFocus();
                  });
                },
                decoration: InputDecoration(
                  labelText: !_focusNode.hasFocus
                      ? _namePlaceholders[_currentProfileChoice]
                      : 'Username',
                  labelStyle: TextStyle(color: AppTheme.whiteGradient, fontSize: 16),
                  hintText: _namePlaceholders[_currentProfileChoice],
                  filled: true,
                  fillColor: AppTheme.surfaceColor(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(
                      color: AppTheme.gradient1.withAlpha(50),
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(
                      color: AppTheme.gradient1.withAlpha(50),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: AppTheme.gradient1, width: 2),
                  ),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Pick an Avatar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  itemCount: _assetsPath.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: size.width > 600 ? (isDesktop ? 10 : 6) : 4,
                    mainAxisSpacing: 5,
                    crossAxisSpacing: 5,
                  ),
                  itemBuilder: (context, index) {
                    final isSelected = _currentProfileChoice == index;
                    return GestureDetector(
                      onTap: () => setState(() => _currentProfileChoice = index),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.gradient1
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          backgroundImage: AssetImage(_assetsPath[index]),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemePage(Color accentColor) {
    final size = MediaQuery.sizeOf(context);
    final isDesktop = size.width > 900;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isDesktop ? 800 : double.infinity),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50),
              Text(
                'AESTHETICS',
                style: TextStyle(
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppTheme.gradient1,
                ),
              ),
              const Text(
                'Visual Style',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  _styleCard('Light', Icons.wb_sunny_outlined, 0),
                  const SizedBox(width: 15),
                  _styleCard('Dark', Icons.nightlight_round_outlined, 1),
                  const SizedBox(width: 15),
                  _styleCard('System', Icons.settings_suggest_outlined, 2),
                ],
              ),
              const SizedBox(height: 30),
              const Text(
                'Accent Color',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: GridView.builder(
                  shrinkWrap: true,
                  itemCount: AccentColors.accentColors.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isDesktop ? 12 : 6,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemBuilder: (context, index) {
                    final color = AccentColors.accentColors[index];
                    final isSelected = color.toARGB32() == accentColor.toARGB32();
                    return GestureDetector(
                      onTap: () => _setAccentColor(color),
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 16)
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _styleCard(String title, IconData icon, int mode) {
    final isSelected = _currentThemeChoice == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _currentThemeChoice = mode;
          _setThemeMode(mode);
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.gradient1
                : AppTheme.gradient1.withAlpha(20),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : AppTheme.gradient1),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.gradient1,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
