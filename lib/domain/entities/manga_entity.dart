import 'package:equatable/equatable.dart';

class ResponseEntity extends Equatable {
  final bool? success;
  final String? message;
  final dynamic data;
  const ResponseEntity({
    required this.success,
    required this.message,
    required this.data,
  });

  @override
  List<Object?> get props => [message, success, data];
  @override
  bool? get stringify => true;
}
