import 'package:flutter_bloc/flutter_bloc.dart';
import 'profile_event.dart';
import 'profile_state.dart';
import 'package:sales_app/features/users/repository/users_repository.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final UsersRepository repository;

  ProfileBloc({required this.repository}) : super(ProfileInitial()) {
    on<LoadProfile>(_onLoadProfile);
    on<UpdateProfile>(_onUpdateProfile);
    on<RequestAccountDeletion>(_onRequestDeletion);
  }

  Future<void> _onLoadProfile(LoadProfile _event, Emitter<ProfileState> emit) async {
    try {
      emit(ProfileLoading());
      final user = await repository.getCurrentUser();
      emit(ProfileLoaded(user));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> _onUpdateProfile(UpdateProfile event, Emitter<ProfileState> emit) async {
    try {
      emit(ProfileLoading());
      final res = await repository.updateUser(event.userId, event.payload);
      emit(ProfileUpdated(res['message'] ?? 'Profile updated'));
      add(LoadProfile());
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> _onRequestDeletion(RequestAccountDeletion event, Emitter<ProfileState> emit) async {
    try {
      emit(ProfileLoading());
      // We will call delete user endpoint; backend may require superuser confirmation.
      await repository.deleteUser(event.userId);
      emit(ProfileUpdated('Account deletion requested. An administrator will confirm.'));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }
}