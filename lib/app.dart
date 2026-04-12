import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/auth/auth_bloc.dart';
import 'bloc/auth/auth_event.dart';
import 'bloc/cart/cart_bloc.dart';
import 'bloc/order/order_bloc.dart';
import 'bloc/product/product_bloc.dart';
import 'bloc/product/product_event.dart';
import 'views/splash_screen.dart';
import 'views/auth/login_screen.dart';
import 'views/auth/signup_screen.dart';
import 'views/auth/forgot_password_screen.dart';
import 'views/auth/reset_password_otp_screen.dart';
import 'views/auth/reset_password_screen.dart';
import 'views/product_menu_screen.dart';
import 'views/product_details_screen.dart';
import 'views/cart_screen.dart';
import 'views/checkout_screen.dart';
import 'views/order_confirmation_screen.dart';
import 'views/order_tracking_screen.dart';
import 'views/orders_screen.dart';
import 'views/profile_screen.dart';
import 'views/edit_profile_screen.dart';
import 'views/saved_addresses_screen.dart';
import 'views/add_edit_address_screen.dart';

class MilkoTeaApp extends StatelessWidget {
  const MilkoTeaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthBloc()..add(CheckAuthStatus()),
        ),
        BlocProvider(
          create: (context) => ProductBloc()..add(LoadProducts()),
        ),
        BlocProvider(
          create: (context) => CartBloc(),
        ),
        BlocProvider(
          create: (context) => OrderBloc(),
        ),
      ],
      child: MaterialApp(
        title: 'MilkoTea Virac',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.brown,
          primaryColor: const Color(0xFF6B4423),
          useMaterial3: true,
        ),
        initialRoute: SplashScreen.route,
        routes: {
          SplashScreen.route: (_) => const SplashScreen(),
          LoginScreen.route: (_) => const LoginScreen(),
          SignUpScreen.route: (_) => const SignUpScreen(),
          ForgotPasswordScreen.route: (_) => const ForgotPasswordScreen(),
          ProductMenuScreen.route: (_) => const ProductMenuScreen(),
          CartScreen.route: (_) => const CartScreen(),
          CheckoutScreen.route: (_) => const CheckoutScreen(),
          OrderConfirmationScreen.route: (_) => const OrderConfirmationScreen(),
          OrderTrackingScreen.route: (_) => const OrderTrackingScreen(),
          OrdersScreen.route: (_) => const OrdersScreen(),
          ProfileScreen.route: (_) => const ProfileScreen(),
          SavedAddressesScreen.route: (_) => const SavedAddressesScreen(),
          EditProfileScreen.route: (_) => const EditProfileScreen(),
          AddEditAddressScreen.route: (_) => const AddEditAddressScreen(),
        },
        onGenerateRoute: (settings) {
          // Handle routes with arguments
          if (settings.name == ProductDetailsScreen.route) {
            final product = settings.arguments;
            return MaterialPageRoute(
              builder: (_) => ProductDetailsScreen(product: product as dynamic),
            );
          }
          if (settings.name == ResetPasswordOtpScreen.route) {
            final email = settings.arguments as String;
            return MaterialPageRoute(
              builder: (_) => ResetPasswordOtpScreen(email: email),
            );
          }
          if (settings.name == ResetPasswordScreen.route) {
            final email = settings.arguments as String;
            return MaterialPageRoute(
              builder: (_) => ResetPasswordScreen(email: email),
            );
          }
          return null;
        },
      ),
    );
  }
}