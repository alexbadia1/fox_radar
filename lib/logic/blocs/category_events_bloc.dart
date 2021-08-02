import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/material.dart';
import 'package:communitytabs/logic/logic.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';

class CategoryEventsBloc
    extends Bloc<CategoryEventsEvent, CategoryEventsState> {
  final DatabaseRepository db;
  final String category;
  final int paginationLimit = PAGINATION_LIMIT;

  CategoryEventsBloc({@required this.db, @required this.category})
      : assert(db != null),
        assert(category != null),
        super(CategoryEventsStateFetching());

  @override
  Stream<CategoryEventsState> mapEventToState(
      CategoryEventsEvent categoryEventsEvent) async* {
    print("Category Events Received An Event!");
    // await Future.delayed(Duration(milliseconds: 5000));

    /// Fetch some events
    if (categoryEventsEvent is CategoryEventsEventFetch) {
      yield* _mapCategoryEventsEventFetchToState();
    } // if

    /// Reload the events list
    else if (categoryEventsEvent is CategoryEventsEventReload) {
      yield* _mapCategoryEventsEventReloadToState();
    } // else if

    /// The event added to the bloc has not associated state
    /// either create one, or check all the available CategoryEvents
    else {
      yield CategoryEventsStateFailed();
    } // else
  } // mapEventToState

  Stream<CategoryEventsState> _mapCategoryEventsEventReloadToState() async* {
    /// Get the current state for later use...
    final _currentState = this.state;
    bool _maxEvents = false;

    if (_currentState is CategoryEventsStateSuccess) {
      yield CategoryEventsStateSuccess(
        eventModels: _currentState.eventModels,
        maxEvents: _currentState.maxEvents,
        lastEvent: _currentState.lastEvent,
        isFetching: true,
      );
    } // if

    try {
      // User is fetching events from a failed state
      if (!(_currentState is CategoryEventsStateFetching) && !(_currentState is CategoryEventsStateSuccess)) {
        yield CategoryEventsStateFetching();
        // Retry will fail to quickly,
        //
        // Give the user a good feeling that events are actually being searched for.
        await Future.delayed(Duration(milliseconds: 350));
      }// if

      // No posts were fetched yet
      final List<QueryDocumentSnapshot> _docs =
          await _fetchEventsWithPagination(
              lastEvent: null, limit: paginationLimit);
      final List<SearchResultModel> _eventModels =
          _mapDocumentSnapshotsToSearchEventModels(docs: _docs);

      // Failed Reload from a failed state
      if (_currentState is CategoryEventsStateFailed && _docs.isEmpty) {
        yield CategoryEventsStateReloadFailed();
        yield CategoryEventsStateFailed();
        return;
      } // if

      if (_eventModels.length != this.paginationLimit) {
        _maxEvents = true;
      } // if

      yield CategoryEventsStateSuccess(
        eventModels: _eventModels,
        maxEvents: _maxEvents,
        lastEvent: _docs.last,
        isFetching: false,
      );
    } // try
    catch (e) {
      yield CategoryEventsStateFailed();
    } // catch
  } // _mapCategoryEventsEventReloadToState

  Stream<CategoryEventsState> _mapCategoryEventsEventFetchToState() async* {
    /// Get the current state for later use...
    final _currentState = this.state;
    bool _maxEvents = false;

    try {
      /// No posts were fetched yet
      if (_currentState is CategoryEventsStateFetching) {
        final List<QueryDocumentSnapshot> _docs =
            await _fetchEventsWithPagination(
                lastEvent: null, limit: paginationLimit);
        final List<SearchResultModel> _eventModels =
            _mapDocumentSnapshotsToSearchEventModels(docs: _docs);

        if (_eventModels.length != this.paginationLimit) {
          _maxEvents = true;
        } // if

        yield CategoryEventsStateSuccess(
          eventModels: _eventModels,
          maxEvents: _maxEvents,
          lastEvent: _docs.last,
          isFetching: false,
        );
      } // if

      /// Some posts were fetched already, now fetch 20 more
      else if (_currentState is CategoryEventsStateSuccess) {
        final List<QueryDocumentSnapshot> _docs =
            await _fetchEventsWithPagination(
                lastEvent: _currentState.lastEvent, limit: paginationLimit);

        /// No event models were returned from the database
        if (_docs.isEmpty) {
          yield CategoryEventsStateSuccess(
            eventModels: _currentState.eventModels,
            maxEvents: true,
            lastEvent: _currentState.lastEvent,
            isFetching: false,
          );
        } // if

        /// At least 1 event was returned from the database
        else {
          final List<SearchResultModel> _eventModels =
              _mapDocumentSnapshotsToSearchEventModels(docs: _docs);

          if (_eventModels.length != this.paginationLimit) {
            _maxEvents = true;
          } // if

          yield CategoryEventsStateSuccess(
            eventModels: _currentState.eventModels + _eventModels,
            maxEvents: _maxEvents,
            lastEvent: _docs?.last ?? _currentState.lastEvent,
            isFetching: false,
          );
        } // else
      } // if
    } catch (e) {
      yield CategoryEventsStateFailed();
    } // catch
  } // _mapCategoryEventsEventFetchToState

  Future<List<QueryDocumentSnapshot>> _fetchEventsWithPagination(
      {@required QueryDocumentSnapshot lastEvent, @required int limit}) async {
    return db.searchEventsByCategory(
        category: this.category, lastEvent: lastEvent, limit: limit);
  } // _fetchEventsWithPagination

  List<SearchResultModel> _mapDocumentSnapshotsToSearchEventModels(
      {@required List<QueryDocumentSnapshot> docs}) {
    return docs.map((doc) {
      // Convert the firebase timestamp to a DateTime
      DateTime tempRawStartDateAndTimeToDateTime;
      Timestamp _startTimestamp = doc[ATTRIBUTE_RAW_START_DATE_TIME];
      if (_startTimestamp != null) {
        tempRawStartDateAndTimeToDateTime = DateTime.fromMillisecondsSinceEpoch(
                _startTimestamp.millisecondsSinceEpoch)
            .toUtc()
            .toLocal();
      } // if
      else {
        tempRawStartDateAndTimeToDateTime = null;
      } // else

      return SearchResultModel(
        // Title converted to [STRING] from [STRING] in Firebase.
        newTitle: doc[ATTRIBUTE_TITLE] ?? '',

        // Host converted to [STRING] from [STRING] in Firebase.
        newHost: doc[ATTRIBUTE_HOST] ?? '',

        // Location Converted to [] from [] in Firebase.
        newLocation: doc[ATTRIBUTE_LOCATION] ?? '',

        // RawStartDate converted to [DATETIME] from [TIMESTAMP] in Firebase.
        newRawStartDateAndTime: tempRawStartDateAndTimeToDateTime ?? null,

        // Category converted to [STRING] from [STRING] in Firebase.
        newCategory: doc[ATTRIBUTE_CATEGORY] ?? '',

        // Implement Firebase Images.
        newImageFitCover: doc[ATTRIBUTE_IMAGE_FIT_COVER] ?? true,

        // DocumentId converted to [STRING] from [STRING] in firebase.
        newEventId: doc[ATTRIBUTE_EVENT_ID] ?? '',

        // AccountID converted to [STRING] from [STRING] in firebase.
        newAccountID: doc[ATTRIBUTE_ACCOUNT_ID] ?? '',
      );
    }).toList();
  } // _mapDocumentSnapshotsToSearchEventModels

  @override
  Stream<Transition<CategoryEventsEvent, CategoryEventsState>> transformEvents(
      Stream<CategoryEventsEvent> events, transitionFn) {
    return super.transformEvents(
        events.debounceTime(const Duration(milliseconds: 0)), transitionFn);
  } // transformEvents

  @override
  void onChange(Change<CategoryEventsState> change) {
    print('${this.category} Category Events Bloc: $change');
    super.onChange(change);
  } // onChange

  @override
  Future<void> close() {
    print('Category Events Bloc Closed!');
    return super.close();
  } // close
} // CategoryEventsBloc
