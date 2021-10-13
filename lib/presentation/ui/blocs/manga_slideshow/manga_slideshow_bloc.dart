import 'package:bloc/bloc.dart';

class MangaSlideShowState {
  int? index;
  int? noOfItems;
  MangaSlideShowState({this.index, this.noOfItems});
}

class MangaSlideShowCubit extends Cubit<MangaSlideShowState> {
  MangaSlideShowCubit() : super(MangaSlideShowState(index: 1, noOfItems: 0));

  void setIndex(int newIndex) {
    emit(MangaSlideShowState(index: newIndex, noOfItems: state.noOfItems));
  }

  void setNoOfItems(int itemsNo) {
    emit(MangaSlideShowState(index: state.index, noOfItems: itemsNo));
  }
}
