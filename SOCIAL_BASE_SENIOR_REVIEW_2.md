# SOCIAL BASE — Senior Engineer Review #2（再レビュー）

| | |
|---|---|
| 対象 | `SOCIAL_BASE_SYSTEM_DESIGN.md`（v2 / 3,401行 / 29章） |
| 前提文書 | `SOCIAL_BASE_SENIOR_REVIEW.md`（第1回）、`SOCIAL_BASE_REVIEW_RESOLUTION.md`（採否判断） |
| 参照実装 | `ml-editing-board.html`（5,226行）※読み取りのみ・`f264170` から無変更を確認済み |
| レビュー日 | 2026-08-29 |
| 立場 | Staff / Senior Backend & Platform Engineer（設計者とは別人） |
| 判定 | **B. 修正後に実装開始可能** |

---

## 0. 総評

第1回の30件（BLOCKER 3 / HIGH 13 / MEDIUM 10 / LATER 4）のうち、**BLOCKER 3件はすべて実在の記述として反映されており、内容も実装可能な粒度に達している。** BLOCKER-1 の権限テーブル4本の `workspace_id` と複合外部キー、BLOCKER-2 の RLS 運用規約4点、BLOCKER-3 の `sub` 同定は、いずれも「反映したと書いてあるだけ」ではなく設計書本文・スキーマ表・テスト章・ADR の4層に一貫して入っている。**Architecture の再設計は不要**という第1回の判断は維持する。

事実誤認の訂正（HIGH-3）も実測と完全に一致した。`ml-editing-board.html` を再度実測し、10社13契約 / 動画10・静止画3 / `count` 合計50 / steps=4が9契約・steps=2が4契約 / poster なつみ9・りりか4 / MEMBERS 6名（社員3・スタッフ3）/ `myRole()==="社員"` は8箇所で `:3564` を含む / `STATE` は `seeded:true`・50行・全て 2026-08・`clients` と `notes` キー不在 / `trans` は投稿済み38件に対し投稿待ち6件で、両方を持つ3行のうち2行が時系列逆転 — **v2 に書かれた数値はすべて実装と一致する。**

一方で、次の3種類の問題が残る。

1. **PARTIAL 判断の残り穴が2件。** HIGH-5 の `seeded` の扱いが決定事項になっていない。HIGH-6 の契約有効期間フィルタと `contract_version_hash` が反映されていない。PARTIAL 判断そのものは妥当だが、ACCEPT した部分の反映が不完全である。
2. **修正の結果、章をまたぐ矛盾が生じた。** 長文を分割追記で編集した副作用で、`tasks` の `version` と Template 参照、`predicates` と `conditions`、`§11.5` の規則数、`§28` の Q 件数が、直した章と直していない章で食い違っている。
3. **第1回で見落としていた設計上の穴が2件。** `generate()` の投稿担当補正が現行では非対称であること（Parity ゲートを直撃する）と、月次生成の手順から `assignEditors()` が丸ごと欠落していること。

指摘は **BLOCKER 0件 / HIGH 3件 / MEDIUM 9件 / LATER 1件**。Phase 1 の完了条件（unresolved BLOCKER = 0 かつ unresolved HIGH = 0）には**あと3件届いていない**。ただしいずれも列・段落・手順の追記で閉じられ、Architecture の変更を伴わない。

### 0.1 問題を発見できなかった領域（問題なし）

以下は今回の再レビューで指摘なし。反映内容と他章との整合性の両方が妥当と判断した。

- **BLOCKER-2 の反映**（§6.5 L663-701 / §21.1 L2314 / §25.2 L2844-2847 / §26.1 L2933-2934 / ADR-019 L3334）— 所有者ロールとアプリロールの分離、`force row level security`、`SET LOCAL` のみの使用、Repository 基底への一元化、`nullif(current_setting(..., true), '')` による fail closed、本番と同じプーラ構成でのテスト。4点すべてが実装可能な粒度で書かれている。**§21.1 の Query Service の記述とも矛盾しない** — 「読み取りも必ず明示トランザクションで包み、先頭で `set local app.workspace_id` を発行する」と明記され、autocommit の落とし穴まで書かれている。
- **BLOCKER-3 の反映** — `sub` による同定が §5.1（L396）/ §6.2 `users` 行（L591）/ §8.2（L1160-1180）/ §20.1 Identity binding（L2254）/ §25.3（L2863）/ ADR-004（L3190）の**6箇所すべてで一貫している**。招待を email で出して初回ログインで `sub` を claim する運用、email をログインのたびに上書きする規約まで揃っている。
- **HIGH-9（`external_event_key`）** — §6.3 の列定義・provider 別対応表・§15.1 の `dedupeKey()`・§17.4・§25.5・§7.3 ER まで一貫。provider 固有の知識が Adapter に閉じている。
- **HIGH-10（Integration の接続主体）/ HIGH-12（スナップショット同期と Parity 再実行）/ HIGH-13（業務日付）** — いずれも本文・スキーマ・テスト・ADR・§28 の Q まで揃っている。
- **HIGH-8 の7規則本体**（§11.5 L1544-1558）— `workflow_transitions.archived_at`、`semantic` / `is_initial` / `is_terminal` の変更禁止条件、規則7の Task 参照。§20.2 と §25.4 への波及も入っている。
- **MEDIUM-2（索引5本）/ MEDIUM-3（`dedupe_key` / `rule_snapshot` / `daily_notes` の一意制約）/ MEDIUM-5（`pk(workspace_id, key)`）/ MEDIUM-6（`last_evaluated_on`）/ MEDIUM-10（single-flight）/ LATER-2（Scope 評価器を作らない）** — すべてスキーマ表・本文に実在。
- **§8.3 / §8.4 / §18 / §22.6 / §26.4 / §29 の ADR 書式** — 第1回で「問題なし」とした領域に劣化なし。ADR-021〜024 の追加も文脈・決定・理由・結果・変更容易度・参照が揃っている。
- **文書整合性** — `check_doc_integrity.sh` は PASS（章数29、章節番号の連続、目次一致、相互参照のダングリングなし、コードフェンスと mermaid の閉じ、`ml-editing-board.html` は `f264170` から無変更）。

### 0.2 現行実装の再実測（v2 の記述との突き合わせ）

| v2 の記述 | 実測 | 判定 |
|---|---|---|
| 10社13契約（§2.3 L142 ほか） | distinct client = 10、契約 = 13 | 一致 |
| 動画10 / 静止画3（§24.4 L2675） | `kind:"動画"` 10件 / `kind:"静止画"` 3件 | 一致 |
| steps=4 -> 7営業日 / steps=2 -> 3営業日（§24.4 L2677） | steps=4 が9契約、steps=2 が4契約。`:1725` は `con.steps===4 ? 7 : 3` | 一致 |
| なつみ9件 / りりか4件（§24.4 L2679） | poster は2名のみ。なつみ9 / りりか4 | 一致 |
| MEMBERS 6名（社員3 / スタッフ3）（§24.4 L2680-2681） | なつみ・友美・翔平が社員、りりか・ゆかり・つかさがスタッフ | 一致 |
| `myRole()==="社員"` は8箇所で `:3564` を含む（§9.3） | `:2176` `:2353` `:2366` `:3517` `:3564` `:4014` `:4820` `:5081`。`:3564` は Drive未設定・タイトル未入力の内訳行を囲む分岐 | 一致 |
| `editor` Role 保持者3名（りりか / ゆかり / つかさ）（§24.6 L2772） | `STAFF_MAP` のキーと `SEED_SHIFTS` のロスターが完全一致 | 一致 |
| `trans` は投稿済み38件・投稿待ち6件・両方持つ3行のうち2行が逆転（§24.4 L2711） | 完全一致。`r-2026-08-NCN-4`（5.49日の逆転）と `r-2026-08-木下テーブルテニスクラブ-16`（4,072ms の逆転） | 一致 |
| `STATE` は `seeded:true` / 50行 / 2026-08のみ / `clients`・`notes` キー不在（§24.2 L2587） | 完全一致。`lastUpdated` は `2026-08-26T23:03:47.835Z` | 一致 |
| `migrateState()` が両キーを空で作る（§24.4 L2732） | `st.clients = st.clients \|\| {}`（`:1933`）、`st.notes = st.notes \|\| {}`（`:1935`） | 一致 |
| `STAFF_MAP` は18箇所（§8.1 L1148 / §24.4 L2683） | **19行・21箇所**（`:4993` と `:5155` が1行に2回出現） | わずかに過小。指摘の趣旨には影響しないため指摘としない |

**新たに実測した事実**（v2 に反映されておらず、§12.4 の月次生成手順の評価に直結する）。

- `generate()` の `:1714` は `var postDays = cfg.staff[poster] ? workingDays(cfg.shifts, cfg.staff[poster], cfg.ym) : null;`、`:1722` は `if(postDays && Object.keys(postDays).length && !postDays[planned])`。`cfg.staff` には `STAFF_MAP` が渡される（`:4992`）。**したがって poster がなつみ（社員・`STAFF_MAP` に無い）の9契約 = 34本には、投稿担当の非稼働日補正が一切かからない。** りりかの4契約 = 16本にだけかかる。
- `generate()` の `:1733` は `editor: con.editor || ""`。`SEED_CONTRACTS` に `editor` フィールドは存在しない（実測で0件）。**`generate()` は常に `editor:""` を返し、担当は直後の `assignEditors(plan, caps)`（`:1763` 定義 / `:4994` 呼び出し）が capacity を見て割り当てている。**
- `generate()` の `:1713` は `poster = (v||s).poster`。**静止画契約の `poster` は動画契約が存在する限り読まれない。** 現行データでは同一クライアントの2契約が同じ poster なので顕在化していない。

---

## 1. 第1回指摘の解消状況

判定基準。**解消** = Resolution の主張どおり v2 に実在し、他章とも矛盾しない。**部分的** = 主要部分は入っているが一部が欠落、または他章と矛盾している。**未解消** = v2 に見当たらない。**悪化** = 修正の結果、以前より悪くなった。

### 1.1 BLOCKER

| ID | 判定 | 根拠となる v2 の該当箇所 | 備考 |
|---|---|---|---|
| BLOCKER-1 | **解消** | §6.1「Workspace 境界の強制」L556-585（例外表2件＋規約＋SQL例）、§6.2 L588-620（`role_capabilities` L594 / `member_roles` L595 / `workflow_run_transitions` L602 / `notification_deliveries` L616 に `workspace_id` と複合 FK）、§6.5 の2. L671、§25.2 L2843、ADR-021 L3355 | 権限テーブル4本の `workspace_id` は実在する。§6 冒頭 L533 の「すべてのテーブルは `workspace_id` を持ち」と §6.1 L556-566 の例外表（`users` / `webhook_receipts`）は、総論と例外の関係で整合している。ただし規約の書き方に穴あり -> R2-MEDIUM-4 |
| BLOCKER-2 | **解消** | §6.5「RLS 運用規約」L682-701、§21.1 L2314、§25.2 L2845-2847、§26.1 L2933-2934、ADR-019 L3334 | (1)ロール分離と `force row level security` /(2)`SET LOCAL` のみ /(3)全アクセスの明示トランザクション化と Repository 基底への一元化 /(4)未設定時0行。4点すべて実装可能な粒度。§21.1 と矛盾しない |
| BLOCKER-3 | **解消** | §5.1 L396、§6.2 `users` 行 L591、§8.2 L1160-1180、§20.1 L2254、§25.3 L2863、ADR-004 L3190 | 6箇所すべてで一貫。招待の claim フローまで記述されている |

### 1.2 HIGH

| ID | 判定 | 根拠となる v2 の該当箇所 | 備考 |
|---|---|---|---|
| HIGH-1 | **解消** | §9.2 L1295-1300（`editor` に `task.create` / `task.assign` / `schedule.manage` の ○）、§9.1 L1281（`content.review.internal` 新設）、§9.3 L1329-1344（8箇所の全列挙。`:3564` を含む）、§9.3 L1346-1348、§25.3 L2864、§28 Q13 L3111 | `:3517` と `:3564` を必ず同じ Capability に束ねる注意書きも入っている |
| HIGH-2 | **部分的** | §8.1 L1148（`STAFF_MAP` のキー集合 -> `editor` Role 保持者）、§10.5 L1451-1470、§24.4 L2683（Method C）、§24.6 L2772（3名で一致） | 「担当候補メンバー = `editor` Role 保持者」の定義は §8.1 / §24.4 / §24.6 / §10.5 で一貫しており**1つに集約されている**。§10.5 は「絞り込みであって権限ではない」と明記し、`task.read.all` との混同も解消した。ただし絞り込み規則の適用範囲が `myTasks()` のみで、同じ規則を持つ `scopeRows()`（`:3064`）と `:3335` が明示されていない -> R2-MEDIUM-8 |
| HIGH-3 | **解消** | §2.3 L142、§3.2 L245、§24.4 L2672/2674/2675/2677/2679、§24.6 L2764/2772、ADR-002 L3171 | 全数値が実測と一致。§24.6 L2755 で「期待値は Step 2-1 の実測で確定させる」に変わり、人が数えた数字を仕様書に書く形をやめている |
| HIGH-4 | **部分的** | §24.4 L2711（Method E、実測値つき）、§19.3 L2202-2204、§28.2 R3 L3120 | 反映内容は正確で、実測値も一致。ただし §5.4 L489 が `trans{}` -> 「`WorkflowRun` の遷移履歴 ＋ `AuditLog`」のままで、§19.3 / §24.4 の「展開しない」と正面から矛盾 -> R2-MEDIUM-1 |
| HIGH-5 | **部分的** | §24.2 L2587（数量前提を持たない旨）、Step 2-1/2-2 L2607-2609、§24.4 L2732-2734（キー不在は正常・Method B 主経路） | **PARTIAL 判断（公開版 state は未取得なので数量前提を書かない）は妥当。** ローカルの `<script id="state">` は artifact 側の state 行とは別物で、公開版に実データがある可能性は否定できない。実測をカットオーバー手順の先頭（Step 2-1）に置いた対応も正しい。**ただし移行計画に穴が残る** — `seeded:true` のまま切り替える場合の扱いが決定事項になっていない -> R2-HIGH-2 |
| HIGH-6 | **部分的** | §12.4 L1640-1666（ServiceContract 単位への書き換え、`phaseOf` の鍵を `client_id` へ・互換モードで `legacy_key`）、§25.1 L2832（同種2契約のケース） | 契約単位ループと位相の鍵は反映済み。ただし (a) 対象契約を `starts_on` / `ends_on` / `status` で絞る手順が無い、(b) `contract_version_hash`（§12.4 L1673 / §22.3 L2432）が未定義で `service_contracts`（§6.4 L653）に `version` も `updated_at` も無い -> R2-HIGH-3。さらに投稿担当補正の非対称性が未記述 -> R2-HIGH-1 |
| HIGH-7 | **部分的** | §5.1 L428、§6.2 `workflow_runs` 行 L601、§11.6 L1578-1580、§22.5 L2450、§24.4 L2740、§25.2 L2849 | `period_key` と複合 UNIQUE は実在。ただし第1回が求めた「`period_key` が NULL の行を1件だけ許す部分ユニークインデックス」が落ちており、NULL の Run に対して UNIQUE も §22.5 の upsert 冪等化も効かない -> R2-MEDIUM-3 |
| HIGH-8 | **部分的** | §11.5 L1548-1558（7規則）、§6.2 `workflow_transitions` 行 L600、§20.2 L2260、§25.4 L2873-2875 | 7規則本体は完全。ただし §28.2 R8 L3126 が「§11.5 の4規則」のまま -> R2-MEDIUM-1 |
| HIGH-9 | **解消** | §6.3 L629 / L638-646、§15.1 L1873、§17.4 L2060-2071、§22.4 L2436、§25.5 L2882、§7.3 ER L1094 | |
| HIGH-10 | **解消** | §15.1 L1888-1898、§8.2 注記 L1158、§26.5 L2970、§28 Q14 L3112、ADR-004 結果 L3192 | |
| HIGH-11 | **部分的** | §6.2 `automation_rules` 行 L612（`predicates jsonb`）、§13.3 L1726-1746、§1.3 L92、ADR-023 L3375 | **PARTIAL 判断（配列を AND 結合し、OR は Rule 分割で表現する）は妥当**（詳細は §1.5）。ただし §13.1 L1710 と §7.2 ER L927 に `conditions` が残存 -> R2-MEDIUM-1 |
| HIGH-12 | **解消** | §24.2 Step 5-1〜5-5 L2617-2624、L2629-2630、§24.3 L2645-2656、§24.4 L2758、§24.6 L2765、ADR-024 L3385 | Parity を Step 4 と 5-4 の両方で走らせる理由も明記されている |
| HIGH-13 | **解消** | §6.1「業務日付の定義」L545-554、§3.3 L265、§23.2 L2509-2513、§24.6 L2789、§25.1 L2837、ADR-022 L3365 | |

### 1.3 MEDIUM

| ID | 判定 | 根拠となる v2 の該当箇所 | 備考 |
|---|---|---|---|
| MEDIUM-1 | **部分的** | §5.1 L410-412、§6.2 `tasks` 行 L603、§11.1 L1499、§6.4 `content_item_tasks` L657 + 補足 L659-661、§7.3 ER L1074-1078 | 本体は解消。`content_item_tasks` は Module 側に置かれ Core を汚していない。ただし §5.4 L485（`status` -> `Task.workflow_state_id`）と §7.1 ER L755（`workflow_templates \|\|--o{ tasks`）が旧定義のまま -> R2-MEDIUM-1 |
| MEDIUM-2 | **解消** | §6.2 `task_assignments` L604 / `workflow_runs` L601 / `audit_logs` L617、§6.4 `content_items` L655、§25.2 L2851 | 索引5本すべて実在 |
| MEDIUM-3 | **解消** | §6.2 `notifications` L615 / `automation_runs` L614 / `daily_notes` L611、§14.4 L1840、§24.5 L2749 | ER 図（§7.2）には未反映だがスキーマ表が正典であり実害なし |
| MEDIUM-4 | **部分的** | §22.1 L2397-2409（操作 -> version の対応表） | 対応表は追加された。ただし §22.1 L2411 が「`tasks` は version を持たせない」と書く一方、§5.1 L410 / §6.2 L603 / §7.1 ER L842 には `version` が残存 -> R2-MEDIUM-2 |
| MEDIUM-5 | **解消** | §6.2 `idempotency_keys` 行 L620（`pk(workspace_id, key)`） | 主キー修正で Workspace 横断の経路自体が塞がれている。`request_hash` の内容明記（副次的推奨）は未反映だが指摘しない |
| MEDIUM-6 | **解消** | §6.2 `automation_rules` 行 L612（`last_evaluated_on`）、§13.6 L1799 | catch-up と上限7日が入っている |
| MEDIUM-7 | **部分的** | §19.4 L2218（外形監視から出す旨の1文） | §26.5 の表（L2965-2973）にハートビート行が無く、§26.6「Job Runner 停止」行 L2980 も未更新。Resolution は「§26.5 に明記」と述べるが実在しない -> R2-MEDIUM-7 |
| MEDIUM-8 | **解消** | §24.6「画面の一致」L2784-2789、§25.6 判定行 L2893 | **PARTIAL 判断（artifact 対 新環境では画素差0 を要求しない）は妥当**（詳細は §1.5） |
| MEDIUM-9 | **部分的** | §6.2 `schedule_entries` 行 L605、§7.2 ER L876、§12.1 L1610 | `schedule_entries.kind` は解消。`recommendations.kind`（§7.2 ER L985）は literal のまま。Resolution が約束した `check_doc_integrity.sh` の Core 純度チェックはスクリプトに存在しない -> R2-MEDIUM-9 |
| MEDIUM-10 | **解消** | §15.1 L1900-1902、共通ルール7 L1880 | |

### 1.4 LATER

| ID | 判定 | 根拠 |
|---|---|---|
| LATER-1 | **未解消** | §28.2 R7 L3125 に「Read Model をページング可能にしておく」とあるのみ。§21.2 L2319-2341 の API 定義に `cursor` / `limit` / `ETag` が無い。Resolution は「`views/*` の応答にページング可能な形だけ先に持たせる」と述べている |
| LATER-2 | **解消** | §9.5 L1403-1405（v1 は列のみ、評価器は作らない） |
| LATER-3 | **未解消** | §18.1 L2113 / §18.2 L2129 に設定の版管理の記述なし。§28.3 L3132-3136 の未決事項4項目にも無い |
| LATER-4 | **未解消** | §28.3 L3136 に「Audit Log の保持期間」があるのみ。`automation_runs` / `webhook_receipts` / `jobs` の保持期間と分割は無い |

### 1.5 PARTIAL 判断そのものの評価

第1回で PARTIAL とした3件について、**その判断自体の妥当性**と、不採用にした部分に問題が無いかを評価した。

**HIGH-5（公開版 state は未取得なので数量前提を書かない）— 妥当。ただし穴が1つ残る。**

訂正の根拠は正しい。`ml-editing-board.html` の `<script id="state">` は GitHub 上のコピーが持つ state であり、artifact に保存されている運用中の state とは別物である。両者はコードが同一でも state 行だけが異なり得る。したがって「実データがほぼ無いので移行は軽い」という第1回の結論を設計書に固定しなかったのは正しい判断である。実測を Step 2-1 として移行手順の先頭に置き、期待値をそこで確定させる形（§24.2 L2607-2609、§24.6 L2755）は、第1回が求めた「人が数えた数字を仕様書に書かない」をより強く満たしている。

不採用にした部分（移行手順の2分岐への簡素化）にも問題は無い。公開版が実データを持つ可能性がある以上、6ステップを維持するのは保守的で正しい。

**穴** — 第1回は「`seeded` の扱いを決定事項にする」を明示的に求めたが、§24.4 L2741 は `seeded` を Method E とし「サンプルデータのフラグ。移行時は実データのみ」と書くだけで、**`seeded:true` のまま切り替え日を迎えた場合に何をするかが決まっていない**。§28 の Q1〜Q14 にも該当項目が無い。詳細は R2-HIGH-2。

**HIGH-11（式 DSL を作らず、AND 結合の述語配列にする）— 妥当。不採用部分にも問題なし。**

`predicates` を「登録済み述語 + パラメータ」の配列とし、AND で結合、OR は Rule を分ける、という形は次の2点を同時に満たす。第一に master plan が求める AND / OR 条件を、式のネスト無しで表現できる。第二に P4（日数はデータ）を完全に満たしつつ、式評価器・パス解決・演算子テーブルとその検証を作らずに済む。§13.5 の初期9ルールはすべて AND のみで書けるため、不採用にした「式のネスト」で失われる表現力は現時点でゼロである。文字列パスによるリファクタリング耐性ゼロの問題（第1回が挙げた `publish_date` 改名時の無音故障）も、述語を関数として型で守る形になったことで解消している。

副作用として、OR を Rule 分割で表現すると同一事象に対して複数の `AutomationRun` と通知が生じ得る。ただし §14.4 の `dedupe_key`（`kind + resource_id + 対象日`）が同一 `kind` については抑制するため、実務上の影響は許容範囲。設計変更を求めるレベルではない。

**MEDIUM-8（artifact 対 新環境では画素差0 を要求しない）— 妥当。**

第1回が挙げた3つの理由（§3.4 自身がローディング表現の追加を許可している、現行の同期的な楽観更新が API 往復に変わる、別オリジン・別配信経路でのフォントのサブピクセルレンダリング差）はいずれも回避不能である。達成不能な基準を Write 移行のゲートに残すと、運用時に「無理だったので目視で OK にした」となりゲート全体の効力が失われる。数値 Parity と DOM 実測（実寸スクショ + DOM 実測という現行の QA 手法がそのまま使える）へ切り替えた判断は正しい。§25.6 の画素差0 を「新環境の変更前後」に限定した切り分けも明確である。

軽微な残り — §3.4 L290 の「同一幅でのスクリーンショット画素差0 を Regression の基準にする」は比較対象を明示していない。§25.6 L2893 が明示しているため実害は小さいが、§3.4 にも「新環境の変更前後」を1語足すのが望ましい。指摘としては挙げない。

---

## 2. 新規および残存の指摘

### 2.1 BLOCKER

**なし。**

第1回の BLOCKER 3件はすべて解消され、v2 の変更によって新たな BLOCKER も生じていない。

---

### 2.2 HIGH

#### R2-HIGH-1 — `generate()` の投稿担当補正が現行では34/50本に適用されていない事実が §12.4 に無く、Parity ゲートが確実に落ちる

**1. 該当設計**
§12.4「月次生成」の手順5（L1659「投稿担当の非稼働日に当たったら `nearestWorking()` で前後の空き営業日へ寄せる」）、§24.6「計算結果の一致」の `generate()` 行（L2776「同じ入力で同じ配置になる」）、§25.1 L2832。

**2. 問題**
現行 `generate()` の該当箇所は次のとおり。

```js
:1713  var poster = (v||s).poster;
:1714  var postDays = cfg.staff[poster] ? workingDays(cfg.shifts, cfg.staff[poster], cfg.ym) : null;
...
:1722  if(postDays && Object.keys(postDays).length && !postDays[planned]){
:1723    planned = nearestWorking(bd, postDays, planned, dates);
:1724  }
```

`cfg.staff` には `STAFF_MAP` が渡される（`:4992`）。**poster がなつみ（社員、`STAFF_MAP` に無い）の場合 `postDays` は `null` になり、補正は一切かからない。** 実測した poster の分布は なつみ9契約 / りりか4契約であり、本数に直すと **34本が補正なし、16本が補正あり**である。

§12.4 の手順5 は、この条件分岐を書かずに「投稿担当の非稼働日に当たったら寄せる」と無条件で記述している。移行後、なつみには `working_schedules` が1件も無い（`SEED_SHIFTS` は編集スタッフ3名分のみ）。素直に実装すると、「勤務予定が1件も無い = 全日が非稼働」と解釈されて**34本すべての投稿予定日が動く**か、逆に「勤務予定が無い = 常に稼働」と解釈されて動かないかの、どちらかになる。**設計書はどちらとも書いていない。**

**3. 発生する具体的リスク**
§24.6 は「1件でも差分があれば先へ進まない」という Write 移行の最終ゲートであり、その項目に `generate()` の配置一致が含まれている。上の解釈が現行と一致しなければ、**34/50本の `publish_date` と、そこから逆算される `internal_due`（§12.3）がすべてずれる。** Parity は確実に落ち、原因が「設計書に書かれていない条件分岐」であるため、実装者は落ちた理由を `phaseOf` や `distribute` の側に探すことになる。

さらに Phase 5 で `working_schedules` を社員にも入力できるようにした瞬間、なつみの9契約に補正がかかり始め、**設定を入れただけで先月と今月の投稿日配置が変わる**。この挙動は仕様として明示されていないため、誰も予期しない。

副次的に、`:1713` の `poster = (v||s).poster` は**静止画契約の poster を読まない**。契約単位ループへ書き換えると各契約の poster が使われるようになる。現行データでは同一クライアントの2契約が同じ poster なので差分は出ないが、**§12.4 はこれが挙動変更であることを書いていない**。

**4. 推奨変更**
- §12.4 の手順5 を「**投稿担当に `working_schedules` が1件も無い場合は補正しない**（現行 `cfg.staff[poster]` が偽のときと同じ）」と明記する。§12.4 は既に「処理内容を1点変える」と宣言しているので、変えない点も同じ粒度で書く。
- §24.6 の `generate()` 行に「投稿担当の稼働日補正は、`working_schedules` を持つメンバーが poster の契約にのみ適用される（移行時点では `editor` Role 保持者3名のみ）」を注記する。
- §12.4 に「契約単位ループ化により、静止画契約の `poster` が読まれるようになる。現行データでは差分ゼロだが、これは意図した挙動変更である」を1文追加する。
- §25.1 の生成ロジックの Unit テストに「**poster が勤務予定を持たない契約で、投稿予定日が補正されないこと**」を1ケース追加する。

**5. 過剰設計にならない最小修正**
実装は増えない。**§12.4 に条件を1文、§24.6 に注記1行、§25.1 にテスト1ケース。** 後から気付くと、Parity が落ちた原因の切り分けに数日かかる。

---

#### R2-HIGH-2 — `seeded:true` のまま切り替え日を迎えた場合の扱いが決定事項になっていない（HIGH-5 の残存）

**1. 該当設計**
§24.4 運用データ表の `seeded` 行（L2741、Method **E**、「サンプルデータのフラグ。移行時は実データのみ」）、§24.2 Step 5-3（L2621「最終 STATE を再抽出し、スナップショット同期を流す」）、§14.3（L1830「サンプル表示中 -> **廃止**（移行時に実データのみになる）」）、§28.1 の Q 一覧（Q1〜Q14）。

**2. 問題**
Resolution は HIGH-5 の構造的な指摘を採用し、`clients` / `notes` のキー不在を正常として扱う形にした。これは正しい。しかし第1回が並べて求めた「**`seeded` の扱いを決定事項にする**」は反映されていない。

`seeded:true` は、`notices()`（`:2264`）が「表示中の月の進捗ステータスと投稿完了日はサンプルです」と表示している状態を意味する。つまり `rows[].status` / `postedAt` / `trans` / `actor` は運用の記録ではない。§24.4 は「移行時は実データのみ」と書くが、**それをどう保証するかが手順のどこにも無い。** Step 5-3 は「最終 STATE を再抽出してスナップショット同期を流す」としか書いておらず、`seeded` の値による分岐が存在しない。

取り得る状態は3つあり、どれになるかは切り替え日にならないと分からない。

| 切り替え日の公開版 state | 現行手順の結果 |
|---|---|
| `seeded:false`（実運用の進捗が入っている） | 正常に移行される。問題なし |
| `seeded:true` のまま | **サンプルの `status` / `postedAt` / `trans` が本番 DB の初期状態になる。** §14.3 が約束した「移行時に実データのみになる」が成立しない |
| 移行前に「サンプルを削除」（`:2285`）を押した | `STATE.rows` から当月分が全削除される。スナップショット同期は差集合を archive するため、**`content_items` が0件で本番開始**になる |

**3. 発生する具体的リスク**
2つ目の経路が最も危険である。金曜夜に移行し、月曜朝にスタッフが「今日」画面を開くと、投稿済み36本・確認中5本といった**架空の進捗が本番データとして表示される**。artifact 側では `notices()` が「サンプルです」と注意書きを出していたが、§14.3 でその表示は廃止されているため、**新環境には「これはサンプルです」と伝える手段が無い。** 誰も気付かないまま、その状態から運用が始まる。

3つ目の経路では、Step 5-4 の Parity が「0件 対 0件」で通過してしまう。§24.6 の件数チェックは `content_items` の件数を `STATE.rows` と比較するので、両方0なら一致する。**移行の最終防衛線が空振りする。**

R2 リスク一覧（§28.2）は「移行時のデータ欠落」を挙げているが、対策として §24.6 の Parity を指しており、この経路には効かない。

**4. 推奨変更**
- **§28.1 に Q15 を追加する。** 「切り替え日に公開版が `seeded:true`（サンプル表示中）だった場合、サンプルの進捗をそのまま移行するか、`content_items` を `generate()` で新規生成して進捗を初期化するか」。推奨案は後者（進捗を初期化し、`publish_date` と担当だけ引き継ぐ）。
- **§24.2 Step 2-1 の実測項目に `seeded` の値を明記する。** 現在は「件数・月・キーの有無」だけで、`seeded` が入っていない。ここで早期に判明すれば運用側で `unseed` する時間が取れる。
- **§24.2 Step 5-3 に分岐を書く。** 「`seeded:true` の場合は Q15 の決定に従う。サンプルを本番として取り込む場合でも、`audit_logs` に `migration.import` の1件として `seeded:true` であった旨を残す」。
- §24.4 の `mlboard.ops.v1` 行と同様に、**「サンプルを削除」（`:2285`）をカットオーバー前に押さないこと**を Step 5-1 のチェック項目に加える。押してしまった場合の復旧手段が無い（artifact に undo は無い）。

**5. 過剰設計にならない最小修正**
実装は増えない。**§28 に Q を1行、§24.2 に実測項目1つと分岐1段落、Step 5-1 にチェック1行。** 決めずに切り替え日を迎えると、その場で判断することになり、判断を誤ると戻せない。

---

#### R2-HIGH-3 — `contract_version_hash` が未定義のまま残り、契約の有効期間フィルタも §12.4 の手順に入っていない（HIGH-6 の残存）

**1. 該当設計**
§12.4「冪等性」（L1673「`idempotency_key = workspace_id + target_month + contract_version_hash` を使う」）、§22.3（L2432 同文）、§12.4 の生成手順1〜7（L1655-1666）、§6.4 `service_contracts`（L653）、§5.2（L455）、§28 Q4。

**2. 問題**
Resolution は HIGH-6 を ACCEPT とし、契約単位ループと `phaseOf` の鍵を反映した。しかし第1回が同じ指摘の中で挙げた2点が反映されていない。

**(a) `contract_version_hash` の定義が無い。** §12.4 と §22.3 の2箇所でこのキーが冪等キーの構成要素として使われているが、**何をハッシュするかがどこにも書かれていない。** §6.4 の `service_contracts` の列一覧は `id, workspace_id, client_id, kind, monthly_count, step_count, lead_time_business_days, default_publisher_member_id, default_editor_member_id, workflow_template_id, starts_on, ends_on, status, legacy_id` で、**`version` も `updated_at` も無い**（§6.1 は `created_at` / `updated_at` を共通規約としているが、`version` は「更新競合を扱うテーブル」に限定しており、§22.1 の対象3テーブルに `service_contracts` は含まれない）。ハッシュ対象が決まらなければ冪等キーは作れない。

**(b) 対象月に有効な契約を絞る手順が無い。** §12.4 の手順は「1. 営業日を得る -> 2. ServiceContract ごとに `monthly_count` 本を用意する -> ...」で始まる。`starts_on` / `ends_on` / `status` による絞り込みが**どの手順にも現れない**。§5.2 と §6.4 は両方の列を持っているのに、生成が参照しない。第1回は「§12.4 の手順に『0. 対象月に有効な契約を `starts_on` / `ends_on` / `status` で絞る』を追加する」と明示的に求めた。

**3. 発生する具体的リスク**
**(a) の帰結** — Phase 5 で翌月生成 API を実装する段になって、`contract_version_hash` の仕様が無いことに気付く。その場で「契約行全体を JSON 化してハッシュ」と決めると、`updated_at` のような生成結果に影響しない列が入り、**契約を一切変えていないのに毎回キーが変わって冪等性が効かない**（連打で `merge()` が2回走るという、まさに直そうとした問題が残る）。逆に列を絞りすぎると、契約を変更したのに同じキーになり、**変更が反映されない**。どちらも「実装したが効いていない」型の故障で、テストを書く側も何を検証すればよいか分からない。

**(b) の帰結** — 具体的な入力で壊れる。「アシストタクシーとの契約が 2026-10 で終了」と `ends_on` に登録する。11月の生成を押す。**契約は `status = active` のままなので4本が生成され、りりかに存在しない仕事が割り当てられる。** クライアント管理画面の「目標」は `clientAgg()` が全契約の `monthly_count` を合計するので、終了済み契約の分も目標に乗り続ける。運用側は「契約を終了させたのに消えない」という状態を、毎月手で削除して回ることになる（§24.3 が述べるとおり **UI に ContentItem の削除機能は無い**）。

**4. 推奨変更**
- **`service_contracts` に `version integer not null default 1` を追加する**（§5.2 / §6.4 / §7.3 ER）。契約の内容変更で必ずインクリメントする。
- **§22.3 に `contract_version_hash` の定義を書く。** 「対象月に有効な契約行の `(id, kind, monthly_count, step_count, lead_time_business_days, default_publisher_member_id, workflow_template_id, version)` を `id` 昇順で連結したハッシュ」。生成結果に影響する列だけを含め、`updated_at` は含めない。
- **§12.4 の手順に 0 を追加する。**

```
0. 対象月に有効な契約だけを選ぶ
   where status = 'active'
     and starts_on <= 対象月の月末
     and (ends_on is null or ends_on >= 対象月の月初)
```

- §25.1 の生成ロジックの Unit テストに「`ends_on` を過ぎた契約が生成対象に入らないこと」「契約を変えずに2回実行して `contract_version_hash` が同一であること」の2ケースを追加する。
- §25.5 の冪等性テストの「翌月生成を2回実行して行が二重にならないこと」は、`contract_version_hash` が定義されて初めて書ける。

**5. 過剰設計にならない最小修正**
`ServiceContract` の履歴管理（temporal table）は要らない。**列1本（`version`）、§22.3 に定義1段落、§12.4 に手順0を1つ、テスト2ケース。** `version` はスキーマに触るため **Phase 2 の初回 migration に含める必要がある**。手順0 は Phase 5 の実装時でも間に合うが、忘れると本番で終了済み契約が生成され続ける。

---

### 2.3 MEDIUM

#### R2-MEDIUM-1 — v2 の修正が7箇所に波及しておらず、章をまたぐ矛盾が残っている

**1. 該当設計**
§5.4（L485 / L489）、§7.1 ER（L755 / L842）、§7.2 ER（L927）、§13.1（L1710）、§28.2 R8（L3126）、§28.1 オーナー向け説明（L3139 / L3149）、§24.4（L2732-2735）。

**2. 問題**
長文を分割追記で編集した結果、**直した章と直していない章が同じ事項について別のことを言っている**。7箇所ある。

| # | 箇所 | 現在の記述 | 矛盾する先 |
|---|---|---|---|
| 1 | §5.4 L485 | `status` -> `Task.workflow_state_id` | §5.1 L410-412 / §6.2 L603 / §11.1 L1499（Task は `workflow_run_id` のみを持ち、状態は `workflow_runs` が唯一の正） |
| 2 | §5.4 L489 | `trans{}` -> 「`WorkflowRun` の遷移履歴 ＋ `AuditLog`」 | §24.4 L2711 / §19.3 L2202（**展開しない**。Method E で `audit_logs` 1件に raw JSON だけ残す） |
| 3 | §7.1 ER L755 | `workflow_templates \|\|--o{ tasks : "適用"` | §6.2 L603（`tasks` から `workflow_template_id` を削除した）。ER に存在しない列への関連が描かれている |
| 4 | §7.1 ER L842 | `tasks { ... int version }` | §22.1 L2411（「`tasks` は状態を持たないため version を持たせない」） |
| 5 | §7.2 ER L927 | `automation_rules { ... jsonb conditions }` | §6.2 L612 / §13.3 L1730 / ADR-023 L3377（`predicates`） |
| 6 | §13.1 L1710 | `Rule = { trigger_type, conditions, actions, schema_version, enabled }` | 同上 |
| 7 | §28.2 R8 L3126 | 「§11.5 の**4規則**。保存時に検証しエラーにする」 | §11.5 L1548（**7規則**） |

加えて2件の付随的な破損がある。

- **§28.1 の Q 件数が古い。** 表は Q1〜Q14（L3097-3112）だが、直後のオーナー向け説明が「判断をお願いしたいことを**12個**にまとめました」（L3139）「上の表の**12項目**」（L3149）のまま。HIGH-1 で Q13、HIGH-10 で Q14 を足したときに更新されていない。**この文書はオーナーが読む前提なので、実害が出るのはここである** — Q13（スタッフの権限を現行どおりにするか）と Q14（Integration の接続アカウント）が、オーナーの目には「12個」の外側にある扱いになる。
- **§24.4 の Migration Matrix で `version` 行がテーブル外に取り残されている。** L2711-2730 の表の直後に段落が2つ挿入され（L2732 / L2734）、その後に `| version | — | — | E | STATE スキーマ版。DB migration が置き換える |`（L2735）が単独で残っている。Markdown ではヘッダを持たない1行の表になり、**移行対象の1行が Matrix から視覚的に脱落する**。`check_doc_integrity.sh` はこれを検出しない。

**3. 発生する具体的リスク**
#1 と #4 は実装者が §5.4 と §7.1 の ER を見て `tasks` に `workflow_state_id` と `version` を作る経路を残す。MEDIUM-1 と MEDIUM-4 で潰したはずの「状態が2箇所にある」「どの version を送るか不定」が復活する。ER 図は実装時に最も参照される図であり、**スキーマ表より ER のほうが読まれる**。

#2 は移行スクリプトを書く人が §5.4 を見て `workflow_run_transitions` への展開を実装する。HIGH-4 で「絶対にやってはいけない」と結論した虚偽の監査履歴の生成が、そのまま実装される。

#5 と #6 は Phase 6 の実装者が `conditions` という列名で実装を始める。

#7 は §11.5 を読まずに R8 だけ見た人が「規則は4つ」と理解する。

**4. 推奨変更**
7箇所をそれぞれ次のように直す。

- §5.4 L485：`status` -> `WorkflowRun.current_state_id`（`Task` は `workflow_run_id` 経由で参照）
- §5.4 L489：`trans{}` -> 「移行しない（§24.4 Method E）。raw JSON を `audit_logs` に1件保存」
- §7.1 ER L755：`workflow_templates ||--o{ tasks : "適用"` の行を削除する
- §7.1 ER L842：`tasks` ブロックから `int version` を削除する
- §7.2 ER L927：`jsonb conditions` -> `jsonb predicates`
- §13.1 L1710：`Rule = { trigger_type, predicates, actions, schema_version, enabled }`
- §28.2 R8：「§11.5 の**7規則**」
- §28.1 L3139 / L3149：「12個」「12項目」-> 「14個」「14項目」
- §24.4：L2735 の `version` 行を L2730 の直後（表の中）へ戻し、2つの段落を表の後ろへ移す

そのうえで、**`check_doc_integrity.sh` に「表の途中に空行を挟んだまま `|` 行が続いていないか」のチェックを1つ足す**。今回の破損は既存のどのチェックにも掛からなかった。

**5. 過剰設計にならない最小修正**
すべて文言の修正。**9行の書き換えと1つの行移動。** 実装量ゼロ。

---

#### R2-MEDIUM-2 — `tasks.version` の存否が §22.1 と §5.1 / §6.2 / §7.1 で矛盾し、`tasks.due_at` の楽観ロック根拠が未定義

**1. 該当設計**
§22.1 L2391（「`content_items` / `workflow_runs` / `daily_notes` に `version integer` を持つ」）、L2411（「`tasks` は状態を持たない（§11.1）ため version を持たせない」）、§22.1 の対応表 L2401-2405、§5.1 L410、§6.2 L603、§7.1 ER L842。

**2. 問題**
§22.1 は `tasks` に `version` を持たせないと明言しているが、§5.1 の `Task` のフィールド一覧・§6.2 の `tasks` 行・§7.1 の ER の3箇所には `version` が残っている（R2-MEDIUM-1 の #4 と同根）。

より実務的な問題は対応表のほうにある。§22.1 は「投稿予定日 / 締切の変更」の送る version を `content_items.version` としているが、**締切（`due_at`）は `tasks` の列である**（§6.2 L603）。つまり「A テーブルの行を更新するのに B テーブルの version を検証する」形になる。これ自体は集約（aggregate）の考え方として成立し得るが、**成立させるには「`tasks` を更新するときは同一トランザクションで `content_items.version` もインクリメントする」という規約が要る。** その1文が §22.1 に無い。

同様に「担当変更」も `content_items.version` とされているが、`task_assignments` は行の追加削除であり `content_items` を一切触らない。version をインクリメントする主体が書かれていない。

**3. 発生する具体的リスク**
実装者が §22.1 の対応表どおりに `expectedVersion` を検証したあと、`content_items.version` をインクリメントし忘れる。**検証は通るが version が進まないので、楽観ロックが何も守らない状態になる。** 2人が同時に締切を変更すると、後の書き込みが黙って勝つ。§25.2 の「`version` 不一致の UPDATE が0行になること」というテストは、`content_items` を直接 UPDATE するケースしか検証しないため、この経路を検出しない。

逆に、§5.1 / §6.2 を見て `tasks.version` を作った実装者は、`tasks` の更新で `tasks.version` を検証する。すると同じ操作に対して2つの実装が並存し、UI がどちらを送ればよいか決まらない（MEDIUM-4 で潰したはずの状態に戻る）。

**4. 推奨変更**
- §5.1 L410 / §6.2 L603 / §7.1 ER L842 から `version` を削除し、§22.1 と揃える。
- §22.1 の対応表の下に規約を1文追加する。「**`tasks` および `task_assignments` を変更する Command は、同一トランザクション内で対応する `content_items.version` をインクリメントする。** ContentItem を集約のルートとして扱う」。
- §25.2 のテストに「`tasks.due_at` を古い `content_items.version` で更新しようとすると 409 になること」を1ケース追加する。

**5. 過剰設計にならない最小修正**
**列の削除3箇所と、規約1文とテスト1ケース。** 集約の境界を1つ決めるだけで、新しい概念は増えない。

---

#### R2-MEDIUM-3 — `period_key` が NULL の Run に対して UNIQUE が効かず、§22.5 の upsert 冪等化が成立しない

**1. 該当設計**
§6.2 `workflow_runs` 行 L601（`unique(workspace_id, template_id, subject_type, subject_id, period_key)`）、§5.1 L428、§11.6 L1578-1580、§22.5 例2 L2450、§25.2 L2849。

**2. 問題**
PostgreSQL の UNIQUE 制約は、既定で NULL 同士を「異なる値」として扱う（`NULLS DISTINCT`）。**`period_key IS NULL` の行は何行でも作れる。** 第1回の HIGH-7 は「`period_key` が NULL の行を1件だけ許す部分ユニークインデックスとの組み合わせ」を明示的に求めたが、v2 にはこの但し書きが無い。

§5.1 L428 と §6.2 L601 は「期間概念が無ければ NULL」と定めているので、SOCIAL BASE の主工程（ContentItem 1本ごとの Run）はすべて `period_key = NULL` になる。したがって**主工程の Run にはこの UNIQUE が一切効かない**。

さらに §22.5 の例2 は「Workflow Run を作る Action は `(workspace_id, template_id, subject_type, subject_id, period_key)` をキーとした upsert にする」と書いているが、`ON CONFLICT` はユニークインデックスに依存する。**`period_key` が NULL の行では衝突が発生しないため、upsert は常に INSERT になる。** 冪等化の仕組みとして機能しない。

**3. 発生する具体的リスク**
Job は at-least-once（§23.3）である。翌月生成の Job が再実行され、同じ ContentItem に対して `create_workflow_run` が2回走ると、**同じ ContentItem に Run が2つできる。** `tasks.workflow_run_id` は片方しか指さないので、もう片方は「どの Task からも参照されないが `current_state_id` を持つ Run」として残る。§11.5 規則3（現在どれかの Run が滞在している State は archive できない）の判定がこの孤児 Run に引っかかり、**実際には誰も使っていない State を archive できなくなる。**

§25.2 のテスト（L2849）は `period_key` を持つケースしか検証しないため、この経路を通らない。

**4. 推奨変更**
- §6.2 の `workflow_runs` 行の制約を次のように書き換える。

```sql
-- period_key を持つ Run（月次など）
unique (workspace_id, template_id, subject_type, subject_id, period_key)
-- period_key が NULL の Run（主工程など）は対象ごとに1件だけ
create unique index workflow_runs_no_period_uq
  on workflow_runs (workspace_id, template_id, subject_type, subject_id)
  where period_key is null;
```

  （PostgreSQL 15 以降なら `unique nulls not distinct (...)` の1本でもよい。採用するバージョンを §26.1 で決めているので、どちらかに固定する。）
- §22.5 の例2 に「`period_key` が NULL の場合は部分ユニークインデックス側を `ON CONFLICT` の対象にする」を追記する。
- §25.2 のテストに「`period_key = NULL` の Run が同一対象に2件作れないこと」を1ケース追加する。

**5. 過剰設計にならない最小修正**
**インデックス1本と、§22.5 に1文、テスト1ケース。** スキーマに触るため Phase 2 に含める。後から入れる場合は既に重複した Run の掃除が要る。

---

#### R2-MEDIUM-4 — 「全テーブルに `unique(id, workspace_id)` を張る」規約が、`id` 列を持たない4テーブルに適用できない

**1. 該当設計**
§6.1 L568（「そのうえで、**全テーブルに `unique(id, workspace_id)` を張り、すべての親子参照を複合外部キーにする**。UNIQUE の無い親は複合外部キーで参照できないため、これは『例』ではなく全テーブルに機械的に適用する規約である」）、§6.2 の前書き L588（「全テーブルに `unique(id, workspace_id)` を張る（§6.1 の規約）。表では省略し」）、ADR-021 L3358。

**2. 問題**
BLOCKER-1 の修正で規約が「例」から「機械的に適用する規約」へ強化されたのは正しい。しかし **`id` 列を持たないテーブルが4本ある**ため、規約を文字どおり適用できない。

| テーブル | 列（§6.2 / §6.4） | 状況 |
|---|---|---|
| `role_capabilities` | `workspace_id, role_id, capability_key, scope_type, scope_id` | `id` 無し。`pk(role_id, capability_key, scope_type, scope_id)` |
| `member_roles` | `workspace_id, workspace_member_id, role_id` | `id` 無し。`pk(workspace_member_id, role_id)` |
| `idempotency_keys` | `workspace_id, key, endpoint, ...` | `id` 無し。`pk(workspace_id, key)` |
| `content_item_tasks` | `workspace_id, content_item_id, task_id` | `id` 無し。`pk(workspace_id, content_item_id, task_id)` |

加えて `users` と `webhook_receipts` は `workspace_id` を持たない（§6.1 の例外表に記載済み）ため、こちらも `unique(id, workspace_id)` を張れない。**§6.1 の例外表は `workspace_id` についての例外しか扱っておらず、UNIQUE 規約についての例外を扱っていない。**

**3. 発生する具体的リスク**
Phase 2 の初回 migration を書く担当者が、規約どおり全テーブルにループで `unique(id, workspace_id)` を生成すると、上記6本で失敗する。そこで担当者は「規約が正確でない」と判断し、**どのテーブルに張るかを自分の判断で決める**。BLOCKER-1 の本質は「権限テーブルに複合外部キーの参照先が無い」ことだったので、判断が入る余地を残すこと自体がリスクである。実害の可能性は低いが、**この規約は「機械的に適用できること」を売りにしているため、機械的に適用できないのは規約としての欠陥**である。

**4. 推奨変更**
§6.1 L568 の規約を次のように精密化する。

> **他テーブルから参照される可能性のあるテーブル（＝ `id` を主キーとするテーブル）には、例外なく `unique(id, workspace_id)` を張る。** 結合テーブル・キー値テーブル（`role_capabilities` / `member_roles` / `idempotency_keys` / `content_item_tasks`）は `id` を持たず、他から参照されないため対象外とする。`users` / `webhook_receipts` は `workspace_id` を持たないため対象外（§6.1 の例外表）。

§6.2 の前書き L588 も同様に「`id` を持つ全テーブルに」と限定する。

**5. 過剰設計にならない最小修正**
**§6.1 と §6.2 の前書きを1文ずつ書き換えるだけ。** 実装量ゼロ。むしろ migration の記述が減る。

---

#### R2-MEDIUM-5 — 月次生成の手順（§12.4）から `assignEditors()` が欠落しており、テスト対象にも入っていない

**1. 該当設計**
§12.4 L1638（「現行 `generate()`（`:1697`）+ `merge()`（`:5019`）をサーバー側 Command として移植する」）、§12.4 の手順1〜7 L1655-1666、§3.3 L260（サーバーへ移す対象に `assignEditors()` を列挙）、§25.1 L2832（生成ロジックのテスト対象に `generate` / `distribute` / `interleave` / `phaseOf` / `nearestWorking`）、§10.3 L1437、§6.4 `service_contracts.default_editor_member_id`。

**2. 問題**
現行の翌月生成は3ステップである。

```js
:4992  var plan = generate({contracts:SEED_CONTRACTS, ym:target, genDate:TODAY, shifts:SEED_SHIFTS, staff:STAFF_MAP});
:4993  var caps = {}; Object.keys(STAFF_MAP).forEach(function(n){ caps[n] = capacityOf(SEED_SHIFTS, STAFF_MAP[n], target).cap || 1; });
:4994  assignEditors(plan, caps);
```

`generate()` は `editor: con.editor || ""`（`:1733`）を返すだけで、`SEED_CONTRACTS` に `editor` フィールドが無いため**常に空文字を返す**。編集担当を実際に割り当てているのは `assignEditors(plan, caps)`（`:1763` 定義）で、`capacityOf()` から作った `caps` を入力に取る、独立した capacity ベースの割当アルゴリズムである。

**§12.4 はこの関数に一度も言及していない。** L1638 は `generate()` と `merge()` だけを移植対象として挙げ、手順1〜7 にも担当割当のステップが無い。§25.1 の生成ロジックのテスト対象一覧にも `assignEditors` は入っていない（§3.3 だけが名前を挙げているが、§3.3 はサーバーへ移す関数の一覧であって仕様ではない）。

§10.3 は「`ServiceContract.default_editor_member_id` は既定値。生成時に `task_assignments` へコピーされる」と書くが、**`SEED_CONTRACTS` に editor が無い以上、移行時点で `default_editor_member_id` はすべて NULL である。** §24.4 のマスターデータ表にも `default_editor_member_id` の移行元は存在しない（`poster` -> `default_publisher_member_id` はある）。つまり §10.3 の「既定値からコピー」だけでは、**生成された ContentItem に編集担当が一人も付かない。**

**3. 発生する具体的リスク**
Phase 5 の完了条件は「新規クライアント1社を画面から追加でき、翌月生成に反映される」である。手順どおりに実装すると、生成された50本すべてが**担当者なし**になる。その結果、

- `MyTasksQuery`（§5.5）が全員について0件を返す。ホームと「今日」の「自分のタスク」が空になる。
- `TeamLoadQuery` の `loadOf()` は `r.editor !== name` で弾くため、3名全員が `score = 0` の「余裕あり」になる。
- §24.6 の Parity「担当（editor）別の件数 | 一致」は**移行した `STATE.rows` については通る**（rows には実測でりりか24 / ゆかり14 / つかさ12 が入っている）。したがって Parity ゲートはこの欠落を検出しない。翌月生成を最初に実行したときに初めて露見する。

capacity ベースの割当という業務ロジックが**仕様書に一度も書かれないまま実装される**ことも問題である。誰が何を根拠に割り当てるかは §18 の負荷スコアと同じく業務判断であり、Frontend と Backend の両方に持たせてはいけない類の計算（§3.3）である。

**4. 推奨変更**
- **§12.4 の手順に担当割当を追加する。** 現行の3ステップ構成を明示する。

```
0. 対象月に有効な契約を絞る（R2-HIGH-3）
1〜6. 日付とリードタイムの決定（現行 generate() 相当）
6.5 編集担当を割り当てる（現行 assignEditors(plan, caps) 相当）
    caps は editor Role 保持者ごとの capacityOf().cap（§18.1）
    ServiceContract.default_editor_member_id が設定されていればそれを優先し、
    未設定なら capacity ベースで割り当てる
7. merge（現行どおり）
```

- **§12.4 に `assignEditors()` の割当規則を1段落で明文化する。** 現行実装（`:1763`）の挙動をそのまま書けばよい。「処理内容は変えない」方針の対象である。
- §25.1 の生成ロジックのテスト対象に **`assignEditors`** を追加し、「同じ入力で同じ担当割当になること」を Unit テストにする（§25.1 の「現行 JS の出力を期待値として使う」がそのまま適用できる）。
- §24.6 の「計算結果の一致」に **`assignEditors()` の担当割当** を1行追加する。現行の `plan` に対する出力を期待値にできる。
- §10.3 に「`default_editor_member_id` は移行時点では未設定であり、生成時は capacity ベースの割当が既定である」を注記する。

**5. 過剰設計にならない最小修正**
新概念は不要。**§12.4 に手順1つと段落1つ、§25.1 と §24.6 に1行ずつ、§10.3 に注記1文。** 実装は現行関数の移植であり、追加コストはゼロ。

---

#### R2-MEDIUM-6 — 「1段戻す」の逆向き Transition が §11.3 に列挙されておらず、`unique(template_id, from, to)` と `is_terminal` に抵触する

**1. 該当設計**
§11.3 L1522-1531（Transition の表・6行）、L1536（「**1段戻す** — 現行 `PREV_STATUS`（`:1553`）に相当する取り消しは、逆向きの Transition として定義する」）、§6.2 `workflow_transitions` 行 L600（`unique(template_id, from_state_id, to_state_id)`）、§11.3 の State 表 L1514-1521（`posted` は終端 ○）、§24.4 L2688（`PREV_STATUS` -> `workflow_transitions`（逆向き）、検証「1段戻すが現行と同じ遷移先」）。

**2. 問題**
現行の `PREV_STATUS`（実測）は5組ある。

```js
:1553  var PREV_STATUS = {"編集中":"未着手","確認中":"編集中","要修正":"確認中",
:1554                     "投稿待ち":"確認中","投稿済み":"投稿待ち"};
```

これを「逆向きの Transition」として `workflow_transitions` に入れると2点で衝突する。

**(a) `要修正 -> 確認中` が既存の Transition と重複する。** §11.3 の表には既に `要修正 -> 確認中`（ボタン文言「修正完了」、主 ○）がある。`unique(template_id, from_state_id, to_state_id)` があるため、**同じ (from, to) の行を2つ作れない。** 「1段戻す」の要修正からの遷移は、既存の「修正完了」Transition を流用するしかない。§11.3 も §24.4 もこの重複に触れていない。

**(b) 終端 State から出る Transition ができる。** `投稿済み -> 投稿待ち` は、§11.3 の State 表で `is_terminal = ○` としている `posted` からの outgoing transition である。`is_terminal` は §11.2 の semantic と並んで「完了率」「今日画面の done バケット」の意味論を決める列であり、**終端なのに出口がある**という状態は、§11.5 規則4（履歴があれば `is_terminal` を変更できない）と組み合わさると後から直せなくなる。

さらに、§11.3 の Transition 表は6行しかなく、**逆向き4〜5行がどこにも列挙されていない。** §24.4 の検証列は「1段戻すが現行と同じ遷移先」だが、比較対象の表が設計書に無いため検証しようがない。

**3. 発生する具体的リスク**
Phase 4 で `workflow_transitions` を seed する担当者が、§11.3 の表の6行だけを投入する。「1段戻す」が動かない。あるいは逆向き5行を足そうとして `要修正 -> 確認中` で重複キー違反になり、そこで初めて設計の穴に気付く。

より根の深い問題として、逆向き Transition を通常の Transition として登録すると、**UI の遷移ボタン候補に「1段戻す」先が混ざる可能性がある。** §11.3 は「『次へ』は使わない。ボタンには必ず具体的なアクション名を出す」という現行方針を維持すると宣言しているが、`is_primary` だけでは「進むボタン」と「取り消し」の区別がつかない。現行は `STATUS_ACTIONS` と `PREV_STATUS` を別の定数として持ち、UI も別の導線（`:3037`）で出している。

**4. 推奨変更**
- **§11.3 の Transition 表に逆向き行を明示的に追加する**（4行）。

| from | to | ボタン文言 | 種別 | 必要 Capability |
|---|---|---|---|---|
| 編集中 | 未着手 | 1段戻す | `undo` | `workflow.transition` |
| 確認中 | 編集中 | 1段戻す | `undo` | `workflow.transition` |
| 投稿待ち | 確認中 | 1段戻す | `undo` | `workflow.transition` |
| 投稿済み | 投稿待ち | 1段戻す | `undo` | `workflow.transition` |

- **`workflow_transitions` に `kind text`（`forward` / `undo`）を追加する**か、既存の `is_primary` を3値に拡張する。UI は `forward` だけを進行ボタンとして描き、`undo` は現行同様に別導線で出す。これが無いと §3.4 の Visual / Interaction Contract を維持できない。
- **要修正からの「1段戻す」は既存の `修正完了` Transition を流用する**と §11.3 に明記する（`unique(template_id, from, to)` があるため新規行は作れない）。
- **`is_terminal` と `undo` の関係を §11.2 か §11.3 に1文で定める。** 「`is_terminal` は『通常の進行がここで終わる』を意味し、`kind = undo` の outgoing transition の存在を妨げない」。
- §25.4 の Workflow Test に「終端 State からの `undo` 遷移が通ること」「`forward` 遷移としては終端から出られないこと」を追加する。

**5. 過剰設計にならない最小修正**
**§11.3 に表4行と注記2文、`workflow_transitions` に列1本、テスト2ケース。** 列を足すためスキーマに触るので Phase 2 に含める。

---

#### R2-MEDIUM-7 — 監視のハートビート（MEDIUM-7 の対策）が §26.5 / §26.6 に反映されていない

**1. 該当設計**
§19.4 L2218（「dead-letter と同期停止の通知だけは Job を経由しない外形監視から出す。Job Runner が止まったときに『止まった』という通知を Job で送ろうとしても届かない」）、§26.5「監視で見るもの」L2965-2973、§26.6「障害時のUX」の Job Runner 停止行 L2980。

**2. 問題**
Resolution は MEDIUM-7 を ACCEPT とし「§26.5 に明記」と記録しているが、**§26.5 の表にはハートビートも外形監視も1行も無い。** 7つの指標（API エラー率 / dead-letter 件数 / Integration 最終同期 / OAuth トークン期限 / 接続アカウント失効 / webhook チャンネル期限 / `business_calendar` 残日数）はすべて内部から検知するものである。§26.6 の「Job Runner 停止」行も「画面は正常。通知と外部同期だけ遅れる。**滞留を監視で検知する**」のままで、**その検知結果をどの経路で人へ届けるかが書かれていない。**

反映されているのは §19.4 の1文だけで、これは Observability の章にあり、運用手順（§26）を読む人の目には入らない。

**3. 発生する具体的リスク**
Phase 10（Production Hardening）で監視を組む担当者は §26.5 の表を実装仕様として使う。表に無いものは作られない。**結果として、Job Runner が停止したときにそれを知らせる経路が存在しない構成が出来上がる。** cron トリガーが設定ミスや課金停止で無効になると、画面は正常に動くため誰も気付かず、通知・Integration 同期・Automation が数週間止まったまま運用が続く。§13.5 の「定例資料 7日前」Rule が発火しなくなるが、**作られていない Task には誰も気付けない。**

§19.4 の1文だけでは、実装者は「誰かがやるだろう」と読み飛ばす。

**4. 推奨変更**
- **§26.5 の表に1行追加する。**

| 指標 | 閾値 |
|---|---|
| **Job Runner のハートビート（外形監視）** | ドレイン Job が正常終了するたびに外部の cron 監視サービスへ HTTP GET を送る。**一定時間叩かれなければ、SOCIAL BASE を経由しない経路（メール等）で通知する** |

- **§26.6 の「Job Runner 停止」行を書き換える。** 「滞留を監視で検知する。**検知と通知は §26.5 のハートビート（外形監視）で行い、SOCIAL BASE の Job / Notification 経路に依存しない**」。
- §27 Phase 10 の完了条件に「ハートビートを意図的に止めて、外部監視から通知が届くことを確認する」を追加する。試していない監視は §26.4 のバックアップと同じで、無いのと同じである。

**5. 過剰設計にならない最小修正**
**ドレイン Job の末尾に HTTP GET を1行、外部サービスの登録1回、表に2行。** 常駐プロセスもインフラも増えず、§26.1 の「常時稼働サーバーを持たない」前提を崩さない。

---

#### R2-MEDIUM-8 — `editor` Role による絞り込みの適用範囲が `myTasks()` に限定され、`scopeRows()` と動画一覧のフィルタが漏れている

**1. 該当設計**
§10.5 L1451-1470（「現行 `myTasks()`（`:2217`）は `if(STAFF_MAP[ME])` が真のとき…移行後もこの規則を維持する」）、§5.5 の Query Service 表 L505-514、§2.5 L171（今日画面の関数に `scopeRows()` を列挙）。

**2. 問題**
`STAFF_MAP[ME]` による絞り込みは現行に**3箇所**ある。

| 行 | 関数 | 絞り込み条件 |
|---|---|---|
| `:2219` | `myTasks()` | `r.editor===ME \|\| contractById(r.contractId).poster===ME` |
| `:3066` | `scopeRows()` | 同上（コメント「自分に関係する行。編集スタッフは自分の担当と投稿担当だけを見る」） |
| `:3335` | 動画一覧のフィルタ | `FILTER.editor==="__me__" && STAFF_MAP[ME]` のとき自分の担当に絞る |

§10.5 は `myTasks()` だけを扱い、「editor Role を持つ Member -> 自分が assignee の Task に絞る」という規則を定めているが、**同じ規則が適用される `scopeRows()` と `:3335` に言及していない。** §5.5 の Query Service 表も、`TodayTasksQuery` の置き換え対象を `todayBuckets()` / `todayReview()` とするだけで `scopeRows()` を含めず、`ContentListQuery` も `filteredRows()` としか書いていない。§2.5 L171 は今日画面の関数として `scopeRows()` を挙げているので、**設計書は `scopeRows()` の存在を知りながら移行先を定義していない。**

**3. 発生する具体的リスク**
Phase 4 で `TodayTasksQuery` / `ContentListQuery` を実装する担当者は §5.5 と §10.5 を読む。`scopeRows()` の絞り込みが仕様として書かれていないため、**「今日」画面と動画一覧で全員に全件を返す実装になる。** りりかの「今日」画面に、自分と無関係な他スタッフの案件が並ぶ。

これは Phase 3 / Phase 4 の完了条件（「現行の `visibleViews()` / `writable()` と同じ画面が出る」「Visual Regression で画素差0」）に直接抵触する。実測では `rows` の editor 分布はりりか24 / ゆかり14 / つかさ12 なので、**りりかの画面が24件から50件に増える。** §24.6 の数値 Parity は `content_items` の総件数を比較するので、この差を検出しない（DB 上の件数は同じで、画面に出る件数だけが違う）。

**4. 推奨変更**
- **§10.5 の見出しと本文の対象を広げる。** 「『自分のタスク』の絞り込み」-> 「編集担当スコープの既定値」とし、「**この既定値は `MyTasksQuery` / `TodayTasksQuery` / `ContentListQuery` の3つに等しく適用する**（現行 `myTasks()` `:2217` / `scopeRows()` `:3064` / 動画一覧の『自分の担当』フィルタ `:3335`）」と明記する。
- 絞り込み条件を1つの式として書く。「**`editor` Role 保持者に対しては、`task_assignments` に `owner` または `publisher` として自分が含まれる Task に絞る**」。現行の `r.editor===ME || contract.poster===ME` と等価である。
- §5.5 の `TodayTasksQuery` の置き換え対象に `scopeRows()` を、`ContentListQuery` に「担当者フィルタの既定値」を追記する。
- §25.3 の Permission Test（あるいは §25.6 の E2E）に「`editor` Role 保持者の『今日』画面と動画一覧の既定表示が、自分が assignee の Task に絞られること」を1ケース追加する。

**5. 過剰設計にならない最小修正**
**§10.5 の見出しと1段落、§5.5 の表に2セル、テスト1ケース。** 実装側は「担当スコープを解決するクエリ」を1本に集約するだけで、HIGH-2 の「担当候補メンバーの定義を1つに集約する」と同じ形になる。

---

#### R2-MEDIUM-9 — MEDIUM-9 の残存。`recommendations.kind` が literal のままで、約束された Core 純度チェックはスクリプトに存在しない

**1. 該当設計**
§7.2 ER L985（`recommendations { text kind "publish_date or assignment" }`）、§4.2 の禁止事項 L336-338、`check_doc_integrity.sh`。

**2. 問題**
MEDIUM-9 は `schedule_entries.kind` と `recommendations.kind` の両方について、Module 固有語が Core のスキーマ記述に enum のように列挙されている点を指摘した。v2 は前者を解消した（§6.2 L605「`kind` は Module が登録する不透明な文字列。**Core は具体値を知らない**」、§7.2 ER L876「`text kind "module-registered (see 12.1)"`」、§12.1 L1610 の注記）。

**`recommendations.kind` は手つかずである。** §7.2 の ER は `"publish_date or assignment"` と literal で書き続けており、§6.2 の `recommendations` 行（L618）にも「Module 登録の不透明な文字列」という注記が無い。`publish_date` は SOCIAL BASE 固有の概念であり、営業部 Workspace には存在しない。

加えて、Resolution が「**`check_doc_integrity.sh` の Core 純度チェックにこれらの語を追加する**」と記録しているが、**スクリプトには Core 純度チェックそのものが存在しない。** 実在するのは章数・見出し・重複行・相互参照・コードフェンス・mermaid・末尾・git の8種類のみである。Resolution の記述と実物が食い違っている。

**3. 発生する具体的リスク**
実装者が §7.2 の ER を読んで `check (kind in ('publish_date','assignment'))` を書く。営業部 Workspace で「見積の担当変更提案」のような別種の Recommendation を作るとき、**Core のスキーマを migration で変更することになる。** §1.1 が「本書で最も強い制約であり、他のすべての判断に優先する」と宣言した P1 が、Core のスキーマ層で破られる。`schedule_entries.kind` は直したのに `recommendations.kind` は直っていない、という状態は、規約の適用が場当たり的であることを示す。

Core 純度チェックが存在しないことにより、この種の混入は今後も機械的には検出されない。

**4. 推奨変更**
- §7.2 ER L985 を `text kind "module-registered (see 18.3)"` に変更する。
- §6.2 の `recommendations` 行に「`kind` は Module が登録する不透明な文字列。Core は具体値を知らない（値は §18.3）」を追記する。§18.3 に具体値の表を置く。
- **`check_doc_integrity.sh` に Core 純度チェックを1つ追加する。** §6.2「Core テーブル」節と §7.1 / §7.2 の ER ブロックを対象に、`client` / `video` / `instagram` / `drive` / `slack` / `publish` / `shoot` / `meeting` / `poster` / `editor` の語が現れたら FAIL にする（`§12.1` `§18.3` のような参照だけを許す）。§4.2 の禁止事項を機械化するもので、これが無いと同じ混入が再発する。

**5. 過剰設計にならない最小修正**
**ER の1行、スキーマ表に注記1つ、スクリプトに grep 1本。** 実装上は CHECK 制約を作らないだけなので、作業はむしろ減る。

---

### 2.4 LATER

#### R2-LATER-1 — LATER-1 / LATER-3 / LATER-4 が設計書に未反映

Resolution はこの3件を「ACCEPT（LATER）」として §21.2 / §28.3 への反映を記録しているが、いずれも設計書に見当たらない。

| ID | Resolution の記述 | v2 の実態 |
|---|---|---|
| LATER-1 | 「`views/*` の応答にページング可能な形だけ先に持たせ、実装は件数が増えてから」 | §21.2 L2319-2341 の API 定義に `cursor` / `limit` / `ETag` が無い。§28.2 R7 L3125 に「Read Model をページング可能にしておく」とあるのみ |
| LATER-3 | 「§28.3 の未決事項に追加」 | §28.3 L3132-3136 の4項目に「設定値の版管理」「導出値の設定変更と過去画面の再現性」が無い |
| LATER-4 | 「§28.3 に追加」 | §28.3 L3136 は「Audit Log の保持期間」のみ。`automation_runs` / `webhook_receipts` / `jobs`（完了分）の保持期間と削除方法が無い |

**推奨** — v1 で実装するものは何も無いので、次の3行を足すだけでよい。§21.2 の `views/*` の説明に「クエリパラメータ `?cursor=` `&limit=` を v1 で確定させ、実装は全件返しでよい（後方互換の破壊を避けるため）」。§28.3 に「負荷スコアの重み・`capacity.hours_per_item` を変更したときの過去月の再現性（設定値の版管理）」と「`automation_runs` / `webhook_receipts` / `jobs`（完了分）の保持期間と削除方法。Phase 10 で決める」。**Phase 1 の完了条件には影響しない。**

---

## 3. 判定

# **B. 修正後に実装開始可能**

**Architecture の再設計は不要**である。第1回で妥当と判断した骨格（Modular Monolith / Core と Module の分離 / PostgreSQL を SoT / Outbox + Job / Recommendation を提案に留める / 段階移行）は v2 でも維持されており、BLOCKER 3件の修正はいずれも Architecture ではなく列・制約・ロール設定の追加として吸収されている。**Workspace 分離という設計書の中心的な約束は、v2 でスキーマ層・実行環境の両方で成立するようになった。** BLOCKER-1 / 2 / 3 の反映は「書いたと主張しているだけ」ではなく、本文・スキーマ表・テスト章・ADR の4層に一貫して入っている。事実誤認（HIGH-3）も実装との突き合わせで完全に一致した。

一方、Phase 1 の完了条件（unresolved BLOCKER = 0 かつ unresolved HIGH = 0）は**まだ満たしていない**。HIGH 3件はいずれも「第1回で ACCEPT した指摘の反映が途中で止まっている」類のものである。

- **R2-HIGH-1**（`generate()` の投稿担当補正の非対称性）は、§24.6 の Parity ゲートを機械的に落とす。34/50本の投稿予定日と締切が現行と一致しなくなる。
- **R2-HIGH-2**（`seeded` の扱い）は、切り替え日に「サンプルが本番になる」か「0件で本番開始」かの分岐が未決のまま残っている。Parity がこの経路を検出しないため、最終防衛線が効かない。
- **R2-HIGH-3**（`contract_version_hash` と契約有効期間）は、`service_contracts.version` がスキーマに無いため **Phase 2 の初回 migration に含める必要がある**。ここだけは後回しにできない。

MEDIUM 9件のうち **R2-MEDIUM-1 は性質が異なる。** 内容の誤りではなく、分割追記による編集の取りこぼしが7箇所（＋文書破損2箇所）残っているというもので、放置すると **MEDIUM-1 / MEDIUM-4 / HIGH-4 / HIGH-8 / HIGH-11 で潰したはずの問題が、ER 図と §5.4 を読んだ実装者の手で復活する。** ER 図はスキーマ表より読まれるため、優先度は高い。修正はすべて文言であり、実装量はゼロである。

### 実装着手の条件

**Phase 2 のスキーマ確定前に必須**
R2-HIGH-3（`service_contracts.version`）/ R2-MEDIUM-3（`period_key` NULL の部分ユニーク）/ R2-MEDIUM-6（`workflow_transitions` の `kind` 列）/ R2-MEDIUM-2（`tasks.version` の削除）/ R2-MEDIUM-4（規約の精密化）。いずれも列・インデックス・文言で、後付けは既存データの掃除を伴う。

**Phase 2 着手前に済ませるべき（文言のみ・実装量ゼロ）**
R2-MEDIUM-1（章をまたぐ矛盾7箇所と文書破損2箇所）。最も安く、最も効果が大きい。§28.1 の「12個 -> 14個」はオーナーが読む箇所なので、確認依頼を出す前に直す。

**Phase 4 / 5 着手前に必須**
R2-HIGH-1（`generate()` の補正条件）/ R2-MEDIUM-5（`assignEditors()` の手順化）/ R2-MEDIUM-8（絞り込みスコープの適用範囲）。3件とも Parity ゲートまたは Phase 完了条件に直結する。

**移行フェーズ着手前に必須**
R2-HIGH-2（`seeded` の扱いを §28 の Q に上げ、Step 2-1 の実測項目と Step 5-3 の分岐に反映する）。

**Phase 10 で対応**
R2-MEDIUM-7（ハートビート）/ R2-MEDIUM-9（Core 純度チェック）/ R2-LATER-1。

以上の修正はいずれも Architecture の変更を伴わず、合計しても設計書の文言修正と列4本・インデックス1本に収まる。**これらを反映して unresolved BLOCKER = 0 / unresolved HIGH = 0 を満たせば、Phase 2 から実装に入って差し支えない。**

---

## 付録 — 指摘ID一覧

| ID | 区分 | 章 | 要旨 | 由来 |
|---|---|---|---|---|
| R2-HIGH-1 | HIGH | §12.4 / §24.6 | `generate()` の投稿担当補正が34/50本に適用されていない事実が未記述で Parity が落ちる | 新規 |
| R2-HIGH-2 | HIGH | §24.2 / §24.4 / §28 | `seeded:true` のまま切り替えた場合の扱いが決定事項になっていない | HIGH-5 残存 |
| R2-HIGH-3 | HIGH | §12.4 / §22.3 / §6.4 | `contract_version_hash` が未定義。契約の有効期間フィルタも手順に無い | HIGH-6 残存 |
| R2-MEDIUM-1 | MEDIUM | §5.4 / §7.1 / §7.2 / §13.1 / §24.4 / §28 | 修正が波及しておらず章をまたぐ矛盾が7箇所、文書破損が2箇所 | 新規（v2 の編集起因） |
| R2-MEDIUM-2 | MEDIUM | §22.1 / §5.1 / §6.2 | `tasks.version` の存否が矛盾。`tasks.due_at` の楽観ロック根拠が未定義 | MEDIUM-4 残存 |
| R2-MEDIUM-3 | MEDIUM | §6.2 / §22.5 | `period_key` が NULL の Run に UNIQUE が効かず upsert 冪等化が成立しない | HIGH-7 残存 |
| R2-MEDIUM-4 | MEDIUM | §6.1 / §6.2 | 「全テーブルに `unique(id, workspace_id)`」が `id` を持たない4テーブルに適用できない | 新規（v2 の修正起因） |
| R2-MEDIUM-5 | MEDIUM | §12.4 / §25.1 / §24.6 | 月次生成の手順から `assignEditors()` が欠落。担当割当の仕様もテストも無い | 新規 |
| R2-MEDIUM-6 | MEDIUM | §11.3 / §6.2 | 「1段戻す」の逆向き Transition が未列挙で UNIQUE と `is_terminal` に抵触 | 新規 |
| R2-MEDIUM-7 | MEDIUM | §26.5 / §26.6 | ハートビート（外形監視）が §19.4 の1文だけで運用章に無い | MEDIUM-7 残存 |
| R2-MEDIUM-8 | MEDIUM | §10.5 / §5.5 | 絞り込みの適用範囲が `myTasks()` のみで `scopeRows()` と `:3335` が漏れ | HIGH-2 残存 |
| R2-MEDIUM-9 | MEDIUM | §7.2 / §4.2 / スクリプト | `recommendations.kind` が literal のまま。Core 純度チェックは実在しない | MEDIUM-9 残存 |
| R2-LATER-1 | LATER | §21.2 / §28.3 | LATER-1 / 3 / 4 が設計書に未反映 | LATER 残存 |
