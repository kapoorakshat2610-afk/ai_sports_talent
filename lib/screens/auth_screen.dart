import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
const AuthScreen({super.key});

@override
State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
final AuthService _authService = AuthService();

final TextEditingController _usernameController =
TextEditingController();

final TextEditingController _emailController =
TextEditingController();

final TextEditingController _passwordController =
TextEditingController();

bool isLogin = true;
bool isLoading = false;
bool obscurePassword = true;

String selectedRole = 'athlete';

@override
void dispose() {
_usernameController.dispose();
_emailController.dispose();
_passwordController.dispose();
super.dispose();
}

Future<void> _submit() async {
final username = _usernameController.text.trim();


final email = _emailController.text.trim();

final password = _passwordController.text;

if (username.isEmpty) {
  _showMessage('Please enter username.');
  return;
}

if (!isLogin && email.isEmpty) {
  _showMessage('Please enter email.');
  return;
}

if (password.isEmpty) {
  _showMessage('Please enter password.');
  return;
}

if (password.length < 6) {
  _showMessage(
    'Password must contain at least 6 characters.',
  );
  return;
}

setState(() {
  isLoading = true;
});

try {
  if (isLogin) {
    // Login works for both athlete and coach.
    await _authService.login(
      username: username,
      password: password,
    );
  } else {
    // Create account with the selected role.
    await _authService.register(
      username: username,
      email: email,
      password: password,
      role: selectedRole,
    );

    // Automatically login after registration.
    await _authService.login(
      username: username,
      password: password,
    );
  }

  if (!mounted) return;

  final role = await _authService.getRole();

  // Make sure the selected login type matches
  // the role stored for the account.
  if (isLogin && role != selectedRole) {
    await _authService.logout();

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    _showMessage(
      'This account is registered as ${role == 'coach' ? 'Coach' : 'Athlete'}. '
      'Please select ${role == 'coach' ? 'Coach' : 'Athlete'} and login again.',
    );

    return;
  }

  setState(() {
    isLoading = false;
  });

  _showMessage(
    isLogin
        ? 'Login successful.'
        : 'Account created successfully.',
    isError: false,
  );

  Navigator.pushReplacementNamed(
    context,
    role == 'coach' ? '/coach' : '/app',
  );
} catch (e) {
  if (!mounted) return;

  setState(() {
    isLoading = false;
  });

  _showMessage(
    e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
  );
}


}

void _showMessage(
String message, {
bool isError = true,
}) {
ScaffoldMessenger.of(context)
..hideCurrentSnackBar()
..showSnackBar(
SnackBar(
content: Text(message),
backgroundColor:
isError ? Colors.red : Colors.green,
),
);
}

Widget _buildRoleSelector() {
return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
isLogin ? 'Login as' : 'Account type',
style: const TextStyle(
fontWeight: FontWeight.w600,
fontSize: 15,
),
),


    const SizedBox(height: 10),

    Row(
      children: [
        Expanded(
          child: ChoiceChip(
            label: const Text('Athlete'),
            avatar: const Icon(
              Icons.directions_run,
              size: 20,
            ),
            selected: selectedRole == 'athlete',
            onSelected: isLoading
                ? null
                : (selected) {
                    if (!selected) return;

                    setState(() {
                      selectedRole = 'athlete';
                    });
                  },
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: ChoiceChip(
            label: const Text('Coach'),
            avatar: const Icon(
              Icons.sports,
              size: 20,
            ),
            selected: selectedRole == 'coach',
            onSelected: isLoading
                ? null
                : (selected) {
                    if (!selected) return;

                    setState(() {
                      selectedRole = 'coach';
                    });
                  },
          ),
        ),
      ],
    ),
  ],
);


}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: Text(
isLogin
? '${selectedRole == 'coach' ? 'Coach' : 'Athlete'} Login'
: 'Create Account',
),
centerTitle: true,
),


  body: SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),

          const Icon(
            Icons.sports,
            size: 70,
          ),

          const SizedBox(height: 20),

          Text(
            'AI Sports Talent',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 8),

          Text(
            isLogin
                ? 'Sign in to continue'
                : 'Create your athlete or coach account',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 25),

          // Athlete / Coach selector is now visible
          // on BOTH Login and Create Account screens.
          _buildRoleSelector(),

          const SizedBox(height: 20),

          TextField(
            controller: _usernameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Username',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
          ),

          const SizedBox(height: 15),

          if (!isLogin) ...[
            TextField(
              controller: _emailController,
              keyboardType:
                  TextInputType.emailAddress,
              textInputAction:
                  TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon:
                    Icon(Icons.email),
              ),
            ),

            const SizedBox(height: 15),
          ],

          TextField(
            controller: _passwordController,
            obscureText: obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              border:
                  const OutlineInputBorder(),
              prefixIcon:
                  const Icon(Icons.lock),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    obscurePassword =
                        !obscurePassword;
                  });
                },
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
              ),
            ),
          ),

          const SizedBox(height: 25),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed:
                  isLoading ? null : _submit,
              child: isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      isLogin
                          ? 'Login as ${selectedRole == 'coach' ? 'Coach' : 'Athlete'}'
                          : 'Create Account',
                    ),
            ),
          ),

          const SizedBox(height: 15),

          TextButton(
            onPressed: isLoading
                ? null
                : () {
                    setState(() {
                      isLogin = !isLogin;

                      // Keep athlete as the default
                      // only when entering registration.
                      if (!isLogin) {
                        selectedRole = 'athlete';
                      }
                    });
                  },
            child: Text(
              isLogin
                  ? 'Create a new account'
                  : 'Already have an account? Login',
            ),
          ),
        ],
      ),
    ),
  ),
);


}
}
