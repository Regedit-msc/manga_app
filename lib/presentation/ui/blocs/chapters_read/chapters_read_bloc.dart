import 'package:bloc/bloc.dart';
import 'package:webcomic/data/models/local_data_models/chapter_read_model.dart';

class ChaptersReadState {
  List<ChapterRead> chaptersRead = [];
  ChaptersReadState({required this.chaptersRead});
}

class ChaptersReadCubit extends Cubit<ChaptersReadState> {
  ChaptersReadCubit() : super(ChaptersReadState(chaptersRead: []));

  void setResults(List<ChapterRead> chapters) {
    emit(ChaptersReadState(chaptersRead: chapters));
  }
}
