import 'dart:async';

import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';

/// 测试用的假播放后端。
///
/// 只实现音频服务用到的那几条通道，其余保持接口默认行为。
class FakeJustAudioPlatform extends JustAudioPlatform {
  FakeJustAudioPlatform() {
    JustAudioPlatform.instance = this;
  }

  /// 收到的加载请求。
  final List<LoadRequest> loads = [];

  /// 收到的跳转请求。
  final List<SeekRequest> seeks = [];

  /// 收到的循环模式。
  final List<LoopModeMessage> loopModes = [];

  /// 播放请求次数。
  int playCount = 0;

  /// 暂停请求次数。
  int pauseCount = 0;

  final StreamController<PlaybackEventMessage> _events =
      StreamController<PlaybackEventMessage>.broadcast();

  final StreamController<PlayerDataMessage> _data =
      StreamController<PlayerDataMessage>.broadcast();

  @override
  Future<AudioPlayerPlatform> init(InitRequest request) async =>
      _FakeAudioPlayerPlatform(this, request.id);

  @override
  Future<DisposePlayerResponse> disposePlayer(
    DisposePlayerRequest request,
  ) async => DisposePlayerResponse.fromMap(const {});

  /// 主动推送一条播放事件。
  void emitEvent(PlaybackEventMessage event) => _events.add(event);

  /// 主动推送一条数据更新。
  void emitData(PlayerDataMessage data) => _data.add(data);

  /// 关闭内部流。
  Future<void> close() async {
    await _events.close();
    await _data.close();
  }
}

class _FakeAudioPlayerPlatform extends AudioPlayerPlatform {
  _FakeAudioPlayerPlatform(this._owner, String id) : super(id);

  final FakeJustAudioPlatform _owner;

  /// 假后端统一返回的时长。
  static const Duration _duration = Duration(minutes: 3);

  @override
  Stream<PlaybackEventMessage> get playbackEventMessageStream =>
      _owner._events.stream;

  @override
  Stream<PlayerDataMessage> get playerDataMessageStream => _owner._data.stream;

  @override
  Future<LoadResponse> load(LoadRequest request) async {
    _owner.loads.add(request);
    // 真实后端加载完成后会推一条播放事件，just_audio 等这条事件
    // 才认为加载结束，所以假后端也要推一条。
    _owner.emitEvent(
      PlaybackEventMessage(
        processingState: ProcessingStateMessage.ready,
        updateTime: DateTime.now(),
        updatePosition: Duration.zero,
        bufferedPosition: Duration.zero,
        duration: _duration,
        icyMetadata: null,
        currentIndex: request.initialIndex ?? 0,
        androidAudioSessionId: null,
      ),
    );
    return LoadResponse(duration: _duration);
  }

  @override
  Future<PlayResponse> play(PlayRequest request) async {
    _owner.playCount++;
    return PlayResponse.fromMap(const {});
  }

  @override
  Future<PauseResponse> pause(PauseRequest request) async {
    _owner.pauseCount++;
    return PauseResponse.fromMap(const {});
  }

  @override
  Future<SeekResponse> seek(SeekRequest request) async {
    _owner.seeks.add(request);
    return SeekResponse.fromMap(const {});
  }

  @override
  Future<SetLoopModeResponse> setLoopMode(SetLoopModeRequest request) async {
    _owner.loopModes.add(request.loopMode);
    return SetLoopModeResponse.fromMap(const {});
  }

  @override
  Future<SetVolumeResponse> setVolume(SetVolumeRequest request) async =>
      SetVolumeResponse.fromMap(const {});

  @override
  Future<SetSpeedResponse> setSpeed(SetSpeedRequest request) async =>
      SetSpeedResponse.fromMap(const {});

  @override
  Future<SetShuffleModeResponse> setShuffleMode(
    SetShuffleModeRequest request,
  ) async => SetShuffleModeResponse.fromMap(const {});

  @override
  Future<SetAutomaticallyWaitsToMinimizeStallingResponse>
  setAutomaticallyWaitsToMinimizeStalling(
    SetAutomaticallyWaitsToMinimizeStallingRequest request,
  ) async => SetAutomaticallyWaitsToMinimizeStallingResponse.fromMap(const {});

  @override
  Future<DisposeResponse> dispose(DisposeRequest request) async =>
      DisposeResponse.fromMap(const {});
}
