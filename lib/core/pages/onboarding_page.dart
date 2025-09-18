import 'package:flutter/material.dart';
import 'package:flutter_onboarding_slider/flutter_onboarding_slider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shinobihaven/core/theme/app_theme.dart';
import 'package:shinobihaven/core/theme/theme_provider.dart';
import 'package:shinobihaven/core/utils/toast.dart';
import 'package:shinobihaven/core/utils/user_box_functions.dart';
import 'package:shinobihaven/core/widgets/theme_choice.dart';
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

  final OutlineInputBorder _border = OutlineInputBorder(
    borderSide: BorderSide(color: AppTheme.whiteGradient),
    borderRadius: BorderRadius.circular(15),
  );
  final OutlineInputBorder _focusedBorder = OutlineInputBorder(
    borderSide: BorderSide(color: AppTheme.gradient1),
    borderRadius: BorderRadius.circular(15),
  );

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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return OnBoardingSlider(
      headerBackgroundColor: AppTheme.whiteGradient,
      controllerColor: Theme.brightnessOf(context) == Brightness.dark
          ? AppTheme.whiteGradient
          : AppTheme.blackGradient,
      onFinish: () {
        if (!_userConsent) {
          Toast(
            context: context,
            title: 'User Consent Required',
            description: 'Please agree the above consent to proceed',
            type: ToastificationType.warning,
          );
          return;
        }
        setState(() {
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
        });
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LandingPage()),
          (route) => false,
        );
      },
      finishButtonText: "Let's Go",
      finishButtonTextStyle: TextStyle(
        color: AppTheme.gradient1,
        fontSize: 25,
        fontWeight: FontWeight.bold,
      ),
      finishButtonStyle: FinishButtonStyle(
        backgroundColor: AppTheme.primaryBlack,
        foregroundColor: AppTheme.whiteGradient,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      background: [SizedBox(), SizedBox(), SizedBox(), SizedBox()],
      centerBackground: true,
      totalPage: 4,
      speed: 0.9,
      pageBodies: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'ShinobiHaven',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.gradient1,
                      letterSpacing: 1.2,
                      shadows: [
                        Shadow(
                          color: AppTheme.gradient1.withAlpha(51),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Text(
                'Discover and watch thousands of anime episodes and movies. Enjoy seamless streaming and a personalized experience.',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            _focusNode.unfocus();
          },
          child: SingleChildScrollView(
            child: Container(
              width: size.width,
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                spacing: 8,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What should we call you?',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.gradient1,
                          letterSpacing: 1.2,
                          shadows: [
                            Shadow(
                              color: AppTheme.gradient1.withAlpha(51),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(15),
                    child: TextField(
                      controller: _nameController,
                      focusNode: _focusNode,
                      cursorColor: AppTheme.gradient1,
                      style: TextStyle(fontSize: 16),
                      onSubmitted: (query) {},
                      decoration: InputDecoration(
                        hintText: _namePlaceholders.elementAt(
                          _currentProfileChoice,
                        ),
                        hintStyle: TextStyle(
                          // color: AppTheme.whiteGradient.withValues(alpha: 0.65),
                          fontSize: 16,
                        ),
                        labelText: 'Enter a Username',
                        labelStyle: TextStyle(
                          color: Theme.brightnessOf(context) == Brightness.dark
                              ? AppTheme.whiteGradient
                              : AppTheme.blackGradient,
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        border: _border,
                        enabledBorder: _border,
                        focusedBorder: _focusedBorder,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 18,
                        ),
                      ),
                    ),
                  ),
                  Text('Choose a profile', style: TextStyle(fontSize: 18)),
                  SizedBox(
                    // height: size.height * 0.5,
                    width: size.width,
                    child: SingleChildScrollView(
                      child: Wrap(
                        alignment: WrapAlignment.spaceEvenly,
                        spacing: 15,
                        runSpacing: 15,
                        children: List.generate(_assetsPath.length, (index) {
                          final asset = _assetsPath.elementAt(index);
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _focusNode.unfocus();
                                _currentProfileChoice = index;
                              });
                            },
                            child: Container(
                              height: size.width / 4,
                              width: size.width / 4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: _currentProfileChoice == index
                                    ? Border.all(
                                        color: AppTheme.gradient1,
                                        width: 5,
                                      )
                                    : null,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(100),
                                child: Image.asset(
                                  asset,
                                  height: 95,
                                  width: 95,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  SizedBox(),
                ],
              ),
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Spacer(),
              Column(
                spacing: 15,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Make Yourself Home',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'How would like your app?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
              Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ThemeChoice(
                    currentThemeChoice: _currentThemeChoice,
                    title: 'Light Mode',
                    titleTextColor: AppTheme.blackGradient,
                    themeColor: AppTheme.whiteGradient,
                    themeMode: 0,
                    onTap: () {
                      setState(() {
                        _currentThemeChoice = 0;
                        _setThemeMode(0);
                      });
                    },
                  ),
                  ThemeChoice(
                    currentThemeChoice: _currentThemeChoice,
                    title: 'Dark Mode',
                    titleTextColor: AppTheme.whiteGradient,
                    themeColor: AppTheme.blackGradient,
                    themeMode: 1,
                    onTap: () {
                      setState(() {
                        _currentThemeChoice = 1;
                        _setThemeMode(1);
                      });
                    },
                  ),
                  ThemeChoice(
                    currentThemeChoice: _currentThemeChoice,
                    title: 'System Choice',
                    themeColor: Theme.brightnessOf(context) == Brightness.light
                        ? AppTheme.whiteGradient
                        : AppTheme.blackGradient,
                    titleTextColor:
                        Theme.brightnessOf(context) == Brightness.dark
                        ? AppTheme.whiteGradient
                        : AppTheme.blackGradient,
                    themeMode: 2,
                    onTap: () {
                      setState(() {
                        _currentThemeChoice = 2;
                        _setThemeMode(2);
                      });
                    },
                  ),
                ],
              ),
              Spacer(flex: 2),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Column(
                spacing: 15,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Just a heads up!',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppTheme.gradient1,
                        size: 30,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'ShinobiHaven does not store any files on our server, we only linked to the media which is hosted on 3rd party services.',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SwitchListTile.adaptive(
                value: _userConsent,
                inactiveThumbColor: AppTheme.greyGradient,
                activeColor: AppTheme.whiteGradient,
                onChanged: (consent) {
                  setState(() {
                    _userConsent = consent;
                  });
                },
                activeTrackColor: AppTheme.gradient1,
                title: Text(
                  'I agree to the disclaimer',
                  style: TextStyle(fontSize: 18),
                ),
                subtitle: Text(
                  'And I will not use the app to access, distribute, or promote pirated or illegal content. I understand ShinobiHaven only links to third‑party hosts and I am responsible for my use.',
                ),
              ),
              Text(
                'Browse safely and enjoy your anime binge sessions without worries ❤️',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(),
            ],
          ),
        ),
      ],
    );
  }
}
