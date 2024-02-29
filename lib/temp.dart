import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeState {

}

class HomeBloc extends Notifier<HomeState> {
  @override
  HomeState build() {
    return HomeState();
  }
}

final myBloc = NotifierProvider(() => HomeBloc());
