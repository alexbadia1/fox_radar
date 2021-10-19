import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fox_radar/logic/logic.dart';
import 'package:photo_manager/photo_manager.dart';

class DeviceImagesBloc extends Bloc<DeviceImagesEvent, DeviceImagesState> {
  final int paginationLimit = 10;
  int failedAttempts = 0;
  DeviceImagesBloc() : super(DeviceImagesStateFetching());

  @override
  Stream<DeviceImagesState> mapEventToState(DeviceImagesEvent event) async* {
    if (event is DeviceImagesEventFetch) {
      yield* _mapDeviceImagesEventFetchToDeviceImagesState();
    } // if

    else {
      // error
    }
  } // mapEventToState

  Stream<DeviceImagesState> _mapDeviceImagesEventFetchToDeviceImagesState() async* {
    // Get the current state for later use...
    final _currentState = this.state;
    bool _maxImages = false;

    // Fetch called fom fail state
    if (_currentState is DeviceImagesStateFailed) {
      yield DeviceImagesStateFetching();
    } // if

    try {
      bool hasPermission = false;

      try {
        final PermissionState result = await PhotoManager.requestPermissionExtend();
        hasPermission = result.isAuth;
      } // try

      catch (newApiError) {
        try {
          await PhotoManager.forceOldApi();
          hasPermission = await PhotoManager.requestPermission();
        } // try
        catch (oldApiError) {
          yield DeviceImagesStateFailed(failedAttempts: this.failedAttempts++);
        } // catch
      }

      if (hasPermission) {
        // No posts were fetched yet...
        if (_currentState is DeviceImagesStateFetching || _currentState is DeviceImagesStateFailed || _currentState is DeviceImagesStateDenied) {
          // Set "onlyAll == true": to only get ONE Album (Recent Album by default)
          final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(onlyAll: true, type: RequestType.image);

          // Get photos
          final List<AssetEntity> photos = await albums[0]?.getAssetListPaged(0, this.paginationLimit);

          // Map photos to file data type
          List<Uint8List> tempFiles = await _mapPhotosToFiles(photos: photos);
          List<String> tempFilesPaths = await _mapPhotosToFilePaths(photos: photos);

          if (tempFiles.length != this.paginationLimit) {
            _maxImages = true;
          } // if

          // Compress images
          // print("Compressing images");
          // final List<Uint8List> compressedImageBytes = await _mapFilesToCompressedUint8List(tempFiles);

          yield DeviceImagesStateSuccess(
              paths: tempFilesPaths,
              images: tempFiles,
              lastPage: 0,
              maxImages: _maxImages,
              isFetching: false
          );
        } // if

        // Some images were already fetched from storage, get more
        else if (_currentState is DeviceImagesStateSuccess) {
          // Set "onlyAll == true": to only get ONE Album (Recent Album by default)
          final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(onlyAll: true, type: RequestType.image);

          // Get photos
          final List<AssetEntity> photos = await albums[0]?.getAssetListPaged(_currentState.lastPage + 1, paginationLimit);

          // Map photos to file data type
          List<Uint8List> tempFiles = await _mapPhotosToFiles(photos: photos);
          List<String> tempFilesPaths = await _mapPhotosToFilePaths(photos: photos);

          // // Compress images
          // final List<Uint8List> compressedImageBytes = await _mapFilesToCompressedUint8List(tempFiles);

          // No images were retrieved
          if (tempFiles.isEmpty) {
            yield DeviceImagesStateSuccess(
                paths: _currentState.paths,
                images: _currentState.images,
                lastPage: _currentState.lastPage,
                maxImages: true,
                isFetching: false
            );
          } // if

          else {
            if (tempFiles.length != this.paginationLimit) {
              _maxImages = true;
            } // if

            yield DeviceImagesStateSuccess(
              paths: _currentState.paths + tempFilesPaths,
              images: _currentState.images + tempFiles,
              maxImages: _maxImages,
              lastPage: _currentState.lastPage + 1,
              isFetching: false,
            );
          } // else
        } // else-if

      } // if

      else {
        yield DeviceImagesStateDenied();
      } //else
    } // try
    catch (e) {
      print(e);
      if (e is PlatformException) {
        if (e.code == 'Request for permission failed.') {
          yield DeviceImagesStateDenied();
        } // if
      } // if

      yield DeviceImagesStateFailed(failedAttempts: this.failedAttempts++);
    } // catch
  } // _mapDeviceImagesEventFetchToDeviceImagesState

  Future<List<Uint8List>> _mapPhotosToFiles({@required List<AssetEntity> photos}) async {
    List<Uint8List> ans = [];

    ans = await Future.microtask(() async {
      for (int i = 0; i < photos.length; ++i) {
        final Uint8List f = await photos[i].originBytes;
        ans.add(f);
      } // for

      return ans;
    });

    return ans;
  } // _mapPhotosToFiles

  Future<List<String>> _mapPhotosToFilePaths({@required List<AssetEntity> photos}) async {
    List<String> ans = [];

    ans = await Future.microtask(() async {
      for (int i = 0; i < photos.length; ++i) {
        final f = await photos[i].file;
        ans.add(f.path);
      } // for

      return ans;
    });

    return ans;
  } // _mapPhotosToFiles

  @override
  void onChange(Change<DeviceImagesState> change) {
    print('Device Images Bloc: $change');
    super.onChange(change);
  } // onChange

  @override
  Future<void> close() {
    print('Device Images Bloc Closed');
    return super.close();
  } // close
}
