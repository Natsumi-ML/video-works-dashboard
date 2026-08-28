# SOCIAL BASE「今日」画面 レスポンシブ実装指示書

**対象:** `02_today.png` を基準とした「今日」画面のレスポンシブ対応  
**目的:** Desktop / Tablet / Mobile で情報優先順位を崩さず、スマホでも「今日何をすべきか」が一目で分かるUIにする。  
**重要:** PC版を単純縮小しない。画面幅に応じてレイアウト構造そのものを切り替える。

---

## 1. 前提

- Desktop版のデザインは既存の `02_today.png` を Visual Specification とする。
- 色・ステータス・文言・ボタン名称は `SOCIAL_BASE_UI_IMPLEMENTATION_SPEC.md` を正とする。
- 今回は **Layer C（描画）とCSSのみ**を対象とし、Layer A（ロジック）・Layer B（保存）・データモデルは変更しない。
- 「今日」画面で表示する情報内容は維持する。
- スマホでも以下の5画面へ移動可能にする。
  - ホーム
  - 今日
  - 動画一覧
  - チーム負荷
  - 投稿カレンダー
- クライアント管理は社員のみであり、スマホの共通ボトムナビには置かない。

---

## 2. ブレークポイント

以下を基準とする。

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

# 3. Desktop（1200px以上）

Desktopは現在の `02_today.png` を維持する。

## 3.1 レイアウト

```text
┌──────── Sidebar ────────┬──────────────── Main ────────────────┐
│                          │ TopBar                               │
│                          │                                     │
│                          │ KPI × 3                              │
│                          │                                     │
│                          │ 最優先タスク | 今日やること | 要確認 │
│                          │                              今日のメモ│
└──────────────────────────┴─────────────────────────────────────┘
```

### 下段3カラム比率

```css
grid-template-columns: 1fr 1.6fr 1fr;
gap: 16px;
```

- 最優先タスク：左
- 今日やること：中央・最も広い
- 要確認 + 今日のメモ：右

Desktopでは各セクション内容を常時表示する。

---

# 4. Tablet（768–1199px）

Tabletではサイドバーを非表示にし、ヘッダー＋カード主体へ切り替える。

## 4.1 ヘッダー

高さ目安: `56–64px`

左から:

```text
[Hamburger] [SOCIAL BASE logo]       [Search] [Notification] [Avatar]
```

### 条件

- サイドバーは drawer 化する。
- ロゴは横長でもよいが、幅不足時はマーク＋短いワードマーク。
- 検索欄そのものは常設しない。検索アイコンでoverlay/search sheetを開く。
- ユーザーカードの長い氏名・部署表示はしない。Avatarのみでよい。

---

## 4.2 月・Drive行

ヘッダー直下に2列。

```text
[ < 2026年08月 > ]    [Google Drive]
```

- 月セレクタは横幅の約55〜60%
- Driveボタンは残り
- 高さ: 44px以上

---

## 4.3 KPI

Tabletでは3枚を**縦積み**する。

順序:

```text
最優先
今日やること
要確認
```

各カードは横幅100%。

### KPI内部

参考画像の情報量を維持。

```text
最優先 3件
期限超過              2件  ●
投稿予定日未設定      1件  ●

今日やること 8件
進行中                5件
本日対応予定          3件

要確認 6件
Drive未設定           2件
投稿日時未設定        2件
タイトル未入力        2件
```

- カード高さは内容に応じて自然に伸びる
- 無意味な固定heightを使わない
- `詳細を見る` / `すべて見る` はカード下部
- タップ領域全体を大きくする

---

## 4.4 下段詳細セクション

TabletではDesktopの3カラムをやめる。

各セクションを**アコーディオン**化。

```text
[ 最優先タスク                         v ]
[ 今日やること                         v ]
[ 要確認                               v ]
[ 今日のメモ                           v ]
```

### 初期状態

推奨:

- すべて閉じる
- KPIカードをタップした場合のみ該当accordionを開く

例:

```text
「今日やること 8件」をタップ
↓
「今日やること」accordionが開く
↓
該当位置までsmooth scroll
```

---

## 4.5 Tabletでの詳細表示

アコーディオンを開いた場合は、縦リストカードとして表示。

### 最優先タスク

```text
[Client icon] Client
Video title

期限: 未設定        [期限超過]
担当: ○○

[投稿日を設定する]
```

### 今日やること

```text
[Client icon] Client      [status]
Video title
担当: [avatar] name

                       [action]
```

### 要確認

カテゴリごとにgroup化。

```text
Drive未設定                      2件
・動画...
・動画...              [確認する]

投稿日時未設定                   2件
...
```

---

# 5. Mobile（0–767px）

Mobileは「今日何をすべきかを瞬時に確認する」ことを最優先にする。

**Desktopの縮小表示は禁止。**

---

## 5.1 Mobile Header

高さ目安: `52–58px`

```text
[☰]  [SOCIAL BASE]        [🔍] [🔔] [Avatar]
```

### ルール

- 左サイドバー非表示
- Hamburgerでdrawer
- ロゴは中央寄り
- Avatarは24〜32px
- 1行に収める
- 氏名・部署カードは表示しない

---

## 5.2 月・Drive

Header直下。

```text
[ < 2026年08月 > ] [Google Drive]
```

- 2列
- gap 8px
- 1ボタン高さ 42〜46px

---

## 5.3 KPI

Mobileも縦積み。

順序固定:

```text
1. 最優先
2. 今日やること
3. 要確認
```

### Card

```css
width: 100%;
border-radius: 14px;
padding: 14px 16px;
```

### 色

- 最優先 = critical gradient
- 今日やること = blue gradient
- 要確認 = orange gradient

**他ページと同じ色表現を使用する。**

### 情報量

Mobileでも内訳は隠さない。

例:

```text
最優先 3件
期限超過             2件  ●
投稿予定日未設定     1件  ●
                    すべて見る >
```

---

# 6. Mobile Accordion

KPIの下に4つ。

```text
最優先タスク
今日やること
要確認
今日のメモ
```

初期状態:
- 原則閉じる

ただしユーザーがKPIカードを押した場合:
- 対応accordionを開く
- smooth scroll

### accordion row

```css
min-height: 48px;
background: #fff;
border: 1px solid var(--border);
border-radius: 10px;
```

### Header

```text
[icon] Section title                       [chevron]
```

---

# 7. Mobile Bottom Sheet

Mobileでは一覧の詳細をカード内に全部詰め込まない。

以下をタップした際にBottom Sheetを使用。

- 最優先タスク
- 今日やること
- 要確認項目
- 動画タイトル
- クライアント

## 7.1 Bottom Sheet

```css
position: fixed;
bottom: 0;
left: 0;
right: 0;
max-height: 88vh;
border-radius: 20px 20px 0 0;
overflow-y: auto;
```

上部:
- drag handle
- title
- close

---

## 7.2 最優先タスク sheet

```text
最優先タスク

[Client icon] Client
Video title

期限
担当
priority / severity

[主アクション]

---

次のタスク...
```

---

## 7.3 今日やること sheet

```text
今日やること

[Client icon] Client           [status]
Video title
担当 [avatar] name

[action]

---

next...
```

---

## 7.4 要確認 sheet

カテゴリ別。

```text
要確認

Drive未設定                      2件

・Client / Video
                                  [確認する]

・Client / Video
                                  [確認する]

---

投稿日時未設定                   2件
...
```

---

# 8. 今日のメモ

Mobileではaccordion。

開いた状態:

```text
今日のメモ
────────────────
・...
・...
・...
────────────────
[編集する]
```

背景:
- 白
- またはごく薄いblue
- dark background禁止

---

# 9. Bottom Navigation

Mobile / Tabletでは固定ボトムナビを使用。

```text
ホーム
今日
動画一覧
チーム負荷
カレンダー
```

### 今日
active state:
- icon blue
- label blue
- optional very light blue background

### サイズ

```css
height: 64–72px;
padding-bottom: env(safe-area-inset-bottom);
```

### touch target
各item 44px以上。

---

# 10. Sidebar Drawer

Hamburger tap:

```text
SOCIAL BASE
────────────
ホーム
今日
動画一覧
チーム負荷
投稿カレンダー

[employee only]
クライアント管理
```

社員の場合のみクライアント管理表示。

drawer:
- width: 78–84vw
- max-width: 320px
- dark navy background
- desktop sidebarと同じworldview

---

# 11. Responsive Table / List Rules

今日画面ではtableを横スクロールさせない。

Desktop:
- row/table

Tablet/Mobile:
- card/list

### 禁止

```text
PCテーブルを transform: scale()
PC画面全体を zoom
横スクロール前提
文字を極端に小さくする
```

---

# 12. Responsive Typography

## Desktop

```text
Page title       27–30px
Section title    18–20px
KPI label        16–18px
KPI value        34–40px
Body             14–15px
```

## Tablet

```text
Section title    17–19px
KPI label        16–17px
KPI value        30–36px
Body             14px
```

## Mobile

```text
Section title    16–18px
KPI label        15–17px
KPI value        28–34px
Body             13.5–14.5px
Metadata         >=12px
```

---

# 13. Touch & Interaction

Mobile / Tablet:

```css
min-height: 44px;
```

対象:
- buttons
- nav
- accordion
- KPI clickable area
- task rows

### hover依存禁止

PCのみhoverを補助利用。

Mobileは:
- tap
- pressed
- focus
で状態が分かること。

---

# 14. Animation

Accordion:

```text
150–200ms
height + opacity
```

Bottom Sheet:

```text
180–240ms
translateY
```

KPI tap:
- 0.98程度の軽いpress
- 大きなbounce禁止

`prefers-reduced-motion` 対応。

---

# 15. Visual Consistency

Desktop / Tablet / Mobileで以下を変えない。

```text
色
ステータス
警告色
アイコンの意味
ボタン文言
情報の意味
```

変えてよい:

```text
レイアウト
列数
表示順
詳細の開き方
一覧→カード
drawer / bottom sheet
```

---

# 16. Visual QA

実装後、以下3サイズで実画面をスクリーンショットする。

```text
Desktop: 1448 x 1086
Tablet:  834 x 1112
Mobile:  375 x 812
```

deviceScaleFactor=1
zoom=100%

確認:

- horizontal overflowなし
- fixed bottom navがcontentを隠さない
- accordionが画面外にはみ出さない
- cards width=viewport内
- touch target >=44px
- text truncation正常
- status chip潰れなし
- KPI color consistency
- hamburger drawer正常
- bottom sheet正常

Mobile:

```js
document.documentElement.scrollWidth === window.innerWidth
```

を満たすこと。

---

# 17. 実装順序

```text
1. DesktopのToday画面をFIX
2. Headerをresponsive化
3. Sidebar→Drawer
4. KPI responsive化
5. 3カラム→Accordion
6. List→Mobile cards
7. Bottom Sheet
8. Bottom Navigation
9. Tablet調整
10. 375px visual QA
11. 834px visual QA
12. Desktop再確認
```

---

# 18. Acceptance Criteria

- [ ] Desktopは `02_today.png` の構造を維持
- [ ] Tabletでsidebarが消えdrawerになる
- [ ] Mobileでsidebarが消えdrawerになる
- [ ] Tablet/Mobile KPIは縦積み
- [ ] KPI色はDesktopと完全統一
- [ ] Desktopの3カラムをMobileでそのまま縮小していない
- [ ] Mobileの詳細セクションはaccordion
- [ ] KPI tapで対応accordionを開ける
- [ ] 詳細はbottom sheetで見られる
- [ ] 今日のメモはlight background
- [ ] fixed bottom navあり
- [ ] staffからclient管理は見えない
- [ ] employeeのみdrawerからclient管理へ行ける
- [ ] 375pxでhorizontal overflowなし
- [ ] touch target 44px以上
- [ ] desktopの既存ロジックを壊していない
- [ ] console error 0

---

# 19. Claude Codeへの最終指示

```text
このレスポンシブ対応では、
PC版を縮小してスマホに押し込まないでください。

Desktop:
02_today.png をVisual Specificationとして維持。

Tablet/Mobile:
同じ情報と同じデザインシステムを使いながら、
KPIを縦積み、
詳細セクションをaccordion、
詳細内容をbottom sheet、
ナビゲーションをhamburger + fixed bottom navigation
へ再構成してください。

色、ステータス、文言、ロジックは変更しません。
変更対象はLayer CとCSSのみです。

実装後は
1448×1086
834×1112
375×812
の3サイズでスクリーンショットを撮り、
横崩れと情報階層をVisual QAしてください。

375pxで
document.documentElement.scrollWidth === window.innerWidth
を必ず確認してください。
```
