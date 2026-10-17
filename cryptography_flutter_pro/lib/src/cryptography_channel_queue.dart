// Copyright 2019-2020 Gohilla.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '_internal.dart';

enum _CallState { fresh, waiting, held, released }

class CryptographyChannelCall {
  final CryptographyChannelQueue _queue;
  final int _size;
  Completer<void>? _completer;
  _CallState _state = _CallState.fresh;

  CryptographyChannelCall(this._queue, this._size) {
    RangeError.checkNotNegative(_size, 'size');
  }

  bool get isWaitingExpected =>
      _queue._locks.isNotEmpty || !_queue._canAdmit(_size);

  Future<void> lock() async {
    if (_state != _CallState.fresh) {
      throw StateError('A channel lock can only be acquired once');
    }
    if (isWaitingExpected) {
      _state = _CallState.waiting;
      final completer = Completer<void>();
      _completer = completer;
      _queue._locks.add(this);
      await completer.future;
    } else {
      _admit();
    }
  }

  void _admit() {
    _queue._totalRequests++;
    _queue._totalSize += _size;
    _state = _CallState.held;
  }

  void unlock() {
    if (_state != _CallState.held) {
      throw StateError('Only an acquired channel lock can be released');
    }
    _state = _CallState.released;
    _queue._totalSize -= _size;
    _queue._totalRequests--;
    while (_queue._locks.isNotEmpty) {
      final call = _queue._locks.first;
      if (!_queue._canAdmit(call._size)) break;
      _queue._locks.removeFirst();
      call._admit();
      call._completer!.complete();
      call._completer = null;
    }
  }
}

/// Waiting group used for preventing copying too much data to a channel such
/// as [compute] channel or [MethodChannel].
///
/// This should reduce risk of memory exhaustion.
class CryptographyChannelQueue {
  /// Default queue in this platform.
  static final CryptographyChannelQueue defaultInstance = () {
    if (isCupertino) {
      return _defaultInstanceForCupertino;
    }
    return _defaultInstanceForAndroid;
  }();

  /// Default queue for iOS and Mac OS X
  static final CryptographyChannelQueue _defaultInstanceForCupertino =
      CryptographyChannelQueue(
        maxConcurrentRequests: 100,

        // 100MB
        maxConcurrentSize: 100 * 1024 * 1024,
      );

  /// Default queue for Android.
  static final CryptographyChannelQueue _defaultInstanceForAndroid =
      CryptographyChannelQueue(
        maxConcurrentRequests: 100,

        // We observed crashes when this was too high (e.g. >50MB)
        // 20MB should be ok.
        maxConcurrentSize: 20 * 1024 * 1024,
      );

  /// Target maximum size of concurrent requests.
  /// A single oversized request is admitted alone to prevent starvation.
  final int maxConcurrentSize;

  /// Maximum number of concurrent requests.
  final int maxConcurrentRequests;

  final _locks = Queue<CryptographyChannelCall>();

  var _totalSize = 0;
  var _totalRequests = 0;

  CryptographyChannelQueue({
    required this.maxConcurrentSize,
    required this.maxConcurrentRequests,
  }) {
    if (maxConcurrentRequests <= 0) {
      throw ArgumentError.value(
        maxConcurrentRequests,
        'maxConcurrentRequests',
        'Must be positive',
      );
    }
    if (maxConcurrentSize <= 0) {
      throw ArgumentError.value(
        maxConcurrentSize,
        'maxConcurrentSize',
        'Must be positive',
      );
    }
  }

  // An oversized request runs alone, so it cannot block the queue forever.
  bool _canAdmit(int size) =>
      _totalRequests < maxConcurrentRequests &&
      (_totalRequests == 0 || _totalSize + size <= maxConcurrentSize);

  int get totalRequests => _totalRequests;

  int get totalSize => _totalSize;

  CryptographyChannelCall newLock({required int size}) {
    return CryptographyChannelCall(this, size);
  }

  static int estimateSize(Object? value, {int maxDepth = 5}) {
    maxDepth--;
    if (maxDepth < 0) {
      throw StateError('Reached maximum depth');
    }
    if (value is Uint8List) {
      return value.lengthInBytes;
    }
    if (value is String) {
      // Length is in UTF-16 code units.
      // Therefore, we multiply by 2.
      return 2 * value.length;
    }
    if (value is Iterable) {
      var sum = 0;
      for (var item in value) {
        sum += estimateSize(item, maxDepth: maxDepth);
      }
      return 64 + sum + value.length * 8;
    }
    if (value is Map) {
      var sum = 0;
      for (var item in value.keys) {
        sum += estimateSize(item, maxDepth: maxDepth);
      }
      for (var item in value.values) {
        sum += estimateSize(item, maxDepth: maxDepth);
      }
      return 64 + sum + value.length * 16;
    }
    return 8;
  }
}
