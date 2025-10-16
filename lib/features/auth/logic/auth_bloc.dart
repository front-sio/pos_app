import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../data/auth_repository.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;
  
  AuthBloc({required this.repository}) : super(AuthInitial()) {
    on<AppStarted>((event, emit) async {
      final token = await repository.getToken();
      final userIdString = await repository.getUserId();
      final userId = userIdString != null ? int.tryParse(userIdString) : null;
      final firstName = await repository.getFirstName();
      final lastName = await repository.getLastName();
      final username = await repository.getUsername();
      final email = await repository.getEmail();

      if (token != null && userId != null) {
        emit(AuthAuthenticated(
          token: token,
          userId: userId,
          email: email ?? '',
          firstName: firstName ?? '',
          lastName: lastName ?? '',
          username: username ?? ''
        ));
      } else {
        emit(AuthUnauthenticated());
      }
    });

    on<LoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final userData = await repository.login(event.email, event.password);
        final token = userData['token'] as String;
        final userId = userData['user']['id'] as int;
        
        // Safely extract and handle potential nulls
        final firstName = userData['user']['first_name'] as String? ?? '';
        final lastName = userData['user']['last_name'] as String? ?? '';
        final username = userData['user']['username'] as String? ?? '';
        final email = userData['user']['email'] as String? ?? '';

        // Save the username to storage
        await repository.saveUsername(username);

        emit(AuthAuthenticated(
          token: token,
          userId: userId,
          email: email,
          firstName: firstName,
          lastName: lastName,
          username: username
        ));
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });

    on<RegisterRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final userData = await repository.register(
          event.username, event.email, event.firstName, event.lastName, event.password, event.gender
        );
        final token = userData['token'] as String;
        final userId = userData['user']['id'] as int;

        // Safely extract and handle potential nulls
        final firstName = userData['user']['first_name'] as String? ?? '';
        final lastName = userData['user']['last_name'] as String? ?? '';
        final username = userData['user']['username'] as String? ?? '';
        final email = userData['user']['email'] as String? ?? '';
        
        // Save the username to storage
        await repository.saveUsername(username);
        
        emit(AuthAuthenticated(
          token: token,
          userId: userId,
          email: email,
          firstName: firstName,
          lastName: lastName,
          username: username
        ));
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });
    
    on<LogoutRequested>((event, emit) async {
      await repository.logout();
      emit(AuthUnauthenticated());
    });
  }
}
