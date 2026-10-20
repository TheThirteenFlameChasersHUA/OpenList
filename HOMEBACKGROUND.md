# 首页自定义背景（Fork 扩展）

这个 fork 给 OpenList 增加了一个可选的首页背景层。背景配置由管理员在
`管理 -> 设置 -> Home Background` 中维护，保存到后端设置表，所有访客共享。

## 功能

- 支持图片 URL、`data:` URL、CSS 渐变和 CSS 颜色
- 支持本地图片上传；浏览器端会先缩放到最长边 1920px，并编码为 WebP
  后以 data URL 形式保存，避免再增加一套文件上传/静态目录服务
- 可调背景模糊（0-30px）和主题色遮罩（0-100%）
- 启用背景时，页头、面包屑和文件列表卡片自动切换为半透明玻璃样式
- 背景值为空时完全回退原版布局：`HomeBackground` 只渲染原来的 children，
  不产生额外 DOM
- 深浅色主题都使用对应的遮罩与玻璃色

## 后端改动

新增设置项（均为 PUBLIC，前端可从 `/api/public/settings` 读取）：

| key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `home_background` | text | 空 | 图片 URL、data URL、CSS 渐变或颜色 |
| `home_background_blur` | number | `0` | 模糊半径，前端限制 0-30 |
| `home_background_mask` | number | `50` | 遮罩不透明度，前端限制 0-100 |

改动文件：

- `internal/conf/const.go`：新增三个设置 key 常量
- `internal/model/setting.go`：新增扩展分组 `BACKGROUND = 100`
- `internal/bootstrap/data/setting.go`：在 `InitialSettings()` 中注册默认值

### 为什么分组用 100

上游的 settings group 是一个连续的 `iota` 枚举。为了避免将来上游追加新分组时
发生数字冲突，这个 fork 把背景分组固定为 `100`，并且不修改上游 `Group` 枚举的
现有顺序。前端也使用独立的 `BACKGROUND_GROUP` 常量，而不是扩展 `Group` 枚举。

## 前端改动

新增文件：

- `src/components/home-background/index.tsx`：首页背景组件
- `src/components/home-background/style.css`：背景层、遮罩、玻璃效果
- `src/components/home-background/util.ts`：CSS 值解析、图片压缩、URL 安全处理
- `src/components/home-background/group.ts`：前端 `BACKGROUND_GROUP = 100`
- `src/pages/manage/settings/Background.tsx`：管理页
- `src/pages/manage/settings/Background.css`：管理页预览/预设样式

接入点（只有 4 处）：

- `src/pages/home/Layout.tsx`：用 `<HomeBackground>` 包住原有首页内容
- `src/pages/manage/sidemenu_items.tsx`：新增设置子菜单和路由组件
- `src/lang/en/manage.json`：菜单文案
- `src/lang/en/settings.json`：设置项和页面文案

其余语言由 Crowdin 生成；合并上游后需要把新增 key 同步到 Crowdin 项目，
否则非英文语言会回退到英文。

## 构建

上游 `build.sh` 默认从 `OpenListTeam/OpenList-Frontend` 的 Release 下载前端。
使用本 fork 的前端时，先在 `OpenList-Frontend` 构建，再把 `dist` 放进后端的
`public/dist`：

```bash
cd OpenList-Frontend
corepack pnpm install --frozen-lockfile
corepack pnpm build

cd ../OpenList
rm -rf public/dist
mkdir -p public/dist
cp -R ../OpenList-Frontend/dist/. public/dist/
go build -o openlist .
```

`public/dist` 已被 `.gitignore` 忽略，构建产物不会进入提交。

### Docker

源码方式构建镜像（会从 fork 的前端 tag 拉取前端）：

```bash
docker build -f Dockerfile.fork -t openlist-home-background:latest .
```

或使用 Compose：

```bash
docker compose -f docker-compose.fork.yml up -d --build
```

GitHub Release `home-background-v1` 还提供了一个预编译 Docker 构建包：

```text
openlist-home-background-docker-v1-linux.tar.gz
```

解压后可直接 `docker build`，不需要 Node.js 或 Go 环境。

## 上游合并检查清单

1. `internal/conf/const.go`：保留三个 `HomeBackground*` 常量
2. `internal/bootstrap/data/setting.go`：保留三条 `InitialSettings` 记录
3. `internal/model/setting.go`：保留独立的 `const BACKGROUND = 100`
4. `src/pages/home/Layout.tsx`：保留 `<HomeBackground>` 包裹层
5. `src/pages/manage/sidemenu_items.tsx`：保留 `background` 子菜单
6. 如果上游重写设置保存流程，只需要适配 `Background.tsx` 的
   `/admin/setting/list`、`/admin/setting/save` 调用
7. 不要为了这个功能修改 `src/pages/manage/settings/Common.tsx` 或
   `SettingItem.tsx`，这样上游设置页重构时冲突最小

## 验证记录

- `corepack pnpm build` 通过
- `go build` 通过
- 生产模式启动后写入设置并重启，三个设置值仍然存在
- 管理页：预设、URL/渐变输入、本地上传、实时预览、清空、保存均可用
- 首页：浅色/深色/移动端截图验证，背景关闭时回退原版
- `corepack pnpm lint` 仍有上游已有的类型错误（Monaco、archive、
  AddOrEdit 等），本次新增文件没有产生新的类型错误
