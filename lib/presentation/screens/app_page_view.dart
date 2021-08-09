import 'package:authentication_repository/authentication_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:communitytabs/logic/logic.dart';
import 'package:database_repository/database_repository.dart';
import 'package:communitytabs/presentation/presentation.dart';

class AppPageView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<UploadEventBloc>(
      create: (context) => UploadEventBloc(
        uid: RepositoryProvider.of<AuthenticationRepository>(context).getUserModel().userID,
        db: RepositoryProvider.of<DatabaseRepository>(context),
      ),
      child: PageView(
        controller: BlocProvider.of<AppPageViewCubit>(context).appPageViewController,
        physics: NeverScrollableScrollPhysics(),
        children: [
          MultiBlocProvider(
            providers: [
              BlocProvider<SlidingUpPanelCubit>(
                create: (context) => SlidingUpPanelCubit(),
              ),
              BlocProvider<HomePageViewCubit>(
                create: (context) => HomePageViewCubit(),
              ),
            ],
            child: HomeScreen(),
          ),
          MultiBlocProvider(
            providers: [
              BlocProvider<SlidingUpPanelCubit>(
                create: (context) => SlidingUpPanelCubit(),
              ),
            ],
            child: AccountScreen(),
          ),
        ],
      ),
    );
  } // build
} // AppPageView
