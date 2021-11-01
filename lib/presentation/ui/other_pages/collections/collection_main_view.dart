import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter/material.dart';
import 'package:webcomic/data/common/constants/collection_constants.dart';
import 'package:webcomic/di/get_it.dart';
import 'package:webcomic/presentation/ui/loading/loading.dart';

class CollectionMainView extends StatefulWidget {
  final String collectionId;

  const CollectionMainView({Key? key, required this.collectionId})
      : super(key: key);

  @override
  _CollectionMainViewState createState() => _CollectionMainViewState();
}

class _CollectionMainViewState extends State<CollectionMainView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<Object>(
          stream: getItInstance<firestore.FirebaseFirestore>()
              .collection(CollectionConsts.collections)
              .doc(widget.collectionId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Column();
            }
            return Loading();
          }),
    );
  }
}
