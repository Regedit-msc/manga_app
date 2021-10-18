import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webcomic/data/models/local_data_models/subscribed_model.dart';

class SubsState {
  List<Subscribe> subs = [];
  SubsState({required this.subs});
}

class SubsCubit extends Cubit<SubsState> {
  SubsCubit() : super(SubsState(subs: []));

  void setSubs(List<Subscribe> subs) {
    subs.sort((a, b) {
      return b.dateSubscribed.compareTo(a.dateSubscribed);
    });

    emit(SubsState(subs: subs));
  }
}
