import 'package:flutter/material.dart';
import 'package:riyadh_guide/screens/favourites.dart';
import 'package:riyadh_guide/screens/home_screen.dart';
import 'package:riyadh_guide/screens/news.dart';
import 'package:riyadh_guide/screens/search.dart';
import 'package:riyadh_guide/screens/signin.dart';
import 'package:riyadh_guide/screens/welcome_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class account extends StatefulWidget {
  const account({super.key});

  @override
  State<account> createState() => _accountState();
}

class _accountState extends State<account> {
  int currentTab = 1;
  @override
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _cardsController = TextEditingController();
  final FirebaseAuth auth = FirebaseAuth.instance;
  String? _selectedcard;
    String uid = '';
  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  void fetchUserData() {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      uid = user.uid;

      FirebaseFirestore.instance
          .collection('user')
          .doc(uid)
          .get()
          .then((DocumentSnapshot documentSnapshot) {
        if (documentSnapshot.exists) {
          String username = documentSnapshot['name'];
          String email = documentSnapshot['email'];
          List<dynamic>? cards;

          Map<String, dynamic>? data =
              documentSnapshot.data() as Map<String, dynamic>?;
          if (data != null && data.containsKey('cards')) {
            cards = data['cards'];
          } else {
            cards = ['نافع', 'الانماء', 'قطاف'];
          }

          setState(() {
            _usernameController.text = username;
            _emailController.text = email;
            _cardsController.text = cards?.join(", ") ??
                ''; // Join the card values into a comma-separated string
          });
        }
      }).catchError((error) {
        // Handle error retrieving user data
      });
    }
  }

  bool hasSpecialCharacter(String value) {
    // Define a list of special characters
    List<String> specialCharacters = [
      '!',
      '@',
      '#',
      '\$',
      '%',
      '^',
      '&',
      '*',
      '_',
      '-',
      '(',
      ')',
      '\\',
      '?'
    ];

    // Check if the value contains any special character
    for (var character in specialCharacters) {
      if (value.contains(character)) {
        return true;
      }
    }

    return false;
  }

  void resetPassword() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String oldPassword = '';
        String newPassword = '';
        String authenticationErrorMessage = '';
        String newPasswordErrorMessage = '';

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('تغيير كلمة المرور'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'ادخل كلمة المرور القديمة',
                      ),
                      onChanged: (value) {
                        oldPassword = value;
                      },
                      obscureText: true,
                    ),
                    if (authenticationErrorMessage.isNotEmpty)
                      Visibility(
                        visible: authenticationErrorMessage.isNotEmpty,
                        maintainState: true,
                        child: Text(
                          authenticationErrorMessage,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 16.0,
                          ),
                        ),
                      ),
                    SizedBox(height: 16.0),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'ادخل كلمة المرور الجديدة',
                        errorText: newPasswordErrorMessage.isNotEmpty
                            ? newPasswordErrorMessage
                            : null,
                      ),
                      onChanged: (value) {
                        newPassword = value;
                      },
                      obscureText: true,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('الغاء'),
                ),
                Flexible(
                  child: TextButton(
                    onPressed: () {
                      // Validate new password
                      if (newPassword.isEmpty) {
                        setState(() {
                          newPasswordErrorMessage =
                              'كلمة المرور الجديدة لا يمكن أن تكون فارغة.';
                        });
                      } else if (newPassword.length < 8) {
                        setState(() {
                          newPasswordErrorMessage =
                              ' يجب أن تحتوي على 8 أحرف على الأقل.';
                        });
                      } else if (!hasSpecialCharacter(newPassword)) {
                        setState(() {
                          newPasswordErrorMessage =
                              ' يجب أن تحتوي على حرف خاص واحد.';
                        });
                      } else {
                        // Clear new password error message
                        setState(() {
                          newPasswordErrorMessage = '';
                        });

                        // Authenticate old password
                        User? user = FirebaseAuth.instance.currentUser;

                        if (user != null) {
                          String? email = user.email;

                          if (email != null) {
                            AuthCredential credential =
                                EmailAuthProvider.credential(
                                    email: email, password: oldPassword);

                            user
                                .reauthenticateWithCredential(credential)
                                .then((authResult) {
                              // Old password authentication successful
                              // Clear authentication error message
                              setState(() {
                                authenticationErrorMessage = '';
                              });

                              // Proceed with password update
                              user.updatePassword(newPassword).then((_) {
                                // Password updated successfully
                                Navigator.pop(context); // Close the dialog
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text('تم تغيير كلمة المرور'),
                                      content:
                                          Text('تم تحديث كلمة المرور بنجاح.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: Text('موافق'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }).catchError((error) {
                                // Handle error updating password
                                if (error is PlatformException) {
                                  String errorMessage =
                                      error.message ?? 'حدث خطأ.';
                                  Navigator.pop(context); // Close the dialog
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text('خطأ في تحديث كلمة المرور'),
                                        content: Text(errorMessage),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: Text('موافق'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                }
                              });
                            }).catchError((error) {
                              // Handle error authenticating old password
                              if (error is FirebaseAuthException) {
                                String errorMessage = 'كلمة المرور غير صحيحة';
                                setState(() {
                                  authenticationErrorMessage = errorMessage;
                                });
                              }
                            });
                          }
                        }
                      }
                    },
                    child: Text('تغيير'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Function to show the sign-out confirmation dialog
  void showSignOutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('تأكيد تسجيل الخروج'),
          content: Text('هل أنت متأكد أنك تريد تسجيل الخروج؟'),
          actions: <Widget>[
            TextButton(
              child: Text('إلغاء'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('موافق'),
              onPressed: () {
                signOut();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

// Sign-out function
  signOut() async {
    await auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
    // Show a snackbar indicating successful sign out
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم تسجيل الخروج بنجاح'),
        backgroundColor: Color.fromARGB(181, 203, 145, 210),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (uid == '') {
      return Scaffold(
        appBar: AppBar(
          title: Text('حسابي'),
          backgroundColor: Color.fromARGB(255, 211, 198, 226),
          automaticallyImplyLeading: false,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              currentTab = 0;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WelcomeScreen(),
                ),
              );
            });
          },
          child: Image.asset(
            'lib/icons/Logo.png',
          ),
          backgroundColor: Color.fromARGB(157, 165, 138, 182),
          elevation: 20.0,
//mini: true,
        ),
        bottomNavigationBar: BottomAppBar(
          notchMargin: 10,
          shape: CircularNotchedRectangle(),
          color: Color.fromARGB(157, 217, 197, 230),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            mainAxisSize: MainAxisSize.max,
            children: [
              Padding(
                padding: EdgeInsets.only(right: 10.0, left: 10.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.account_box),
                      onPressed: () {
                        setState(() {
                          currentTab = 1;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => account(),
                            ),
                          );
                        });
                      },
                      color: currentTab == 1 ? Colors.white : Colors.black,
                    ),
                    Text(
                      "حسابي",
                      style: TextStyle(
                          color: currentTab == 1 ? Colors.white : Colors.black),
                    )
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.search),
                      onPressed: () {
                        setState(() {
                          currentTab = 2;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => search(),
                            ),
                          );
                        });
                      },
                      color: currentTab == 2 ? Colors.white : Colors.black,
                    ),
                    Text(
                      "البحث",
                      style: TextStyle(
                          color: currentTab == 2 ? Colors.white : Colors.black),
                    )
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 30.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.newspaper),
                      onPressed: () {
                        setState(() {
                          currentTab = 3;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => news(),
                            ),
                          );
                        });
                      },
                      color: currentTab == 3 ? Colors.white : Colors.black,
                    ),
                    Text(
                      "أحداث اليوم",
                      style: TextStyle(
                          color: currentTab == 3 ? Colors.white : Colors.black),
                    )
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.favorite),
                      onPressed: () {
                        setState(() {
                          currentTab = 4;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => favourites(),
                            ),
                          );
                        });
                      },
                      color: currentTab == 4 ? Colors.white : Colors.black,
                    ),
                    Text(
                      "المفضلة",
                      style: TextStyle(
                          color: currentTab == 4 ? Colors.white : Colors.black),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: Text(
                  'أنت لا تملك حساب في دليل الرياض بعد',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: Text(
                  'اكمل تسجيل الدخول ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: SizedBox(
                  width: 250,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => HomePage()),
                      );
                    },
                    child: Text(
                      ' سجل دخول الأن ',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 232, 231, 233),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      primary: Color.fromARGB(255, 99, 62, 118),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
          appBar: AppBar(
            title: Text('حسابي'),
            backgroundColor: Color.fromARGB(255, 211, 198, 226),
            automaticallyImplyLeading: false,
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              setState(() {
                currentTab = 0;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WelcomeScreen(),
                  ),
                );
              });
            },
            child: Image.asset(
              'lib/icons/Logo.png',
            ),
            backgroundColor: Color.fromARGB(157, 165, 138, 182),
            elevation: 20.0,
//mini: true,
          ),
          bottomNavigationBar: BottomAppBar(
            notchMargin: 10,
            shape: CircularNotchedRectangle(),
            color: Color.fromARGB(157, 217, 197, 230),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              mainAxisSize: MainAxisSize.max,
              children: [
                Padding(
                  padding: EdgeInsets.only(right: 10.0, left: 10.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.account_box),
                        onPressed: () {
                          setState(() {
                            currentTab = 1;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => account(),
                              ),
                            );
                          });
                        },
                        color: currentTab == 1 ? Colors.white : Colors.black,
                      ),
                      Text(
                        "حسابي",
                        style: TextStyle(
                            color:
                                currentTab == 1 ? Colors.white : Colors.black),
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.search),
                        onPressed: () {
                          setState(() {
                            currentTab = 2;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => search(),
                              ),
                            );
                          });
                        },
                        color: currentTab == 2 ? Colors.white : Colors.black,
                      ),
                      Text(
                        "البحث",
                        style: TextStyle(
                            color:
                                currentTab == 2 ? Colors.white : Colors.black),
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 30.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.newspaper),
                        onPressed: () {
                          setState(() {
                            currentTab = 3;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => news(),
                              ),
                            );
                          });
                        },
                        color: currentTab == 3 ? Colors.white : Colors.black,
                      ),
                      Text(
                        "أحداث اليوم",
                        style: TextStyle(
                            color:
                                currentTab == 3 ? Colors.white : Colors.black),
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.favorite),
                        onPressed: () {
                          setState(() {
                            currentTab = 4;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => favourites(),
                              ),
                            );
                          });
                        },
                        color: currentTab == 4 ? Colors.white : Colors.black,
                      ),
                      Text(
                        "المفضلة",
                        style: TextStyle(
                            color:
                                currentTab == 4 ? Colors.white : Colors.black),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50.0),
                      border: Border.all(
                        color: Color.fromARGB(
                            255, 8, 8, 8), // Set the outline color
                        width: 1.0, // Set the outline width
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.person,
                          color: Color.fromARGB(255, 69, 51, 80)),
                      title: TextFormField(
                        readOnly: true,
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'اسم المستخدم',
                          labelStyle: TextStyle(fontSize: 18.0),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.0),
                  Container(
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 255, 255, 255),
                      borderRadius: BorderRadius.circular(50.0),
                      border: Border.all(
                        color: Color.fromARGB(
                            255, 8, 8, 8), // Set the outline color
                        width: 1.0, // Set the outline width
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.email,
                        color: Color.fromARGB(255, 69, 51, 80),
                      ),
                      title: TextFormField(
                        readOnly: true,
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'البريد الالكتروني',
                          labelStyle: TextStyle(fontSize: 18.0),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.0),
                  Container(
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 255, 255, 255),
                      borderRadius: BorderRadius.circular(50.0),
                      border: Border.all(
                        color: Color.fromARGB(
                            255, 8, 8, 8), // Set the outline color
                        width: 1.0, // Set the outline width
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.credit_card,
                        color: Color.fromARGB(255, 69, 51, 80),
                      ),
                      title: TextField(
                        readOnly: true,
                        controller: _cardsController,
                        decoration: InputDecoration(
                          labelText:
                              'البطاقات التي لديك للحصول على افضل العروض:',
                          labelStyle: TextStyle(fontSize: 18.0),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 50.0),
                  ElevatedButton(
                    onPressed: resetPassword,
                    style: ElevatedButton.styleFrom(
                      primary: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50.0),
                        side: BorderSide(
                          color: const Color.fromARGB(
                              255, 12, 12, 12), // Set the outline color
                          width: 1.0, // Set the outline width
                        ),
                      ),
                      padding: EdgeInsets.all(10.0),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          color: Color.fromARGB(255, 69, 51, 80),
                        ),
                        SizedBox(width: 8.0),
                        Text(
                          'تغيير كلمة المرور',
                          style: TextStyle(
                            fontSize: 16.0,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.0),
                  Hero(
                    tag: 'uniqueTagForFab', // Assign a unique tag
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.fromARGB(255, 99, 62, 118),
                      ),
                      child: IconButton(
                        onPressed: () {
                          showSignOutConfirmationDialog(context);
                        },
                        icon: Icon(Icons.logout_rounded),
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ));
    }
  }
}
