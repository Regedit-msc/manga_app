import 'package:bloc/bloc.dart';
import 'package:webcomic/data/models/newest_manga_model.dart';

class MangaResultsState {
  List<Datum> mangaSearchResults = [];
  MangaResultsState({required this.mangaSearchResults});
}

class MangaResultsCubit extends Cubit<MangaResultsState> {
  MangaResultsCubit() : super(MangaResultsState(mangaSearchResults: []));

  void setResults(List<Datum> results) {
    emit(MangaResultsState(mangaSearchResults: results));
  }
}
