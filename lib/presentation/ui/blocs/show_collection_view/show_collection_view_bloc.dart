import 'package:bloc/bloc.dart';

class ShowCollectionCubit extends Cubit<bool> {
  ShowCollectionCubit() : super(false);

  void setShowCollection(bool v) {
    emit(v);
  }
}
