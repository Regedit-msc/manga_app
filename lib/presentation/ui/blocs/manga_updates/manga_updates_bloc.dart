import 'package:bloc/bloc.dart';
import 'package:webcomic/data/models/manga_updates_model.dart';

class MangaUpdatesState {
  List<Datum>? updates;
  MangaUpdatesState({this.updates});
}

class MangaUpdatesCubit extends Cubit<MangaUpdatesState> {
  MangaUpdatesCubit() : super(MangaUpdatesState(updates: []));

  void setUpdates(List<Datum> updates) {
    emit(MangaUpdatesState(updates: updates));
  }
}
