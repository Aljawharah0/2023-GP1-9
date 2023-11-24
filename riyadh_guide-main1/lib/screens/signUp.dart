import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:riyadh_guide/screens/signin.dart';
import 'package:riyadh_guide/screens/welcome_screen.dart';
import 'package:riyadh_guide/screens/reusable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  TextEditingController _passwordTextController = TextEditingController();
  TextEditingController _emailTextController = TextEditingController();
  TextEditingController _userNameTextController = TextEditingController();
  FocusNode _passwordFocusNode = FocusNode();
  int _passwordStrength = 0;

  List<String> _banks = ['بنك الراجحي', 'بنك الاهلي', 'بنك ساب'];
  List<String> _selectedBanks = [];
  String? _selectedBank;
  //for email checking
  String? _emailValidationResult;
  //for immediately checking
  String? _userNameErrorMessage;
  String? _emailErrorMessage;
  String? _ErrorMessage;

  final _formKey = GlobalKey<FormState>();
  //bool _buttonClicked = false;
  bool _showImmediateErrors = true;

  @override
  void dispose() {
    // Dispose of the FocusNode when the widget is disposed
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "حساب جديد",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          // White background
          Container(
            height: MediaQuery.of(context).size.height * 0.28,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/icons/roro.JPG'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // White background and content
          Container(
            margin:
                EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.25),
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            // Content of the screen
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.start, // Align fields to the top
                    children: <Widget>[
                      const SizedBox(height: 10),
                      reusableTextField(
                        "اسم المستخدم",
                        Icons.person_outline,
                        false,
                        _userNameTextController,
                        validator: (value) {
                          //return _userNameErrorMessage;
                          return _showImmediateErrors
                              ? _userNameErrorMessage
                              : null;
                        },
                        onChanged: (value) {
                          setState(() {
                            // _buttonClicked = false;
                            _userNameErrorMessage =
                                null; // Clear previous error message
                            _emailErrorMessage = null;
                            _showImmediateErrors =
                                true; // Set the flag to true when user types
                          });

                          // Perform additional checks and update _userNameErrorMessage if needed

                          if (value != null &&
                              value.startsWith(RegExp(r'[0-9]'))) {
                            setState(() {
                              _userNameErrorMessage = 'يجب أن لا يبدأ برقم';
                            });
                          } else if (value != null &&
                              !RegExp(r'^[a-zA-Z\u0600-\u06FF][a-zA-Z0-9._\u0600-\u06FF]*$')
                                  .hasMatch(value)) {
                            setState(() {
                              _userNameErrorMessage =
                                  'يجب أن يحتوي على أحرف و أرقام ويمكن أن يتضمن "." أو "_"';
                            });
                          }
                        },
                      ),

                      // Display the error message
                      Text(
                        _userNameErrorMessage ?? '',
                        style: TextStyle(color: Colors.red),
                      ),
                      //  const SizedBox(height: 3),
                      reusableTextField(
                        "البريد الالكتروني",
                        Icons.email_outlined,
                        false,
                        _emailTextController,
                        validator: (value) {
                          // return _emailErrorMessage;
                          return _showImmediateErrors
                              ? _emailErrorMessage
                              : null;
                        },
                        onChanged: (value) async {
                          final result = await validateEmail(value);
                          setState(() {
                            _emailErrorMessage = result;
                            _showImmediateErrors =
                                true; // Set the flag to true when user types
                          });
                        },
                      ),
                      Text(
                        _emailErrorMessage ??
                            '', // Display an empty string if there's no error
                        style: TextStyle(color: Colors.red),
                      ),
                      //const SizedBox(height: 3),
                      reusableTextField(
                        "كلمة المرور",
                        Icons.lock_outlined,
                        true,
                        _passwordTextController,
                        validator: (value) {
                          if (_passwordFocusNode.hasFocus) {
                            if (value == null || value.isEmpty) {
                              return 'يرجى إدخال كلمة المرور';
                            } else if (value.length < 8) {
                              return 'يجب أن تكون كلمة المرور على الأقل 8 خانات';
                            } else if (!RegExp(
                                    r'(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#$%^&*()_+{}|:"<>?~,-.])')
                                .hasMatch(value)) {
                              return 'يجب أن تحتوي كلمة المرور على حرف كبير، رقم، وحرف خاص';
                            }
                          }
                          return null;
                        },
                        onChanged: (value) {
                          if (_passwordFocusNode.hasFocus) {
                            // Update the password strength based on your criteria
                            int strength = calculatePasswordStrength(value);
                            setState(() {
                              _passwordStrength = strength;
                            });
                          }
                        },
                        focusNode: _passwordFocusNode,
                      ),
                      // Password Strength Indicator
                      if (_passwordFocusNode.hasFocus)
                        Row(
                          children: <Widget>[
                            Icon(
                              _passwordStrength >= 8
                                  ? Icons.check_circle
                                  : Icons.remove_circle,
                              color: _passwordStrength >= 8
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            SizedBox(width: 5),
                            Text(
                              _passwordStrength >= 8
                                  ? 'كلمة المرور قوية'
                                  : 'كلمة المرور ضعيفة',
                              style: TextStyle(
                                color: _passwordStrength >= 8
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'اختر البطاقات التي لديك للحصول على أفضل العروض:',
                            style: TextStyle(
                              color: Color.fromARGB(255, 106, 57, 117),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // Add the bank selection dropdown here
                          InkWell(
                            onTap: () {
                              _showBankSelectionDialog(context);
                            },
                            child: Container(
                              padding: EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Color.fromARGB(255, 106, 57, 117)),
                                borderRadius: BorderRadius.circular(40.0),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _selectedBank ?? 'البطاقات البنكية',
                                    style: TextStyle(
                                        color:
                                            Color.fromARGB(255, 106, 57, 117),
                                        fontSize: 16),
                                  ),
                                  Icon(Icons.arrow_drop_down,
                                      color: const Color.fromARGB(
                                          255, 106, 57, 117)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _ErrorMessage ?? '',
                        style: TextStyle(color: Colors.red),
                      ),
                      firebaseUIButton(context, "انشاء حساب جديد", () {
                        setState(() {
                          _showImmediateErrors = false;
                        });
                        // Check if any of the fields is null or empty
                        if (_userNameTextController.text == null ||
                            _userNameTextController.text.isEmpty ||
                            _emailTextController.text == null ||
                            _emailTextController.text.isEmpty ||
                            _passwordTextController.text == null ||
                            _passwordTextController.text.isEmpty) {
                          setState(() {
                            // Set a general error message
                            _ErrorMessage = 'يجب تعبئة جميع الحقول المطلوبة';
                          });
                          return; // Return without further processing
                        }

                        // Validate the form
                        // Validate the form
                        if (_userNameErrorMessage != null ||
                            _emailErrorMessage != null ||
                            _passwordTextController.text.length < 8) {
                          return; // Return without further processing if there are errors
                        }
                        // if (_formKey.currentState!.validate()) {
                        // Include the selected banks in your authentication process
                        FirebaseAuth.instance
                            .createUserWithEmailAndPassword(
                          email: _emailTextController.text,
                          password: _passwordTextController.text,
                        )
                            .then((value) {
                          print("انشاء حساب جديد");
                          // Save user information to Firestore
                          saveUserData(
                              value.user?.uid,
                              _userNameTextController.text,
                              _emailTextController.text);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WelcomeScreen(),
                            ),
                          );
                        }).onError((error, stackTrace) {
                          print("Error ${error.toString()}");
                        });
                        //}
                      }),

                      // Clickable text to navigate to the sign-in screen
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SignInScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'لديك حساب؟ تسجيل الدخول',
                          style: TextStyle(
                              color: Color.fromARGB(255, 83, 56, 97),
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                      ),
                      SizedBox(height: 3),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBankSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("البطاقات البنكية"),
          content: Container(
            width: double.minPositive,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _banks.length,
              itemBuilder: (BuildContext context, int index) {
                String bank = _banks[index];
                bool isSelected = _selectedBanks.contains(bank);

                return ListTile(
                  title: Text(bank),
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedBanks.remove(bank);
                      } else {
                        _selectedBanks.add(bank);
                      }
                    });
                  },
                  leading: Checkbox(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (isSelected) {
                          _selectedBanks.remove(bank);
                        } else {
                          _selectedBanks.add(bank);
                        }
                      });
                    },
                  ),
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text("تم"),
              onPressed: () {
                /*setState(() {
                  _selectedBank = _selectedBanks.isNotEmpty
                      ? _selectedBanks.join(', ')
                      : null;
                });*/
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

bool _containsUppercase(String value) {
  return value.contains(new RegExp(r'[A-Z]'));
}

bool _containsLowercase(String value) {
  return value.contains(new RegExp(r'[a-z]'));
}

bool _containsSpecialChar(String value) {
  return value.contains(new RegExp(r'[!@#$%^&*()_+{}|:"<>?~,-.]'));
}

int calculatePasswordStrength(String password) {
  // Implement your own logic for calculating password strength
  // For example, you can assign points for each condition met
  // and set a threshold for considering the password strong
  return password.length >= 8 &&
          _containsUppercase(password) &&
          _containsLowercase(password) &&
          _containsSpecialChar(password)
      ? 10
      : 0;
}

Future<String?> validateEmail(String? email) async {
  if (email == null || email.isEmpty) {
    return 'يرجى إدخال البريد الإلكتروني';
  } else if (!isValidEmail(email)) {
    return 'البريد الإلكتروني غير صالح';
  } else {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: email, password: 'somePasswordForValidation');

      // If the email is successfully created (not used before),
      // delete the temporary user and return null
      await userCredential.user?.delete();
      return null;
    } catch (e) {
      print("FirebaseAuthException code: ${(e as FirebaseAuthException).code}");
      // If there is an error, check the error code
      if (e.code == 'email-already-in-use') {
        return 'هذا البريد الإلكتروني مستخدم من قبل';
      }
      // Handle other errors if needed
      return 'حدث خطأ أثناء التحقق من البريد الإلكتروني';
    }
  }
}

// Function to save user data to Firestore
Future<void> saveUserData(String? userId, String username, String email) async {
  try {
    await FirebaseFirestore.instance.collection('user').doc(userId).set({
      'name': username,
      'email': email,
      // Add other fields as needed
    });
  } catch (e) {
    print("Error saving user data: $e");
  }
}
