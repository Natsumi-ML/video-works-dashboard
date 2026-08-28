# SOCIAL BASE UI/UX 実装仕様書
**Version:** 1.0  
**Purpose:** Claude Code に読み込ませ、既存のダッシュボードを SOCIAL BASE の完成イメージへ改修するための UI/UX 実装仕様。  
**Scope:** 画面構成、デザインシステム、レスポンシブ、操作フロー、画面遷移、表示権限、将来の外部連携を阻害しないデータ/UIインターフェース。  
**Out of Scope:** Google Drive / Google Calendar / Slack の本番API連携、営業日計算、負荷計算アルゴリズム、投稿自動化などのバックエンドロジック本体。これらは別仕様で実装する。

---

# 0. 最重要ルール

Claude Code は以下を最優先で守ること。

1. **既存実装をベースに改修する。全面的な別デザインへの作り直しは禁止。**
2. 添付の完成イメージをUIの視覚的な基準とする。
3. **最終ロゴは `rogo.png` を正とする。**
   - 各画面の参考画像左上に表示されている旧ロゴマークは使用しない。
   - `rogo.png` のロゴマーク + `SOCIAL BASE` ワードマークを正式採用する。
4. 全体背景は明るい色を維持する。黒背景/全面ダークUIにはしない。
5. 濃色背景は原則として以下に限定する。
   - 左サイドバー
   - Home の `My Tasks`
   - 必要なモーダル/オーバーレイの背景
6. グラデーションは「重要なKPIカード」「アクティブナビ」「主要CTA」などに限定し、画面全体を多色で埋めない。
7. 同じ意味のステータスは、**全画面で同じ文言・同じステータス色**を使う。
8. 「契約」という文言はUI上で使用しない。**すべて「クライアント」へ統一する。**
9. `進行トラック` は独立ページとして存在させない。**「動画一覧」ページ内の1ブロックに統合する。**
10. `クライアント管理` は**社員のみ**表示・アクセス可能。スタッフにはサイドバー項目自体を表示しない。
11. PC / スマホとも Drive ボタン名は以下で統一する。
    - `素材を開く`
    - `確認用にアップロード`
12. `確認用にアップロード` は SOCIAL BASE 内でファイルを直接アップロードする意味ではない。
    - 対象クライアントの「確認用（編集済み動画置き場）」Google Drive フォルダを開く。
13. 1クリック進行を重視し、ステータス操作のボタン名は「次へ」ではなく**次に実行する具体的アクション名**を表示する。
14. UI生成画像内のダミー氏名・数値・日付をハードコードしない。既存データまたはモックデータレイヤーから描画する。
15. 新しい色を都度追加しない。原則として本仕様のデザイントークンのみを使用する。

---

# 1. 参照画像

以下を画面レイアウトの基準とする。

| ファイル | 画面 |
|---|---|
| `01_ホーム.png` | Home |
| `02_今日.png` | 今日 |
| `03_動画一覧.png` | 動画一覧 + 進行トラック |
| `04_チーム負荷.png` | チーム負荷 |
| `05_投稿カレンダー(1).png` | 投稿カレンダー |
| `06_クライアント管理.png` | クライアント管理 |
| `rogo.png` | 正式ロゴ |

**重要:** 画面画像とロゴ画像でロゴマークが異なる場合は、必ず `rogo.png` を優先する。

---

# 2. プロダクトの役割

SOCIAL BASE は「動画編集専用ツール」ではない。

以下をまとめて管理する社内SNS運用ダッシュボードである。

- ショート動画制作
- 動画進行管理
- 社内確認
- 投稿管理
- 月間投稿目標管理
- SNS運用
- クライアント管理
- 企画準備
- 定例資料準備
- チーム負荷
- Google Drive 導線
- 将来的な Google Calendar / Slack / Drive データ連携

UIの最優先目的は以下。

- 今日何をやるべきかがすぐ分かる
- タスク漏れを防ぐ
- 投稿目標の遅れを早く見つける
- クリック回数を減らす
- 編集スタッフがスマホでも快適に作業できる
- 社員が全クライアントの状況を横断的に把握できる

---

# 3. ロール・表示権限

ロールは原則2種類。

```text
employee = 社員
staff    = 編集スタッフ
```

専用の「社長ロール画面」は作成しない。

## 3.1 共通画面

社員・スタッフの両方がアクセス可能。

- ホーム
- 今日
- 動画一覧
- チーム負荷
- 投稿カレンダー

## 3.2 社員のみ

- クライアント管理

### 権限ルール

- 社員は**全クライアントの情報を閲覧できる**。
- 社員ごとにクライアントを分離しない。
- スタッフには `クライアント管理` のナビ項目を表示しない。
- URL直打ち等でもアクセスを許可しないよう、UI非表示だけでなくルート/表示権限もガードできる構造にする。
- スタッフは共通画面から全体進捗を確認可能。

---

# 4. 正式ロゴ

## 4.1 採用デザイン

`rogo.png` を正式ロゴの基準とする。

ロゴマークの特徴:

- 上下に分かれた、Sを抽象化したような流線形
- 上側と下側で「流れ」「つながり」を表現
- 中央に独立した再生三角形
- シアン → ブルーの軽いグラデーション
- 丸みを持たせ、ゲームUIの親しみやすさを残す
- 小サイズでもシルエットが判別できる

ワードマーク:

- `SOCIAL BASE`
- 白文字
- `BASE` の `A` 内部下部にシアンのドット
- 画面上では画像化した正式ワードマークを優先し、CSSの通常フォントで再現しない

## 4.2 使用方法

### サイドバー
- ロゴマーク + ワードマーク
- 高さ目安: 30–34px
- 左右余白: 18–22px

### モバイルヘッダー
- 横幅に余裕がある場合: ロゴマーク + `SOCIAL BASE`
- 狭い場合: ロゴマークのみ

### favicon / PWAアイコン
- ロゴマークのみ
- ワードマークを入れない
- 16px / 32px でも判別できる形を維持

### 禁止
- ロゴの色変更
- ロゴ縦横比変更
- 旧ロゴとの混在
- 外側に不要な発光や派手なドロップシャドウを追加
- 背景付きの `rogo.png` をそのまま小さく貼って、ロゴ周囲に矩形背景を残すこと

**実装時は可能なら透明背景SVG/PNGとして切り出したブランドアセットを使用する。**

---

# 5. デザインシステム

## 5.1 デザインコンセプト

キーワード:

```text
Bright
Friendly
Game-like
Operational
Clear
Fast
Soft
Professional
```

「よくある無彩色SaaS」にはしないが、1画面の色数は抑える。

基本構成:

```text
明るいメイン背景
+
濃紺サイドバー
+
白/淡色コンテンツカード
+
重要なKPIだけ鮮やかなグラデーション
+
明確なステータスバッジ
+
大きく押しやすいCTA
```

---

# 6. カラートークン

以下を CSS Variables 等で一元管理すること。

```css
:root {
  /* Brand */
  --brand-teal: #00AFB5;
  --brand-cyan: #10CFE0;
  --brand-blue: #1677F2;
  --brand-deep-blue: #0C58D8;

  /* App surfaces */
  --app-bg: #F6F8FC;
  --surface: #FFFFFF;
  --surface-soft: #F9FBFE;
  --surface-blue-soft: #F2F8FF;

  /* Sidebar */
  --sidebar-top: #03152F;
  --sidebar-mid: #07346C;
  --sidebar-bottom: #0B5BE8;

  /* Text */
  --text-primary: #0B1F46;
  --text-secondary: #52647F;
  --text-muted: #8795AA;
  --text-inverse: #FFFFFF;

  /* Border */
  --border: #DCE4F0;
  --border-strong: #CBD6E5;

  /* Critical */
  --critical: #FF315F;
  --critical-2: #FF685E;
  --critical-soft: #FFF2F5;
  --critical-border: #FFC6D0;

  /* Warning */
  --warning: #FF8A00;
  --warning-2: #FFB32B;
  --warning-soft: #FFF7E9;
  --warning-border: #FFD9A4;

  /* Success */
  --success: #13A978;
  --success-soft: #EAF9F3;

  /* Purple */
  --purple: #8A4BE8;
  --purple-2: #B154E8;
  --purple-soft: #F4ECFF;

  /* Neutral status */
  --neutral-soft: #EEF2F7;
  --neutral-text: #60718A;

  /* Calendar */
  --calendar-offday-bg: #E9EDF2;
  --calendar-grid: #D6DEE9;

  /* Dark work panel */
  --work-dark-1: #061D3C;
  --work-dark-2: #0D3159;
}
```

## 6.1 KPIグラデーション

```css
--gradient-critical: linear-gradient(135deg, #FF315F 0%, #FF685E 100%);
--gradient-blue: linear-gradient(135deg, #10BFE6 0%, #1677F2 100%);
--gradient-teal: linear-gradient(135deg, #12CFC3 0%, #00A5AE 100%);
--gradient-purple: linear-gradient(135deg, #B154E8 0%, #7043E4 100%);
--gradient-orange: linear-gradient(135deg, #FFB32B 0%, #FF7900 100%);
--gradient-nav: linear-gradient(135deg, #10C7D6 0%, #0F83F5 100%);
```

## 6.2 色数制御

同一画面で強いグラデーションを使うのは**原則3〜5カードまで**。

以下は白/淡色背景を使う。

- 一覧
- 表
- 詳細パネル
- 今日画面の下段カード
- 優先対応の小カード
- クライアント一覧
- チームメンバー一覧
- カレンダー本体

---

# 7. ステータスシステム

## 7.1 正式ステータス

```text
未着手
編集中
要修正
確認中
投稿待ち
投稿済み
```

**「承認済み」はステータスとして使用しない。**

`承認` は `確認中 → 投稿待ち` へ進める**アクション名**。

## 7.2 ステータス色

強いカード背景ではなく、主にチップ/バッジに使用する。

| ステータス | 文字/主色 | 薄背景 |
|---|---|---|
| 未着手 | `#D97706` | `#FFF3DE` |
| 編集中 | `#1677F2` | `#EAF3FF` |
| 要修正 | `#F43F5E` | `#FFF0F3` |
| 確認中 | `#00A5AE` | `#E8F9FA` |
| 投稿待ち | `#8A4BE8` | `#F4ECFF` |
| 投稿済み | `#139A72` | `#E9F8F2` |

**同じステータスは全画面でこの色を使用する。**

## 7.3 警告/優先度はステータスと分離

```text
最優先
期限超過
要確認
注意
```

例:
- `確認中 + 期限超過`
- `投稿待ち + 要確認`

ステータスを赤に塗り替えて警告表現しない。

---

# 8. 動画ワークフロー

## 8.1 正式フロー

```text
未着手
  ↓ [着手する]
編集中
  ↓ [編集完了]
確認中
  ├─ [承認] → 投稿待ち
  └─ [要修正] → 要修正
                    ↓ [修正完了]
                  確認中
投稿待ち
  ↓ [投稿済みにする]
投稿済み
```

## 8.2 アクションマッピング

```js
const STATUS_ACTIONS = {
  未着手: ["着手する"],
  編集中: ["編集完了"],
  要修正: ["修正完了"],
  確認中: ["承認", "要修正"],
  投稿待ち: ["投稿済みにする"],
  投稿済み: []
};
```

## 8.3 「要修正」アクション

`確認中` で `要修正` を押した場合:

1. ボタン直下または詳細パネル内に小さな修正指示入力UIを表示
2. ラベル: `修正内容を入力`
3. textarea を表示
4. 確定ボタン: `要修正にする`
5. 確定すると:
   - `status = 要修正`
   - `revision_note` を保存
6. スタッフが対象動画を開いた場合、修正指示を通常情報より上に強調表示
7. 修正完了後 `修正完了` → `確認中`

### UI
- `承認`: Primary
- `要修正`: Secondary / Outline
- 入力欄は赤くしすぎず、薄いcritical背景 + critical枠
- 入力後の確定以外はワンクリック進行を優先する

---

# 9. Google Drive UI仕様

クライアントごとに以下2URLを保持する。

```text
material_drive_url
review_drive_url
```

## 9.1 フォルダ

### 未編集動画（素材置場）
ユーザーが事前にGoogle Drive上で作成する。

### 確認用（編集済み動画置き場）
ユーザーが事前にGoogle Drive上で作成する。

**SOCIAL BASE がフォルダを自動作成してはいけない。**

一度URLを登録したら、その後継続して同じフォルダを使う。

## 9.2 共通ボタン

PC・スマホとも同じ文言。

```text
[素材を開く]
[確認用にアップロード]
```

### 動作
- `素材を開く` → `material_drive_url`
- `確認用にアップロード` → `review_drive_url`

外部リンクとして安全に開く。

未設定の場合:
- 社員画面では `Drive未設定`
- 設定できる導線を表示
- スタッフには壊れたリンクを表示しない

---

# 10. 共通レイアウト

## 10.1 Desktop

基準: 1280px以上。

```text
┌──────── Sidebar 216px ────────┬──────────────── Main ───────────────────┐
│                                │ Top bar                                  │
│ Logo                           │ Search                 Add / Drive / User│
│ Navigation                     ├───────────────────────────────────────────┤
│                                │ Page content                               │
│ Employee only section          │                                            │
│                                │                                            │
└────────────────────────────────┴────────────────────────────────────────────┘
```

### Sidebar
- width: `216px`
- fixed
- top-to-bottom dark blue gradient
- white icons/text
- selected item: cyan→blue gradient
- selected row radius: 10–12px
- nav row height: 48–52px
- group separation line: subtle white 10–14% opacity

### Main
- min-width: 0
- background: `--app-bg`
- page padding: 22–28px
- content max width: fluid, desktop full width

### Top bar
- height target: 72–80px
- Search left
- Buttons right
- Search max width: 540–600px
- `動画追加` = gradient primary
- `Google Drive` = white outline card button
- user menu = white card

---

# 11. 角丸・影・余白

```css
--radius-sm: 8px;
--radius-md: 12px;
--radius-lg: 16px;
--radius-xl: 18px;
```

### Content cards
- radius: 14–16px
- border: `1px solid var(--border)`
- shadow: `0 8px 24px rgba(20, 45, 80, .07)`

### KPI cards
- radius: 14–16px
- no heavy border
- subtle shadow

### Buttons
- min-height desktop: 38–42px
- min-height touch/mobile: 44–48px
- radius: 9–11px

---

# 12. Typography

UI本文は既存環境に合わせるが、以下を推奨。

```css
font-family:
  "Noto Sans JP",
  "Hiragino Kaku Gothic ProN",
  "Yu Gothic",
  system-ui,
  sans-serif;
```

### Sizes
- Page title: 28–32px / 700
- Section title: 18–22px / 700
- KPI label: 16–20px / 600–700
- KPI value: 34–46px / 700
- Normal body: 14–15px
- Metadata: 12–13px
- Badge: 12–13px / 600

### 禁止
- 本文12px未満を多用しない
- 装飾目的の極端に細いウェイトを使わない

---

# 13. 共通コンポーネント

以下は可能な限り共通化する。

```text
AppShell
Sidebar
TopBar
SearchBox
PrimaryButton
SecondaryButton
KpiCard
StatusBadge
SeverityBadge
ClientBadge
Avatar
ProgressBar
VideoRow
VideoDetailsPanel
StatusActionControls
IssueCard
FilterBar
DataTable
RightDrawer
BottomSheet
CalendarGrid
```

実装スタックは既存プロジェクトを維持し、UIのためだけにフレームワーク移行しない。

---

# 14. クライアントアイコン

## 14.1 基本

人物:
- 丸型

クライアント:
- 角丸スクエア

### サイズ
- list small: 28–36px
- detail header: 40–48px
- radius: 9–12px

## 14.2 ロゴあり
- 白または淡色背景
- `object-fit: contain`
- padding 4–6px

## 14.3 ロゴなし
- クライアント略称1〜2文字
- 角丸スクエア
- クライアント固有色は「薄い色 + 文字」に限定
- 過度に多色化しない

---

# 15. Home

参照: `01_ホーム.png`

## 15.1 目的

5秒以内に以下を判断できること。

```text
何を今やるべきか
何が遅れているか
今月の投稿目標は大丈夫か
何本が確認中 / 投稿待ち / 投稿済みか
選択中動画の詳細
```

## 15.2 上段KPI

順序:

```text
最優先
投稿目標
確認中
投稿待ち
投稿済み
```

### 最優先
- critical gradient
- 件数
- 内訳:
  - 期限超過
  - 投稿予定日未設定 等
- `すべて見る`

クリック:
- 動画一覧へ遷移
- `priority=critical` 等の絞り込み状態を適用
- ユーザーがすぐ対象動画を認識できる状態にする

### 投稿目標
- blue gradient
- `18 / 30本`
- 残り
- progress bar
- ペース不足の短い警告

クリック:
- 動画一覧へ遷移
- `クライアント進行トラック` ブロックへスクロール/アンカー移動

### 確認中 / 投稿待ち / 投稿済み
クリックで**カード直下にポップオーバー**。

表示:
- 最大4〜5件
- `クライアントアイコン`
- `動画タイトル`

長いタイトル:
```css
white-space: nowrap;
overflow: hidden;
text-overflow: ellipsis;
```

表示しない:
- 日付
- 担当
- Drive
- 詳細メタ情報

最下部:
```text
他3件 / すべて見る >
```

`すべて見る`:
- 動画一覧へ該当ステータスでフィルタ済み遷移

### ポップオーバールール
- 一度に開けるのは1カードのみ
- 別カードクリックで前のカードを閉じる
- click outside / Escape で閉じる
- desktop: floating popover
- mobile: bottom sheet または inline accordion

---

# 16. Home / My Tasks

## 16.1 見た目

**My Tasksのみ濃色背景。**

```css
background: linear-gradient(180deg, var(--work-dark-1), var(--work-dark-2));
color: white;
```

他の一覧カードまで暗くしない。

## 16.2 行構成

```text
[Client icon] Client name
              Video title
              | Status | Risk/Deadline | Action
```

Desktopでは表形式でもよい。

### Action
`次へ` は使用禁止。

ステータスに応じて:

```text
未着手     → 着手する
編集中     → 編集完了
要修正     → 修正完了
確認中     → 承認 / 要修正
投稿待ち   → 投稿済みにする
投稿済み   → actionなし
```

## 16.3 行クリック

行をクリック:
- 右側 `動画詳細` を更新
- 選択行を軽くハイライト
- アクションボタンクリック時は行選択と競合しないよう `stopPropagation` 相当

---

# 17. Home / 動画詳細

右側の白カード。

## 17.1 Header

```text
[Client logo 40–48]
Client name
Video title
```

- クライアント名は中程度
- 動画タイトルをより大きく
- 旧デザインの「巨大なクライアント名ブロック」は使用しない

## 17.2 情報

- 担当
- 現在ステータス
- 期限/投稿日
- 修正指示（存在時）
- ステータスステッパー
- Google Drive
- メモ

## 17.3 修正指示

`要修正` の場合:
- 詳細上部寄りに表示
- critical soft background
- critical border
- 見落とさないが全面赤にはしない

## 17.4 Drive

```text
[素材を開く] [確認用にアップロード]
```

## 17.5 ステッパー

基本工程:

```text
未着手
編集中
確認中
投稿待ち
投稿済み
```

`要修正` は分岐状態のため、必要時は確認中の周辺に注記/ステータス表示する。

---

# 18. Home / 停滞中の動画

`My Tasks` と同じ濃色背景にしない。

### 表現
- white / critical-soft
- critical border
- titleにcritical icon
- 停滞日数を右側に強調

例:
```text
足立整骨院  夏のキャンペーン告知動画 | 編集中 | 3日
```

---

# 19. 今日

参照: `02_今日.png`

## 19.1 上段KPI

```text
最優先
今日やること
要確認
```

**Home / 他ページのKPIと同じグラデーション表現を使用する。**

### 最優先
critical gradient

### 今日やること
blue gradient

### 要確認
orange gradient

## 19.2 下段

すべて濃色背景にしない。

### 最優先タスク
- white / critical-soft
- critical border
- item card
- 問題に応じた具体的CTA

例:
```text
投稿予定日未設定 → 投稿日を設定する
期限超過 → 対象詳細を開く
```

### 今日やること
- white
- blue border / header icon
- status + assignee + next action

### 要確認
- white / warning-soft
- orange border
- category grouped

例:
```text
Drive未設定
投稿日時未設定
タイトル未入力
```

### 今日のメモ
- white / very light blue
- dark background禁止

---

# 20. 動画一覧

参照: `03_動画一覧.png`

## 20.1 ページ構造

```text
1. KPI
2. 優先対応
3. クライアント進行トラック
4. すべての動画
```

**独立した「進行トラック」ページは削除。**

---

# 21. 動画一覧 / KPI

例:

```text
要対応クライアント
今月達成見込み
未達リスク
```

Homeと同じ系統のグラデーション表現。

- strong color cards only here
- その下は白背景へ戻す

`危険な契約` 等の文言は禁止。

---

# 22. 動画一覧 / 優先対応

白背景の大きなセクション。

小カード:
- white
- 1px border
- クライアントアイコン
- 問題ラベル
- 残り本数
- 目標 / 投稿済み

カード全体を強いグラデーションにしない。

---

# 23. 動画一覧 / クライアント進行トラック

独立ページだった進行トラックをここへ統合。

## 23.1 目的

クライアント単位で今月の進捗を一目で確認する。

## 23.2 Columns

```text
クライアント
今月目標
投稿済み
進行中
未着手
残り
進捗
ステータス/リスク
```

例:

```text
足立整骨院 | 8本 | 6本 | 1本 | 1本 | 2本 | 75% | 遅延リスク
```

## 23.3 表現

- 白背景テーブル
- progress bar
- 通常クライアントは静かな色
- 危険/遅延だけ赤/オレンジ
- クライアント行クリックで該当動画へ絞り込み可能

---

# 24. 動画一覧 / すべての動画

データテーブル。

必要フィルタ:

- 月
- クライアント
- 担当
- ステータス
- 優先度
- 検索

行に最低限:

```text
クライアント / 動画
投稿状況
進行
残り
進捗
ステータス
担当
Drive
```

動画行クリック:
- desktop: 右詳細drawer
- mobile: bottom sheet

Driveセル:
- Driveアイコン
- 詳細側で2フォルダボタンを表示

---

# 25. チーム負荷

参照: `04_チーム負荷.png`

## 25.1 対象メンバー

編集スタッフを表示。

主な編集スタッフ:
- りりか
- ゆかり
- つかさ

**季実子さん・リカさんはこの画面のメンバーに追加しない。**
この2人は資料分析作業のシフト参照対象だが SOCIAL BASE 利用メンバーではない。

## 25.2 KPI

例:

```text
チーム全体の負荷
高負荷メンバー
低負荷メンバー
期限超過リスク
```

重要カードのみグラデーション。

## 25.3 メンバー別負荷

```text
Avatar
Name
Task count
Load %
Status
Main tasks
Overdue risk
```

負荷色:
- high: critical
- medium: warning
- normal: teal/blue
- low: soft teal

---

# 26. 負荷調整の提案

## 26.1 表示条件

**常時表示しない。**

```js
if (suggestions.length === 0) {
  renderNothing();
}
```

空のプレースホルダーも不要。

## 26.2 表示時

必要な時だけ下部に出現。

```text
負荷調整の提案
```

提案単位は**クライアントではなく動画/タスク単位**。

表示例:

```text
対象動画
移動元: りりか 110%
→
移動先: つかさ 48%

予測効果
理由
[担当変更を検討]
```

### 重要
- システムが自動で担当変更しない
- 社員が確認してから実行
- staffは画面閲覧可能
- 担当変更確定アクションは社員権限を前提とする

## 26.3 再分配履歴

**メイン画面から完全削除。**

---

# 27. 投稿カレンダー

参照: `05_投稿カレンダー(1).png`

## 27.1 Desktop構造

```text
Page title
KPI x3
Filter bar
Calendar grid | Selected day details
Legend
```

KPI:

```text
今月予定
投稿済み
残り
```

## 27.2 カレンダー罫線

以前より明確に見えること。

```css
border-color: var(--calendar-grid);
```

## 27.3 非稼働日

土・日・祝日の**セル全体**を同じ背景色で塗る。

```css
background: var(--calendar-offday-bg); /* #E9EDF2 */
```

PC・モバイルで同じ色を使用。

### 曜日
- 平日: dark text
- 土: blue text
- 日/祝: red text
- 背景は土日祝すべて同じ gray

休日色をピンク・青で塗り分けない。
色数を増やさない。

## 27.4 イベント

カレンダーセル内では情報を詰めすぎない。

Desktop:
- small status dot
- title truncated
- overflow count `他1件`

Mobile:
- status dot / count中心
- 詳細は選択日領域で表示

## 27.5 日付クリック

Desktop:
- 右側詳細パネルを更新

表示:
- 日付
- 件数
- クライアント
- 動画タイトル
- 担当
- ステータス
- Driveへの導線

Mobile:
- カレンダー下に選択日の一覧
- または bottom sheet
- PC用右パネルを無理に横配置しない

---

# 28. 投稿予定日とシフト連携（将来ロジック要件）

UIは将来以下を受け取れる構造にする。

```text
投稿担当 = りりか
↓
りりかのGoogle Calendar + Slack上の最新シフト
↓
出勤日を投稿候補日に使用
```

この仕様書では実計算ロジックを実装しなくてもよいが、
投稿予定日を外部ロジックから更新可能なデータ構造にする。

---

# 29. クライアント管理

参照: `06_クライアント管理.png`

**社員のみ。**

## 29.1 目的

「クライアントの今」を社員が一画面で判断する。

- 撮影
- 企画
- 投稿進捗
- 編集進行
- 定例
- 資料準備
- Drive

## 29.2 KPI

例:

```text
担当クライアント数
今月の投稿数（合計）
企画進行中
資料準備中
```

右:
```text
注意が必要なクライアント
```

一覧:
- 企画期限超過
- 投稿目標未達
- 資料準備遅延
等

---

# 30. クライアント一覧

主な列:

```text
クライアント
次回撮影日
企画期限
企画ステータス
今月投稿数
投稿目標
編集進行状況
担当スタッフ
次回定例MTG
資料準備状況
```

クライアント名クリック:
- desktop: 右側詳細drawer/panel
- mobile: bottom sheet または full-screen detail

社員は全クライアントを閲覧可能。

---

# 31. クライアント詳細

## 31.1 Header
- client icon/logo
- client name
- close

## 31.2 Drive

```text
未編集動画（素材置場）
[素材を開く]

確認用（編集済み動画置き場）
[確認用にアップロード]
```

クライアントごとにURLを2つ保存。

## 31.3 基本情報

- 次回撮影日
- 企画期限
- 今月投稿状況
- 次回定例MTG
- 編集進捗
- 担当編集スタッフ

---

# 32. 企画準備アラート

UIはクライアントごとの個別ルールを表示できること。

将来的な状態例:

```text
まだ余裕あり
準備開始が近い
企画開始推奨
期限間近
期限超過
```

表示例:

```text
企画開始推奨日まであと2営業日
```

実際の営業日計算は別ロジック。

---

# 33. 定例資料準備フロー

正式ステータス:

```text
未依頼
↓
分析・ハイライト作成中
↓
社員対応待ち
↓
資料完成
```

`分析` と `ハイライト作成` を別ステータスに分けない。

## 33.1 担当

分析・ハイライト:
- 季実子さん
- リカさん

この2人は:
- SOCIAL BASE利用者として扱わない
- チーム負荷メンバーに入れない
- ただし将来的に Google Calendar / Slack のシフトを参照する

## 33.2 期限

**毎月12日まで = 「分析・ハイライト作成」の完成目標。**

12日までに理想状態:

```text
社員対応待ち
```

資料全体の最終期限ではない。

## 33.3 社員作業

Canva資料の
```text
課題と改善提案
```
を社員が作成。

締切:
- 各クライアントの定例MTG日から営業日で逆算
- クライアントごとに違う設定を許容

## 33.4 表示

一覧:
- 現在の資料ステータスだけをコンパクト表示

詳細:
```text
○ 未依頼
● 分析・ハイライト作成中
○ 社員対応待ち
○ 資料完成
```

stepper形式。

---

# 34. 資料アラートの流れ

社員への最初の通知は:

```text
「資料を作ってください」
```

ではなく:

```text
「スタッフに分析を依頼した方がいい」
```

から開始。

例:

```text
分析依頼を出してください
対象 8クライアント
```

その後:

```text
未依頼
→ 分析・ハイライト作成中
→ 社員対応待ち
→ 資料完成
```

社員対応待ちになった段階で初めて:

```text
課題と改善提案を作成してください
```

を社員向けに目立たせる。

---

# 35. Responsive Design

## 35.1 Breakpoints

推奨:

```css
mobile: 0–767px
tablet: 768–1199px
desktop: 1200px+
```

既存プロジェクトにbreakpointがある場合は近い値へ合わせてよい。

---

# 36. Mobile 全体

スマホを「PC版の縮小表示」にしない。

編集スタッフがスマホで実作業する前提。

### Header
- 56px程度
- hamburger
- compact logo
- avatar
- searchは検索アイコン → overlayでも可

### Bottom Navigation
固定ボトムナビを推奨:

```text
ホーム
今日
動画一覧
チーム負荷
投稿カレンダー
```

`クライアント管理` は社員の場合のみ hamburger drawer 内に追加。

### Side menu
- hamburger drawer
- 共通画面へのアクセスを維持
- staffにも「ホーム以外」の進捗画面を提供

---

# 37. Mobile Home

優先順位:

```text
1. My Tasks
2. KPI / 全体進捗
3. 優先対応
4. その他情報
```

PCとは順序を変えてよい。

編集スタッフが最短で作業開始できることを優先。

タスクカード:

```text
[Client icon] Client
Video title
Status
Revision note (if any)

[素材を開く]
[確認用にアップロード]

[次の具体的アクション]
```

### Example

```text
足立整骨院
産後ケアのご紹介動画
編集中

[素材を開く]
[確認用にアップロード]
[編集完了]
```

---

# 38. Mobile 動画詳細

PC右側パネルを横に押し込まない。

**Bottom Sheet**:

- max-height: 85–92vh
- rounded top corners
- drag handle optional
- body scroll
- action area sticky bottom

要修正時:

```text
修正指示
↓
素材を開く
↓
確認用にアップロード
↓
修正完了
```

操作しやすい順序。

---

# 39. Mobile 動画一覧

Desktop tableを横スクロールさせるだけにしない。

カード化:

```text
Client
Video title
Status
Progress
Assignee
Risk
Drive
```

タップ:
- bottom sheet detail

フィルタ:
- top filter button
- sheet/modal内で複数指定

---

# 40. Mobile チーム負荷

メンバー行をカード化。

```text
Avatar Name
Load %
Task count
Main tasks
Risk
```

提案がある場合のみ提案カードを下に表示。

---

# 41. Mobile 投稿カレンダー

7列の月表示を維持する場合:

- 1セルをコンパクト化
- イベントは点/件数
- 長いタイトルをセルに入れない

**土日祝セルはPCと同じ `#E9EDF2`。**

日付選択:
- カレンダー下に予定カード一覧
- selected cell: blue outline
- 選択日の詳細を右側に出そうとしない

---

# 42. Mobile クライアント管理

社員のみ。

一覧:
- card layout
- client
- next shoot
- planning
- posting progress
- meeting
- material status

タップ:
- full screen sheet/detail

---

# 43. Accessibility / 操作性

- touch target: 44px以上
- keyboard focus visible
- focus ring:
  `0 0 0 3px rgba(0,175,181,.20)`
- 色だけで状態を伝えない
- icon + text を併用
- Escapeでpopover/drawerを閉じる
- `prefers-reduced-motion` 対応
- hover animationは100–180ms程度
- 大きなスケールアニメーションは禁止

---

# 44. Animation

使ってよい:

```text
fade
small slide
accordion expand
button hover elevation
drawer slide
bottom sheet slide
```

推奨:
```css
transition: 160ms ease;
```

ゲームUIらしさは「反応の良さ」で出し、派手な跳ね・発光で出さない。

---

# 45. データモデル（UI実装用）

実際のデータベース設計とは独立してよいが、UIは最低限以下を扱える構造にする。

## Client

```ts
type Client = {
  id: string;
  name: string;
  shortName?: string;
  logoUrl?: string;

  materialDriveUrl?: string;
  reviewDriveUrl?: string;

  monthlyPostGoal: number;
  monthlyPostedCount: number;

  nextShootDate?: string;
  planningDeadline?: string;
  planningStatus?: string;

  nextRegularMeeting?: string;
  meetingMaterialStatus?:
    | "未依頼"
    | "分析・ハイライト作成中"
    | "社員対応待ち"
    | "資料完成";

  editingProgress?: number;
};
```

## Video

```ts
type VideoStatus =
  | "未着手"
  | "編集中"
  | "要修正"
  | "確認中"
  | "投稿待ち"
  | "投稿済み";

type Video = {
  id: string;
  clientId: string;
  title: string;
  referenceUrl?: string;

  status: VideoStatus;
  assigneeId?: string;

  postDate?: string;
  deadline?: string;

  revisionNote?: string;
  memo?: string;

  stalledDays?: number;

  priority?: "normal" | "attention" | "critical";
  isOverdue?: boolean;
};
```

## User

```ts
type UserRole = "employee" | "staff";

type User = {
  id: string;
  name: string;
  role: UserRole;
  avatarUrl?: string;
};
```

## Load

```ts
type MemberLoad = {
  userId: string;
  taskCount: number;
  loadPercent: number;
  overdueRiskCount: number;
  mainTasks: string[];
};
```

## Load Suggestion

```ts
type LoadSuggestion = {
  id: string;
  videoId: string;
  fromUserId: string;
  toUserId: string;
  predictedImpact?: string;
  reason?: string;
};
```

---

# 46. 外部連携に備えるUI契約

今のUI改修で実APIを作らなくても、後で以下を接続しやすい構造にする。

## Google Drive
- 規定フォルダから台本/動画タイトル/参考URL等を取得
- クライアントごとの2フォルダURLを保持
- フォルダ自動作成はしない

## Google Calendar
- 編集スタッフのシフト
- 季実子さん・リカさんのシフト

## Slack
- 急なシフト変更
- カレンダー情報の補正

データソースをUIコンポーネント内に直接書かず、service / adapter 層へ分離できる構造にする。

---

# 47. 検索

Global search:

placeholder:
```text
動画やクライアント名で検索
```

対象:
- client name
- video title

検索結果が多い場合:
- クライアント
- 動画
でグループ分け可能。

---

# 48. 権限表示

以前の大きな
```text
編集権限がありません
```
の常時バナーは使用しない。

必要な場合:
- 小さなinline info
- sidebarの補足
- tooltip

画面の高さを常時消費しない。

---

# 49. Empty / Loading / Error

各画面で必要。

## Loading
- skeleton
- layout shiftを抑える

## Empty
例:
```text
今日対応する動画はありません
```

## Error
短く:
```text
データを読み込めませんでした
再読み込み
```

外部連携:
```text
Drive情報を取得できません
```

---

# 50. 実装優先順位

Claude Code は以下の順に進める。

## Phase 1 — Design system
1. Colors
2. Typography
3. Sidebar
4. Top bar
5. Shared cards
6. Buttons
7. Badges
8. Client icon
9. Responsive primitives

## Phase 2 — Shared workflow
1. Status definitions
2. Dynamic action buttons
3. 要修正 input
4. Video detail panel
5. Drive buttons

## Phase 3 — Pages
1. Home
2. 今日
3. 動画一覧 + 進行トラック統合
4. チーム負荷
5. 投稿カレンダー
6. クライアント管理

## Phase 4 — Responsive
1. Mobile shell
2. Mobile Home
3. Bottom sheet
4. Tables → cards
5. Mobile Calendar
6. employee-only mobile client management

## Phase 5 — Final consistency check
1. terminology
2. colors
3. status
4. role visibility
5. responsive
6. logo
7. Drive buttons

---

# 51. Acceptance Criteria

以下をすべて満たしたらUI実装完了とする。

## Branding
- [ ] 全画面が `SOCIAL BASE` 名称
- [ ] `rogo.png` ベースの正式ロゴ
- [ ] 旧VIDEO WORKSロゴなし
- [ ] 旧SOCIAL BASEロゴマークとの混在なし

## Navigation
- [ ] 独立 `進行トラック` ナビが存在しない
- [ ] staffにはクライアント管理が表示されない
- [ ] employeeにはクライアント管理が表示される
- [ ] mobileから共通5画面へ移動可能

## Workflow
- [ ] `承認済み` ステータスが存在しない
- [ ] `承認` は確認中のaction
- [ ] My Tasksに `次へ` がない
- [ ] statusごとに具体的action名
- [ ] `要修正` で修正指示入力
- [ ] `投稿待ち → 投稿済みにする`

## Drive
- [ ] 2つのDrive URLを扱える
- [ ] `素材を開く`
- [ ] `確認用にアップロード`
- [ ] PC/mobileで同文言
- [ ] フォルダを自動生成しない

## Home
- [ ] My Tasksのみ濃色
- [ ] 停滞中の動画は淡い警告カード
- [ ] KPIクリックがactionにつながる
- [ ] 確認中/投稿待ち/投稿済みのポップオーバー
- [ ] 最大4〜5件
- [ ] icon + titleのみ
- [ ] title ellipsis
- [ ] 日付を表示しない

## 今日
- [ ] 上3KPIは他ページと同じ強いgradient
- [ ] 下段はwhite/light cards
- [ ] 今日のメモは薄色

## 動画一覧
- [ ] 進行トラックを内包
- [ ] クライアント単位の月間進捗を表示
- [ ] すべての動画一覧あり
- [ ] 「契約」文言なし

## チーム負荷
- [ ] 負荷調整提案は必要時のみ
- [ ] 提案0件なら完全非表示
- [ ] 再分配履歴なし
- [ ] 提案は動画/タスク単位
- [ ] 社員確認前に自動変更しない
- [ ] 季実子/リカをチーム負荷メンバーに入れない

## Calendar
- [ ] 土日祝のセル全体が `#E9EDF2`
- [ ] PC/mobile同色
- [ ] 罫線が視認可能
- [ ] 日付クリックで詳細
- [ ] mobileでは詳細が下側/シート

## Client Management
- [ ] employee only
- [ ] 全社員が全clientを見られる
- [ ] client clickでdetail
- [ ] 2 Drive folder URLs
- [ ] 資料フロー4段階
- [ ] 分析・ハイライト目標は毎月12日
- [ ] 社員作業締切はMTGから逆算できるUI構造

## Responsive
- [ ] 375px幅で横崩れしない
- [ ] touch target >=44px
- [ ] desktop tableを単純縮小しない
- [ ] video detail bottom sheet
- [ ] My Tasksがmobile Homeで最優先

---

# 52. Claude Codeへの実装指示

以下の順序で作業すること。

```text
1. 現在のコード構造を確認する
2. 既存機能を壊さない範囲で共通デザイントークンを定義する
3. Sidebar / TopBar / LogoをSOCIAL BASE仕様へ統一
4. Workflow Statusを一元化
5. My Tasksの「次へ」を動的アクションへ置換
6. Video detail / Drive buttons / 要修正inputを共通化
7. Homeを完成イメージへ寄せる
8. 今日を完成イメージへ寄せる
9. 進行トラックを動画一覧に統合し、独立ナビを削除
10. チーム負荷を更新し、条件付き提案へ変更
11. 投稿カレンダーの非稼働日と右詳細を実装
12. クライアント管理をemployee-onlyで実装
13. Mobile responsiveを実装
14. 全画面で文言/色/ステータスの整合性を確認
15. acceptance criteriaを自己チェックする
```

### コード変更時の禁止事項

```text
- 既存ロジックを理由なく削除しない
- 新規フレームワークへ全面移行しない
- 1画面ごとに別々のstatus colorを定義しない
- 同じUIをページごとにコピペ実装しない
- 画像生成のダミー文言を本番値としてハードコードしない
- クライアントDriveフォルダを自動作成しない
- staffへクライアント管理を露出しない
- 負荷調整を自動確定しない
- mobileをdesktopの単純縮小にしない
```

---

# 53. 最終デザイン判断

SOCIAL BASE の完成UIは以下の印象を目標とする。

> 「業務ツールとして一目で分かりやすいが、無機質なSaaSではない。  
> 明るい背景、濃紺のサイドバー、限定された鮮やかなグラデーション、  
> 押したくなる大きな操作部品、ゲームUIのような軽快さを持つ。  
> しかし色は必要以上に増やさず、重要度によってカードサイズと視覚的強度を変える。」

迷った場合は以下の優先順位で判断する。

```text
1. 作業を迷わない
2. タスクを見落とさない
3. 重要度が一目で分かる
4. クリック数を減らす
5. スマホで操作しやすい
6. 見た目が楽しく洗練されている
```

以上。
