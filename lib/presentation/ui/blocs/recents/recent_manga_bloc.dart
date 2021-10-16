import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webcomic/data/models/local_data_models/recently_read_model.dart';

class RecentsState {
  List<RecentlyRead> recents = [];
  RecentsState({required this.recents});
}

class RecentsCubit extends Cubit<RecentsState> {
  RecentsCubit() : super(RecentsState(recents: []));

  void setResults(List<RecentlyRead> chapters) {
    chapters.sort((a, b) {
      return b.mostRecentReadDate.compareTo(a.mostRecentReadDate);
    });

    emit(RecentsState(recents: chapters));
  }
}
