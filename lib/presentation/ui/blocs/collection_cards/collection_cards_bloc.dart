import 'package:bloc/bloc.dart';
import 'package:webcomic/data/models/newest_manga_model.dart';

class CollectionCardsState {
  List<Datum> cards = [];
  CollectionCardsState({required this.cards});
}

class CollectionCardsCubit extends Cubit<CollectionCardsState> {
  CollectionCardsCubit()
      : super(CollectionCardsState(cards: [Datum(), Datum()]));

  void addCard(Datum card) {
    emit(CollectionCardsState(cards: [...state.cards, card]));
  }

  void updateDataAtIndex(Datum card, int index) {
    List<Datum> cards = state.cards;
    cards[index] = card;
    emit(CollectionCardsState(cards: cards));
  }

  void removeCardAtIndex(int index) {
    List<Datum> cards = state.cards;
    cards.removeAt(index);

    emit(CollectionCardsState(cards: cards));
  }
}
