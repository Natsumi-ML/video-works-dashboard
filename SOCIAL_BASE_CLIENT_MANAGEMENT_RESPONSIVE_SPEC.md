# SOCIAL BASE「クライアント管理」画面
# Desktop Visual QA + Responsive UI 実装指示書

**対象画面:** クライアント管理  
**参照画像:** `06_client.png`  
**目的:** Desktopでは参照画像をVisual Specificationとして忠実に再現し、Tablet / Mobileでは同じデザインシステムを保ちながら最適なレスポンシブUIへ再構成する。  
**重要:** PC版を単純縮小しない。画面幅に応じて構造そのものを切り替える。

---

## 0. 最重要ルール

GitHub内の以下を必ず確認すること。

- `CLAUDE.md`
- `SOCIAL_BASE_UI_IMPLEMENTATION_SPEC.md`
- `06_client.png`
- `rogo.png`

優先順位は以下。

1. `SOCIAL_BASE_UI_IMPLEMENTATION_SPEC.md` の確定仕様
2. 正式ロゴ `rogo.png`
3. `06_client.png` のDesktopレイアウト・サイズ・余白・情報階層
4. 現在の実装

参考画像に古いロゴ・古いステータス・ダミーデータがあっても、その内容は再現しない。

参考画像から再現する対象は以下。

- レイアウト
- サイズ比率
- 余白
- カード構造
- 情報階層
- カラム構成
- 視覚的密度

現在の実データ・クライアント数・投稿数・担当者名等は変更しない。

---

## 1. 今回変更してよい範囲

変更対象:

- Layer C（描画）
- CSS
- Responsive用の表示切替
- Drawer / Bottom Sheet 等のUI表現

変更禁止:

- Layer A のロジック
- Layer B の保存処理
- データモデル
- クライアントデータ
- 動画データ
- ステータス定義
- Drive URL
- 権限仕様
- 資料準備フロー
- 既存の保存機能
- 既存のクリック処理

見た目を合わせるために機能を削除しない。

---

## 2. Breakpoints

```css
/* Mobile */
@media (max-width: 767px) {}

/* Tablet */
@media (min-width: 768px) and (max-width: 1199px) {}

/* Desktop */
@media (min-width: 1200px) {}
```

既存CSSに近いbreakpointがある場合は統合してよい。

---

# Desktop

## 3. Desktop 全体構成

`06_client.png` をVisual Specificationとして、以下の大構成へ合わせる。

```text
┌──────── Sidebar ───────┬─────────────────────────────────────────────┐
│                        │ TopBar                                      │
│                        │                                             │
│                        │ クライアント管理 [社員のみ]                  │
│                        │                                             │
│                        │ KPI KPI KPI KPI | 注意が必要なクライアント   │
│                        │                                             │
│                        │ ┌──────────── 左一覧 ───────┐ ┌──右詳細──┐ │
│                        │ │ Filters                   │ │ Client    │ │
│                        │ │ Client Table              │ │ Detail    │ │
│                        │ │                           │ │           │ │
│                        │ └───────────────────────────┘ └───────────┘ │
└────────────────────────┴─────────────────────────────────────────────┘
```

---

## 4. Desktop ページタイトル

```text
クライアント管理 [社員のみ]
```

目安:

```css
font-size: 28px;
font-weight: 700;
```

- `社員のみ` は小さなbadge
- タイトル右に配置
- タイトル下の余白を大きく取りすぎない
- KPIまで `12〜16px` 程度

---

## 5. Desktop TopBar

Desktopでは以下の4要素を基本とする。

```text
[Search]                       [動画追加] [Google Drive] [User]
```

検索placeholder:

```text
動画やクライアント名で検索
```

トップバーに以下を混在させない。

- 月切替
- 大きな権限警告
- 不要な補助ボタン

---

## 6. Desktop KPI + 注意カード

現在の2×2 KPI構成は禁止。

必ずDesktopでは以下を同一行にする。

```text
[KPI1][KPI2][KPI3][KPI4][注意が必要なクライアント]
```

推奨:

```css
.client-summary-grid {
  display: grid;
  grid-template-columns:
    repeat(4, minmax(0, 1fr))
    minmax(280px, 1.25fr);
  gap: 16px;
  align-items: stretch;
}
```

---

## 7. KPIカード

順序:

```text
担当クライアント数
今月の投稿数（合計）
企画進行中
資料準備中
```

デザイン:

- 白〜ごく薄い色背景
- 細いborder
- 角丸14px前後
- 左上に色付き丸アイコン
- 小さいラベル
- 大きい数値
- 下に短い補足
- 強いグラデーションは禁止

アクセント:

```text
担当クライアント数 → Blue
今月投稿数         → Teal
企画進行中         → Purple
資料準備中         → Orange
```

目安:

```css
.kpilight {
  min-height: 136px;
  padding: 18px 20px;
  border-radius: 14px;
}
```

4枚の高さを揃える。

不要な大きな空白を作らない。

---

## 8. 注意が必要なクライアント

KPIと同じ1行の中に置く。

現在のように縦長にして空白を大量に残さない。

構造:

```text
⚠ 注意が必要なクライアント

企画期限超過        n社  [badge]
投稿目標未達リスク  n社  [badge]
資料準備遅延        n社  [badge]

                         すべて見る >
```

デザイン:

- very light critical background
- critical-soft border
- compact padding
- 件数badgeは右端
- 最下部に `すべて見る >`

---

## 9. Desktop メイン2カラム

参考画像のように以下を目安とする。

```text
左：約64〜66%
右：約34〜36%
```

推奨:

```css
.client-main-grid {
  display: grid;
  grid-template-columns:
    minmax(0, 1.75fr)
    minmax(380px, 0.9fr);
  gap: 16px;
  align-items: start;
}
```

---

## 10. Filters

現在のように画面全幅へ伸ばさない。

Filtersは**左のクライアント一覧カードの中**に入れる。

```text
┌─────────────────────────────────────┐
│ [Status] [担当] [資料状況] [クリア] │
├─────────────────────────────────────┤
│ クライアント一覧                    │
│ ...                                 │
└─────────────────────────────────────┘
```

右詳細の上にはFilterを伸ばさない。

---

## 11. クライアント一覧

Filter・タイトル・tableを1枚の白いカードにまとめる。

Header:

```text
クライアント一覧  全○社
クライアント名をクリックすると、詳細が表示されます
```

説明文は小さく、secondary text。

---

## 12. Desktop クライアントテーブル

列:

```text
クライアント
次回撮影日
企画期限
企画ステータス
今月投稿数
投稿目標
編集進行状況
担当スタッフ
定例MTG日
資料準備状況
```

行高目安:

```css
48px〜54px
```

Typography目安:

```text
Header: 11〜12px
Row:    12〜13px
```

現状よりコンパクトにする。

---

## 13. Client icon

```text
[icon] Client Name
```

目安:

```css
.client-icon {
  width: 28px;
  height: 28px;
  border-radius: 7px;
}
```

ロゴがなければ略称。

---

## 14. 選択中の行

参考画像のような薄いBlue。

```css
background: #F3F8FF;
border: 1px solid #8FC5FF;
```

濃色背景にはしない。

---

## 15. Desktop 右詳細パネル

右側は単なる小さなplaceholderではなく、**主要カラム**として扱う。

可能なら初期状態では以下のどちらかを表示する。

- 前回選択したクライアント
- または一覧先頭

新しいデータ構造は作らず、既存のselection stateを利用する。

```css
.client-detail-panel {
  width: 100%;
  background: #fff;
  border: 1px solid var(--border);
  border-radius: 14px;
}
```

可能なら:

```css
position: sticky;
top: 90px;
```

---

## 16. Desktop 詳細パネル情報順序

必ず以下の情報階層にする。

```text
[Client icon] Client name                  ×

関連フォルダ（Google Drive）

[未編集動画（素材置場）]
撮影済みの素材を格納するフォルダ
                               [素材を開く]

[確認用（編集済み動画置き場）]
編集済み動画を格納するフォルダ
                     [確認用にアップロード]

────────────────────

次回撮影日
企画期限
今月の投稿状況 + progress
次回 定例MTG

────────────────────

資料準備フロー

未依頼
→ 分析・ハイライト作成中
→ 社員対応待ち
→ 資料完成

────────────────────

注意 / 補足
```

---

## 17. Drive

確定仕様を優先する。

必ず:

```text
[素材を開く]
[確認用にアップロード]
```

PC / Tablet / Mobile 共通文言。

---

## 18. 資料準備フロー

Desktopでは横型4ステップ。

```text
○────────○────────○────────○
未依頼   分析・ハイライト   社員対応待ち   資料完成
         作成中
```

色:

```text
未依頼                  Gray
分析・ハイライト作成中   Orange
社員対応待ち             Purple
資料完成                 Green
```

現在地点だけ強調。

補足・日付目安を各ステップ下に表示可能。

---

## 19. 毎月12日の意味

重要:

```text
毎月12日
=
「分析・ハイライト作成」の完成目標
```

12日までに理想的には:

```text
社員対応待ち
```

にする。

資料全体の完成期限ではない。

社員が担当する「課題と改善提案」は、各クライアントの定例MTGから逆算する仕様。

---

## 20. Desktopで現在特に修正すべき点

現画面と `06_client.png` の主な差分:

```text
1. KPIが2×2
2. KPIカードが大きすぎる
3. 注意カードが縦長すぎる
4. 上部が間延び
5. Filtersが全幅
6. 左一覧＋右詳細の2カラムが弱い
7. 右詳細が小さいplaceholder
8. 詳細情報の階層が違う
9. table行が大きい
10. 情報密度が低い
11. 一覧開始位置が下すぎる
12. 右側に不要な空白がある
```

これを優先的に修正する。

---

# Responsive Design

## 21. Responsiveの基本思想

ResponsiveではDesktop版を単純縮小しない。

構造は以下へ切り替える。

```text
Desktop = Table + 常設Right Detail
Tablet  = Compact List + Detail Drawer
Mobile  = Client Cards + Detail Bottom Sheet
```

---

# Tablet

## 22. Tablet 全体構造

Tabletでは左Sidebarを消してDrawer化する。

構成:

```text
Header
↓
Page Title
↓
KPI
↓
注意カード
↓
Filters
↓
Client list
↓
選択Client詳細
↓
Bottom Navigation
```

---

## 23. Tablet Header

```text
[☰] [SOCIAL BASE]          [Search] [Notification] [Avatar]
```

- Sidebar非表示
- Hamburger → Drawer
- 長いUser Cardは非表示
- Searchはiconでoverlayでも可
- 高さ56〜64px

---

## 24. Tablet KPI

Tabletでは4枚横並びにこだわらない。

推奨:

```text
[KPI1][KPI2]
[KPI3][KPI4]
```

```css
grid-template-columns: repeat(2, minmax(0, 1fr));
gap: 12px;
```

注意カードはその下に100%幅。

---

## 25. Tablet Client list

Desktop tableを縮小して押し込まない。

Tabletでは情報量に応じて以下へ切り替える。

- compact table
- または horizontal card list

横スクロールを前提にしない。

優先情報:

```text
Client
次回撮影
企画
投稿進捗
担当
資料準備
```

その他情報は詳細Panelへ。

---

## 26. Tablet Client detail

右カラム固定はやめる。

クライアントをtapしたら**右からDrawer**または**Bottom Sheet**を開く。

Tablet推奨:

```text
Right Drawer
width: 420〜520px
```

内容はDesktop detailと同じ。

---

## 27. Tablet Navigation

固定Bottom Navigation推奨:

```text
ホーム
今日
動画一覧
チーム負荷
カレンダー
```

`クライアント管理` はemployee onlyのためBottom Navigationには置かない。

社員はHamburger Drawerからアクセス。

---

# Mobile

## 28. Mobile 全体思想

Mobileは以下の流れを最優先にする。

```text
クライアント一覧を確認
↓
必要なClientをtap
↓
詳細を見る
```

Desktopの大きなtableを縮小しない。

---

## 29. Mobile Header

```text
[☰] [SOCIAL BASE]        [🔍] [Avatar]
```

- 高さ52〜58px
- Sidebar非表示
- User name/部署非表示
- ロゴは横幅に応じてsymbolのみでも可

---

## 30. Mobile Page title

```text
クライアント管理 [社員のみ]
```

- 20〜24px
- badgeを横に
- padding左右16px

---

## 31. Mobile KPI

4枚を2列にする。

```text
[KPI1][KPI2]
[KPI3][KPI4]
```

カード高さはコンパクト。

例:

```text
[icon] 担当クライアント
       10社
```

補足文は必要なら1行まで。

Mobileでは過度な説明をKPI内に詰めない。

---

## 32. Mobile 注意カード

KPIの直下。

横幅100%。

```text
⚠ 注意が必要なクライアント    18件 >
```

初期状態はコンパクトにしてよい。

tapするとaccordion展開:

```text
企画期限超過
投稿目標未達
資料準備遅延
```

---

## 33. Mobile Filters

Filtersは1行に全部並べない。

```text
[フィルター 3]
```

という1ボタンへまとめる。

tapするとBottom Sheet:

```text
Status
担当
資料準備状況

[条件をクリア]
[適用する]
```

---

## 34. Mobile Client list

tableは禁止。

**Card listへ変更する。**

1 Client 1 Card。

例:

```text
┌──────────────────────────────┐
│ [logo] NCN                   │
│                              │
│ 次回撮影      未設定         │
│ 企画          未着手         │
│ 投稿          4 / 6本  67%   │
│ 担当          りりか         │
│ 資料          未依頼         │
│                              │
│                         ＞   │
└──────────────────────────────┘
```

カードtap → detail Bottom Sheet。

---

## 35. Mobile Client card priority

表示優先度:

```text
1. Client
2. 次回撮影
3. 企画Status
4. 月間投稿Progress
5. 担当
6. 資料準備Status
```

Desktop tableの全列をカードに載せない。

企画期限・定例MTG等の詳細はsheetで表示。

---

## 36. Mobile Detail Bottom Sheet

クライアントtap:

```text
Bottom Sheet
max-height: 90vh
```

Header:

```text
drag handle

[logo] Client Name                     ×
```

順序:

```text
Google Drive

[素材を開く]
[確認用にアップロード]

基本情報
・次回撮影日
・企画期限
・今月投稿
・担当
・定例MTG

資料準備
・横4stepではなくMobile用縦step

注意・補足
```

---

## 37. Mobile 資料準備Flow

Mobileで横4stepを無理に縮小しない。

縦型へ変更:

```text
● 未依頼
│
● 分析・ハイライト作成中
│
● 社員対応待ち
│
○ 資料完成
```

現在stepを強調。

---

## 38. Mobile Drive

2ボタンは縦積み。

```text
[素材を開く]
[確認用にアップロード]
```

ボタン高さ44〜48px。

---

## 39. Mobile Bottom Navigation

```text
ホーム
今日
動画一覧
チーム負荷
カレンダー
```

クライアント管理はBottom Navへ入れない。

employeeのみHamburgerからアクセス。

---

## 40. Mobile Sidebar Drawer

Hamburger:

```text
SOCIAL BASE

ホーム
今日
動画一覧
チーム負荷
投稿カレンダー

社員のみ
クライアント管理

その他補助機能
```

現在ページのクライアント管理をactive表示。

---

# Common Responsive Rules

## 41. Touch

Tablet / Mobileは最低:

```css
min-height: 44px;
```

対象:

- buttons
- filters
- client cards
- drawer nav
- bottom nav
- Drive
- close button

hover依存禁止。

---

## 42. Typography Responsive

Desktop:

```text
Page title 28px
Section 18〜20px
Body 12〜15px
```

Tablet:

```text
Page title 24〜27px
Section 17〜19px
Body 13〜14px
```

Mobile:

```text
Page title 21〜24px
Section 16〜18px
Body 13〜14px
Metadata >=12px
```

---

## 43. Responsive禁止事項

禁止:

```text
PC画面をtransform: scale()
zoomで縮小
tableをそのまま375pxへ押し込む
小さすぎる文字
horizontal scroll前提
右詳細panelを画面外に残す
```

---

# Visual QA

## 44. Visual QAサイズ

実装後、必ず以下でスクリーンショットを取得。

```text
Desktop: 1448 × 1086
Tablet:   834 × 1112
Mobile:   375 × 812
```

条件:

```text
deviceScaleFactor = 1
zoom = 100%
```

---

## 45. Desktop Visual QA

`06_client.png` と同サイズで比較。

可能ならoverlay/diffを使用。

確認:

```text
Sidebar width
TopBar height
Title position
KPI start position
KPI size
KPI gap
Warning card size
Main columns start Y
Left/right ratio
Filter position
Table row height
Detail width
Detail height
Padding
Typography
Border radius
```

「概ね一致」で終わらない。

画面のシルエットだけでも `06_client.png` とほぼ同じになるまで調整する。

---

## 46. Responsive QA

Tablet / Mobile:

```text
horizontal overflowなし
Bottom Navがcontentを隠さない
Drawer正常
Bottom Sheet正常
Client card崩れなし
KPI崩れなし
Status chip崩れなし
Drive button >=44px
```

Mobileで:

```js
document.documentElement.scrollWidth === window.innerWidth
```

を必ず確認。

---

# Implementation Order

## 47. 実装順序

以下の順で作業する。

```text
1. Desktop Client ManagementだけをVisual QA
2. DesktopのSummary 1行化
3. Filtersを左へ移動
4. Left list + Right detailをFIX
5. Detail内部をFIX
6. Desktop screenshot再比較
7. DesktopをFIX判定
8. Tablet Header / Drawer
9. Tablet KPI 2×2
10. Tablet list / detail Drawer
11. Mobile Header
12. Mobile KPI 2×2
13. Mobile filters sheet
14. Client table → card list
15. Client detail Bottom Sheet
16. Mobile vertical material flow
17. Bottom Navigation
18. 834px QA
19. 375px QA
20. Desktop再確認
```

---

# Acceptance Criteria

## 48. Acceptance Criteria

### Desktop

- [ ] KPI4枚が1行
- [ ] 注意カードも同一行
- [ ] KPI高さが概ね統一
- [ ] Filterは左一覧内
- [ ] 左一覧＋右詳細の2カラム
- [ ] 右詳細に十分な存在感
- [ ] table密度が参考画像と一致
- [ ] 上部の間延びが解消
- [ ] `06_client.png` と画面シルエットがほぼ一致

### Tablet

- [ ] Sidebarなし
- [ ] Hamburger Drawer
- [ ] KPI 2×2
- [ ] 注意カード100%
- [ ] Client listはタブレット最適化
- [ ] DetailはDrawer/Sheet
- [ ] horizontal overflowなし

### Mobile

- [ ] Sidebarなし
- [ ] Header compact
- [ ] KPI 2×2
- [ ] 注意カードcompact
- [ ] FilterはBottom Sheet
- [ ] Client tableをCard化
- [ ] Client detailはBottom Sheet
- [ ] 資料準備Flowは縦型
- [ ] Drive button縦積み
- [ ] Bottom Navigationあり
- [ ] 375px横崩れなし
- [ ] touch target >=44px

### 共通

- [ ] クライアント管理はemployee only
- [ ] staffには表示しない
- [ ] 既存ロジックを壊していない
- [ ] Drive 2URL仕様維持
- [ ] 資料準備Flow仕様維持
- [ ] 12日は分析・ハイライト完成目標
- [ ] console error 0

---

# Push / 公開

## 49. Visual QA中の扱い

私がスクリーンショットを目視確認してFIXを出すまで、以下は行わない。

- GitHubへのpush
- 公開版Artifact更新

ローカルコミットは可。

---

# 最終指示

## 50. Claude Codeへの最終指示

まずDesktopのクライアント管理画面だけを修正する。

いきなりResponsiveまで全部変更せず、

```text
Desktop修正
→ screenshot
→ 06_client.png と比較
→ 再修正
```

を最低1回行う。

Desktopが参考画像とほぼ同じ構成になったら、そのデザインシステムを保持したままTablet / Mobileへ展開する。

ResponsiveではPCを縮小するのではなく、

```text
Desktop = Table + 常設Right Detail
Tablet  = Compact List + Detail Drawer
Mobile  = Client Cards + Detail Bottom Sheet
```

へ構造を切り替える。

実装完了後、以下3枚のスクリーンショットを提示する。

- Desktop 1448×1086
- Tablet 834×1112
- Mobile 375×812

それを人間が確認するまで、この画面を完了扱いにしない。
