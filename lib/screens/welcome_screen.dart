import 'package:flutter/material.dart';
import 'package:pursenal/app/global/dimensions.dart';
import 'package:pursenal/screens/profile_entry_screen.dart';
import 'package:pursenal/l10n/app_localizations.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  double _opacity1 = 0.0;
  double _opacity2 = 0.0;
  double _opacity3 = 0.0;
  double _opacity4 = 0.0;
  double _opacity5 = 0.0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() => _opacity1 = 1.0);
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      setState(() => _opacity2 = 1.0);
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      setState(() => _opacity3 = 1.0);
    });
    Future.delayed(const Duration(milliseconds: 2000), () {
      setState(() => _opacity4 = 1.0);
    });
    Future.delayed(const Duration(milliseconds: 2500), () {
      setState(() => _opacity5 = 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Center(
          child: SizedBox(
            width: smallWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 78),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedOpacity(
                          duration: const Duration(seconds: 1),
                          opacity: _opacity1,
                          child: Text(
                            AppLocalizations.of(context)!.welcomeTo,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedOpacity(
                          duration: const Duration(seconds: 1),
                          opacity: _opacity2,
                          child: Text(
                            AppLocalizations.of(context)!.pursenal,
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(fontSize: 40),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        minRadius: 50,
                        child: Center(
                          child: Image.asset(
                            "assets/icons/app_logo.png",
                            width: 128,
                            height: 128,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                AnimatedOpacity(
                  duration: const Duration(seconds: 1),
                  opacity: _opacity3,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      AppLocalizations.of(context)!.appIntroduction,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(height: 1.5),
                    ),
                  ),
                ),
                const Spacer(),
                AnimatedOpacity(
                  duration: const Duration(seconds: 1),
                  opacity: _opacity4,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      AppLocalizations.of(context)!.createInitialProfile,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedOpacity(
                  duration: const Duration(seconds: 1),
                  opacity: _opacity5,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () => Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileEntryScreen(),
                          ),
                          (s) => false),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.goToProfileCreation,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                    color: Theme.of(context).primaryColor),
                          ),
                          Icon(Icons.keyboard_double_arrow_right,
                              size: 50, color: Theme.of(context).primaryColor)
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
