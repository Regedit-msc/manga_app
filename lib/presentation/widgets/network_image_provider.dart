import 'package:flutter/cupertino.dart';
import 'package:webcomic/data/common/generator/color_generator.dart';

typedef NetworkImageWidgetBuilder = Widget Function(
  BuildContext context,
  ImageProvider imageProvider,
);

typedef NetworkPlaceholderWidgetBuilder = Widget Function(
  BuildContext context,
  String url,
);
typedef NetworkLoadingErrorWidgetBuilder = Widget Function(
  BuildContext context,
  String url,
  dynamic error,
);

class NetworkImageExt extends StatefulWidget {
  final NetworkPlaceholderWidgetBuilder? placeholder;
  final NetworkImageWidgetBuilder imageBuilder;
  final String imageUrl;
  final NetworkLoadingErrorWidgetBuilder? errorWidget;
  NetworkImageExt(
      {Key? key,
      this.placeholder,
      required this.imageUrl,
      required this.imageBuilder,
      this.errorWidget})
      : super(key: key);

  @override
  _NetworkImageExtState createState() => _NetworkImageExtState();
}

class _NetworkImageExtState extends State<NetworkImageExt> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: getImageData(url: widget.imageUrl),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return AnimatedSwitcher(
                duration: Duration(milliseconds: 300),
                child: widget.placeholder!(context, widget.imageUrl));
          }
          if (snapshot.connectionState == ConnectionState.none ||
              snapshot.hasError) {
            return widget.errorWidget!(
                context, widget.imageUrl, snapshot.error);
          }
          final data = snapshot.data as ImageProviderWithImageBytes;
          return snapshot.hasData
              ? TweenAnimationBuilder(
                  curve: Curves.easeIn,
                  duration: Duration(milliseconds: 300),
                  tween: Tween<double>(begin: 0, end: 1.0),
                  builder: (context, _val, child) {
                    return Opacity(opacity: _val, child: child);
                  },
                  child: widget.imageBuilder(
                    context,
                    data.imageProvider ??
                        ResizeImage(
                          Image.network(widget.imageUrl).image,
                          width: MediaQuery.of(context).size.width.ceil(),
                        ),
                  ),
                )
              : Container();
        });
  }
}
