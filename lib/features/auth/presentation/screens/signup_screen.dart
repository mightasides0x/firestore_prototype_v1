import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Import Bloc
import 'package:firestore_prototype_v1/features/auth/presentation/cubit/auth_cubit.dart'; // Import Cubit

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  // Key for accessing the Form state
  static final _formKey = GlobalKey<FormState>();

  // Controllers to capture text input
  static final _emailController = TextEditingController();
  static final _passwordController = TextEditingController();
  // Optionally add a confirm password field
  // static final _confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is Authenticated) {
            // TODO: Navigate to Home Screen on successful signup
            print('Sign Up Successful! User: ${state.user.email}');
            // Optionally pop back to login or go directly home
            // Navigator.pop(context); // Pop back to Login
            // OR
            // Navigator.pushReplacementNamed(context, '/home'); // Go Home
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
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
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
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    // TODO: Add confirm password validation if field is added
                    return null;
                  },
                ),
                // TODO: Add Confirm Password TextFormField here
                const SizedBox(height: 24),
                // Sign up Button with loading state
                BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    return ElevatedButton(
                      onPressed: state is AuthLoading
                          ? null // Disable button when loading
                          : () {
                              if (_formKey.currentState?.validate() ?? false) {
                                final email = _emailController.text.trim();
                                final password = _passwordController.text.trim();
                                // Call Cubit method
                                context.read<AuthCubit>().signUp(email, password);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50), // Full width
                      ),
                      child: state is AuthLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Sign Up'),
                    );
                  },
                ),
                TextButton(
                  onPressed: () {
                    // Navigate back to Login Screen
                    Navigator.pop(context);
                  },
                  child: const Text('Already have an account? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 