import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'
    hide PhoneAuthProvider, EmailAuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_localizations/firebase_ui_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gradufsc/constants.dart';
import 'package:gradufsc/screens/cagr_auth.dart';
import 'package:gradufsc/screens/email_verification.dart';
import 'package:gradufsc/screens/initial.dart';
import 'package:gradufsc/screens/moodle_auth.dart';
import 'package:gradufsc/screens/moodle_token_auth.dart';

import '../constants.dart';
import '../decorations.dart';

final actionCodeSettings = ActionCodeSettings(
  url:
      'https://gradufsc2023.firebaseapp.com', //https://gradufsc2023.firebaseapp.com', //https://gradufsc.page.link/dmCn',
  // handleCodeInApp: false,
  // androidMinimumVersion: '1',
  // androidPackageName: 'com.rafamadaloz.gradufsc',
  // iOSBundleId: 'com.rafamadaloz.gradufsc',
);
final emailLinkProviderConfig = EmailLinkAuthProvider(
  actionCodeSettings: actionCodeSettings,
);

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final auth = FirebaseAuth.instance;

  String get initialRoute {
    if (auth.currentUser == null) {
      return '/sign-in';
    }

    if (!auth.currentUser!.emailVerified && auth.currentUser!.email != null) {
      return '/verify-email';
    }

    return '/initial';
  }

  @override
  Widget build(BuildContext context) {
    final buttonStyle = ButtonStyle(
      padding: MaterialStateProperty.all(const EdgeInsets.all(12)),
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      // foregroundColor: MaterialStateProperty.all<Color>(primaryColor),
    );

    final mfaAction = AuthStateChangeAction<MFARequired>(
      (context, state) async {
        final nav = Navigator.of(context);

        await startMFAVerification(
          resolver: state.resolver,
          context: context,
        );

        nav.pushReplacementNamed('/initial');
      },
    );

    return MaterialApp(
      supportedLocales: const [
        // Locale('en'), // English
        // Locale('es'), // Spanish
        Locale('pt'),
      ],
      theme: ThemeData(
        // primaryColor: Colors.blue[400],
        // shadowColor: Colors.blue[700],
        tabBarTheme: TabBarTheme(
          labelColor: Colors.white, // Cor do texto dos rótulos selecionados
          unselectedLabelColor:
              Colors.white, // Cor do texto dos rótulos não selecionados
        ),
        appBarTheme: const AppBarTheme(
          foregroundColor: Colors.white,
          backgroundColor:
              primaryColor, // define a cor de fundo padrão do AppBar como azul
        ),
        brightness: Brightness.light,
        visualDensity: VisualDensity.standard,
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
              // borderSide: BorderSide(color: primaryColor),
              ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(style: buttonStyle),
        textButtonTheme: TextButtonThemeData(style: buttonStyle),
        outlinedButtonTheme: OutlinedButtonThemeData(style: buttonStyle),
      ),
      initialRoute: initialRoute,
      routes: {
        '/sign-in': (context) {
          return SignInScreen(
            actions: [
              ForgotPasswordAction((context, email) {
                Navigator.pushNamed(
                  context,
                  '/forgot-password',
                  arguments: {'email': email},
                );
              }),
              AuthStateChangeAction<SignedIn>((context, state) {
                if (!state.user!.emailVerified) {
                  Navigator.pushNamed(context, '/verify-email');
                } else {
                  Navigator.pushReplacementNamed(context, '/initial');
                }
              }),
              AuthStateChangeAction<UserCreated>((context, state) {
                if (!state.credential.user!.emailVerified) {
                  Navigator.pushNamed(context, '/verify-email');
                } else {
                  Navigator.pushReplacementNamed(context, '/initial');
                }
              }),
              AuthStateChangeAction<CredentialLinked>((context, state) {
                if (!state.user.emailVerified) {
                  Navigator.pushNamed(context, '/verify-email');
                } else {
                  Navigator.pushReplacementNamed(context, '/initial');
                }
              }),
              mfaAction,
              EmailLinkSignInAction((context) {
                Navigator.pushReplacementNamed(context, '/email-link-sign-in');
              }),
            ],
            styles: const {
              EmailFormStyle(signInButtonVariant: ButtonVariant.filled),
            },
            headerBuilder: headerImage('assets/images/capelo.png'),
            sideBuilder: sideImage('assets/images/capelo.png'),
            // subtitleBuilder: (context, action) {
            //   return Padding(
            //     padding: const EdgeInsets.only(bottom: 8),
            //     child: Text(
            //       action == AuthAction.signIn
            //           ? 'Bem-vindo ao Gradufsc! Faça login para continuar.'
            //           : 'Bem-vindo ao Gradufsc! Crie uma conta para continuar',
            //     ),
            //   );
            // },
            // footerBuilder: (context, action) {
            //   return Center(
            //     child: Padding(
            //       padding: const EdgeInsets.only(top: 16),
            //       child: Text(
            //         action == AuthAction.signIn
            //             ? 'By signing in, you agree to our terms and conditions.'
            //             : 'By registering, you agree to our terms and conditions.',
            //         style: const TextStyle(color: Colors.grey),
            //       ),
            //     ),
            //   );
            // },
          );
        },
        '/verify-email': (context) {
          return EmailVerificationScreenCustom(
            headerBuilder: headerIcon(Icons.verified),
            sideBuilder: sideIcon(Icons.verified),
            actionCodeSettings: actionCodeSettings,
            actions: [
              AuthCancelledAction((context) {
                FirebaseUIAuth.signOut(context: context);
                Navigator.pushReplacementNamed(context, '/sign-in');
              }),
            ],
          );
        },
        '/phone': (context) {
          return PhoneInputScreen(
            actions: [
              SMSCodeRequestedAction((context, action, flowKey, phone) {
                Navigator.of(context).pushReplacementNamed(
                  '/sms',
                  arguments: {
                    'action': action,
                    'flowKey': flowKey,
                    'phone': phone,
                  },
                );
              }),
            ],
            headerBuilder: headerIcon(Icons.phone),
            sideBuilder: sideIcon(Icons.phone),
          );
        },
        '/sms': (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;

          return SMSCodeInputScreen(
            actions: [
              AuthStateChangeAction<SignedIn>((context, state) {
                Navigator.of(context).pushReplacementNamed('/initial');
              })
            ],
            flowKey: arguments?['flowKey'],
            action: arguments?['action'],
            headerBuilder: headerIcon(Icons.sms_outlined),
            sideBuilder: sideIcon(Icons.sms_outlined),
          );
        },
        '/forgot-password': (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;

          return ForgotPasswordScreen(
            email: arguments?['email'],
            headerMaxExtent: 200,
            headerBuilder: headerIcon(Icons.lock),
            sideBuilder: sideIcon(Icons.lock),
          );
        },
        '/email-link-sign-in': (context) {
          return EmailLinkSignInScreen(
            actions: [
              AuthStateChangeAction<SignedIn>((context, state) {
                Navigator.pushReplacementNamed(context, '/');
              }),
            ],
            provider: emailLinkProviderConfig,
            headerMaxExtent: 200,
            headerBuilder: headerIcon(Icons.link),
            sideBuilder: sideIcon(Icons.link),
          );
        },
        // '/cagr-auth': (context) {
        //   return const AuthCAGRPage();
        // },
        '/moodle-auth': (context) {
          return const MoodleAuthPage();
        },
        '/moodle-login': (context) {
          return const MoodleLoginScreen();
        },
        '/initial': (context) {
          return const InitialScreen();
        },
        '/cagr-auth': (context) => const AuthCAGRPage(),
        '/moodle-token': (context) => MoodleTokenScreen(),
      },
      title: 'Gradufsc',
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt'),
      localizationsDelegates: [
        // FirebaseUILocalizations.withDefaultOverrides(const LabelOverrides()),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FirebaseUILocalizations.delegate,
      ],
    );
  }
}
