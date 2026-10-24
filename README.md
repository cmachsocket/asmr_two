# asmr_two

基于 [asmr.one](https://asmr.one) 公开接口的 Flutter 客户端，当前实现了完整的接口层与播放层。

> 非官方项目，与 asmr.one 无隶属关系。接口与数据均来自其公开接口，请勿用于商业用途。

## 接口层

```
lib/core/
├── api/
│   ├── api_client.dart     传输层：线路故障转移、鉴权头、错误归一化
│   ├── api_endpoints.dart  接口路径、请求枚举、搜索关键字编码
│   ├── api_exception.dart  统一异常
│   └── asmr_api.dart       接口方法集合
├── models/                 数据模型
└── storage/                令牌与偏好存储
```

- 线路：`api.asmr-200.com`（默认）、`api.asmr.one`、`api.asmr-100.com`、`api.asmr-300.com`，
  连接失败或超时时自动按顺序切换。
- 鉴权：登录后由 `Bearer <jwt>` 传递，付费作品的播放与下载地址需要带上令牌。
- 筛选：服务端不接收独立筛选参数，筛选条件编码成搜索关键字交给搜索接口解析，
  形如 `耳ほじ $tag:ASMR$ $-tag:治愈$`。

接口清单与参数说明见 [docs/api.md](docs/api.md)。

## 播放层

```
lib/core/audio/
├── audio_player_service.dart  音频引擎：唯一入口，把播放器状态聚合成一个快照
├── playback_item.dart         播放队列条目（音频轨道 + 所属作品）
├── playback_snapshot.dart     播放状态快照（进度、队列、循环、错误）
└── track_plan.dart            曲目树 → 播放队列 + 展示行
lib/state/
├── player_controller.dart     播放 UI 状态：镜像快照并转发命令
└── work_detail_controller.dart 作品详情状态与播放入口
```

- 引擎：`just_audio`；桌面端（Linux / Windows）额外启用 `media_kit` 后端，
  Android / iOS / macOS 走系统后端。
- 状态聚合：播放器的播放状态、进度、时长、当前下标与错误统一收敛到
  `PlaybackSnapshot`，界面只订阅这一个对象。
- 播放地址在起播那一刻解析：付费作品的地址带登录令牌，提前解析会拿到失效地址；
  解析不出地址的条目会被跳过，全部解析不出时提示需要登录。
- 只做顺序播放，不提供乱序。

## 开发

```bash
flutter pub get
flutter analyze
flutter test
dart run tool/api_smoke_check.dart   # 对线上接口做一次冒烟检查
```

## Git hooks

```bash
bash tool/install_git_hooks.sh        # 装 pre-commit 自检
python3 tool/find_magic_numbers.py   # 列出 lib/ 下还没命名的数字（仅 review，不拦）
```

pre-commit 拦「业务 widget 里的硬编码数字」（`EdgeInsets.all(12)`、`fontSize: 14`、
`width: 120` 这类），按 AGENTS.md 的规矩，尺寸要来自主题或比例式工具。
紧急情况用 `git commit --no-verify`，并在 commit message 里写清原因。

