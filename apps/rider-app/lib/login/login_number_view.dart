import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:hive/hive.dart';
import 'package:ridy/config.dart';
import 'package:ridy/generated/l10n.dart';
import 'package:ridy/graphql/generated/graphql_api.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:velocity_x/velocity_x.dart';
import '../login/login_verification_code_view.dart';

class LoginNumberView extends StatefulWidget {
  const LoginNumberView({Key? key}) : super(key: key);

  @override
  _LoginNumberViewState createState() => _LoginNumberViewState();
}

class _LoginNumberViewState extends State<LoginNumberView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String phoneNumber = "";
  String countryCode = defaultCountryCode;
  bool agreedToTerms = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: EdgeInsets.only(
          left: 8,
          right: 8,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 8),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text(
              S.of(context).login_heading_first_line,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(S.of(context).login_heading_second_line,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text(
              S.of(context).login_heading_third_line,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                CountryCodePicker(
                  initialSelection: countryCode,
                  onChanged: (code) => countryCode = code.dialCode!,
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: TextFormField(
                    decoration: InputDecoration(
                      hintText: S.of(context).login_cell_number_textfield_hint,
                    ),
                    onChanged: (value) => phoneNumber = value,
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return S.of(context).login_cell_number_empty_error;
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            if (loginTermsAndConditionsUrl.isNotEmpty)
              Row(
                children: [
                  Checkbox(
                      value: agreedToTerms,
                      onChanged: (value) =>
                          setState(() => agreedToTerms = value ?? false)),
                  RichText(
                      text: TextSpan(children: [
                    const TextSpan(
                        style: TextStyle(color: Colors.black),
                        text: "I have read and agree with "),
                    TextSpan(
                        style: const TextStyle(color: Colors.blue),
                        text: "Terms & Conditions",
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            launch(loginTermsAndConditionsUrl);
                          })
                  ])),
                ],
              ).pOnly(top: 8),
            Container(
              padding: const EdgeInsets.only(top: 20),
              width: double.infinity,
              child: Mutation(
                  options: MutationOptions(document: LOGIN_MUTATION_DOCUMENT),
                  builder: (RunMutation runMutation, QueryResult? result) {
                    return ElevatedButton(
                        onPressed: !agreedToTerms &&
                                loginTermsAndConditionsUrl.isNotEmpty
                            ? null
                            : () async {
                                if (!kIsWeb) {
                                  await FirebaseAuth.instance.verifyPhoneNumber(
                                    phoneNumber: countryCode + phoneNumber,
                                    verificationCompleted:
                                        (PhoneAuthCredential credential) async {
                                      final UserCredential cr =
                                          await FirebaseAuth.instance
                                              .signInWithCredential(credential);
                                      final String firebaseToken =
                                          await cr.user!.getIdToken();
                                      final QueryResult qe = await runMutation(
                                              {"firebaseToken": firebaseToken})
                                          .networkResult!;
                                      final String jwt =
                                          Login$Mutation.fromJson(qe.data!)
                                              .login
                                              .jwtToken;
                                      final Box box =
                                          await Hive.openBox('user');
                                      box.put("jwt", jwt);
                                      Navigator.pop(context);
                                    },
                                    verificationFailed:
                                        (FirebaseAuthException e) {},
                                    codeSent: (String verificationId,
                                        int? resendToken) {
                                      Navigator.pop(context);
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        constraints:
                                            const BoxConstraints(maxWidth: 600),
                                        builder: (context) {
                                          return LoginVerificationCodeView(
                                              verificationId: verificationId);
                                        },
                                      );
                                    },
                                    codeAutoRetrievalTimeout:
                                        (String verificationId) {},
                                  );
                                } else {
                                  await FirebaseAuth.instance
                                      .signInWithPhoneNumber(
                                          countryCode + phoneNumber);
                                }
                              },
                        child: Text(
                          S.of(context).action_next,
                          style: const TextStyle(fontSize: 16),
                        ));
                  }),
            )
          ],
        ),
      ),
    );
  }
}
