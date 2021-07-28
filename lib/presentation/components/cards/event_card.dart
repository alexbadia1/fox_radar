import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:communitytabs/logic/logic.dart';
import 'package:database_repository/database_repository.dart';
import 'package:communitytabs/presentation/presentation.dart';

typedef OnEventCardVertMoreCallback = Function();

class EventCard extends StatefulWidget {
  final SearchResultModel newSearchResult;
  final OnEventCardVertMoreCallback onEventCardVertMoreCallback;

  EventCard({@required this.newSearchResult, this.onEventCardVertMoreCallback})
      : assert(newSearchResult != null);

  @override
  _EventCardState createState() => _EventCardState();
} // ClubBigCard

class _EventCardState extends State<EventCard>
    with AutomaticKeepAliveClientMixin {
  Uint8List _imageBytes;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenPaddingBottom = MediaQuery.of(context).padding.bottom;
    final screenInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    final screenPaddingTop = MediaQuery.of(context).padding.top;

    final _realHeight = screenHeight -
        screenPaddingTop -
        screenPaddingBottom +
        screenInsetsBottom;

    String filePath = 'events/${this.widget.newSearchResult.eventId}.jpg';

    return BlocProvider(
      create: (context) => FetchImageCubit(
        db: RepositoryProvider.of<DatabaseRepository>(context),
      )..fetchImage(path: filePath),
      child: GestureDetector(
        onTap: () => Navigator.of(context).pushNamed(
          '/event',
          arguments: EventScreenArguments(
              documentId: this.widget.newSearchResult.eventId,
              imageBytes: _imageBytes),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Color.fromRGBO(33, 33, 33, 1.0),
            border: Border(
              top: BorderSide(
                color: Color.fromRGBO(61, 61, 61, 1.0),
              ),
            ),
          ),
          child: Column(
            children: <Widget>[
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: Colors.black,
                  child: Builder(
                    builder: (context) {
                      final FetchImageState _fetchImageState =
                          context.watch<FetchImageCubit>().state;
                      if (_fetchImageState is FetchImageSuccess) {
                        _imageBytes = _fetchImageState.imageBytes;
                        return Image.memory(
                          _fetchImageState.imageBytes,
                          fit: this.widget.newSearchResult.getImageFitCover
                              ? BoxFit.cover
                              : BoxFit.contain,
                        );
                      } // if

                      else if (_fetchImageState is FetchImageFailure) {
                        print('Looking for: $filePath');
                        return Container(
                          color: Colors.black,
                        );
                      } // else if

                      else {
                        return Container(
                          color: Colors.black,
                        );
                        // return LoadingWidget(
                        //   size: 75.0,
                        // );
                      } // else
                    },
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: double.infinity,
                  minHeight: _realHeight * .12,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      flex: 3,
                      child: CircleAvatar(
                        backgroundColor: Colors.redAccent,
                      ),
                    ),
                    Expanded(
                      flex: 13,
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.max,
                              children: <Widget>[
                                /// Name: Text
                                ///
                                /// Description: The title of the event,
                                ///              Ellipses on overflow.
                                Text(
                                  this.widget.newSearchResult.getTitle,
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                      color: cWhite100,
                                      fontSize: 16.0
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4),

                              /// Name: Text
                              ///
                              /// Description: The location of the event,
                              ///              Ellipses on overflow.
                                Text(
                                  this.widget.newSearchResult.getLocation,
                                  style: TextStyle(
                                    color: cWhite70,
                                    fontSize: 12.0
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 2),


                                /// Name: Text
                                ///
                                /// Description: The start date and
                                ///              time of the event,
                                ///              Ellipses on overflow.
                                Text(
                                  this.widget.newSearchResult.myStartDate
                                  + this.widget.newSearchResult.myStartTime,
                                  style: TextStyle(
                                      color: cWhite70,
                                      fontSize: 12.0
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          IconButton(
                            icon: Icon(Icons.more_vert),
                            color: cWhite70,
                            onPressed: this.widget.onEventCardVertMoreCallback,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  } // build

  @override
  bool get wantKeepAlive => true;
} // _EventCardState
