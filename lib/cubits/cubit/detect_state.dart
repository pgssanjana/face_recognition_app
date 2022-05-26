part of 'detect_cubit.dart';

@immutable
abstract class DetectState {}

class DetectInitial extends DetectState {}

class DetectLoad extends DetectState {}

class DetectSuccess extends DetectState {
  var level;
  var name;
  DetectSuccess({required this.level, this.name});
}

class DetectError extends DetectState {
}
