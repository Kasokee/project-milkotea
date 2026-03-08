import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {} 

class Authenticated extends AuthState {
  final String userId;
  final String userName;
  final String userEmail;

  Authenticated({
    required this.userId,
    required this.userName,
    required this.userEmail
  });

  @override
  List<Object?> get props => [userId, userName, userEmail];
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}