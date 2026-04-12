import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/auth_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';


class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc({AuthService? authService})
      : _authService = authService ?? AuthService(),
        super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<CheckAuthStatus>(_onCheckAuthStatus);
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final error = await _authService.login(
      email: event.email,
      password: event.password,
    );

    if (error != null) {
      emit(AuthError(error));
      emit(Unauthenticated());
    } else {
      emit(Authenticated(
        userId: _authService.userId!,
        userName: _authService.userName!,
        userEmail: _authService.userEmail!,
      ));
    }
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final error = await _authService.register(
      name: event.name,
      email: event.email,
      phone: event.phone,
      password: event.password,
    );

    if (error != null) {
      emit(AuthError(error));
      emit(Unauthenticated());
    } else {
      emit(Authenticated(
        userId: _authService.userId!,
        userName: _authService.userName!,
        userEmail: _authService.userEmail!,
      ));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authService.logout();
    emit(Unauthenticated());
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    final isLoggedIn = await _authService.checkAuthStatus();
    if (isLoggedIn) {
      emit(Authenticated(
        userId: _authService.userId!,
        userName: _authService.userName!,
        userEmail: _authService.userEmail!,
      ));
    } else {
      emit(Unauthenticated());
    }
  }
}