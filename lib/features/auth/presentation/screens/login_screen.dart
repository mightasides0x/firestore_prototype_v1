import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Import Bloc
import 'package:firestore_prototype_v1/features/auth/presentation/cubit/auth_cubit.dart'; // Import Cubit

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  // Key for accessing the Form state
  static final _formKey = GlobalKey<FormState>();

  // Controllers to capture text input
  static final _emailController = TextEditingController();
  static final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: BlocListener<AuthCubit, AuthState>(
        // Listen for state changes to show errors or navigate
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is Authenticated) {
            // TODO: Navigate to Home Screen on successful login
            print('Login Successful! User: ${state.user.email}');
            // Navigator.pushReplacementNamed(context, '/home');
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form( // Wrap Column with Form
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField( // Use TextFormField
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    // Basic email regex (consider a more robust one or a package)
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null; // Return null if valid
                  },
                ),
                const SizedBox(height: 16),
                TextFormField( // Use TextFormField
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null; // Return null if valid
                  },
                ),
                const SizedBox(height: 24),
                // Use BlocBuilder to show loading state on button
                BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    return ElevatedButton(
                      onPressed: state is AuthLoading
                          ? null // Disable button when loading
                          : () {
                              if (_formKey.currentState?.validate() ?? false) {
                                final email = _emailController.text.trim(); // Trim whitespace
                                final password = _passwordController.text.trim();
                                // Call Cubit method
                                context.read<AuthCubit>().logIn(email, password);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: state is AuthLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Login'),
                    );
                  },
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to Sign Up Screen using named route
                    Navigator.pushNamed(context, '/signup');
                  },
                  child: const Text('Don\'t have an account? Sign Up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 