# SOCIAL BASE — Review Resolution

`SOCIAL_BASE_SENIOR_REVIEW.md` の指摘に対する採否判断と、`SOCIAL_BASE_SYSTEM_DESIGN.md` への反映結果。

| | |
|---|---|
| 対象レビュー | `SOCIAL_BASE_SENIOR_REVIEW.md`（948行、2026-08-29） |
| レビュー判定 | **B. 修正後に実装開始可能** |
| 指摘件数 | BLOCKER 3 / HIGH 13 / MEDIUM 10 / LATER 4 |
| 本書の判断 | ACCEPT 27 / PARTIAL 3 / REJECT 0 |

**このファイルは記録であり仕様ではない。** ACCEPT / PARTIAL の内容はすべて `SOCIAL_BASE_SYSTEM_DESIGN.md` へ反映済みで、仕様確認は正典だけを見ればよい。

---

## 0. Primary Agent による事実検証

レビューの指摘を鵜呑みにせず、`ml-editing-board.html` と `<script id="state">` を実測して裏を取った。

| レビューの主張 | 実測 | 結果 |
|---|---|---|
| 11社ではなく **10社** | `SEED_CONTRACTS` の distinct client = 10 | **正しい。設計書が誤り** |
| 動画9/静止画4 ではなく **動画10/静止画3** | `kind:"動画"` 10件 / `kind:"静止画"` 3件 | **正しい。設計書が誤り** |
| poster なつみ9 / りりか4 | 一致 | 設計書が正しい |
| `STAFF_MAP` は編集担当ロスター | 定義1 + 参照17 = 18箇所。`Object.keys()` が担当セレクト・チーム負荷・`myTasks()` 絞り込み・カレンダー営業日軸・`generate()` の caps を決めている | **正しい。設計書の「破棄」は誤り** |
| `generate()` は種別ごと先頭契約1件しか見ない | `:1708-1709` の `filter(...)[0]` | **正しい** |
| ローカル `STATE` は `seeded:true` / 50行 / 2026-08のみ / `clients`・`notes` キー不在 | 実測一致（50行・全て2026-08・両キー0件） | **正しい（ただし §HIGH-5 の但し書き参照）** |
| `trans{}` に時系列矛盾が実在 | 投稿待ちと投稿済みを両方持つ3行のうち **2行**で 投稿済み < 投稿待ち。さらに 投稿済み 38件に対し 投稿待ち 6件しか無い | **正しい（件数のみ3→2に訂正）** |

**レビュー文書自体の軽微な不整合**：総評は「HIGH 11件」と書いているが、本文と付録は HIGH-1〜13 の13件。本書は13件として扱う。指摘の中身には影響しない。

---

## 1. BLOCKER

### BLOCKER-1 — Workspace 分離のスキーマ層防御が権限テーブルに存在しない → **ACCEPT**

自分でスキーマを確認した。`unique(id, workspace_id)` を書いていたのは `workspace_members` と `clients` の2つだけで、§6.1 が規約として宣言した複合外部キーは他のどの関連でも成立しない。さらに `member_roles` と `role_capabilities` には `workspace_id` 列自体が無く、**権限の中核テーブルだけが一重防御**という、設計書自身の主張と正反対の状態だった。指摘のとおり。

**反映** — §6.1 に例外表（`users` / `webhook_receipts` のみ）を追加し、`unique(id, workspace_id)` を全テーブルの規約として明記。`member_roles` / `role_capabilities` / `workflow_run_transitions` / `notification_deliveries` に `workspace_id not null` と複合外部キーを追加。§25.2 に「別 Workspace の Role を付与する INSERT が拒否される」テストを追加。

### BLOCKER-2 — Serverless + プーラ構成で RLS が機能しない → **ACCEPT**

§6.5 は「RLS を有効化してセッション変数で絞る」としか書いておらず、(a) テーブル所有者が RLS をバイパスする点、(b) transaction pooling で `SET` が次リクエストへ持ち越される点、(c) autocommit では `SET LOCAL` が効かない点のいずれにも触れていなかった。とくに (b) は Workspace 分離の完全な破綻で、しかもログに異常が残らない。ADR-019 で「最初から入れる」と決めておきながら、機能する条件を書いていなかった。

**反映** — §6.5 に「RLS 運用規約」を新設（所有者ロールとアプリロールの分離、`force row level security`、全 DB アクセスの明示トランザクション化と `set local`、`nullif(current_setting(...), '')` で未設定時0行）。§21.1 に「Query Service も明示トランザクションで包む」を追記。§25.2 のテストを「本番と同じプーラ構成を通し、同一物理接続で連続実行して workspace を継承しないこと」に変更。§26.1 に接続プーリングモードを決定事項として追加。ADR-019 を更新。

### BLOCKER-3 — Identity を email で束ねており OIDC `sub` が無い → **ACCEPT**

`users` に `sub` 相当の列が無く、email で同定する設計だった。email はアドレス再割当で別人に渡る可変の識別子であり、退職者の Role・担当・監査IDを新入社員が継承する。§19 の「誰がいつ何をどう変えたか」という要件そのものが偽になる。既知のアンチパターンで、弁解の余地がない。

**反映** — `users` に `external_subject` / `identity_provider` と `unique(identity_provider, external_subject)` を追加。§8.2 を「同定は `sub`、email は表示と招待照合のみ。招待は email で出し初回ログインで `sub` を束ねる」に変更。§20.1 に Identity binding の行を追加。§25.3 に「同じ email・異なる `sub` が既存 User に入れない」テストを追加。ADR-004 を更新。

---

## 2. HIGH

### HIGH-1 — 既定 Role が現行挙動を再現していない → **ACCEPT**

現行で `myRole()==="社員"` の分岐は8箇所しかなく、動画追加・担当変更・日付変更はすべて `writable()` のみ＝全員可。§9.2 で `editor` からこれらを外したのは、**設計者が黙って権限を絞った**ことになる。移行時の挙動変更はオーナー判断に上げるべきで、設計で決めてよいことではない。§9.3 の `:3564` 欠落と、要確認項目を `content.update` に対応付けた誤り（スタッフに社員向け督促が出る）も指摘のとおり。

**反映** — §9.2 の `editor` に `task.create` / `task.assign` / `schedule.manage` を ○ で追加。§9.3 を「現行の分岐箇所の全列挙表」に作り直し `:3564` を追加。要確認項目の対応先を `content.review.internal`（新設1キー）に変更。§28 に **Q13「移行時にスタッフの動画追加・担当変更・日付変更を現行どおり全員可のままにするか」** を追加。

### HIGH-2 — `STAFF_MAP` の破棄は誤り → **ACCEPT**

18箇所で編集担当ロスターとして使われている。破棄すると、チーム負荷が3名→6名、カレンダーの営業日軸、`generate()` の担当割当と投稿日補正、`myTasks()` の絞り込みがすべて変わる。とくに §10.5 で「`task.read.all` を持つので現行と同じく全件が見える」と書いたのは**明確な誤り**で、現行はスタッフを自分の担当に絞っている。§10.5 自身が「絞り込みであって権限ではない。混同しない」と書きながら混同していた。

**反映** — §24.4 の `STAFF_MAP` を Method E → **C**、移行先を「`editor` Role 保持者」と明記。§8.1 の対応表を修正。§10.5 を「MyTasks の絞り込みは `editor` Role 保持者にのみ適用。権限とは無関係」に書き換え。§24.6 の「6名すべて一致」を「`editor` Role 保持者3名で一致」に修正。担当候補の定義を「`editor` Role を持つ Member」に一本化。

### HIGH-3 — Migration Matrix / Parity の期待値に事実誤認 → **ACCEPT**

10社を11社、動画10/静止画3 を 動画9/静止画4 と書いていた。Parity の期待値が間違っていれば、ゲートは通っても移行の正しさを保証しない。

**反映** — 文書全体の「11社」を **10社** に、`SEED_CONTRACTS` 行の内訳を **動画10 / 静止画3** に修正。§24.6 の Parity 期待値をすべて実測値に置き換え。

### HIGH-4 — `trans{}` の履歴展開は実データ上成立しない → **ACCEPT**

実測で確認した。投稿済みの時刻が投稿待ちより古い行が実在し（3行中2行）、そもそも投稿済み38件に対し投稿待ちは6件しか記録が無い。`applyOp`（`:1831`）が遷移のたびに上書きするため、`trans{}` は「各状態に最後に入った時刻」であって履歴ではない。これを `workflow_run_transitions` に展開すると**虚偽の監査履歴**を作る。移行で最もやってはいけない種類の操作。

**反映** — §24.4 の `trans{}` を Method D → **E（破棄）** に変更。理由と実測値を明記。raw JSON は移行時の `audit_logs` 1件（`action = migration.import`）に丸ごと保存し、参照可能性だけ残す。§19.3 に「移行前の遷移履歴は復元しない。Audit は移行時点以降が対象」と明記。§28.2 の R3 を更新。

### HIGH-5 — 現行 STATE がほぼ空のサンプルデータ → **PARTIAL**

構造的な指摘は全面的に受け入れる。ただし**事実の範囲を訂正する**。レビューが読んだのは `ml-editing-board.html`（GitHub版）の state 行であり、**運用中の公開版 artifact の state ではない**。両者はコードが同一でも state 行だけが異なる（＝公開版には利用者の実データが入っている可能性がある）。公開版の state は今回未取得であり、「実データがほぼ無いので移行は軽い」という結論は**現時点では確定していない**。

**反映（採用）** — 移行計画が `STATE.clients` / `STATE.notes` の存在を前提にしない形へ修正。`migrateState()`（`:1933-1935`）が両キーを空で作るため不在は正常であり、Method A の各行に「キー不在なら0件移行として正常終了」を明記。Drive URL・撮影日・企画・資料準備・定例MTG・日次メモは **Method B（手入力で初期投入）を主経路、A を補助**に変更。

**反映（訂正）** — §24 冒頭に「**移行計画の数量前提は公開版 state の実測で確定させる。Step 2 の最初の作業はその抽出と実測**」を追加。設計書には推定値を書かない。

### HIGH-6 — 月次生成が ServiceContract を一級市民として扱っていない → **ACCEPT**

`generate()` は `cs.filter(kind)[0]` でクライアントごとに種別1契約しか見ない（`:1708-1709`）。現行データではたまたま成立しているだけで、Phase 5 で契約が画面から編集可能になった瞬間、2本目の契約が**無音で消える**。`phaseOf(client)` がクライアント名を鍵にしている点も、改名で配置が変わる。

**反映** — §12.4 の生成手順を「Client 単位」から「**ServiceContract 単位**」に書き換え。`phaseOf` の鍵を可変のクライアント名から不変の `client_id` に変更（移行時は現行配置を再現するため `legacy_key` を鍵にする互換モードを用意）。§25.1 に「1クライアントに同種2契約」のケースを追加。

### HIGH-7 — `workflow_runs` に期間キーが無い → **ACCEPT**

「クライアント単位・月次の Run」を DB 上で一意に特定できず、重複作成も防げない。`materialLate()` が「その Run の対象月の12日」で判定できない。

**反映** — `workflow_runs` に `period_key text null`（Core は書式を解釈しない不透明な文字列）と `unique(workspace_id, template_id, subject_type, subject_id, period_key)` を追加。§5.1 / §11.6 / §24.4 に反映。Run 生成 Action の冪等性を `period_key` を含む upsert で担保することを §22.5 に明記。

### HIGH-8 — Workflow 変更時の4規則が不十分 → **ACCEPT**

Transition の物理削除を明示的に許可しながら `workflow_run_transitions.transition_id` が参照している点、`semantic` 変更が完全に無防備な点（過去12か月の完了率が一操作で跳ね上がる）、Template 切替時の `tasks` の扱いが未定義な点。いずれも実際に起こる。

**反映** — §11.5 を4規則→**7規則**に拡張。`workflow_transitions` に `archived_at` を追加し物理削除を禁止。`semantic` / `is_initial` / `is_terminal` は履歴が1件でもあれば変更不可。Workflow Template 変更を §20.2 の強い監査対象に追加。§25.4 に3ケース追加。

### HIGH-9 — Slack webhook の重複排除キーが誤り → **ACCEPT**

`webhook_receipts` を Google の `channel_id + message_number` 前提で設計し、Slack にそれを当てはめていた。`X-Slack-Retry-Num` はイベント識別子ではないため、2人目の申請が重複キー違反で **200 OK のまま無言で捨てられる**。「無音で消えない」という自分の原則を入口で破っていた。

**反映** — `webhook_receipts.message_number` を `external_event_key text not null` に置き換え、`unique(provider, connection_id, external_event_key)` に変更。§15.1 の `IntegrationProvider` に `dedupeKey(request)` を追加し、provider 固有の知識を Adapter に閉じる。§17.4 を「再送は `event_id` / `trigger_id` で弾く。`X-Slack-Retry-Num` はログ用」に修正。§25.5 に「異なる2イベントが同一チャンネルから来ても両方処理される」を追加。

### HIGH-10 — 退職時の Google アカウント停止が Integration を破壊する → **ACCEPT**

§8.2 で「退職時に Google アカウントを止めれば SOCIAL BASE も閉じる」を利点として挙げたが、その人が接続した Drive / Calendar のトークンも同時に失効する。接続主体が個人のままだと、退職のたびに全社の外部連携が止まる。

**反映** — §15.1 に「Integration の接続主体は Workspace であり個人ではない」を追加。接続に使うアカウントは共有の運用アカウント（または Google の service account + domain-wide delegation）を推奨とし、`integration_connections.connected_by` は監査用の記録に降格。§26.5 に「接続アカウントの失効検知」を追加。§28 に **Q14「Integration 接続に使う Google アカウントをどれにするか」** を追加。

### HIGH-11 — jsonb 条件式 DSL は過剰設計 → **PARTIAL**

指摘の主旨は正しい。既知9ルールのために式評価器・パス解決・演算子テーブルとその検証を自作するのは P5（過剰設計をしない）に反する。`rule_key` + `params` なら P4（設定をコードに埋めない＝日数はデータ）を満たしつつ実装が1桁小さい。

**ただし全面採用はしない。** master plan §18 が Conditions に「AND / OR 条件」を明示的に求めている。登録済み述語を**単一**しか持てない形にすると、その要求を落とすことになる。

**反映（採用）** — `automation_rules.conditions jsonb` を **`predicates jsonb`（登録済み述語 + パラメータの配列）**に変更。述語は9個の関数とレジストリで実装し、式評価器は作らない。§1.3 の Non-Goals に「Automation の汎用条件式言語」を追加。

**反映（不採用部分）** — 配列内の述語は **AND で結合**し、OR が必要な場合は Rule を分ける、という形で AND/OR 要求を満たす。式のネストは作らない。

### HIGH-12 — 削除が同期されず Parity ゲートの順序が逆 → **ACCEPT**

`legacy_id` の UPSERT だけでは、`merge()`（`:5019`）や「サンプルを削除」（`:2285`）で消えた行がゴーストとして新環境に残る。ゴーストには Task と Run がぶら下がるため、「今日」画面に存在しない案件が期限超過として出続け、UI に削除手段が無い。Parity を Step 4 のスナップショットにだけ掛け、実際に本番になる Step 5 の再抽出データを検証しないのも順序が逆。

**反映** — §24.3 を「`legacy_id` をキーとした upsert + **差集合の archive**」に変更（物理削除しない）。§24.2 の Step 5 を 5-1〜5-4 に分解し、**5-3 に Parity 再実行と撤退条件**を追加。§24.4 の `mlboard.ops.v1` 行に「全員の画面で未同期バナー（`:2255`）が出ていないことを確認する」手順を明記。

### HIGH-13 — 業務日付の基準タイムゾーンが未定義 → **ACCEPT**

現行は `TODAY = fromUTC(Date.now() + 9h)`（`:5180`）で明示的に JST 暦日。設計書は `workspaces.timezone` 列を定義しながら「業務上の今日はどのタイムゾーンの暦日か」を一度も書いていなかった。Serverless と cron は通常 UTC で動くため、毎月12日のアラートが13日に飛ぶ、締切が1営業日ずれる、Visual Regression の画素差0 が原理的に出ない、といった不具合が出る。しかも JST 00:00〜09:00 にしか症状が出ないため日中のテストで再現しない。

**反映** — §6.1 に「業務日付の定義」を新設（日付列と `date.reached` と締切判定の「今日」はすべて Workspace `timezone` の暦日。UTC 暦日を業務日付に使わない）。Domain に `businessToday(workspace)` を1本用意し、Domain からの `new Date()` 直呼びを禁止する規約を §3.3 と同格で追加。§23.2 の cron に時刻の基準を明記。§24.6 の `TODAY` 注入を「Workspace timezone の暦日」と明記。§25.1 に JST 00:00〜09:00 相当の固定時刻テストを追加。

---

## 3. MEDIUM

| ID | 判断 | 理由と反映 |
|---|---|---|
| MEDIUM-1 | **ACCEPT** | §5.1 と §6.2 で Task の状態保持が食い違っていた（`workflow_state_id` vs `workflow_run_id`）。`workflow_runs` を唯一の正とし、`tasks` から `workflow_state_id` と `workflow_template_id` を削除。Template は `task → run → template` で解決。加えて Module 側に `content_item_tasks` 結合テーブルを置き、`unique(task_id)` で v1 の 1:1 を DB で保証する（Core の多態参照を汚さずに整合性を得る） |
| MEDIUM-2 | **ACCEPT** | 索引5本を追加（`task_assignments(workspace_id, workspace_member_id, assignment_role)` / `workflow_runs(workspace_id, current_state_id)` / `content_items(workspace_id, client_id, target_month)` / `content_items(workspace_id, service_contract_id, target_month)` / `audit_logs(workspace_id, request_id)`）。§25.2 に主要 Query の `EXPLAIN` が Seq Scan にならないテストを追加 |
| MEDIUM-3 | **ACCEPT** | 本文が約束した列がスキーマ表に無かった。`notifications.dedupe_key` + 部分 UNIQUE、`automation_runs.rule_snapshot jsonb not null`、`daily_notes` に `unique(workspace_id, date)` を追加 |
| MEDIUM-4 | **ACCEPT** | Read Model に version が3つ乗る問題。MEDIUM-1 で `tasks` の状態を Run に一本化したうえで、**API は操作対象ごとに送る version を1つに定める**（工程遷移＝`workflow_runs.version`、内容編集＝`content_items.version`）。§22.1 に対応表を追加 |
| MEDIUM-5 | **ACCEPT** | `idempotency_keys` の主キーが Workspace 横断だった。`pk(workspace_id, key)` に変更 |
| MEDIUM-6 | **ACCEPT** | `date.reached` の catch-up。Job が落ちた日の Rule が永久に飛ばない問題。`automation_rules` に `last_evaluated_on date` を持たせ、起動時に未評価の日を順に処理する（上限7日、それ以前は通知して打ち切り） |
| MEDIUM-7 | **ACCEPT** | 監視通知が Job Runner 自身に依存していた。dead-letter と同期停止の通知だけは Job を経由しない外形監視から出す。§26.5 に明記 |
| MEDIUM-8 | **PARTIAL** | 「画素差0」の基準が二重だった点は ACCEPT。ただし **artifact 対 新環境で画素差0 は要求しない**（オリジンもフォント解決も異なるため原理的に不可能）。§25.6 の画素差0 は「**新環境の変更前後**」に限定し、artifact との比較は §24.6 の数値 Parity と DOM 実測で行う、と切り分ける |
| MEDIUM-9 | **ACCEPT** | 自分の Core 純度チェックが `client / video / instagram / drive / slack` しか見ておらず、`publish_planned` / `shoot` / `client_meeting` という Module 固有語が Core の `schedule_entries.kind` に入っていたのを見逃していた。`kind` を Module 登録の不透明な文字列に変更し、具体値は §12.1 の SOCIAL BASE 側の表に移す。**`check_doc_integrity.sh` の Core 純度チェックにこれらの語を追加する** |
| MEDIUM-10 | **ACCEPT** | OAuth リフレッシュの single-flight。同時実行で refresh token が二重使用され失効する。`integration_connections` 行の `select ... for update` でリフレッシュを直列化することを §15.1 に明記 |

## 4. LATER

| ID | 判断 | 扱い |
|---|---|---|
| LATER-1 | **ACCEPT（LATER）** | Read Model のページングと ETag。§28.2 の R7（350件で40,779px）と同じ課題。`views/*` の応答にページング可能な形だけ先に持たせ、実装は件数が増えてから |
| LATER-2 | **ACCEPT（LATER）** | Scope 評価器は作らず、`scope_type` / `scope_id` の列だけ先行させる。§9.5 に「v1 は列のみ。評価器は要件が出てから」と明記 |
| LATER-3 | **ACCEPT（LATER）** | 負荷スコアの重みを変えると過去画面が再現できなくなる件。§28.3 の未決事項に追加 |
| LATER-4 | **ACCEPT（LATER）** | Audit Log と Automation Run の保持期間・分割。§28.3 に追加 |

---

## 5. REJECT

なし。

レビューの指摘のうち、事実に基づかないもの・過剰設計を招くものは無かった。PARTIAL とした3件（HIGH-5 / HIGH-11 / MEDIUM-8）も、指摘の主旨は採用し、事実の範囲または適用範囲だけを訂正している。

---

## 6. 未解消の確認事項

修正の結果、**オーナー判断が必要な項目が2つ増えた**。§28 に追加済み。

| # | 論点 | 出所 |
|---|---|---|
| Q13 | 移行時に、スタッフの動画追加・担当変更・投稿日変更を現行どおり全員可のままにするか | HIGH-1 |
| Q14 | Google Drive / Calendar の接続に使うアカウントをどれにするか（個人アカウントだと退職時に連携が止まる） | HIGH-10 |

---

## 7. 完了状況

| 区分 | 件数 | ACCEPT | PARTIAL | REJECT | 未解消 |
|---|---|---|---|---|---|
| BLOCKER | 3 | 3 | 0 | 0 | **0** |
| HIGH | 13 | 11 | 2 | 0 | **0** |
| MEDIUM | 10 | 9 | 1 | 0 | 0 |
| LATER | 4 | 4（将来対応として記録） | 0 | 0 | 0 |

**unresolved BLOCKER = 0 / unresolved HIGH = 0。**

ただし Phase 1 の完了条件は「修正版を同じ観点で再レビューし、そこで BLOCKER / HIGH が0件であること」。本書の反映後、再レビューを実施する。

---

## 変更履歴

| 日付 | 内容 |
|---|---|
| 2026-08-29 | 初版。第1回レビュー（BLOCKER 3 / HIGH 13 / MEDIUM 10 / LATER 4）に対する判断 |

---

## 8. 第2回レビューへの判断

| | |
|---|---|
| 対象レビュー | `SOCIAL_BASE_SENIOR_REVIEW_2.md`（674行） |
| 判定 | **B. 修正後に実装開始可能** |
| 指摘件数 | BLOCKER **0** / HIGH 3 / MEDIUM 9 / LATER 1 |
| 本書の判断 | ACCEPT 13 / PARTIAL 0 / REJECT 0 |

**第1回の BLOCKER 3件はすべて解消と確認された。** HIGH 13件のうち7件が解消、6件が部分的。残った分と新規指摘を v3 で反映した。

### 8.1 HIGH

| ID | 判断 | 内容と反映 |
|---|---|---|
| R2-HIGH-1 | **ACCEPT** | 実測で確認。`generate()` `:1714` の `cfg.staff[poster] ? ... : null` により、poster がなつみ（社員・`STAFF_MAP` 外）の9契約 **34/50本には投稿担当の非稼働日補正がかかっていない**。§12.4 手順5 を無条件に書いていたため Parity が確実に落ちる。手順5を「勤務予定が登録されている場合に限り」に修正し、非対称性の説明と「移行時は社員の `working_schedules` を投入しない」を追記 |
| R2-HIGH-2 | **ACCEPT** | `seeded:true` のまま切り替えると、サンプルの進捗が本番の初期状態になる。§14.3 で「サンプル表示中」バナーを廃止しているため新環境に警告手段がなく、Parity も0件対0件で通過する。§24.4 の `seeded` を Method E → **A** に変更し、Step 2-1 の実測項目に加え、**§28 に Q15（サンプルデータの扱い）を追加**してオーナー判断に上げた |
| R2-HIGH-3 | **ACCEPT** | `contract_version_hash` を2箇所で使いながら未定義だった。§12.4 に定義（対象契約の `(id, version)` を連結してハッシュ）を追記し、`service_contracts` に `version` 列を追加。契約の有効期間フィルタ（`status = active` かつ `starts_on` / `ends_on` の範囲）も手順に追加 |

### 8.2 MEDIUM

| ID | 判断 | 反映 |
|---|---|---|
| R2-MEDIUM-1 | **ACCEPT** | 分割追記の副作用で章をまたぐ矛盾が7箇所と文書破損2箇所。§5.4 の `status` / `trans{}` 行、§7.1 ER の `tasks.version` と `workflow_templates -> tasks`、§7.2 ER と §13.1 の `conditions`、§28.2 R8 の「4規則」、§28.1 の「12個」、§24.4 で表外へ脱落した `version` 行をすべて修正。**この種の意味的な矛盾は既存の整合性チェックでは検出できないため、Core 純度チェックをスクリプトへ追加した**（下記 R2-MEDIUM-9） |
| R2-MEDIUM-2 | **ACCEPT** | `tasks.version` を §6.2 からも削除し、「工程は `workflow_runs.version`、内容・日付は `content_items.version` が守る」と明記 |
| R2-MEDIUM-3 | **ACCEPT** | PostgreSQL の UNIQUE は NULL を互いに異なる値として扱うため、`period_key` が NULL の Run の重複を防げない。**部分ユニーク2本**（`where period_key is not null` と `where period_key is null`）に変更 |
| R2-MEDIUM-4 | **ACCEPT** | 「全テーブルに `unique(id, workspace_id)`」は `id` 列を持たない結合テーブル4本（`role_capabilities` / `member_roles` / `content_item_tasks` / `idempotency_keys`）には適用できない。規約を「`id` 列を持つ全テーブル」に精密化し、結合テーブルは主キーに `workspace_id` を含めるか複合外部キーで担保すると明記 |
| R2-MEDIUM-5 | **ACCEPT** | 月次生成の手順から `assignEditors()` が欠落していた。手順8として追加し、§25.1 のテスト対象と §24.6 の Parity 項目にも加えた |
| R2-MEDIUM-6 | **ACCEPT** | 「1段戻す」の逆向き Transition を5件すべて表で列挙。`workflow_transitions.kind`（`forward` / `undo`）を追加。`is_terminal` は「前進が終わる」意味であり undo は出ることを明記し、§11.5 規則3の判定に `is_terminal` を使わないとした |
| R2-MEDIUM-7 | **ACCEPT** | 外形監視のハートビートを §19.4 の1文だけでなく §26.5 の監視表と §26.6 の障害時UXにも反映 |
| R2-MEDIUM-8 | **ACCEPT** | 絞り込みの適用箇所が `myTasks()` だけでなく `scopeRows()`（`:3066`）と `filteredRows()`（`:3335`）にもある。3箇所を表で列挙し、`:3335` だけ poster を含まない差も明記して Read Model と対応付けた |
| R2-MEDIUM-9 | **ACCEPT** | **Resolution が「スクリプトへ Core 純度チェックを追加した」と書いていたが実在しなかった**（手動 grep しかしていなかった）。`check_doc_integrity.sh` に実際のチェックとして実装し、`recommendations.kind` の ER 記述も Module 登録の不透明な文字列に修正 |

### 8.3 LATER

| ID | 判断 | 反映 |
|---|---|---|
| R2-LATER-1 | **ACCEPT** | 第1回の LATER-1 / 3 / 4 を「反映済み」としながら設計書に無かった。§28.3 の未決事項に3件とも追記 |

### 8.4 REJECT

なし。

### 8.5 完了状況

| 区分 | 件数 | ACCEPT | PARTIAL | REJECT | 未解消 |
|---|---|---|---|---|---|
| BLOCKER | 0 | — | — | — | **0** |
| HIGH | 3 | 3 | 0 | 0 | **0** |
| MEDIUM | 9 | 9 | 0 | 0 | 0 |
| LATER | 1 | 1 | 0 | 0 | 0 |

**unresolved BLOCKER = 0 / unresolved HIGH = 0。** v3 に対して第3回レビューを実施し、そこで BLOCKER / HIGH が0件であれば Phase 1 完了とする。

### 8.6 オーナー確認事項の追加

| # | 論点 | 出所 |
|---|---|---|
| Q15 | 移行時にサンプルデータをどう扱うか。公開版が `seeded:true` のままなら、サンプルの進捗が本番の初期状態になる | R2-HIGH-2 |

合計15項目（§28.1）。
