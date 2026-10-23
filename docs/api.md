# asmr.one 接口文档

本文档记录 asmr_two 使用的 asmr.one 公开接口。

所有条目均以官网前端当前使用的形式为准，并经线上接口验证。
「Dart 方法」列给出 `AsmrApi` 中对应的封装方法。

## 线路

| 名称 | 地址 |
| --- | --- |
| latest（默认） | `https://api.asmr-200.com` |
| original | `https://api.asmr.one` |
| mirror-100 | `https://api.asmr-100.com` |
| mirror-300 | `https://api.asmr-300.com` |

官网主域为 `https://asmr.one`，请求需带 `Referer: https://asmr.one/`。
各线路接口一致，差别只在可用性；客户端在连接失败、超时或 5xx 时按上表顺序自动切换。

## 通用约定

**请求头**

| 头 | 说明 |
| --- | --- |
| `Accept: application/json` | 固定 |
| `Content-Type: application/json` | 固定 |
| `Referer: https://asmr.one/` | 固定 |
| `Authorization: Bearer <jwt>` | 登录后接口需要；令牌来自 `POST /api/auth/me` |

**分页**

列表接口统一返回分页子对象：

```json
{
  "works": [ ... ],
  "pagination": { "currentPage": 1, "pageSize": 20, "totalCount": 62940 }
}
```

部分接口把分页放在顶层，客户端两种形态都兼容。

**错误**

```json
{ "error": "No authorization token was found" }
```

参数校验失败时附带字段明细：

```json
{
  "errors": [ { "value": "", "msg": "Invalid value", "param": "progress", "location": "body" } ],
  "error": "progress: Invalid value"
}
```

`401` 表示缺少或过期的令牌。客户端统一抛出 `ApiException`，并用 `isUnauthorized` 标识鉴权失败。

## 枚举

| 枚举 | 取值 |
| --- | --- |
| `WorkOrder` | `create_date`、`release`、`dl_count`、`rate_average_2dp`、`review_count`、`price`、`id`、`random`、`betterRandom` |
| `SortDirection` | `desc`、`asc` |
| `VoteStatus` | `0` 未投票、`1` 赞成、`2` 反对 |
| `PlaylistPrivacy` | `0` 私密、`1` 登录可见、`2` 公开 |
| `ReviewProgress` | `marked`、`listening`、`listened`、`replay`、`postponed` |
| `FeedbackType` | `start-listen`、`listen-5mins`、`listen-15mins`、`listen-30mins`、`listen-60mins`、`listen-30percent`、`listen-60percent`、`listen-90percent` |
| `CoverType` | `main`、`sam`、`240x240` |

## 搜索关键字语法

服务端不接收独立的筛选参数，筛选条件编码进搜索关键字，由搜索接口解析。

| 形式 | 含义 |
| --- | --- |
| `耳ほじ` | 普通文本 |
| `$tag:ASMR$` | 包含标签 |
| `$-tag:ASMR$` | 排除标签 |
| `"sleep sounds"` | 含空格的文本用引号包裹 |

要点：

- **结尾的 `$` 不能省**。`$tag:ASMR` 会被解析成「仅命名空间」，筛选条件不生效且结果为 0 条。
- **排除的减号紧跟 `$`**：`$-tag:治愈$`，不是 `-$tag:治愈$`。
- **值按名称匹配，不是 id**。例如 `$circle:072LABO$` 用社团名，`$tag:ASMR$` 用标签名。
- 多个条件用空格分隔，可与普通文本混用。

可用命名空间：

| 命名空间 | 别名 | 取值 | 语义 |
| --- | --- | --- | --- |
| `tag` | `t` | 标签名 | 包含 |
| `circle` | `c` | 社团名 | 包含 |
| `va` | `v` | 声优名 | 包含 |
| `age` | | `adult`、`r15`、`general` | 包含 |
| `lang` | | `JPN`、`ENG`、`CHI`、`CHI_HANS`、`CHI_HANT`、`KO_KR` | 包含 |
| `rate` | | 数值 | 评分 ≥ |
| `price` | | 日元整数 | 价格 = |
| `sell` | | 整数 | 销量 ≥ |
| `duration` | `d` | 秒 | 时长 ≥ |

## 作品

### GET `/api/works`

作品列表。

| 参数 | 类型 | 说明 |
| --- | --- | --- |
| `order` | string | 见 `WorkOrder`，默认 `create_date` |
| `sort` | string | `desc` / `asc` |
| `page` | int | 页码，从 1 开始 |
| `pageSize` | int | 每页数量 |
| `seed` | int | 随机种子，配合 `order=random` 使用 |
| `subtitle` | int | `1` 只看有字幕，`0` 只看无字幕；不传不限制 |
| `withPlaylistStatus[]` | string[] | 收藏状态所属的播放列表 id（UUID），可重复 |

响应：`{ works: Work[], pagination }`

Dart 方法：`fetchWorks`、`fetchRandomWork`

### GET `/api/work/{id}`

作品详情。响应为单个 `Work` 对象。

Dart 方法：`fetchWork`

### GET `/api/workInfo/{id}`

作品详情的备用路径，部分线路只挂了其中一个。

Dart 方法：`fetchWorkInfo`

### GET `/api/tracks/{id}?v=2`

作品曲目树。`v=2` 不能省。

响应为节点数组，节点的 `type` 取值：

| type | 说明 |
| --- | --- |
| `folder` | 目录，含 `children` |
| `audio` | 音频，可播放 |
| `image` | 图片 |
| `text` | 文本 |

Dart 方法：`fetchTracks`

### 搜索

`GET /api/search/{keyword}`，关键字需 `encodeURIComponent`。

| 参数 | 类型 | 说明 |
| --- | --- | --- |
| `order` | string | 见 `WorkOrder` |
| `sort` | string | `desc` / `asc` |
| `page` | int | 页码 |
| `pageSize` | int | 每页数量 |
| `seed` | int | 随机种子 |
| `subtitle` | int | `1` / `0` |
| `includeTranslationWorks` | bool | 是否包含翻译版，默认 `true` |
| `withPlaylistStatus[]` | string[] | 播放列表 id（UUID） |

关键字超过 500 字符时改用 `POST /api/search/`，请求体为
`{ keyword, order, sort, page, pageSize, seed, subtitle, localSubtitledWorks, includeTranslationWorks, withPlaylistStatus }`。

Dart 方法：`searchWorks`

### Work 字段

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | int | 站内作品 id |
| `title` | string | 标题 |
| `circle_id` | int | 社团 id |
| `name` | string | 社团名 |
| `nsfw` | bool | 是否成人向 |
| `release` | string | 发售日期 |
| `dl_count` | int | 销量 |
| `price` | int | 售价（日元），`0` 为免费 |
| `review_count` | int | 评论数 |
| `rate_count` | int | 评分人数 |
| `rate_average_2dp` | number | 平均评分，可能是 `5` 也可能是 `4.69` |
| `rate_count_detail` | array | 评分分布，元素含 `review_point`、`count`、`ratio` |
| `rank` | array | 榜单，元素含 `term`、`category`、`rank`、`rank_date` |
| `has_subtitle` | bool | 是否带字幕 |
| `create_date` | string | 入库日期 |
| `vas` | array | 声优，元素含 `id`、`name` |
| `tags` | array | 标签，元素含 `id`、`name`、`i18n`、`count`、投票字段 |
| `language_editions` | array | 其它语言版本，元素含 `lang`、`label`、`workno` |
| `age_category_string` | string | `adult` / `r15` / `general` |
| `duration` | int | 总时长（秒） |
| `source_type` | string | 来源站点，如 `DLSITE` |
| `source_id` | string | 来源编号，如 `RJ01712623` |
| `source_url` | string | 来源页面地址 |
| `circle` | object | 社团对象，含 `id`、`name`、`source_id`、`source_type` |
| `mainCoverUrl` / `samCoverUrl` / `thumbnailCoverUrl` | string | 封面地址 |
| `userRating` | number | 当前用户的评分 |
| `review_text` | string | 当前用户的评论 |
| `progress` | string | 当前用户的收听进度 |

标签的 `i18n` 形如 `{ "ja-jp": { "name": "癒し" }, "zh-cn": { "name": "治愈" } }`。

## 标签 / 社团 / 声优

### GET `/api/tags/`

标签全集，返回数组。元素含 `id`、`name`、`i18n`、`count`。

### GET `/api/tags/{id}`

单个标签。

### GET `/api/circles/`

社团全集，返回数组。元素含 `id`、`name`、`count`、`i18n`。

### GET `/api/circles/{id}`

单个社团。含 `id`、`name`、`source_type`、`source_id`、`i18n`。

### GET `/api/vas/`

声优全集，返回数组。元素含 `id`（UUID）、`name`、`count`、`i18n`。

### GET `/api/vas/{id}`

单个声优。**注意**：用列表里的 UUID 调用会返回 `400 Invalid value`。

Dart 方法：`fetchTags`、`fetchTag`、`fetchCircles`、`fetchCircle`、`fetchVoiceActors`、`fetchVoiceActor`

## 账号

### POST `/api/auth/me`

登录。请求体 `{ name, password }`，**不要带 `Authorization` 头**。

响应：

```json
{
  "user": { "loggedIn": true, "name": "...", "group": "user", "email": null, "recommenderUuid": "..." },
  "token": "<jwt>"
}
```

**账号不存在时服务端会自动创建**，因此这一步同时完成注册。

### GET `/api/auth/me`

当前会话，需要 `Authorization` 头。响应 `{ user, auth, reg }`，后两项是服务端是否开启登录与注册。

### POST `/api/auth/reg`

注册。请求体 `{ name, password, recommenderUuid? }`，响应同上，含 `token`。

Dart 方法：`login`、`register`、`fetchSession`

## 评论与投票

### GET `/api/review`

我的评论列表。参数 `page`、`order`、`sort`、`filter`。

响应 `{ works: Work[], pagination }`，`works` 里的作品带本人 `userRating`、`review_text`、`progress`。

### PUT `/api/review`

提交或更新评分与评论。

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `work_id` | int | 作品 id |
| `rating` | number \| null | `1`~`5`，`null` 表示清除评分 |
| `review_text` | string | 评论正文 |
| `progress` | string | 见 `ReviewProgress`，只接受这 5 个取值 |

响应 `{ message }`。

### DELETE `/api/review?work_id={id}`

删除我在该作品上的标记与评论。响应 `{ message }`。

### POST `/api/vote/vote-work-tag`

标签投票。

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `workID` | int | 作品 id |
| `tagID` | int | 标签 id |
| `status` | int | `0` 未投票、`1` 赞成、`2` 反对 |

响应 `{ success: true }`。

Dart 方法：`fetchMyReviews`、`submitReview`、`deleteReview`、`voteWorkTag`

## 播放列表

列表 id 是 **UUID 字符串**，`privacy` 是 **整数**。

### GET `/api/playlist/get-work-exist-status-in-my-playlists`

我的播放列表。

| 参数 | 类型 | 说明 |
| --- | --- | --- |
| `workID` | int | 作品 id，不关心收藏状态时传 `0` |
| `page` | int | 页码 |
| `pageSize` | int | 每页数量，官网默认 12 |
| `version` | int | 固定 `2` |

响应 `{ playlists: Playlist[], pagination }`。`Playlist` 字段：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | string | UUID |
| `name` | string | 名称 |
| `description` | string | 描述 |
| `privacy` | int | `0` 私密、`1` 登录可见、`2` 公开 |
| `locale` | string | 语言标记 |
| `user_name` | string | 所属用户 |
| `works_count` | int | 作品数量 |
| `liked_count` | int | 点赞数 |
| `playback_count` | int | 播放数 |
| `created_at` / `updated_at` | string | 时间 |
| `exist` | bool | 该作品是否已在此列表中 |

系统内置列表的 `name` 以 `__SYS_PLAYLIST_` 开头。

### GET `/api/playlist/get-playlist-metadata?id={id}`

播放列表详情，返回单个 `Playlist`。

### GET `/api/playlist/get-default-mark-target-playlist`

默认收藏目标列表，返回单个 `Playlist`。

### POST `/api/playlist/create-playlist`

创建播放列表。请求体 `{ name, privacy, locale, description, works }`，
`privacy` 是整数，`works` 是站内作品 id 数组。响应为新建的 `Playlist`。

### POST `/api/playlist/add-works-to-playlist`

请求体 `{ id, works }`，`works` 是**站内数字作品 id** 数组。响应 `{ id, rowCount }`。

### POST `/api/playlist/remove-works-from-playlist`

请求体同上。响应 `{ id, rowCount }`。

**注意**：`works` 用站内 id（如 `1712623`），传 DLsite 编号（如 `RJ01712623`）会被拒绝。

Dart 方法：`fetchMyPlaylists`、`fetchPlaylistDetail`、`fetchDefaultPlaylist`、`createPlaylist`、`addWorksToPlaylist`、`removeWorksFromPlaylist`

## 推荐

以下四个接口的响应统一是 `{ works: Work[], pagination }`。

### POST `/api/recommender/popular`

热门推荐。请求体 `{ keyword, page, pageSize, subtitle, localSubtitledWorks, withPlaylistStatus }`。

### POST `/api/recommender/recommend-for-user`

个性化推荐。请求体在热门推荐基础上多一个 `recommenderUuid`，取自 `GET /api/auth/me`。

### POST `/api/recommender/item-neighbors`

相似作品。请求体 `{ keyword, itemId, localSubtitledWorks, withPlaylistStatus }`。

### POST `/api/recommender/feedback`

行为上报。请求体 `{ type, recommenderUuid, itemId }`，`type` 见 `FeedbackType`。响应为 `1`。

Dart 方法：`fetchPopular`、`fetchRecommended`、`fetchSimilarWorks`、`reportFeedback`

## 资源地址

| 接口 | 说明 |
| --- | --- |
| `GET /api/cover/{id}.jpg?type=main\|sam\|240x240` | 封面，`type` 只支持这三种 |
| `GET /api/media/stream/{hash}?token={jwt}` | 播放 |
| `GET /api/media/stream-low/{hash}?token={jwt}` | 低码率播放，需要登录，官网未使用 |
| `GET /api/media/download/{hash}?token={jwt}` | 下载 |

`hash` 形如 `1712623/1963358`，取自曲目节点的 `hash` 字段。

曲目节点里的 `mediaStreamUrl`、`mediaDownloadUrl` 是 CDN 直链，免费作品可直接播放；
付费作品这两个字段为空，需要回退到带令牌的接口地址。客户端的
`resolveStreamUrl` / `resolveDownloadUrl` 负责这层回退。

## Dart 接口对照

| 分类 | 方法 |
| --- | --- |
| 线路 | `checkHealth` |
| 作品 | `fetchWorks`、`fetchRandomWork`、`fetchWork`、`fetchWorkInfo`、`fetchTracks`、`searchWorks` |
| 标签 / 社团 / 声优 | `fetchTags`、`fetchTag`、`fetchCircles`、`fetchCircle`、`fetchVoiceActors`、`fetchVoiceActor` |
| 账号 | `fetchSession`、`login`、`register` |
| 评论 / 投票 | `fetchMyReviews`、`submitReview`、`deleteReview`、`voteWorkTag` |
| 播放列表 | `fetchMyPlaylists`、`fetchPlaylistDetail`、`fetchDefaultPlaylist`、`createPlaylist`、`addWorksToPlaylist`、`removeWorksFromPlaylist` |
| 推荐 | `fetchPopular`、`fetchRecommended`、`fetchSimilarWorks`、`reportFeedback` |
| 资源 | `coverUrl`、`streamUrl`、`downloadUrl`、`resolveStreamUrl`、`resolveDownloadUrl`、`webUrl` |
