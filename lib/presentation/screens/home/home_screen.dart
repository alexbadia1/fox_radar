import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:communitytabs/logic/logic.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:database_repository/database_repository.dart';
import 'package:communitytabs/presentation/screens/screens.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        child: SafeArea(
          child: SlidingUpPanel(
            /// TODO: OnCollapsed widget pointer fails after modifying a textfield.
            ///  Figure out a better solution, as onPanel Opened every time the panel
            ///  state changes (especially when modifying a form text field).
            onPanelOpened: () {
              BlocProvider.of<SlidingUpPanelCubit>(context).openPanel();
            },
            controller: BlocProvider.of<SlidingUpPanelCubit>(context)
                .slidingUpPanelControl,
            minHeight: MediaQuery.of(context).size.height * .0625,
            maxHeight: MediaQuery.of(context).size.height,
            collapsed: HomeBottomNavigationBar(key: UniqueKey()),
            isDraggable: false,
            panel: CreateEventScreen(),
            body: BlocProvider(
              create: (context) => CategoryPageCubit(),
              child: PageView(
                controller: BlocProvider.of<HomePageViewCubit>(context)
                    .homePageViewController,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  BlocProvider<SuggestedEventsBloc>(
                    create: (context) => SuggestedEventsBloc(
                      db: RepositoryProvider.of<DatabaseRepository>(context),
                    )..add(SuggestedEventsEventFetch()),
                    child: HomeScreenBody(),
                  ),
                  CategoryScreen(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
