import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webcomic/data/models/google_models/user.dart';

class UserState {
  UserFromGoogle user;
  UserState({required this.user});
}

class UserFromGoogleCubit extends Cubit<UserState> {
  UserFromGoogleCubit()
      : super(UserState(
            user: UserFromGoogle(
                email: '', profilePicture: '', name: '', pro: "false")));

  void setUser(UserFromGoogle user) {
    emit(UserState(user: user));
  }
}
