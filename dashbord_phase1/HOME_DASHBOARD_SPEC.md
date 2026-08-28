---
title: VIDEO WORKS Home Dashboard UI Specification
spec_version: 0.1.0
status: Phase 1 / Home screen only
language: ja
primary_reference: "添付のダッシュボード画像"
implementation_priority: "visual fidelity > scanability > one-click operation > feature completeness"
---

# VIDEO WORKS ホームダッシュボード 実装仕様書

## 0. Claude Code への最重要指示

この仕様書は、添付の参考画像に近い **動画制作チーム向け業務ダッシュボードのホーム画面** を実装するための Phase 1 仕様である。

### 実装方針

- **最初から業務システム全体を完成させないこと。** まずホーム画面のUI/UX完成度を優先する。
- 参考画像を **ビジュアル上の正解** として扱い、レイアウト、密度、カードサイズ、色分け、視線誘導をできるだけ近づける。
- ただし単なる画像コピーではなく、後から実データへ接続できるコンポーネント構造で実装する。
- Phase 1 ではモックデータでよい。API、DB、認証、Google Drive OAuth、投稿API連携は後回し。
- 既存プロジェクトに組み込む場合、既存のフレームワーク・ルーティング・UI基盤を壊さないこと。
- 新規プロジェクトの場合のみ、`React + TypeScript` を前提とし、可能なら `Next.js App Router + Tailwind CSS` を使用する。
- UIライブラリが既に存在する場合は再利用する。存在しない場合は、必要最小限の自作コンポーネントで実装する。
- アイコンは一貫した1つのアイコンセットに統一する。推奨は `lucide-react`。
- 日本語UIを前提とする。
- デスクトップ業務利用が主目的。Phase 1 の最重要画面幅は **1440〜1920px**。

---

# 1. プロダクト目的

このホームダッシュボードは、動画制作チーム内で役割の異なるメンバーが同じ画面を使い、以下を一目で判断できる状態を作る。

1. 今月、必要な投稿本数に対してどこまで消化できているか。
2. 今日、自分が何を処理すべきか。
3. 各動画がどの工程で止まっているか。
4. 「承認済みだが未投稿」の動画が何本あるか。
5. どの契約が遅延・未達リスクにあるか。
6. 自分の作業を完了したら **1クリックで次工程へ渡せる** こと。
7. 完成動画の保存先となる **Google Drive フォルダを1クリックで開ける** こと。

## 1.1 Home画面で最優先する3つの体験

### A. 見た瞬間に状況が分かる

情報を均等に並べるのではなく、重要度に応じてサイズを変える。

優先順位：

1. 月次投稿進捗 / 投稿待ち / 危険契約
2. 今日の自分のタスク
3. 契約別進捗
4. 選択中動画の詳細
5. 履歴・承認情報

### B. 1クリックで次へ進める

各タスク行には必ず「次のステップへ」の主操作を表示する。

例：

- 企画 → 編集中
- 編集中 → 確認待ち
- 確認待ち → 承認済み
- 承認済み → 投稿待ち
- 投稿待ち → 投稿完了

原則としてモーダルを挟まない。

### C. 投稿漏れを防ぐ

「投稿待ち」は他の工程から独立させ、オレンジ〜赤系で強く認識させる。

「承認済み」だけでは完了扱いにしない。

---

# 2. Phase 1 のスコープ

## 2.1 今回実装する

- ホーム / ダッシュボード画面
- 左サイドバー
- 上部ヘッダー
- 全社サマリーKPIカード
- 自分のタスク一覧 `My Tasks`
- 工程カンバンのサマリー
- 契約別進捗サマリー
- 右側の動画詳細パネル
- ワンクリックのステータス更新UI
- Google Driveフォルダを開くボタン
- モックデータによる操作確認
- ローディング / 空状態 / エラーの最低限表示

## 2.2 今回は実装しない

- ログイン / 権限管理の本実装
- DB接続
- Google Drive API / OAuth
- ファイルアップロード
- SNS / YouTube / TikTok への投稿API
- 契約作成画面
- クライアント管理画面
- 動画編集画面
- コメント投稿のリアルタイム同期
- 通知配信
- 請求管理
- 分析レポート詳細
- モバイル専用UI
- 高度なドラッグ&ドロップカンバン

---

# 3. 画面全体の構成

## 3.1 基準画面

- 基準デザインサイズ: `1600 x 900`
- 最適表示: `1440px` 以上
- 最低サポート幅: `1280px`
- ページ背景: very light gray / off-white
- 左サイドバー: dark navy
- コンテンツ中央: light theme
- 右詳細パネル: white

## 3.2 レイアウト

```text
┌─────────────┬──────────────────────────────────────────┬────────────────────┐
│             │ Header / Greeting / Date / Notification │                    │
│ Left        ├──────────────────────────────────────────┤ Right Detail       │
│ Sidebar     │ KPI Summary Cards                        │ Panel              │
│             ├──────────────────────┬───────────────────┤                    │
│             │ My Tasks             │ Contract Summary  │ Video Detail       │
│             │                      │                   │ Progress           │
│             ├──────────────────────┴───────────────────┤ Google Drive       │
│             │ Workflow / Process Summary               │ Approval           │
│             │                                          │                    │
└─────────────┴──────────────────────────────────────────┴────────────────────┘
```

### 3.2.1 推奨幅

| 領域 | 1600px時の目安 |
|---|---:|
| Left Sidebar | 200〜216px |
| Main Content | 残り幅 |
| Right Detail | 330〜360px |
| Main horizontal gap | 20〜24px |
| Page padding | 22〜28px |

### 3.2.2 レスポンシブ挙動

#### `>= 1536px`

- 左サイドバー固定表示
- 右詳細パネル常時表示
- KPIカード5枚を横1列
- My Tasks と契約進捗を2カラム表示

#### `1280px〜1535px`

- 左サイドバー幅を `184〜196px` に縮小
- 右詳細パネル幅を `300〜320px` に縮小
- KPIカードの内部余白を少し縮小
- フォントサイズは基本維持

#### `< 1280px`

Phase 1では完全最適化対象外。

最低限：

- 右詳細パネルを overlay drawer に切り替える
- サイドバーを折りたためる
- メイン領域の横スクロールはできるだけ発生させない

---

# 4. ビジュアルデザインシステム

## 4.1 デザインキーワード

- Premium B2B SaaS
- Calm but lively
- Large information blocks
- High scanability
- Clear state colors
- Minimal visual noise
- Daily-use friendly
- Slightly playful

## 4.2 カラートークン

実装時は CSS Variables にする。

```css
:root {
  --bg-app: #f6f8fb;
  --bg-panel: #ffffff;
  --bg-sidebar: #101c2d;
  --bg-sidebar-elevated: #17263a;
  --bg-dark-card: #16263a;
  --bg-dark-row: #1b2d43;

  --text-primary: #0f172a;
  --text-secondary: #64748b;
  --text-muted: #94a3b8;
  --text-on-dark: #f8fafc;
  --text-on-dark-muted: #b8c3d1;

  --border-soft: #e5eaf0;
  --border-dark: rgba(255,255,255,.09);

  --status-plan: #3b82f6;
  --status-editing: #14a3a3;
  --status-review: #f59e0b;
  --status-approved: #22a06b;
  --status-waiting-post: #ef4444;
  --status-posted: #18a777;

  --priority-high: #ef4444;
  --priority-medium: #f59e0b;
  --priority-low: #94a3b8;

  --accent-purple: #7c3aed;
  --accent-blue: #2563eb;
}
```

## 4.3 サマリーカードの色

参考画像の印象に合わせ、トップKPIはカード全面に色を敷く。

| KPI | 推奨背景 | 意味 |
|---|---|---|
| 今月の投稿予定 | deep navy | 全体量 |
| 投稿済み | teal / green | 健全 |
| 投稿待ち | amber / dark yellow | 要対応 |
| 危険契約 | dark red | リスク |
| 本日の処理待ち | dark purple | 個人ToDo |

カード内文字は白。

## 4.4 タイポグラフィ

優先フォント：

```css
font-family: Inter, "Noto Sans JP", "Hiragino Sans", "Yu Gothic UI", sans-serif;
```

### サイズ目安

| 用途 | サイズ | Weight |
|---|---:|---:|
| Greeting | 24px | 700 |
| Section title | 18px | 700 |
| KPI number | 36〜44px | 700 |
| KPI label | 15〜17px | 700 |
| Card title | 14〜15px | 600 |
| Table / row text | 13〜14px | 500 |
| Meta | 11〜12px | 500 |
| Button | 13〜14px | 600 |

## 4.5 角丸 / 影

```css
--radius-sm: 8px;
--radius-md: 12px;
--radius-lg: 16px;

--shadow-card: 0 6px 18px rgba(15, 23, 42, 0.08);
--shadow-elevated: 0 12px 32px rgba(15, 23, 42, 0.12);
```

### ルール

- KPIカード: `12〜14px`
- My Tasks: `12px`
- Detail panel: 基本角丸なし、内部カードのみ `10〜12px`
- ボタン: `8〜10px`

---

# 5. Home画面コンポーネント仕様

# 5.1 Left Sidebar

## 目的

毎日使う主要導線と、緊急ショートカットを固定表示する。

## 構造

```text
Logo
User Profile

Dashboard
My Tasks [badge]
Projects
Videos
Contracts / Clients
Todo / Posting
Files
Reports
Team
Settings

---
Shortcuts
Posting Waiting [12]
Today Actions [7]
Risk Contracts [2]

---
Help / Support
```

## デザイン

- 背景: `--bg-sidebar`
- 幅: 200〜216px
- 画面高いっぱいに固定
- Main areaとは 1px border で分離
- 選択中メニューは `rgba(255,255,255,0.10)` 程度の明るい背景
- アイコンとテキストの間隔: 10〜12px
- 各行高さ: 42〜46px
- badge は赤、丸型

## ユーザープロフィール

表示内容：

- Avatar 36px
- 名前
- Role
- 下向きChevron

Phase 1ではクリックしても何もしなくてよい。

---

# 5.2 Header

## 左側

```text
山田さん、こんにちは！
今日も素晴らしい作品を届けましょう。
```

実装時は固定名ではなく `currentUser.displayName` を使う。

## 右側

- 日付ボタン
- 月切替セレクト
- Notification bell

### 日付

例：`2025年6月2日（月）`

Phase 1では現在日時から生成しても、モック固定でもよい。

---

# 5.3 Company Summary KPI

## 見出し

`全社サマリー — 2025年6月`

## カード数

5枚

## カード定義

### 1. 今月の投稿予定

表示：

- `128 本`
- `目標 150本`
- `達成率 85%`
- progress bar

### 2. 投稿済み

- `96 本`
- `先月比 +12本`

### 3. 投稿待ち

- `24 本`
- `うち本日期限 5本`
- warning icon

### 4. 危険契約

- `2 契約`
- `遅延の可能性あり`

### 5. 本日の処理待ち

- `7 件`
- `確認・対応が必要です`

## Card interaction

- Hover: `translateY(-1px)` 程度
- KPIクリックで後続ページへ遷移する機能は Phase 2
- Phase 1では hover のみでも可

---

# 5.4 現場オペレーション / My Tasks

## 目的

編集スタッフがホームを開いた瞬間に、今日自分が処理する動画を判断できるようにする。

## デザイン

- dark navy card
- 見出し：`My Tasks`
- card全体は main summary より視覚的に少し重くする
- 背景: `--bg-dark-card`

## 上部タブ

- `すべて 8`
- `今日やること 5`
- `期限間近 3`

active tab は下線または明るい文字。

## 行構造

```text
[Thumbnail] [Status] Video title
                     Client
                     
                     Due date / Priority / [次のステップへ]
```

推奨カラム：

1. サムネイル 56x34
2. 動画タイトル / クライアント
3. 工程
4. 期限
5. 優先度
6. CTA

## 行高さ

`58〜64px`

## CTA

テキスト：

`次のステップへ`

- 紫〜青系の背景
- 行内で最も目立つボタン
- width: 110〜124px
- height: 34〜36px

### クリック時

1. 対象タスクの状態を `nextStatus` に変更
2. UIを即時更新
3. Toast 表示：`「サービス紹介動画 ver.2」を確認待ちへ移動しました`
4. `元に戻す` を5秒程度表示

Phase 1ではフロントエンドstateのみでよい。

## 重要ルール

- CTAを押した後に確認モーダルを出さない
- 誤操作は Undo Toast で戻せる
- ボタン文言はステータスによって可能なら具体化する

例：

- `確認待ちへ`
- `承認済みにする`
- `投稿待ちへ`
- `投稿完了にする`

---

# 5.5 工程カンバン サマリー

## 目的

チーム全体のボトルネックを2秒で判断する。

## 表示する工程

canonical status は以下の6段階。

```ts
type VideoStatus =
  | "planning"
  | "editing"
  | "review"
  | "approved"
  | "waiting_post"
  | "posted";
```

表示ラベル：

1. `企画`
2. `編集中`
3. `確認待ち`
4. `承認済み`
5. `投稿待ち`
6. `投稿完了`

## レイアウト

横一列の compact mini kanban。

各列：

- status header
- 件数
- small thumbnails 2〜4件
- 必要に応じ `+20` のような overflow count

## 投稿待ち

最重要。

- オレンジまたは赤寄り
- border 2px
- 上部に `要対応！` badge を置ける
- `投稿待ち` の件数が 1以上の場合、視線が自然に向く強さにする

---

# 5.6 Management / 契約別進捗

## 見出し

`マネジメント監視 — 契約別 進捗サマリー`

## 目的

社員・管理者・社長が、契約単位で月間消化状況を判断する。

## 行仕様

1契約につき1行。

表示項目：

- Client name
- Month / contract label
- circular progress
- 必要本数
- 投稿済み
- 投稿待ち
- 遅延

### 例

```text
株式会社BRIGHT      80%    必要 20 / 投稿済 16 / 投稿待ち 3 / 遅延 1
株式会社CONNECT     64%    必要 25 / 投稿済 16 / 投稿待ち 6 / 遅延 3
```

## 色

- 投稿済み: green
- 投稿待ち: amber
- 遅延: red

## 最下部

`合計 / 平均`

全契約の合計値を表示。

---

# 5.7 Right Detail Panel

## 目的

選択中動画の判断と操作を、ページ遷移なしで完結させる。

## 幅

- Desktop: `330〜360px`
- 背景: `#fff`
- 左に `1px solid --border-soft`
- 高さ: viewport full
- overflow-y: auto

## Header

- `動画詳細`
- close icon

close時：

- 画面幅が十分ある場合は panel を閉じ、main content を拡張
- ただし初期状態は selectedTask を入れて panel を表示しておく

## Preview

- 16:9 thumbnail
- current status badge
- title
- client
- video ID
- assignee
- deadline

期限超過の場合は赤。

## Tabs

- `詳細`
- `工程履歴`
- `承認状況`
- `投稿記録`
- `コメント`

Phase 1では `詳細` のみ本実装し、他タブはクリックで簡易表示でもよい。

## 詳細項目

- 動画尺
- Format
- 保存先
- Google Drive status

### Drive status

URLあり：

`Google Driveに保存済み ✓`

URLなし：

`保存先未設定`

---

# 5.8 Google Drive Button

## ボタン

`Google Drive フォルダを開く`

## デザイン

- detail panel width にほぼ合わせる
- height: 42〜46px
- white background + blue border または primary blue background
- Google Drive icon を左に表示
- external link icon を右に表示

## 動作

```ts
window.open(video.driveFolderUrl, "_blank", "noopener,noreferrer");
```

## URLなし

- button disabled
- helper: `Google Driveフォルダが未設定です`

Phase 1ではURLをmock dataに持たせる。

---

# 5.9 工程履歴

Vertical timeline。

表示例：

```text
● 企画・構成      2025/5/20 10:30   佐藤
● 撮影            2025/5/21 15:45   佐藤
● 編集            2025/5/27 19:20   山田
● 初稿提出        2025/5/28 11:10   山田
● 修正対応        2025/5/29 16:30   佐藤
● 投稿待ち        2025/6/2 17:00    山田
```

- 完了: green / gray
- current: amber / red
- future: gray outline

---

# 5.10 承認状況

表示対象：

- 編集担当
- クライアント確認
- 最終承認

status：

- `完了`
- `承認済み`
- `未承認`

Phase 1では表示のみ。

---

# 6. Status Design

## 6.1 Status labels

| Key | Label | Color |
|---|---|---|
| planning | 企画 | blue |
| editing | 編集中 | cyan/teal |
| review | 確認待ち | amber |
| approved | 承認済み | green |
| waiting_post | 投稿待ち | orange/red |
| posted | 投稿完了 | emerald |

## 6.2 Status pill

- height: 24〜28px
- border-radius: 999px
- font-size: 11〜12px
- font-weight: 600

色だけに依存せず、必ずラベル文字を併記する。

---

# 7. 情報設計 / Data Model

Phase 1は mock data で実装する。

## 7.1 User

```ts
export interface User {
  id: string;
  displayName: string;
  role: "editor" | "coordinator" | "manager" | "admin";
  avatarUrl?: string;
}
```

## 7.2 VideoTask

```ts
export interface VideoTask {
  id: string;
  videoId: string;
  title: string;
  clientId: string;
  clientName: string;
  thumbnailUrl?: string;

  assignee: User;
  status: VideoStatus;
  progressPercent?: number;

  priority: "high" | "medium" | "low";
  dueAt: string;

  duration?: string;
  format?: string;
  driveFolderUrl?: string;

  contractId: string;
  contractMonthlyTarget: number;

  createdAt?: string;
  updatedAt?: string;

  history: WorkflowHistory[];
  approvals: ApprovalState[];
}
```

## 7.3 ContractSummary

```ts
export interface ContractSummary {
  id: string;
  clientName: string;
  month: string;
  targetPosts: number;
  postedCount: number;
  waitingPostCount: number;
  delayedCount: number;
  progressPercent: number;
  risk: "low" | "medium" | "high";
}
```

## 7.4 DashboardSummary

```ts
export interface DashboardSummary {
  plannedPosts: number;
  targetPosts: number;
  postedPosts: number;
  waitingPostPosts: number;
  waitingPostDueToday: number;
  riskyContracts: number;
  todayActions: number;
}
```

---

# 8. Status Transition Rules

## 8.1 Transition map

```ts
export const NEXT_STATUS: Record<VideoStatus, VideoStatus | null> = {
  planning: "editing",
  editing: "review",
  review: "approved",
  approved: "waiting_post",
  waiting_post: "posted",
  posted: null,
};
```

## 8.2 CTA labels

```ts
export const NEXT_STATUS_LABEL: Record<VideoStatus, string> = {
  planning: "編集へ",
  editing: "確認待ちへ",
  review: "承認済みにする",
  approved: "投稿待ちへ",
  waiting_post: "投稿完了にする",
  posted: "完了",
};
```

## 8.3 操作後

- optimistic update
- toast
- undo
- selected detail panel も即時同期
- KPI count も即時再計算
- contract summary も即時再計算

この連動を Phase 1 の重要デモ要件とする。

---

# 9. Interaction Specification

## 9.1 Task selection

My Tasks の行をクリック：

- `selectedVideoId` 更新
- Right Detail Panel の内容が即切替
- ページ遷移しない

CTAボタンをクリックした場合は row click を発火させない。

```ts
e.stopPropagation();
```

## 9.2 KPI cards

Phase 1では閲覧のみ。

hover state：

- shadow slightly stronger
- cursor pointer はリンク化予定の場合のみ

## 9.3 Contract row

クリック：

- `selectedContractId` 更新
- Phase 1 では視覚的highlightのみでも可

## 9.4 Notification

Bellクリック：

Phase 1では簡易popoverまたはno-op。

---

# 10. Loading / Empty / Error States

## 10.1 Loading

Skeletonを表示。

- KPIカード5枚
- My Tasks 5行
- Contract Summary 5行
- Right Detail

スピナーのみは避ける。

## 10.2 Empty Tasks

```text
今日対応するタスクはありません
すべて順調です。
```

## 10.3 Empty 投稿待ち

```text
投稿待ちはありません
承認済み動画はすべて投稿されています。
```

green success state を使う。

## 10.4 Drive URL missing

button disabled + helper message。

## 10.5 Error

```text
データを読み込めませんでした
再読み込み
```

---

# 11. Accessibility

最低限以下を守る。

- body text は原則 12px 未満にしない
- 主要ボタンは 40px 前後のclick target
- 色だけで状態を表現しない
- icon-only button に `aria-label`
- focus-visible を消さない
- status badge に文字を必ず表示
- danger red に小さい薄色文字だけを置かない
- Keyboard Tab で主要操作へ到達可能

---

# 12. Component Architecture

推奨構成：

```text
app/
  dashboard/
    page.tsx

components/
  dashboard/
    DashboardShell.tsx
    Sidebar.tsx
    DashboardHeader.tsx
    SummaryGrid.tsx
    SummaryCard.tsx
    OperationsPanel.tsx
    MyTasksCard.tsx
    TaskRow.tsx
    WorkflowMiniBoard.tsx
    WorkflowColumn.tsx
    ContractProgressPanel.tsx
    ContractProgressRow.tsx
    VideoDetailPanel.tsx
    VideoPreview.tsx
    WorkflowTimeline.tsx
    ApprovalList.tsx
    DriveFolderButton.tsx
    StatusPill.tsx
    PriorityBadge.tsx

lib/
  dashboard/
    mockData.ts
    status.ts
    selectors.ts

types/
  dashboard.ts
```

## 12.1 Component rule

- 1ファイルが巨大にならないよう分割する
- UI state と visual component を分離する
- status color を各componentでハードコードしない
- `status.ts` の mapping を共通利用する

---

# 13. Suggested State Structure

Phase 1では React state でよい。

```ts
interface DashboardState {
  selectedVideoId: string | null;
  selectedContractId: string | null;
  activeTaskTab: "all" | "today" | "urgent";
  tasks: VideoTask[];
  contracts: ContractSummary[];
}
```

集計値はできるだけ derived state にする。

```ts
const summary = useMemo(() => calculateSummary(tasks, contracts), [tasks, contracts]);
```

---

# 14. Mock Data Requirements

画面が参考画像のように「実運用感」が出るよう、最低限以下を用意する。

- users: 5名
- clients: 6〜8社
- contracts: 5〜8件を画面表示、内部データは13件
- tasks: 12〜18件
- today tasks: 5件
- waiting_post: 3件以上
- delayed tasks: 2件以上
- dangerous contract: 2件以上
- posted: 5件以上

サムネイルは同じ画像を繰り返さず、3〜5種類用意する。

---

# 15. Visual Density Rules

この画面は「情報量が多いが、細かすぎない」ことが重要。

## MUST

- KPI数値は大きい
- My Tasks の行は高さを確保
- Contract Summary の各行は十分な余白を取る
- セクション間に 20px 以上の空白
- 主要statusは色面積を持たせる
- Right detail は文字を詰め込みすぎない

## MUST NOT

- 全てを小さい表にする
- 10px以下の文字を多用する
- 細いborderだらけにする
- status color を低彩度すぎる色にする
- すべてのカードを同じ色にする
- sidebar をライトテーマに変更する
- 投稿待ちを他statusと同じ強さにする

---

# 16. Implementation Order

Claude Codeは以下の順で実装する。

## Step 1

`DashboardShell`

- sidebar
- main content
- right detail panel

ここで3カラム構成を完成させる。

## Step 2

`DashboardHeader` + `SummaryGrid`

参考画像の第一印象をここで合わせる。

## Step 3

`MyTasksCard`

- dark panel
- 5 rows
- CTA
- status badges

## Step 4

`ContractProgressPanel`

- progress circles
- green / amber / red counts

## Step 5

`WorkflowMiniBoard`

投稿待ちを強調する。

## Step 6

`VideoDetailPanel`

- preview
- metadata
- Drive button
- timeline
- approval

## Step 7

Interaction

- row selection
- next status
- toast undo
- summary recalculation

## Step 8

Polish

- spacing
- hover
- focus
- icon alignment
- truncation
- 1440 / 1600 / 1920 testing

---

# 17. Acceptance Criteria

## 17.1 Visual

- [ ] 参考画像と同様に、左がダーク、中央がライト、右が白の3領域に見える
- [ ] KPIカード5枚が最初に目に入る
- [ ] KPI数値が大きく読みやすい
- [ ] My Tasks がダークカードとして強く認識できる
- [ ] status color が明確に区別できる
- [ ] 投稿待ちが独立して目立つ
- [ ] 契約進捗が一目で理解できる
- [ ] Right detail panel にGoogle Driveボタンが常に見つけやすい
- [ ] カード間の余白が参考画像程度に確保されている
- [ ] 情報量は多いが、Excelのように見えない

## 17.2 Functional

- [ ] My Tasks rowをクリックするとdetail panelが切り替わる
- [ ] 次のステップCTAを1クリックするとstatusが更新される
- [ ] CTA後、KPIの数値が再計算される
- [ ] CTA後、契約進捗が再計算される
- [ ] Undoで直前の状態に戻せる
- [ ] Driveボタンでmock URLを新規タブで開ける
- [ ] Drive URLが無い場合はdisabledになる
- [ ] `waiting_post -> posted` が可能
- [ ] `posted` では次工程CTAを出さない

## 17.3 Layout

- [ ] 1600x900 で主要要素が1画面に収まる
- [ ] 1440px幅でも破綻しない
- [ ] Right detail panel が横幅を取りすぎない
- [ ] 1280pxではdrawer modeへ移行できる
- [ ] テキストがカード外にはみ出さない

---

# 18. Phase 1 完了条件

次の状態になったら Phase 1 完了とする。

1. 参考画像の雰囲気が再現されている。
2. ホーム画面だけで「今月の進捗」「今日やること」「投稿待ち」「危険契約」が判断できる。
3. Taskを選択すると右側詳細が切り替わる。
4. 「次のステップへ」を1クリックすると状態が変わる。
5. 投稿待ち → 投稿完了までUI上でデモできる。
6. Google Driveフォルダボタンを押せる。
7. 1440〜1920pxで実務利用できる品質になっている。

---

# 19. Phase 2 に回す項目

Phase 1完了後、以下を検討する。

- API / DB接続
- Auth
- Role permission
- Google Drive OAuth
- Drive folder picker
- File upload
- Contract generation
- Monthly automation
- URL auto-fetch
- タイトル自動生成
- 投稿記録
- SNS API
- コメント
- Notification
- Audit log
- Detail pages
- Calendar
- Search / advanced filter

---

# 20. Claude Code向け最終実装指示

実装開始時は、まず既存リポジトリの構成を確認する。

既存コードがある場合：

1. package.json を確認
2. existing UI / theme / routing を確認
3. 既存コンポーネントを再利用
4. home dashboard route を特定
5. この仕様に合わせて段階的に置換

新規の場合：

1. React + TypeScript で開始
2. デザインtokenをCSS Variablesで定義
3. mock dataを作成
4. DashboardShellから実装
5. 一度に全機能を実装せず、セクション単位で確認

### 最も重要な判断基準

実装に迷った場合は以下の順で優先する。

```text
1. 一目で状況が理解できるか
2. 自分の次の作業がすぐ分かるか
3. 投稿待ちを見落とさないか
4. 1クリックで次工程へ進めるか
5. Google Driveへすぐ移動できるか
6. 参考画像のデザイン性を維持できているか
7. 機能を増やしすぎていないか
```

Phase 1では「機能の多さ」より「ホーム画面の完成度」を優先すること。
