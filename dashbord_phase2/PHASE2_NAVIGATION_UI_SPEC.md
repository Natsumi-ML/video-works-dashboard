---
title: "編集進行ボード Phase 2 / サブ画面 UI・UX 実装仕様書"
spec_version: "1.0.0"
status: "Implementation Ready"
language: "ja-JP"
target: "Claude Code"
scope:
  - "動画一覧"
  - "今日"
  - "進行トラック"
  - "チーム負荷"
  - "投稿待ち"
primary_reference: "phase2-concepts-reference.png"
home_reference: "current-home-reference.png"
implementation_priority:
  - "既存ホーム画面との視覚的一貫性"
  - "一目で状況を把握できること"
  - "1クリックで次工程へ進められること"
  - "重要情報を探さなくてよいこと"
  - "入力・確認工数を減らすこと"
---

# 編集進行ボード Phase 2
# サブ画面 UI・UX 実装仕様書

## 0. この仕様書の目的

この仕様書は、すでに実装済みの「ホーム」画面をデザイン基準として、左メニューから遷移する以下5画面を同じデザイン言語で再設計・実装するための仕様である。

1. **動画一覧**
2. **今日**
3. **進行トラック**
4. **チーム負荷**
5. **投稿待ち**

既存画面の機能・データは可能な限り維持しつつ、見た目・情報階層・操作導線をホーム画面と統一する。

このPhaseでは、機能を増やすことよりも、以下を優先する。

- 重要な情報が大きく見える
- 色を見るだけで状態を理解できる
- 画面を開いた瞬間に「次に何をすべきか」が分かる
- 表のセルを細かく読まなくても判断できる
- タスクを1クリックで次工程へ進められる
- 動画詳細をどの画面からでも同じ方法で確認・操作できる
- 毎日長時間使っても視覚的に疲れにくい
- 「業務シート」ではなく「日常的に使いたくなるSaaS」に見える

---

# 1. Claude Code への最重要実装指示

## 1.1 既存コードを先に確認すること

実装開始前に、必ず既存リポジトリを調査する。

最低限、以下を確認する。

1. framework / runtime
2. `package.json`
3. routing構成
4. state管理方法
5. API / mock dataの置き場所
6. 既存のHome画面コンポーネント
7. Sidebar / Header / Detail Drawer の実装
8. CSS / Tailwind / CSS Modules / styled-components 等のスタイル方式
9. design token / theme定義
10. icon library
11. date utility
12. table / chart / dialog / toast 等の共通UI

### MUST

- 既存の技術スタックを不要に変更しない。
- ホーム画面を壊さない。
- ホーム画面で使われている色、角丸、影、余白、ボタン、フォント階層を再利用する。
- 同じ概念のコンポーネントを重複実装しない。
- データと表示ロジックを分離する。
- KPI数値は可能な限り元データから算出し、画面ごとに別値をハードコードしない。

### MUST NOT

- サブ画面だけ別のUIライブラリに置き換えない。
- ホームと異なるステータス色を使わない。
- 画面ごとに異なる「動画詳細UI」を作らない。
- 同じデータを複数箇所に手動で重複定義しない。
- モーダルを多用しない。
- ワンクリックで済む状態更新に確認ダイアログを挟まない。
- 1画面に同じ強さのカードを大量に並べない。
- 全情報を表形式に押し込まない。

---

# 2. デザイン基準

## 2.1 既存ホーム画面を「Design Source of Truth」とする

`current-home-reference.png` のホーム画面を、Phase 2全画面のデザイン基準とする。

特に以下を踏襲する。

- ダークネイビーの左サイドバー
- 明るいグレー〜白のメイン背景
- 大きな見出し
- 余白を十分に取ったカード
- KPIを大きな数字で見せる
- 状態ごとの明確な色分け
- Primary CTA は青紫系
- 危険・遅延は赤
- 投稿待ちは紫系
- 成功・投稿済みは緑
- 確認待ちは黄〜オレンジ
- 右側詳細パネル
- 選択中の項目が分かる強調
- ボタンラベルを「動詞」にする
- 表示情報を階層化し、重要情報ほど大きくする

## 2.2 Phase 2の参照デザイン

`phase2-concepts-reference.png` を、5画面の構成・密度・視線誘導の参照とする。

参照画像のピクセル完全コピーは不要。

ただし以下は再現する。

- 上部のコンパクトなKPI群
- 大きめのリスト / カード
- 重要なタスクの優先表示
- 画面右側の詳細ドロワー
- 1クリックCTA
- 同一ステータス色の統一
- 「カード → 詳細 → 操作」の視線導線
- 各ページ固有の目的が一目で分かる構造

---

# 3. 共通デザインシステム

## 3.1 カラートークン

既存ホームにトークンがある場合は、下記に置き換えず既存値を優先する。
存在しない場合のみ下記を初期値として使用する。

```css
:root {
  --app-bg: #f4f7fb;
  --surface: #ffffff;
  --surface-subtle: #f8fafc;
  --surface-hover: #f1f5f9;

  --sidebar-bg: #0f1d2e;
  --sidebar-surface: #17283d;
  --sidebar-hover: #23364d;

  --text-primary: #0f172a;
  --text-secondary: #64748b;
  --text-muted: #94a3b8;
  --text-on-dark: #f8fafc;
  --text-on-dark-muted: #b8c5d6;

  --border: #e2e8f0;
  --border-strong: #cbd5e1;

  --primary: #5546ed;
  --primary-hover: #4637dc;
  --primary-soft: #eeecff;

  --status-unstarted: #3b82f6;
  --status-editing: #14a3a3;
  --status-review: #f59e0b;
  --status-approved: #22a06b;
  --status-waiting-post: #6d4aff;
  --status-posted: #0f9f6e;

  --danger: #ef4444;
  --danger-dark: #b91c1c;
  --danger-soft: #fee2e2;

  --warning: #f59e0b;
  --warning-soft: #fff7db;

  --success: #16a34a;
  --success-soft: #dcfce7;
}
```

## 3.2 ステータス色は固定する

全画面で以下を統一する。

| status key | 日本語 | 色 | 用途 |
|---|---|---|---|
| `not_started` | 未着手 | Blue | まだ作業開始していない |
| `editing` | 編集中 | Teal | 編集作業中 |
| `review` | 確認中 / 確認待ち | Amber | 社員・クライアント確認 |
| `approved` | 承認済み | Green | 内容承認済み |
| `waiting_post` | 投稿待ち | Purple | 承認済みだが未投稿 |
| `posted` | 投稿済み / 投稿完了 | Emerald | 公開・投稿済み |
| `delayed` | 遅延 | Red | 締切超過・要対応 |

### 重要

`approved` と `waiting_post` と `posted` は必ず別状態にする。

**承認済み = 完了ではない。**

---

# 4. 共通レイアウト

## 4.1 Desktop基準

主な利用環境はPC。

推奨ターゲット：

- 基準幅: `1600px`
- 最適: `1440px - 1920px`
- 最低: `1280px`
- 高さ: `800px` 以上

## 4.2 Shell

```text
┌──────────────┬───────────────────────────────────────┬──────────────────┐
│              │ Header                                │                  │
│ Left Sidebar ├───────────────────────────────────────┤ Detail Drawer    │
│              │ Page Content                          │                  │
│              │                                       │                  │
│              │                                       │                  │
└──────────────┴───────────────────────────────────────┴──────────────────┘
```

推奨値：

| 項目 | 値 |
|---|---:|
| Sidebar | 200〜220px |
| Detail Drawer | 320〜360px |
| Content horizontal padding | 24〜32px |
| Section gap | 20〜28px |
| Card radius | 12〜16px |
| Compact card radius | 10〜12px |
| Main shadow | `0 8px 24px rgba(15,23,42,.06)` |
| Border | 1px solid soft gray |

## 4.3 Header

全サブ画面でHomeと同じHeaderを再利用する。

含める要素：

- 左: ページタイトル
- 必要に応じサブコピー
- 右:
  - 今日の日付
  - 対象月
  - お知らせ
  - 最終更新時刻
  - 未同期件数

Header自体の高さや余白を画面ごとに変えない。

---

# 5. 共通コンポーネント設計

以下を共通化する。

```text
AppShell
├── Sidebar
├── TopHeader
├── PageContainer
├── KpiStrip
│   └── KpiCard
├── SectionHeader
├── StatusBadge
├── PriorityBadge
├── UserAvatar
├── VideoThumb
├── ProgressRing
├── ProgressBar
├── PrimaryActionButton
├── SecondaryActionButton
├── EmptyState
├── Skeleton
├── Toast
└── EntityDetailDrawer
    ├── VideoDetailHeader
    ├── DetailTabs
    ├── VideoMeta
    ├── WorkflowStepper
    ├── DriveLink
    ├── ActivityTimeline
    └── DetailActionBar
```

## 5.1 KPI Card

KPIカードは、単なる数字カードではなく「状態判断」に使う。

最低情報：

- ラベル
- 大きな数値
- 単位
- 補足
- アイコン
- 必要に応じステータス色
- 必要に応じprogress bar

推奨：

```text
label         14 件
補足          前日比 +2
```

数字:

- `32〜40px`
- font-weight `700〜800`

ラベル:

- `14〜16px`
- font-weight `600〜700`

カード高さ:

- `112〜140px`

## 5.2 StatusBadge

```ts
type WorkflowStatus =
  | 'not_started'
  | 'editing'
  | 'review'
  | 'approved'
  | 'waiting_post'
  | 'posted';
```

StatusBadgeは以下を持つ。

```ts
interface StatusBadgeProps {
  status: WorkflowStatus;
  compact?: boolean;
}
```

表示文言は1箇所で管理する。

```ts
const workflowStatusLabel = {
  not_started: '未着手',
  editing: '編集中',
  review: '確認中',
  approved: '承認済み',
  waiting_post: '投稿待ち',
  posted: '投稿済み',
};
```

## 5.3 PrimaryActionButton

各動画の現在ステータスに応じて、自動で次操作ラベルを返す。

```ts
const nextActionLabel = {
  not_started: '着手する',
  editing: '編集完了',
  review: '確認OK',
  approved: '投稿待ちへ',
  waiting_post: '投稿した',
  posted: '完了',
};
```

`posted` の場合は通常disabledまたは非表示。

### 原則

- クリック前確認モーダルは出さない
- 成功Toastを表示
- Toastに `元に戻す` を表示
- 5〜8秒以内ならUndo可能
- 保存失敗時はUIをロールバック

---

# 6. 共通右側詳細パネル

## 6.1 最重要方針

**全画面で同じ動画詳細パネルを使用する。**

動画一覧専用、今日専用、投稿待ち専用の詳細UIを作らない。

違うのは「どこから動画を見つけたか」だけ。

操作場所は統一する。

## 6.2 動作

- 動画カード / 行 / トラック上マーカーをクリック
- 右側に選択した動画を表示
- Desktopでは固定パネル
- 1280px付近ではdrawer化してよい
- URL queryまたはroute stateで選択動画IDを保持してもよい

例：

```text
/videos?video=video_001
/today?video=video_001
/progress?video=video_001
/pending-posts?video=video_001
```

## 6.3 パネル内容

上から：

1. `動画詳細`
2. 閉じる
3. サムネイル
4. ステータスbadge
5. 動画タイトル
6. クライアント
7. 種別
8. 担当
9. 投稿予定
10. 編集完了希望
11. 工程
12. 投稿担当
13. Google Drive CTA
14. Tabs
15. 下部固定 Action Bar

Tabs:

- 詳細
- 工程履歴
- 投稿記録
- コメント
- ファイル（実装済みデータがある場合）

## 6.4 Google Drive

URLが存在する場合：

```text
[ Google Drive フォルダを開く ↗ ]
```

- 新規タブ
- `rel="noopener noreferrer"`
- 大きな横幅100%ボタン

未設定の場合：

```text
Google Drive フォルダが未設定です
[ Drive URLを設定 ]
```

権限がない場合はdisabled + reason。

## 6.5 下部Action Bar

パネル下部にsticky。

```text
[ 1段戻す ] [ 確認OK ]
```

次工程CTAをPrimaryにする。

### ボタン順

左 = Secondary / 戻す  
右 = Primary / 次へ

---

# 7. データモデル

既存型がある場合はそちらを尊重する。
新規定義が必要な場合のみ参考にする。

```ts
type WorkflowStatus =
  | 'not_started'
  | 'editing'
  | 'review'
  | 'approved'
  | 'waiting_post'
  | 'posted';

type ContentType = 'video' | 'static';

interface TeamMember {
  id: string;
  name: string;
  role: 'employee' | 'editor' | 'manager' | 'poster';
  avatarUrl?: string;
  initials?: string;
}

interface Client {
  id: string;
  name: string;
  shortName?: string;
}

interface Contract {
  id: string;
  clientId: string;
  name: string;
  month: string; // YYYY-MM
  contentType: ContentType;
  monthlyRequiredCount: number;
  postedCount: number;
  waitingPostCount: number;
  delayedCount: number;
  plannedDates?: string[];
}

interface VideoItem {
  id: string;
  clientId: string;
  contractId: string;

  title: string | null;
  type: ContentType;

  assigneeId: string | null;
  posterId?: string | null;

  status: WorkflowStatus;

  editDueDate?: string | null;
  postDueDate?: string | null;
  postedAt?: string | null;
  approvedAt?: string | null;

  driveFolderUrl?: string | null;
  referenceUrls?: string[];

  thumbnailUrl?: string | null;

  createdAt: string;
  updatedAt: string;
}

interface VideoActivity {
  id: string;
  videoId: string;
  type:
    | 'status_changed'
    | 'assignee_changed'
    | 'drive_link_added'
    | 'comment_added'
    | 'posted';
  actorId: string;
  createdAt: string;
  meta?: Record<string, unknown>;
}
```

---

# 8. 派生値の計算ルール

KPIはできる限りデータから計算する。

## 8.1 投稿待ち

```ts
video.status === 'waiting_post'
```

## 8.2 投稿済み

```ts
video.status === 'posted'
```

## 8.3 本日期限

投稿予定日または編集完了希望日が今日で、未完了。

優先順位：

1. `postDueDate`
2. `editDueDate`

## 8.4 遅延

最低限以下。

```ts
postDueDate < today && status !== 'posted'
```

必要に応じて制作工程の遅延も追加。

## 8.5 今日の処理待ち

ログインユーザーが担当する未完了タスク。

```ts
assigneeId === currentUser.id &&
status !== 'posted'
```

必要なら投稿担当も含める。

## 8.6 契約進捗率

```ts
postedCount / monthlyRequiredCount
```

0除算に注意。

## 8.7 契約リスク

Phase 2では複雑な予測AIは不要。

まず下記のルールベースでよい。

`danger`:

- 投稿予定日を過ぎた未投稿動画がある
- 月末までの残日数より残投稿数が明らかに多い
- 月後半で投稿0本
- 48h以上投稿待ち

`warning`:

- 1本遅延
- 進捗が期待ペースをやや下回る

`healthy`:

- 上記以外

---

# 9. 画面1: 動画一覧

Route例：

```text
/videos
```

Sidebar label:

```text
動画一覧
```

## 9.1 目的

「全動画を探す画面」ではあるが、最初に危険案件を見つけられるようにする。

現在のスプレッドシート型一覧を、以下の優先度へ変更する。

1. 状況把握
2. 優先対応
3. 検索・絞り込み
4. 全件一覧
5. 詳細操作

## 9.2 ページ構成

```text
PageHeader
KpiStrip
PriorityVideos
FilterBar
VideoList
DetailDrawer
```

## 9.3 KPI

推奨5枚。

1. 全動画
2. 自分の未完了
3. 本日締切
4. 投稿待ち
5. 遅延

例：

```text
全動画        50本
自分の未完了  14本
本日締切      3本
投稿待ち      3本
遅延          1本
```

### 色

- 全動画: navy/blue
- 自分の未完了: blue
- 本日締切: orange
- 投稿待ち: purple
- 遅延: red

## 9.4 優先対応セクション

見出し：

```text
優先対応
今すぐ確認したい動画
```

表示対象：

- 遅延
- 今日締切
- 投稿待ち
- 48h以上投稿待ち
- タイトル未設定など重要な未入力

最大3〜5件。

横カードで表示する。

### PriorityVideoCard

表示：

- Client badge / initials
- クライアント名
- タイトル
- StatusBadge
- 投稿予定
- 編集完了希望
- 担当者
- 遅延日数 / 残り日数
- Primary CTA

カード幅：

- 3列が基本
- 1280pxでは2列可

## 9.5 FilterBar

順番：

1. 担当
2. ステータス
3. クライアント
4. 検索
5. sort

検索対象：

- クライアント名
- 動画タイトル
- 担当者
- ID（任意）

### Default

編集スタッフ：

- 自分の担当
- 未完了

社員：

- 全担当
- 未完了

roleでdefaultを変えてよい。

## 9.6 全動画リスト

現在の横長表より、行高を大きくする。

推奨:

- row height `64〜76px`
- header `40〜44px`

Columns:

1. クライアント
2. タイトル / 種別
3. 担当
4. 投稿予定
5. 編集完了希望
6. 状態
7. action

### タイトル未設定

`(タイトル未定)` を青紫リンク風表示。

クリックで詳細のTitle編集欄へfocus。

## 9.7 行操作

行自体クリック:

- Detail Drawer open

Primary CTA:

- ステータス更新
- row clickとは別イベント
- `event.stopPropagation()` 等で重複遷移防止

## 9.8 UX

- Selected rowは薄いprimary背景
- Hoverでborder/背景を軽く強調
- Sortは投稿予定の近い順がdefault
- 遅延日は赤字
- 今日締切はorange
- 今後は通常色

---

# 10. 画面2: 今日

Route例：

```text
/today
```

Sidebar:

```text
今日
```

## 10.1 目的

ユーザーが朝この画面を開けば、今日何をすればよいか迷わない状態にする。

「カレンダー」ではなく「今日の作業キュー」。

## 10.2 KPI

5枚程度。

1. 今日やること
2. 期限超過
3. 確認待ち
4. 投稿待ち
5. 未着手

例：

```text
今日やること 14件
期限超過      1件
確認待ち      5件
投稿待ち      3件
未着手        5件
```

## 10.3 セクション

以下に分ける。

```text
午前
午後
締切時間なし
完了済み（折りたたみ）
```

データに時間がない場合は、

- `午前`
- `午後`

を無理に生成せず、

```text
今日の優先
今日中
期限なし
```

でもよい。

## 10.4 TodayTaskRow

ホームのMy Tasksより明るいSurfaceで大きめにする。

表示：

- 時刻
- クライアント
- タイトル
- StatusBadge
- 投稿予定 / 編集期限
- 担当
- Primary CTA

例：

```text
10:00
アシスト / （タイトル未定）
確認中
投稿予定 8/6
担当 りりか
[ 確認OK ]
```

## 10.5 Sort

以下の順。

1. 期限超過
2. 本日・時刻あり
3. 本日・時刻なし
4. 期限なし
5. 完了済み

同カテゴリ内は時刻昇順。

## 10.6 完了動作

CTAクリック:

1. optimistic update
2. rowが軽く完了アニメーション
3. `完了済み` セクションへ移動
4. Toast + Undo
5. KPI再計算

過剰な紙吹雪等は不要。

## 10.7 「今日」の空状態

```text
今日の作業はありません
予定どおり進んでいます。
```

必要なら secondary:

```text
未完了の動画を見る
```

---

# 11. 画面3: 進行トラック

Route例：

```text
/progress
```

Sidebar:

```text
進行トラック
```

## 11.1 目的

契約ごとに「今月必要な投稿本数を期限内に消化できているか」を視覚的に確認する。

一般的なガントチャートではない。

**投稿ペース管理画面**として設計する。

## 11.2 KPI

1. 今月必要
2. 投稿済み
3. 残り
4. 投稿待ち
5. 危険契約

## 11.3 Track設計

1行 = 1契約。

同じ会社でも、

- 動画契約
- 静止画契約

は別行。

例：

```text
木下TTC 動
木下TTC 静
```

## 11.4 X軸

対象月の日付。

全日をラベル表示しない。

週単位または主要日付。

例：

```text
8/3  8/10  8/17  8/24  8/31
```

## 11.5 今日線

今日を最重要視覚要素の1つにする。

- vertical line
- dark navy
- top label `今日 8/27`
- 線の左右が明確

## 11.6 投稿マーカー

1マーカー = 1投稿。

状態：

### 投稿済み

filled circle / block:
- green or blue

### 今日より未来の予定

outlined marker:
- soft gray / primary outline

### 今日より過去で未投稿

赤い下線 / striped mark / red accent。

### 投稿待ち

purple marker。

## 11.7 右側 summary

各行右端:

```text
4 / 6本
残り 2本
遅れ 1本
[ 注意 ]
```

healthy:

```text
6 / 6本
残り 0本
遅れ 0本
● 順調
```

## 11.8 クリック

マーカークリック:

- 対応動画をDetail Drawer表示

契約名クリック:

- 契約詳細routeへ行ける場合は遷移
- 未実装ならcontract filterを適用

## 11.9 スクロール

契約が多い場合:

- 左の契約名列sticky
- 日付header sticky
- 今日線はスクロールしても残す
- 横スクロールは月表示で極力不要
- 13契約程度なら画面内優先

## 11.10 リスクの見せ方

赤を画面全体に大量使用しない。

「遅れている場所」だけに使う。

healthyなトラックはneutral / green。

---

# 12. 画面4: チーム負荷

Route例：

```text
/workload
```

Sidebar:

```text
チーム負荷
```

## 12.1 目的

スタッフの仕事量の偏りを、工数入力なしで簡単に把握する。

Phase 2では精密な工数管理ではなく、

- 今日の担当件数
- 今週の担当件数
- 遅延
- 確認待ち
- 未着手

等から負荷を見せる。

## 12.2 KPI

1. 本日のタスク
2. 高負荷スタッフ
3. 確認待ち
4. 遅延

例：

```text
本日のタスク    31件
高負荷スタッフ   1人
確認待ち         8件
遅延             4件
```

## 12.3 StaffCard Grid

Desktop:

- 3〜4列
- カード高さ統一
- スタッフ数5人なら余白を活かす

カード:

```text
Avatar
なつみ
社員

今日  8件
今週 24件
遅延  1件

███████░ 78%

やや多い
```

## 12.4 LoadScore

正確な工数ではなくUI用簡易値。

例:

```ts
loadScore =
  todayOpenCount * 8 +
  weekOpenCount * 2 +
  overdueCount * 15 +
  waitingReviewCount * 4
```

0〜100へnormalize。

重要:

- 数式はconfigとして分離
- 「工数」と表現しない
- ラベルは「負荷目安」

### Classification

```ts
0-49   -> 余裕あり
50-69  -> 適正
70-84  -> やや多い
85-100 -> 高負荷
```

## 12.5 色

- 余裕あり: blue
- 適正: green
- やや多い: orange
- 高負荷: red

## 12.6 選択スタッフ

カードをクリックすると右側Detail Drawerをスタッフ詳細モードにしてもよい。

ただしPhase 2では動画詳細と混在させない方が安全。

推奨:

- 右パネルは `StaffDetailDrawer` として同じcontainerを共有
- content componentだけ差し替える

Staff詳細：

- 今日タスク
- 投稿待ち
- 確認待ち
- 未着手
- 遅延
- 今週推移
- `タスク一覧を開く`

## 12.7 今週推移

小さな棒グラフを1つだけ使う。

Chart library導入済みなら再利用。
なければCSS barsでよい。

グラフを主役にしない。

---

# 13. 画面5: 投稿待ち

Route例：

```text
/pending-posts
```

Sidebar shortcut:

```text
投稿待ち
```

## 13.1 目的

「承認は済んでいるのに公開されていない動画」を取りこぼさない。

この画面は業務事故防止のため、非常に重要。

## 13.2 KPI

1. 投稿待ち
2. 本日期限
3. 24時間以上
4. 48時間以上

例：

```text
投稿待ち    3本
本日期限    0本
24時間以上  1本
48時間以上  0本
```

### 色

- 投稿待ち: purple
- 本日期限: orange
- 24h: orange/dark
- 48h: red

## 13.3 List

カード型の縦リストを基本とする。

各カード：

- Client badge
- クライアント
- タイトル
- 承認日時
- 投稿予定
- 経過時間
- 投稿担当
- Drive button
- `投稿した` Primary

例：

```text
ヒロダクト
セミナー告知動画

承認済み 8/25 14:20
投稿予定 8/26
投稿担当 ゆかり
承認後 28時間

[ Driveを開く ]      [ 投稿した ]
```

## 13.4 Sort

default:

1. 48h以上
2. 投稿期限超過
3. 本日期限
4. 24h以上
5. その他

## 13.5 CTA

`投稿した`

クリック後：

- status -> posted
- `postedAt = now`
- listから退場
- KPI更新
- home KPI更新
- progress更新
- Toast
- Undo

## 13.6 投稿記録

実データに投稿URLが必要な場合：

クリック直後にモーダルを出さない。

まず投稿済みにし、その後Toastまたはdetail panelで、

```text
投稿URLを追加
```

をoptionalにする。

ただし投稿URL必須の業務ルールがある場合は、inline formを使う。

---

# 14. Sidebar 再設計

現状のSidebarの良さを維持する。

推奨構成：

```text
ホーム

──── 制作
今日
動画一覧
進行トラック

──── 管理
契約
投稿カレンダー
チーム負荷

──── 要対応
処理待ち        14
投稿待ち         3
リスク           1

──── その他
クライアント
ファイル
データチェック

────────────
＋ 翌月を生成
設定
```

## 14.1 Phase 2で実装するactive routes

- ホーム
- 今日
- 動画一覧
- 進行トラック
- チーム負荷
- 投稿待ち

## 14.2 Future routes

今回未実装でも、将来以下を追加できる設計にする。

- 契約
- 投稿カレンダー
- 処理待ち
- リスク
- クライアント
- ファイル
- データチェック

未実装メニューを表示する場合は、

- disabled
- `準備中` Tooltip

のどちらかにする。

**空ページには遷移させない。**

---

# 15. 将来追加推奨機能

Phase 2では必須ではないが、データ構造とnavigationで拡張可能にする。

## 15.1 契約管理

目的:

- 契約単位の必要本数
- 投稿済み
- 残数
- 投稿待ち
- 遅延
- 次回投稿予定

会社単位ではなく契約単位。

## 15.2 投稿カレンダー

制作スケジュールではなく「投稿予定」に特化。

月表示:

- 青 = 予定
- 紫 = 投稿待ち
- 緑 = 投稿済み
- 赤 = 未投稿 / 遅延

## 15.3 処理待ち / Inbox

人間の判断が必要な項目だけ表示。

例:

- 確認待ち
- タイトル未設定
- Drive未設定
- 投稿日未設定
- 投稿記録なし

## 15.4 リスク

月末事故防止。

- 危険契約
- 遅延動画
- 月0投稿
- 48h投稿待ち
- 必要ペース不足

## 15.5 データチェック

連続入力UI。

```text
タイトル未設定 14
Drive未設定     5
投稿日未設定    3
担当未設定      0
```

「保存して次へ」で社員入力工数を下げる。

---

# 16. ナビゲーション・URL設計

既存routingに合わせる。

推奨例：

```text
/
  /home
  /today
  /videos
  /progress
  /workload
  /pending-posts
```

既存root `/` がHomeなら変更しない。

Detail selection:

```text
/videos?selected=video_001
```

filter:

```text
/videos?status=waiting_post&assignee=me
```

今日:

```text
/today?selected=video_001
```

query stateを無理に複雑化しない。

---

# 17. 状態遷移

## 17.1 Standard flow

```text
未着手
  ↓
編集中
  ↓
確認中
  ↓
承認済み
  ↓
投稿待ち
  ↓
投稿済み
```

## 17.2 1段戻す

```text
編集中 -> 未着手
確認中 -> 編集中
承認済み -> 確認中
投稿待ち -> 承認済み
投稿済み -> 投稿待ち
```

権限ルールが既にある場合は既存を優先。

## 17.3 Action labels

```ts
const actionLabels = {
  not_started: '着手する',
  editing: '編集完了',
  review: '確認OK',
  approved: '投稿待ちへ',
  waiting_post: '投稿した',
};
```

既存アプリで「確認中」「確認待ち」など名称が違う場合は、DB enumを変更せずpresentation layerで統一する。

---

# 18. 操作フィードバック

## 18.1 Toast

成功:

```text
ステータスを「投稿待ち」に更新しました
[ 元に戻す ]
```

失敗:

```text
更新できませんでした
変更を元に戻しました。
[ 再試行 ]
```

## 18.2 Loading

action click:

- buttonだけloading
- row全体をブロックしない
- optimistic update可能

page load:

- skeleton
- layout shiftを小さくする

## 18.3 Empty

空状態はエラーのように見せない。

例：

```text
投稿待ちの動画はありません
すべて投稿済みです。
```

## 18.4 Error

error bannerは画面上部。

データ全体が取れない場合のみ大きく表示。

---

# 19. 入力UX

## 19.1 原則

入力フィールドを常に大量表示しない。

見る画面と入力画面を分けすぎない。

「必要な時にその場で入力」。

## 19.2 Inline Edit対象

以下はDetail Drawer内でinline edit推奨。

- タイトル
- 担当者
- 投稿担当
- 投稿予定
- 編集完了希望
- Google Drive URL
- 参考URL

## 19.3 Save

可能ならauto-saveまたはblur-save。

明確な保存が必要な場合のみ保存ボタン。

## 19.4 Date

native date inputだけで使いにくい場合は既存DatePickerを再利用。

表示形式：

```text
2026/08/27
8/27
```

同画面内で統一。

---

# 20. 情報の優先順位

全画面で以下を守る。

## Level 1

画面を開いて3秒以内に分かる。

- KPI
- 遅延
- 今日やること
- 投稿待ち
- 危険契約

## Level 2

5〜10秒で分かる。

- 担当者
- 次の期限
- 契約進捗
- 現在工程

## Level 3

クリックして見る。

- 履歴
- URL
- ID
- コメント
- 細かいmetadata

IDや更新日時をメイン一覧で強く表示しない。

---

# 21. Typography

既存ホームのfontを優先。

新規なら:

```css
font-family:
  Inter,
  "Noto Sans JP",
  system-ui,
  -apple-system,
  BlinkMacSystemFont,
  "Segoe UI",
  sans-serif;
```

推奨:

| 用途 | サイズ | weight |
|---|---:|---:|
| Page title | 24〜30px | 700〜800 |
| Section title | 18〜22px | 700 |
| KPI number | 32〜40px | 700〜800 |
| Card title | 14〜16px | 700 |
| Body | 13〜15px | 400〜500 |
| Caption | 11〜13px | 400〜500 |
| Button | 13〜15px | 600〜700 |

---

# 22. Spacing

8px gridを基本。

```text
4
8
12
16
20
24
32
40
48
```

### 推奨

- Page section: 24〜32px
- Card padding: 16〜20px
- KPI padding: 18〜22px
- Row padding vertical: 12〜16px
- Button height: 40〜44px
- Compact button: 34〜38px

---

# 23. Button rules

## Primary

- 次工程
- 投稿した
- 確認OK
- 編集完了
- 着手する

色:

`--primary`

## Secondary

- Driveを開く
- 詳細を見る
- タスク一覧へ
- フィルタ
- 1段戻す

## Danger

削除など破壊的操作のみ。

遅延状態だからといってCTAを赤くしない。

---

# 24. Accessibility

最低限:

- contrast WCAG AA相当
- statusを色だけで表現しない
- icon + text / badge text
- clickable target 36px以上
- primary buttons 40px以上推奨
- keyboard focus visible
- drawer closeにaria-label
- tooltipはhoverだけに依存しない
- chartの内容をテキストでも表示

---

# 25. Responsive

Phase 2はDesktop First。

## >= 1536px

- sidebar visible
- detail drawer fixed
- KPI 4〜5列
- content最大活用

## 1280〜1535px

- sidebar compact
- drawer 300〜320px
- KPIカード内padding縮小
- 文字サイズは維持

## <1280px

最低限:

- sidebar collapsible
- detail drawer overlay
- KPI横スクロール可
- table / trackは必要ならhorizontal scroll

モバイル専用最適化は今回対象外。

---

# 26. 共通フィルタ

フィルタ値は可能ならURL queryと同期。

例:

```text
?status=review
?assignee=me
?client=client_001
?month=2026-08
```

最低限:

- 担当
- status
- client
- month

クリア:

```text
すべて解除
```

複数フィルタ使用時はbadgeで件数表示してもよい。

---

# 27. パフォーマンス

13契約 / 50〜200動画程度をまず想定。

この規模でvirtualizationは不要。

ただし:

- derived dataはmemo化可能
- unnecessary re-renderを避ける
- image lazy load
- thumbnailは適切サイズ
- drawer data fetchはcache
- chart libraryを増やしすぎない

---

# 28. Mock Data

既存データが利用できる場合は実データ shapeを優先。

Phase 2専用mockが必要な場合:

- 13契約
- 50動画
- 社員2名
- 編集スタッフ3名
- 投稿待ち3本
- 遅延1〜3本
- 今日の処理待ち14件

必ず以下を含む。

- タイトル未設定
- Drive未設定
- 投稿期限超過
- 今日締切
- 承認済み
- 投稿待ち
- 投稿済み
- 未着手
- 編集中
- 確認中

見た目確認のため、全状態を網羅する。

---

# 29. Suggested directory structure

既存構成がある場合は合わせる。

参考:

```text
src/
  app/
    today/
    videos/
    progress/
    workload/
    pending-posts/

  components/
    layout/
      AppShell.tsx
      Sidebar.tsx
      TopHeader.tsx

    dashboard/
      KpiCard.tsx
      KpiStrip.tsx

    video/
      VideoListItem.tsx
      PriorityVideoCard.tsx
      VideoDetailDrawer.tsx
      VideoActionButton.tsx

    progress/
      ContractTrackRow.tsx
      PostMarker.tsx
      TodayLine.tsx

    workload/
      StaffLoadCard.tsx
      StaffDetail.tsx

    common/
      StatusBadge.tsx
      ProgressRing.tsx
      EmptyState.tsx

  domain/
    video/
      types.ts
      status.ts
      selectors.ts
    contract/
      types.ts
      selectors.ts
    workload/
      selectors.ts

  data/
    mocks/
```

---

# 30. State管理

既存方式優先。

Phase 2では以下を一つのsource of truthから算出する。

```text
VideoItems
  ↓
Home KPI
Video List KPI
Today KPI
Pending Posts KPI
Progress Contract Counts
Workload Counts
```

画面ごとに独立したcountを持たない。

### 例

投稿待ちを更新したとき:

```text
投稿待ち画面   -1
ホーム         投稿待ち -1 / 投稿済み +1
進行トラック   posted +1
契約進捗       ratio update
動画一覧       status update
今日           必要に応じtask消滅
```

これらは同じVideoItemのstatus更新から自動的に再計算する。

---

# 31. 実装順序

一度にすべて作らない。

## Step 0

- 既存コード調査
- Homeのdesign token抽出
- Sidebar / Header / Drawer再利用確認

## Step 1

共通コンポーネント。

- KpiCard
- StatusBadge
- PrimaryActionButton
- VideoDetailDrawer
- Toast
- selectors

## Step 2

**動画一覧**

理由:
- 共通動画リスト
- filter
- detail
- action
- KPI

の基礎になるため。

## Step 3

**今日**

動画一覧のVideo row/actionを再利用。

## Step 4

**投稿待ち**

投稿操作を完成させる。

## Step 5

**進行トラック**

契約集計・投稿予定マーカーを作る。

## Step 6

**チーム負荷**

既存動画データからstaff aggregation。

## Step 7

Visual polish。

- spacing
- typography
- icon
- hover
- selected state
- loading
- empty
- responsive

---

# 32. 実装しないもの

このPhaseで不要。

- 高度なAI予測
- 自動SNS投稿
- Google Drive OAuth
- 実ファイルアップロード
- 複雑な権限設定
- リアルタイム同期
- drag & drop workflow
- 高度な分析ダッシュボード
- billing
- CRM
- モバイルネイティブ対応

まず日常業務の5画面を完成させる。

---

# 33. Acceptance Criteria — 共通

以下すべてを満たす。

- [ ] Home画面の見た目を壊していない
- [ ] Sidebarが全ページで共通
- [ ] Headerが全ページで共通
- [ ] ステータス色が全ページで一致
- [ ] 動画詳細Drawerを再利用
- [ ] 動画をどのページから選んでも同じ詳細を表示
- [ ] status更新が1クリック
- [ ] 更新後Toast表示
- [ ] Undo可能
- [ ] KPIが同一データから再計算
- [ ] 投稿待ちと承認済みが別状態
- [ ] Google Drive CTAが分かりやすい
- [ ] 重要情報が3秒以内に判断できる
- [ ] 遅延を赤だけに依存せず文字でも表示
- [ ] 1280pxで主要操作が破綻しない
- [ ] loading / empty / error stateが存在

---

# 34. Acceptance Criteria — 動画一覧

- [ ] KPI 5枚
- [ ] 優先対応3〜5件
- [ ] 担当filter
- [ ] status filter
- [ ] client filter
- [ ] search
- [ ] 全動画list
- [ ] row clickでdetail
- [ ] row CTAでnext status
- [ ] タイトル未設定が識別可能
- [ ] 遅延期限が強調
- [ ] selected rowが判別可能

---

# 35. Acceptance Criteria — 今日

- [ ] 今日のタスクKPI
- [ ] 期限超過が最優先
- [ ] 今日の作業が時系列または優先順
- [ ] 未完了と完了を分離
- [ ] CTAで即更新
- [ ] 更新後に完了セクションへ移動
- [ ] 空状態がある

---

# 36. Acceptance Criteria — 進行トラック

- [ ] 1行1契約
- [ ] 動画/静止画契約を分離
- [ ] 今日線
- [ ] 過去の未投稿が視覚的に分かる
- [ ] 投稿済み/予定/投稿待ちを区別
- [ ] 右側に `x / y本`
- [ ] 残本数
- [ ] 遅延数
- [ ] healthy / warningが分かる
- [ ] marker clickで動画詳細

---

# 37. Acceptance Criteria — チーム負荷

- [ ] スタッフごとに大きなcard
- [ ] 今日件数
- [ ] 今週件数
- [ ] 遅延
- [ ] 負荷目安
- [ ] 過負荷が色＋文字で分かる
- [ ] staff detailまたはtask listへ遷移可能
- [ ] 工数を入力させない

---

# 38. Acceptance Criteria — 投稿待ち

- [ ] 投稿待ちKPI
- [ ] 本日期限
- [ ] 24h以上
- [ ] 48h以上
- [ ] oldest/urgent first
- [ ] Drive CTA
- [ ] `投稿した` CTA
- [ ] 1クリックでposted
- [ ] Home / Progress / KPIへ反映
- [ ] Undo可能
- [ ] empty stateが「すべて投稿済み」と明確

---

# 39. Visual QA Checklist

実装後、`phase2-concepts-reference.png` と `current-home-reference.png` を横に置いて確認する。

## Layout

- [ ] Sidebar幅がHomeと同じ
- [ ] Header高さがHomeと同じ
- [ ] Page左端がHomeと揃っている
- [ ] Card radiusが同じ
- [ ] Section gapが同じ
- [ ] Detail Drawer幅が同じ

## Typography

- [ ] 見出しサイズ
- [ ] KPI数字
- [ ] label
- [ ] button
- [ ] muted text

がHomeと揃っている。

## Color

- [ ] Primary purple
- [ ] review amber
- [ ] waiting post purple
- [ ] posted green
- [ ] delayed red
- [ ] sidebar navy

が統一。

## Density

- [ ] 一覧が詰まりすぎていない
- [ ] 大きすぎて1画面に情報が入らない状態でもない
- [ ] 重要カードと通常行に明確な強弱がある

---

# 40. Claude Code に対する最終判断ルール

実装中に仕様の曖昧さがある場合は、以下の順番で判断する。

```text
1. 既存Home画面との一貫性
2. ユーザーが次の行動を迷わない
3. 投稿漏れを防げる
4. 重要情報を探さなくてよい
5. 1クリックで工程を進められる
6. 入力操作を増やさない
7. 表を増やしすぎない
8. デザイン参照画像に近づける
9. 新機能を増やさない
10. コードを過剰設計しない
```

---

# 41. Claude Code 実装開始用プロンプト

以下をClaude Codeに最初の指示として与えてよい。

```text
このリポジトリにある既存のHome画面をデザイン基準として、
添付の `PHASE2_NAVIGATION_UI_SPEC.md` と
`phase2-concepts-reference.png` を読み、
Phase 2 のサブ画面を実装してください。

今回の対象は以下の5画面です。

1. 動画一覧
2. 今日
3. 進行トラック
4. チーム負荷
5. 投稿待ち

最初にコードを書かず、既存リポジトリを調査してください。

確認するもの:
- framework
- routing
- Home画面
- Sidebar
- Header
- Detail Drawer
- design tokens
- state管理
- mock/API data
- workflow status
- toast
- icon library

調査後、既存コンポーネントの再利用方針と、
変更予定ファイルを簡潔に提示してから実装を開始してください。

重要:
- Home画面は壊さない
- Homeのデザイン言語をそのまま使う
- 全画面で同じVideoDetailDrawerを使用する
- ステータス色を統一する
- 承認済みと投稿待ちと投稿済みを分ける
- ステータス更新は原則1クリック
- 更新後はToast + Undo
- Google Drive CTAを明確にする
- KPIは同じ元データから算出する
- 画面ごとに数字をハードコードしない

実装順は、
共通UI → 動画一覧 → 今日 → 投稿待ち → 進行トラック → チーム負荷 → Visual QA
としてください。

最初から全機能を完成させようとせず、
まず5画面の視認性・操作性・一貫性を高いレベルで完成させてください。
```

---

# 42. Definition of Done

Phase 2完了条件は「5ページが存在する」ことではない。

以下が成立した時点をDoneとする。

### 編集スタッフ

- `今日` を開けば、今日やる作業が分かる
- ボタン1つで次の工程へ渡せる
- 動画を探す場合は `動画一覧` ですぐ見つかる

### 社員

- `投稿待ち` を開けば投稿漏れを防げる
- `進行トラック` で契約消化ペースを把握できる
- 右詳細で情報修正ができる

### 管理者

- `チーム負荷` で偏りを把握できる
- `進行トラック` で危険契約を把握できる

### 全員

- どのページでもUIの使い方が変わらない
- 「詳細を見る場所」と「次へ進める場所」が統一されている
- ホーム画面と同じプロダクトを使っている感覚がある

これを最優先とする。
