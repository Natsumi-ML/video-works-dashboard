# SOCIAL BASE — Senior Engineer Review

| | |
|---|---|
| 対象 | `SOCIAL_BASE_SYSTEM_DESIGN.md`（v1 draft / 3,051行 / 29章） |
| 参照実装 | `ml-editing-board.html`（5,226行）※読み取りのみ |
| レビュー日 | 2026-08-29 |
| 立場 | Staff / Senior Backend & Platform Engineer（設計者とは別人） |
| 判定 | **B. 修正後に実装開始可能** |

---

## 0. 総評と読み方

設計書の骨格（Modular Monolith / Core と Module の分離 / PostgreSQL を SoT にする / Outbox + Job / 段階移行）は妥当で、**Architecture 全体の再設計は不要**と判断する。確定済み前提4点にも致命的欠陥は見つからなかった（§0.3）。

一方で、**「三重で守る」と書いてある Workspace 分離が、実際のスキーマ定義と実行環境の両方で成立していない**（BLOCKER-1 / BLOCKER-2）。また、現行実装を実際に読み合わせた結果、**§9.2 の既定 Role・§24.4 の Migration Matrix・§24.6 の Parity 基準に、事実誤認に基づく箇所が複数ある**。これらは「設計思想は正しいが、書かれている検証条件では検証にならない」類の問題で、そのまま Phase 2 に入ると Phase 3〜5 で作り直しが発生する。

指摘は BLOCKER 3件 / HIGH 11件 / MEDIUM 10件 / LATER 4件。**問題を発見できなかった領域は §0.2 に明記した。**

### 0.1 現行実装との突き合わせで確認した事実

設計書の記述を鵜呑みにせず `ml-editing-board.html` を実測した。行番号・関数名の記述は**おおむね正確**（`:1539` `:1568` `:1697` `:1725` `:1751` `:1828` `:1839` `:1846` `:1861` `:1864` `:1868` `:1873` `:1874` `:1939` `:1999` `:2167` `:2176` `:2183` `:2195` `:2213` `:2217` `:2251` `:2260` `:2353` `:2366` `:3517` `:3583` `:3910` `:3955` `:4014` `:4022` `:4363` `:4820` `:4827` `:4936` `:4942` `:4964` `:4968` `:5019` `:5081` `:5180` をすべて確認、いずれも一致）。Layer 境界（A: 1529-1874 / B: 1876-1984 / C: 1986-5226）も実際と合っている。

一方、**内容の記述には実データと食い違う箇所がある**。実測結果：

| 設計書の記述 | 実測 | 章 |
|---|---|---|
| 11社13契約 | **10社**13契約 | §2.3 / §24.4 / 文書全体の「6人・11社」前提 |
| 動画9 / 静止画4 | **動画10 / 静止画3** | §24.4 |
| なつみ9件 / りりか4件（poster） | 一致 | §24.4 |
| steps=4 → 7営業日 / steps=2 → 3営業日 | 一致（steps=4 が9契約、steps=2 が4契約） | §24.4 |
| MEMBERS 6名（社員3 / スタッフ3） | 一致 | §24.4 |
| `loadOf()` / `capacityOf()` を「メンバー6名すべて一致」で検証 | **現行画面は3名しか計算していない**（`:4156` `names=Object.keys(STAFF_MAP)`） | §24.6 |
| `STAFF_MAP` は名前→ローマ字の対応表（移行不要） | **編集担当ロスターとして16箇所で使われ、4画面と `generate()` の挙動を決めている** | §24.4 |
| `myRole()==="社員"` の判定箇所（8箇所と対応表に7箇所＋`writable()`） | 実際は8箇所。**`:3564` が対応表から欠落** | §9.3 |
| 契約本数の合計 | 50本/月 | §24.6 |

さらに、**公開版の `STATE`（`:1524`）を実際に読んだ結果**：

- 行数 **50件、すべて `2026-08`**。他の月のデータは無い。
- **`"seeded": true`** — つまり進捗ステータスと投稿完了日は**サンプルデータ**（`notices()` `:2264` が「サンプルです」と表示している状態）。
- **`clients` キーも `notes` キーも存在しない。** Drive URL・撮影日・企画ステータス・資料準備状況・定例MTG・日次メモは**1件も入っていない**。
- `trans` に**時系列として矛盾したデータが実在する**（後述 HIGH-4）。

この事実は §24 の移行計画の妥当性そのものに影響する（HIGH-5）。

### 0.2 問題を発見できなかった領域（問題なし）

以下は指摘なし。妥当と判断した。

- **§3.2 Architecture の技術選択** — Modular Monolith / Serverless API / Managed PostgreSQL / Event Sourcing 不採用 / Realtime 不採用。この規模で不要な Microservices 化は無い。Redis を入れない判断も正しい。
- **§4.1 / §4.3 Core と Module の境界の考え方** — シフトを `WorkingSchedule` として Core に置く判断、Slack を Adapter に閉じる判断、`ShiftChangeRequest` を Core の実体にして「Slack を切っても成立する」形にした点はいずれも正しい。強結合にはなっていない。
- **§4.4 資料準備フロー・月次分析を専用 Domain にしない判断** — Recurring Workflow + Automation で表現する方針は妥当（ただし実現手段に穴がある → HIGH-7）。
- **§5.3 ContentItem と Task の分離** — 1:1 運用のまま DB は分離、という判断は正しい。過剰抽象ではない。`Task.source_type` を Core が解釈しない設計も正しい（ただし整合性の担保が別途要る → HIGH-8 ではなく MEDIUM-1 で扱う）。
- **§8.3 Capability ベースの権限** — Role 名をコードに書かない方針、Capability キーを Module が登録する方針は正しい。§8.4 の判定順序も fail closed になっており、Workspace 外を 404 にする判断も正しい。
- **§18 Recommendation を提案に留める方針（P6 / ADR-016）** — `reason` 必須も含めて妥当。
- **§20.2 / §20.3 権限昇格の防止** — 「操作者が持つ Capability の範囲内でしか付与できない」「最後の `permission.manage` 保持者を降格できない」は、この種の設計でよく抜ける2点を押さえている。
- **§22.6 トランザクション境界と Outbox の同一トランザクション書き込み** — 正しい。
- **§25.3 Permission Matrix Test を「表を機械可読にしてテストを自動生成する」形にした点** — 正しい。
- **§26.4 リストアを実際に staging で試す（四半期ごと）** — 正しい。「手順書だけ作って試さない」を明示的に禁じている点を評価する。
- **§29 ADR の書式**（文脈・決定・理由・結果・変更容易度・参照）— 判断の追跡が可能。

### 0.3 確定済み前提の検証

| 前提 | 判定 |
|---|---|
| SoT = PostgreSQL、artifact は Legacy | **欠陥なし。** artifact の CSP 制約（§24.1）は事実で、この前提以外に選択肢が無い |
| Managed PostgreSQL / Serverless API / Managed Jobs | **欠陥なし。ただし RLS との組み合わせに実装上の落とし穴がある**（BLOCKER-2）。前提を覆す必要はなく、接続方式の指定を追加すれば足りる |
| 汎用 Core + 固有 Module | **欠陥なし。** ただし文書内で自分の原則を破っている箇所がある（MEDIUM-9） |
| artifact 上への先行実装禁止（二重実装禁止） | **欠陥なし。** むしろ現行 STATE がほぼ空（§0.1）である以上、この前提は一層正しい |
| UI 原則変更なし | **欠陥なし。** ただし「画素差0」の基準定義に矛盾がある（MEDIUM-8） |

---

## 1. BLOCKER

### BLOCKER-1 — Workspace 分離の「スキーマ層」防御が、権限テーブルにだけ存在しない

**1. 該当設計**
§6.1「Workspace 境界の強制」、§6.2 Core テーブル一覧（`role_capabilities` / `member_roles` / `workflow_run_transitions` / `notification_deliveries`）、§6.5「三重で守る」の 2.（スキーマ層）。

**2. 問題**
§6.1 は「子テーブルは `(id, workspace_id)` に UNIQUE を張り、親からは `(parent_id, workspace_id)` の複合外部キーで参照する」と宣言している。しかし §6.2 / §6.4 の実際のテーブル定義で `unique(id, workspace_id)` が書かれているのは `workspace_members` と `clients` の2つだけで、`tasks` / `workflow_templates` / `workflow_states` / `workflow_runs` / `roles` / `service_contracts` / `content_items` / `schedule_entries` / `recurrence_rules` には無い。**UNIQUE が無い親を複合外部キーで参照することは PostgreSQL では不可能**なので、宣言された防御はほぼ全関連で成立しない。

さらに深刻なのは、**権限の中核である `member_roles` と `role_capabilities` に `workspace_id` 列そのものが無い**ことである。

```
member_roles      : workspace_member_id, role_id            pk(workspace_member_id, role_id)
role_capabilities : role_id, capability_key, scope_type, scope_id
```

この定義では「Workspace A の Role を Workspace B の Member に付与する」行を DB が受理する。`workflow_run_transitions`（`id, run_id, ...`）と `notification_deliveries`（`id, notification_id, ...`）も同様に `workspace_id` を持たず、§6 冒頭の「すべてのテーブルは `workspace_id` を持ち」という記述と §6.2 の表が矛盾している。

**3. 発生する具体的リスク**
Phase 3 で `permission.manage` の API を実装する際、`POST /roles/:roleId/members` のハンドラで `role.workspace_id === session.workspace_id` の検証を1行落とすと、**SOCIAL BASE Workspace の `editor` メンバーに、将来作る営業部 Workspace の `owner` Role を付与できてしまう**。付与後は `hasCapability()` が `member_roles → roles → role_capabilities` を辿るだけなので、`workspace.manage` `permission.manage` `audit.read` がすべて通る。これはアプリ層の1行のバグが即座に権限昇格になるという意味であり、§6.5 が「アプリのバグで `where` が抜けても漏れない」と約束している防御が、**よりによって権限テーブルにだけ存在しない**。

RLS（§6.5 の3.）も `workspace_id` 列が無いテーブルには書けないため、第3防御も同時に効かない。つまり権限テーブルは**一重防御**である。

**4. 推奨変更**
- §6.2 / §6.4 の全テーブルに `unique(id, workspace_id)` を明記し、すべての親子参照を複合外部キーにする。§6.1 の宣言を「例」ではなく規約として全テーブルに適用したことをスキーマで示す。
- `member_roles` / `role_capabilities` / `workflow_run_transitions` / `notification_deliveries` に `workspace_id not null` を追加し、複合外部キーで親と workspace を一致させる。

```sql
alter table roles add constraint roles_id_ws_uq unique (id, workspace_id);
alter table member_roles add column workspace_id uuid not null;
alter table member_roles add constraint member_roles_role_fk
  foreign key (role_id, workspace_id) references roles (id, workspace_id);
alter table member_roles add constraint member_roles_member_fk
  foreign key (workspace_member_id, workspace_id)
  references workspace_members (id, workspace_id);
```

- §6 冒頭の「すべてのテーブルは `workspace_id` を持つ」を、**例外を明示した表**に置き換える（正当な例外は `users` / `webhook_receipts` のみ。この2つが例外である理由も書く）。

**5. 過剰設計にならない最小修正**
新テーブルも新概念も不要。**`workspace_id` 列4本の追加と、`unique(id, workspace_id)` を全テーブルへ機械的に付与するだけ**。Phase 2 の初回 migration に含めれば追加コストはほぼゼロで、後付けは全外部キーの張り直しになるため必ず最初に入れる。§25.2 の DB Integration Test に「別 Workspace の Role を付与する INSERT が拒否される」を1件追加する。

---

### BLOCKER-2 — Serverless + Managed PostgreSQL 構成では §6.5 の RLS が機能しない（あるいは逆に漏れる）

**1. 該当設計**
§6.5「3. DB層（Defense in Depth）— PostgreSQL Row Level Security を有効化し、セッション変数の `workspace_id` で絞る」、§26.1（Serverless HTTP / Managed PostgreSQL）、ADR-019、§25.2（RLS のテスト）。

**2. 問題**
RLS を「有効化して session 変数で絞る」としか書いておらず、実際に機能させるために必須の3点が欠落している。

**(a) テーブル所有者は RLS をバイパスする。** migration を実行するロールがテーブル所有者になり、アプリが同じロールで接続すると、`enable row level security` を付けても**ポリシーは一切適用されない**。`force row level security` を付けるか、アプリ用の非所有者ロールを分けるか、どちらかの明記が要る。これは RLS が「入れたつもりで何もしていない」状態になる最頻の原因で、しかも**テストでも本番でも無症状**（全行見えるのが正常に見えてしまう）。

**(b) Serverless では接続プーラを挟むのが前提だが、`SET` と `SET LOCAL` の区別が書かれていない。** Neon / Supabase / RDS Proxy / PgBouncer の transaction pooling モードでは、1つの物理接続が複数リクエストに使い回される。`SET app.workspace_id = ...`（session レベル）を使うと**設定が次のリクエストへ持ち越され、別ユーザーのリクエストが前のリクエストの `workspace_id` を継承する**。これは Workspace 分離の完全な破綻である。

**(c) Query Service が明示トランザクションを張らない。** §21.1 は「Query Service は読み取り専用」としか書いていない。`SET LOCAL` はトランザクション内でしか効かないため、Read Model のクエリを autocommit で投げると GUC が未設定になる。`current_setting('app.workspace_id')` は未設定時に例外を投げ、`current_setting(..., true)` は NULL を返す。前者なら全画面が 500、後者なら全画面が0件になる。どちらも fail closed ではあるが、**Phase 4 の Vertical Slice が通らない**。

**3. 発生する具体的リスク**
最悪ケースは (b)。将来 SOCIAL BASE Workspace と営業部 Workspace が同居した状態で、なつみのリクエストが処理された直後の同一物理接続で営業部メンバーのリクエストが処理されると、**営業部のユーザーが SOCIAL BASE のクライアント一覧・契約金額に相当する情報を、正常なレスポンスとして受け取る**。アプリ層は `workspace_id` を正しく渡しているので、ログにも異常は残らない。

(a) 単独では、RLS があると信じてアプリ層のレビューが甘くなり、実際には一重防御のまま運用に入る。§25.2 の「RLS が有効な接続で他 Workspace の行が見えないこと」というテストは、**テストが直接接続を使い本番がプーラを使う限り、(b) を一切検出しない**。

**4. 推奨変更**
§6.5 に「RLS 運用規約」として次を明記する。

- migration 用ロール（所有者）とアプリ用ロール（非所有者、`bypassrls` なし）を分ける。全 RLS 対象テーブルに `alter table ... force row level security` を付ける。
- **すべての DB アクセス（読み取りを含む）を明示トランザクションで包み、その先頭で `set local app.workspace_id`／`set local app.member_id` を発行する。** `set`（LOCAL なし）の使用をコードレビューと lint で禁止する。
- ポリシーは `using (workspace_id = nullif(current_setting('app.workspace_id', true), '')::uuid)` の形にし、**未設定時は0行**になるようにする（例外ではなく0行にして、fail closed かつ 500 にしない）。
- §25.2 のテストを「**本番と同じプーラ構成を通して**、リクエスト A の直後にリクエスト B を同一物理接続で実行し、B が A の workspace を継承しないこと」に変更する。これが (b) を検出する唯一のテストである。
- §26.1 に「採用するホスティングの接続プーリングモード（session / transaction）」を決定事項として追記する。

**5. 過剰設計にならない最小修正**
実装物は増えない。**Repository の基底に「トランザクション開始 → `set local` → クエリ → commit」を1箇所だけ実装し、そこ以外から接続を取らせない**だけで (b)(c) は同時に解決する。(a) はロール分離1回と `force row level security` の1行/テーブル。合計の実装量は半日程度で、後から入れると §6.5 が言うとおり全クエリの再検証になる。

---

### BLOCKER-3 — Identity を email だけで束ねており、OIDC の subject を保存していない

**1. 該当設計**
§8.2「Identity（Google Workspace アカウントによる OAuth ログイン / OIDC）」、§6.2 `users`（`id, email, display_name, avatar_url, status, last_login_at`）、ADR-004。

**2. 問題**
`users` に **OIDC の `sub`（Google のアカウント一意ID）を保存する列が無い**。§8.2 は「`User.email` のドメインで許可を絞る」としか書いておらず、ログイン時のユーザー同定が email に依存する設計になっている。email は Google Workspace 側で**再割り当て可能な可変の識別子**であり、`sub` は不変である。OIDC で email をプライマリキーにするのは既知のアンチパターンで、Google 自身も `sub` での同定を明示的に要求している。

**3. 発生する具体的リスク**
具体的に、次の入力で壊れる。

1. 友美（`tomomi@example.co.jp`、Role = `internal`）が退職する。§8.2 の推奨どおり Google アカウントを停止する。
2. 数か月後、同姓・同役職の新入社員に情シスが `tomomi@example.co.jp` を再発行する（日本企業では珍しくない。`info@` `sales@` のような役割アドレスなら日常的に起こる）。
3. 新入社員が初回ログインする。SOCIAL BASE は email で `users` を引き当て、**友美の `User` にそのままログインさせる**。

結果として、新入社員は友美の `WorkspaceMember`・`MemberRole`（`internal`）・`task_assignments` をすべて引き継ぐ。§19 の Audit Log は「友美が操作した」と記録し続けるため、**§19 の「誰がいつ何をどう変えたか」という要件そのものが偽になる**。招待制（`WorkspaceMember` が無ければ入れない）は、この経路では防御にならない — `WorkspaceMember` は既に存在するからである。

副次的に、姓名変更によるアドレス変更（`kato@` → `natsumi.kato@`）で、同一人物が**別ユーザーとして重複作成**され、担当と監査履歴が分断される。

**4. 推奨変更**
- `users` に `external_subject text` と `identity_provider text` を追加し、`unique(identity_provider, external_subject)` を張る。**ログイン時の同定は `sub` で行い、email は表示と招待の照合にのみ使う。**
- email はログインのたびに `sub` を鍵として上書きする（アドレス変更に自動追随する）。
- 招待フローは「email で招待 → 初回ログイン時に `sub` を束ねる（claim）→ 以後 `sub` が正」とする。まだ `sub` が束ねられていない招待レコードにだけ email 一致を許す。
- §20.1 の表に「Identity binding: OIDC `sub`。email は識別子として使わない」を追加する。
- §25.3 に「同じ email・異なる `sub` でのログインが既存 User に入れないこと」を1ケース追加する。

**5. 過剰設計にならない最小修正**
**列2本と UNIQUE 制約1本、そしてログインハンドラの検索キーを1箇所変えるだけ。** Phase 3 の初日に入れれば追加コストはゼロ。後から入れる場合は全ユーザーの再ログインによる `sub` の backfill が必要で、その間は両方式の併存という最も危険な状態になる。

---

## 2. HIGH

### HIGH-1 — §9.2 の既定 Role が現行挙動を再現しておらず、§9.3 の対応表にも誤りと欠落がある

**1. 該当設計**
§9.2「v1 の既定 Role」の `editor` 列、§9.3「現行の判定との対応」。

**2. 問題**
現行実装で `myRole()==="社員"` による分岐は**8箇所しかない**（`:2176` `:2353` `:2366` `:3517` `:3564` `:4014` `:4820` `:5081`）。それ以外の書き込み操作はすべて `writable()`（`:2195`）だけで守られており、**スタッフも実行できる**。実測すると次の食い違いがある。

| 操作 | 現行の実装 | §9.2 の `editor` | 判定 |
|---|---|---|---|
| 動画追加（`openAddVideo` `:4857`。ボタンは `:2328` / `:2490` で `writable()` のみ） | **全員可** | `task.create` = — | **不一致** |
| 担当編集者の変更（`:3012` `disabled:!writable()` のみ） | **全員可** | `task.assign` = — | **不一致** |
| 投稿予定日 / 締切の変更（`:4667` などの日付入力、`writable()` のみ） | **全員可** | `schedule.manage` = — | **不一致** |
| 翌月を生成（`:2366`） | 社員のみ | `content.generate` = — | 一致 |
| クライアント管理画面（`:2176` `:5081`） | 社員のみ | `client.read` = — | 一致 |
| 負荷調整提案の実行（`:4014`） | 社員のみ | `recommendation.decide` = — | 一致 |
| 工程の進行・1段戻す（`:3639` `:3039` `:4937`） | 全員可 | `workflow.transition` = ○ | 一致 |

さらに §9.3 の対応表には次の誤りがある。

- **`:3564` が対応表から欠落している。** ここは「今日」画面 KPI の内訳行（Drive未設定 / タイトル未入力）を社員のみに出す分岐で、`:3517` の `todayReview()` とは別の描画箇所。移行時に片方だけ Capability 化すると、KPI の数字と内訳が食い違う。
- **「今日画面の要確認（Drive未設定・タイトル未入力）」を `client.manage` / `content.update` に対応付けているのが誤り。** §9.2 では `content.update` を `editor` にも与えているため、この対応表どおりに実装すると**スタッフの「今日」画面に「タイトル未入力 N本」が出るようになる**。現行は出ない。ここは「書き込み権限」ではなく「社員が対応する項目かどうか」の表示制御なので、`client.read` 相当（あるいは専用の `content.review.internal`）に対応付けるべきである。

**3. 発生する具体的リスク**
Phase 3 の完了条件は「現行の `visibleViews()` / `writable()` と**同じ画面が出る**」であり、Phase 4 は「Visual Regression で画素差0」である。上表の3件の不一致により、**りりか（スタッフ）でログインした瞬間に、トップバーの「動画追加」ボタンが消え、詳細パネルの「担当編集者」セレクトが disabled になり、日付が編集不可になる**。これは Phase 3 / Phase 4 の完了条件を機械的に満たせないという意味であり、実装が終わってから「仕様が違う」と判明する。

逆方向のリスクもある。「今日」画面の要確認が `content.update` にひもづくと、スタッフに社員向けの督促項目が表示され、UI 仕様（2026-08-28 指示：「Drive未設定・タイトル未入力はスタッフには出さない」）に反する。

**4. 推奨変更**
- §9.2 の `editor` 列で `task.create` / `task.assign` / `schedule.manage` を ○ にする（＝現行どおり）。移行時に挙動を変えたいなら、それは §28 の Q として**オーナー判断に上げる**（Q3「承認をスタッフもできるままにするか」と同じ扱い）。設計者が黙って絞るべきではない。
- §9.3 の対応表に `:3564` を追加する。
- 「今日画面の要確認」の対応先を `content.update` から外し、表示制御用の Capability（`client.read` の流用、または `content.review.internal` の新設）に変更する。
- **§9.3 の対応表を「現行の分岐箇所を全部列挙した表」にする。** 現行の分岐は `myRole()` 8箇所 + `writable()` の2種類しかないので、全列挙は現実的で、これが Permission Matrix Test（§25.3）の入力になる。

**5. 過剰設計にならない最小修正**
Capability を増やさず、**§9.2 の表の ○ を3つ足し、§9.3 に1行足し、対応先を1つ差し替える**だけ。新設するなら `content.review.internal` の1キーのみ。「移行時は現行と完全に同じ、変更は運用開始後に画面から」という §9 の方針をそのまま適用すればよい。

---

### HIGH-2 — `STAFF_MAP` を「破棄」としているが、実際には編集担当ロスターであり、4画面と `generate()` の挙動を決めている

**1. 該当設計**
§24.4 マスターデータ表の `STAFF_MAP` 行（`:1861`、Method **E: 破棄**、理由「名前→ローマ字の対応表。移行後は `workspace_member_id` で直接ひもづくため不要」）、§8.1 の対応表（`STAFF_MAP` のローマ字名 → 廃止）。

**2. 問題**
`STAFF_MAP = {"りりか":"Ririka","ゆかり":"Yukari","つかさ":"Tukasa"}` は確かにローマ字対応表だが、**その `Object.keys()` が「編集担当になれる人の一覧」として16箇所で使われている**。実測した使用箇所：

| 行 | 用途 | 破棄した場合の影響 |
|---|---|---|
| `:2219` | `myTasks()` の絞り込み条件（`STAFF_MAP[ME]` のときだけ自分の担当に絞る） | ホーム/今日の「自分のタスク」の中身が変わる |
| `:3014` `:4875` | 担当編集者セレクトの選択肢（`[""] + 3名`） | 選択肢に社員3名が現れる |
| `:3066` | 「今日」画面の `scopeRows()` の絞り込み | 表示件数が変わる |
| `:3272` `:3335` | 動画一覧の担当者フィルタと「自分の担当」 | フィルタの選択肢と結果が変わる |
| `:3893` | `axisDays()` → `closedDays(SEED_SHIFTS, MONTH, STAFF_MAP)` | **投稿カレンダーの営業日軸が変わる** |
| `:4051` `:4104` `:4156` | チーム負荷画面のメンバー一覧と `capacityOf()` | **3名 → 6名になる** |
| `:4230` `:4446` `:4470` | カレンダー / クライアント管理のフィルタ選択肢 | 選択肢が変わる |
| `:4986` `:4992` `:4993` | `generate()` の `staff` 引数と `caps`（`assignEditors` の入力） | **翌月生成の担当割当と投稿日配置が変わる** |

とくに `generate()` では `cfg.staff[poster]` の有無で「投稿担当の非稼働日から前後へ寄せる」補正（`:1719-1721`）が入るかどうかが決まる。現行では poster が **なつみ（社員、`STAFF_MAP` に無い）の9契約は補正なし**、りりか（`STAFF_MAP` にある）の4契約だけ補正あり、という非対称な挙動になっている。

**3. 発生する具体的リスク**
`STAFF_MAP` を捨て、`workspace_members` 6名全員を「担当になれる人」として扱うと、次が同時に起きる。

- **チーム負荷画面が3名から6名に増える。** なつみ・友美・翔平の行が追加され、`working_schedules` が無いので `cap = 0`、`loadOf()` は担当行が無いので `score = 0` → 全員「余裕あり」。KPI「低負荷メンバー」が0人から3人に跳ね上がる。§24.6 の Parity「`loadOf()` の score / band 6名すべて一致」は**そもそも現行に6名分の値が存在しない**ため検証不能。
- **投稿カレンダーの営業日軸が変わる可能性がある。** `closedDays()` は「シフトが1件もない平日が3日以上連続した区間」を休業と推定する（`:1751`）。対象を6名に広げると `open` 集合が変わり、推定される休業日が変わる。§12.2 は「推定をやめて `business_calendar` を正とする」としているが、**移行時の初期値をどう作るかは「推定結果を候補として提示」（Method B）**なので、誰の勤務を入力するかで初期の営業日が変わる。
- **`generate()` の結果が変わる。** なつみに `working_schedules` を入れた瞬間、9契約すべてに投稿日の寄せ補正がかかり、投稿予定日が現行と一致しなくなる。§24.6 の「`generate()` 同じ入力で同じ配置になる」が成立しない。
- **`myTasks()` の絞り込み規則が消える。** §10.5 は「`task.read.all` を持つ → 全件 / 持たない → 自分が assignee のみ」に置き換えると書き、「§9.2 では `editor` にも `task.read.all` を与えているため現行と同じく全件が見える」と結論している。**これは誤り** — 現行は `STAFF_MAP[ME]` が真なら（＝スタッフなら）自分の担当に絞る。`task.read.all` にひもづけると、りりかのホーム画面が自分の担当だけから月内50件全部に変わる。

**4. 推奨変更**
- **§24.4 の `STAFF_MAP` を Method E から C（サーバー側 seed）に変更する。** 移行先は「Workspace 内で編集担当として割り当て可能なメンバー」を表す概念で、Core に既にある `Role`（`editor`）で表現できる。すなわち `MemberRole` で `editor` Role を持つメンバー＝担当候補、とする。
- 担当セレクトの選択肢、チーム負荷の対象、`myTasks()` の絞り込み、`generate()` の `caps` の入力を、すべて**「`editor` Role を持つ Member」**という単一の定義に統一する。現行の3名がそのまま `editor` Role を持ち、社員3名は持たない構成にすれば挙動が一致する。
  - 注意：§24.4 は `MEMBERS[].role` を「社員3名 → `internal`、スタッフ3名 → `editor`」と対応付けている。この対応をそのまま使えば `editor` Role 保持者はちょうど3名になり、`STAFF_MAP` と一致する。**つまり修正は「`STAFF_MAP` の移行先は `editor` Role である」と書き足すだけで済む。**
- §10.5 の「`task.read.all` で myTasks の絞り込みを表現する」という記述を撤回し、**「MyTasks は `editor` Role 保持者に対してのみ assignee 絞り込みを行う」**と明記する。§10.5 自身が「絞り込みであって権限ではない。ここを混同しない」と書いている以上、絞り込み条件を権限に載せてはいけない。
- §24.6 の「メンバー6名すべて一致」を「`editor` Role 保持者3名（りりか / ゆかり / つかさ）で一致」に修正する。

**5. 過剰設計にならない最小修正**
新テーブル・新概念は不要。**§24.4 の1行を E → C に変え、移行先を「`editor` Role」と書く。§10.5 の1段落を書き換える。§24.6 の「6名」を「3名」に直す。** 実装側は「担当候補メンバーを引く」クエリを1本に集約するだけ。

---

### HIGH-3 — Migration Matrix / Parity の期待値に事実誤認があり、ゲートとして機能しない

**1. 該当設計**
§2.3（`SEED_CONTRACTS` = 「11社13契約」）、§24.4 マスターデータ表の検証列、§24.6「件数の一致」「計算結果の一致」、および文書全体で繰り返される「6人・11社」という規模前提。

**2. 問題**
実測との突き合わせで、Parity の期待値として書かれている数値が誤っている。

| §24.4 / §24.6 の期待値 | 実測 |
|---|---|
| 「11社が登録され `name` が一致」 | **10社**（NCN / SBSネクサード / 木下テーブルテニスクラブ / グレースホールディングス / 柿本商会 / 茨城交通 / アシストタクシー / ヒロダクト工業 / メトロ自動車 / なの花交通バス） |
| 「動画9 / 静止画4」 | **動画10 / 静止画3** |
| 「クライアント別の件数：11社それぞれ一致」 | 10社 |
| 「`loadOf()` の score / band：メンバー6名すべて一致」 | 現行画面は3名分しか計算していない（HIGH-2） |
| 「`capacityOf()` の cap：メンバー6名すべて一致」 | `SEED_SHIFTS` は3名分しか無い。社員3名は `capacityOf(shifts, undefined, ym)` で `{days:0, hours:0, cap:0}` |

「13契約」「なつみ9件 / りりか4件」「steps=4 → 7営業日 / steps=2 → 3営業日」「MEMBERS 6名」は正しい。

**3. 発生する具体的リスク**
§24.6 は「**1件でも差分があれば Write 移行に進まない**」という強いゲートである。ここに誤った期待値が入っていると、次のどちらかが起きる。

- 期待値どおりに実装しようとして、存在しない11社目を探す・静止画契約を1件でっち上げる、といった無駄と混乱が生じる。
- あるいは「表が間違っていた」と判断して**表全体の信頼が落ち、ゲートが形骸化する**。移行の最終防衛線が「だいたい合っている」で通過するようになる。後者のほうが実害が大きい。

また「6人・11社」は §1.2 / §3.2 / ADR-002 で規模判断の根拠として使われている。10社と11社で技術判断は変わらないが、**設計書が現行を正確に把握しているかの信頼性**に直結する。

**4. 推奨変更**
- §2.3 / §24.4 / §24.6 / 規模記述の「11社」を **10社**に修正する。
- 「動画9 / 静止画4」を **「動画10 / 静止画3」**に修正する。
- 「メンバー6名すべて一致」を **「`editor` Role 保持者3名で一致」**に修正する（HIGH-2 と同じ修正）。
- **§24.6 の期待値をハードコードした数値ではなく、「移行元から機械的に算出した値と一致すること」に変える。** 具体的には、抽出した `STATE` と現行の定数から期待値 JSON を生成するスクリプトを移行リポジトリに置き、Parity テストはその JSON と新環境の Read Model を突き合わせる。人が数えた数字を仕様書に書かない。

**5. 過剰設計にならない最小修正**
数値の訂正は5箇所。**期待値生成スクリプトは、`ml-editing-board.html` から `SEED_CONTRACTS` と `<script id="state">` を読んで集計する 50行程度の Node スクリプト1本**で足りる（§25.1 の「現行 JS の出力を期待値として使う」という方針と同じ手段なので、追加コストはほぼゼロ）。

---

### HIGH-4 — `rows[].trans{}` を遷移履歴に展開する移行方式は、実データ上で成立しない（虚偽の監査履歴を作る）

**1. 該当設計**
§24.4 運用データ表：`rows[].trans{}` → `workflow_run_transitions`（Method **D**、検証「遷移時刻を履歴行に展開。actor は不明として `null`」）、§19.3、R3。

**2. 問題**
`applyOp()` の実装（`:1831`）は `r.trans[op.payload.to] = op.at` である。つまり `trans` は「**到達したステータス → 最後にそこへ到達した時刻**」のマップであって、遷移の列ではない。同じステータスに複数回入っても1件しか残らず、**遷移元（`from_state`）は一切記録されない**。

「1段戻す」（`PREV_STATUS` `:1553`、UI は `:3039`）も同じ経路を通るため、巻き戻した先の時刻で上書きされる。結果として、**タイムスタンプの大小関係が実際の進行順と一致しない行が実在する**。公開版 `STATE`（`:1524`）から実際の3件：

| id | `status` | `trans` |
|---|---|---|
| `r-2026-08-NCN-4` | **未着手** | 投稿済み:1787270400000 / 投稿待ち:…140152 / 確認中:…163662 / 編集中:…165113 / 未着手:…170740 |
| `r-2026-08-木下テーブルテニスクラブ-16` | **投稿待ち** | 投稿待ち:1787745043484 / **投稿済み:1787745039412**（投稿済みのほうが早い） |
| `r-2026-08-茨城交通-32` | **確認中** | 確認中:1787785426947 / **投稿待ち:1787785424997** |

**3. 発生する具体的リスク**
`trans` を時刻順に並べて `workflow_run_transitions` を作ると、`r-2026-08-木下テーブルテニスクラブ-16` について「**投稿済みになった 4 ミリ秒後に投稿待ちへ進んだ**」という、Workflow 定義上ありえない遷移が保存される。`r-2026-08-NCN-4` は「投稿済み → 投稿待ち → 確認中 → 編集中 → 未着手」という、実際に起きた操作（巻き戻し）とは異なる形の履歴になる。

さらに `from_state_id` と `transition_id` は §6.2 で NOT NULL 相当の位置づけ（遷移を一意に指す列）なので、**復元不能な値を推測で埋めることになる**。§19 の売り文句は「なぜこの動画が投稿待ちに戻っているのかを後から確認できる」だが、移行直後の履歴はそれに答えられないどころか**誤った答えを返す**。R3 は「actor が復元できない」ことだけを受容リスクとしており、**遷移の順序と from が復元できないことには触れていない**。

なお §11.5 の規則3「現在どれかの Run が滞在している State は archive できない」との相互作用もある。捏造された履歴が存在する State は、実際には誰も通っていなくても履歴上は使用中に見える。

**4. 推奨変更**
- **`trans` を遷移履歴に展開しない。** `workflow_run_transitions` には「移行によって現在の State に設定された」という**1件だけ**を作る（`from_state_id = null`、`transition_id = null`、`actor_member_id = null`、`note = '移行時点の状態。移行前の遷移履歴は復元できない'`）。
- 元の `trans` マップは **`workflow_runs.legacy_transitions jsonb`**（または `content_items` の移行専用列）にそのまま退避する。参考情報としては価値があるので捨てない。UI の「工程履歴」（`timeline()` `:3016`）は移行前分をこの jsonb から**「参考（移行前）」と明示して**描画する。
- §24.4 の Method を D から **A + 注記**に変え、検証列を「行数一致」ではなく「`current_state_id` が `rows[].status` と一致」に変える。
- R3 を「操作者が復元できない」から「**移行前の遷移履歴（順序・遷移元・操作者）は復元できない。移行時点の状態のみを引き継ぐ**」に書き直す。

**5. 過剰設計にならない最小修正**
新テーブル不要。**`workflow_runs` に `legacy_transitions jsonb` を1列足し、import スクリプトの当該分岐を「1件だけ INSERT」に変える**だけ。UI 側は既存の `timeline()` に「移行前」ラベル付きの分岐を1つ足すか、あるいは何も出さない（現行の 2026-08 は §0.1 のとおりサンプルデータなので、実務上の損失はほぼ無い）。

---

### HIGH-5 — 現行 `STATE` はほぼ空のサンプルデータであり、§24 の移行計画がその前提を反映していない

**1. 該当設計**
§24.2「移行の順序」Step 0〜7、§24.4 運用データ表（`clients[].material` / `review` / `nextShootDate` / `planningDeadline` / `planningStatus` / `nextRegularMeeting` / `materialStatus` / `notes{}` をすべて **Method A: JSON抽出→変換import**）、§24.6 Parity、§24.7 Rollback。

**2. 問題**
公開版 `STATE`（`ml-editing-board.html:1524`）を実際に読むと、次のとおりである。

```
{"version":1, "seeded":true, "rows":[ 50件・すべて 2026-08 ], "months":{}, "maintenance":false, "lastUpdated":"2026-08-26T23:03:47.835Z"}
```

- **`clients` キーが存在しない。** Drive URL（material / review）、次回撮影日、企画期限、企画ステータス、定例MTG、資料準備状況は**1件も入力されていない**。`migrateState()`（`:1919`）が読み込み時に `st.clients = {}` を作っているだけである。
- **`notes` キーも存在しない。** 日次メモは0件。§24.5 でわざわざ `daily_notes` テーブルを新設する対象データが、現時点で0件。
- **`"seeded": true`。** これは `notices()`（`:2264`）が「表示中の 2026-08 分の**進捗ステータスと投稿完了日はサンプルです**」と表示している状態を意味する。つまり `rows[].status` / `postedAt` / `trans` / `actor` は実運用の記録ではない。実データなのは「クライアントごとの本数とシフト」だけ、と現行 UI 自身が宣言している。
- `rows` は 50件、2026-08 のみ。契約の月間合計（50本）と一致しており、`generate()` の初期出力そのものである。

**3. 発生する具体的リスク**
- **§24.6 の Parity が「サンプル対サンプル」の照合になる。** 「ステータス別の件数が一致」「投稿済みの件数と `published_at` が一致」を通しても、実運用データの正しさは一切保証されない。移行の最終防衛線が空振りする。
- **§24.4 の client 系9行が全部「0件の移行」になる。** 「URL が一致」「設定済みの件数が一致」という検証は、0 = 0 で自動的に通る。実際にはこれらは**移行ではなく初期入力（Method B）**であり、誰が・いつ・どこから10社分の Drive URL や定例MTG日を集めるかという作業が計画に存在しない。Phase 5 / Phase 7 の完了条件（「Drive 未接続の検知」「定例MTGが取り込まれる」）が、入力データ無しで評価不能になる。
- **`seeded:true` のまま移行すると、サンプルの進捗が本番 DB の初期状態になる。** 逆に、移行前に「サンプルを削除」（`:2285`）を押すと **`STATE.rows` から当月分が全削除される**（`STATE.rows.filter(r.month !== monthOf(TODAY))`）。どちらを選ぶかが計画に書かれていない。押した後に移行すると `content_items` が0件になり、押さずに移行するとサンプルが本番になる。
- **§24.2 の6ステップ + 2週間の並行稼働は、この規模のデータに対して過大である。** 50行のサンプル・0件のマスターに対して「Read 並行稼働 → Parity → 金曜夜カットオーバー → 2週間の参照系保持」を敷くのは、リスクに見合わない運用コストであり、かつ Step 3〜4 の期間中に artifact 側で書き込みが続くことで別の問題（HIGH-12）を生む。

**4. 推奨変更**
- **§24 の冒頭に「移行対象データの実測」節を追加する。** 上記の実測結果（50行 / 2026-08 のみ / `seeded:true` / `clients` `notes` 不在）を明記し、そこから移行方式を導く。
- `clients[].*` の9行を **Method A → B（手入力で初期投入）**に変更し、§28 に「10社分の Drive URL・定例MTG・撮影日を誰がいつ用意するか」を Q として追加する。
- **`seeded` の扱いを決定事項にする。** 推奨は「カットオーバー時点で実運用の進捗が入っていれば `unseed` 済みの実データを移行、まだサンプルのままなら `content_items` は `generate()` で新規生成し、`rows` は移行しない」。どちらにせよ §28 の Q として明示する（オーナー判断が要る）。
- **移行手順を実データ量に合わせて簡素化する。** `clients` / `notes` が0件、`rows` がサンプルなら、Step 3（Read 並行稼働）と Step 6（2週間の参照系保持）は不要になる可能性が高い。「実運用の進捗が入っている場合は §24.2 の6ステップ、サンプルのままなら Step 1 → Step 5（新規生成でカットオーバー）」の2分岐にする。

**5. 過剰設計にならない最小修正**
実装は増えず、**むしろ減る**。§24 に実測節を1つ足し、Method 列を9行 A → B に変え、`seeded` の扱いを §28 の Q として1行足し、移行手順に「サンプルのままの場合」の短縮ルートを1段落追記する。移行スクリプトは `rows` と設定値だけを扱えばよくなる。

---

### HIGH-6 — 月次生成が ServiceContract を一級市民として扱っておらず、マスターが編集可能になった瞬間に無音のデータ欠落が起きる

**1. 該当設計**
§12.4「月次生成」（「現行 `generate()` + `merge()` をサーバー側 Command として移植する。**処理内容は変えない**」）、§5.2 `ServiceContract`、§22.3（`idempotency_key = workspace_id + target_month + contract_version_hash`）、§27 Phase 5 の完了条件（「新規クライアント1社を画面から追加でき、翌月生成に反映される」）、ADR-010。

**2. 問題**
現行 `generate()`（`:1697`）は契約単位ではなく**クライアント単位**で処理し、種別ごとに**先頭の契約1件しか見ない**。

```js
:1706  Object.keys(byClient).forEach(function(client){
:1708    var v = cs.filter(function(c){return c.kind==="動画"})[0];   // 先頭1件のみ
:1709    var s = cs.filter(function(c){return c.kind==="静止画"})[0]; // 先頭1件のみ
:1710    var nv = v?v.count:0, ns = s?s.count:0;
:1713    var poster = (v||s).poster;                                   // 先頭契約の poster のみ
```

現行の `SEED_CONTRACTS` では「1クライアント × 1種別 = 最大1契約」なので顕在化していない。しかし `merge()`（`:5019`）は **`SEED_CONTRACTS.forEach`** で契約単位に回るため、`plan` に存在しない契約に対しては `fresh = []` かつ `over = 0 - count < 0` となり、**overflow にも計上されず、行も作られない**。つまり無音で欠落する。

加えて2点。

- **`ServiceContract.starts_on` / `ends_on` を `generate()` が参照する記述がどこにも無い。** §12.4 の手順1〜6にも、§5.2 のフィールド説明にも無い。終了した契約が翌月も生成され続ける。
- **`contract_version_hash`（§22.3）の定義が無い。** `service_contracts` には `version` も `updated_at` も §6.4 の列一覧に無い（`version` は §6.1 で「更新競合を扱うテーブル」に付けるとあるが、`service_contracts` が対象かは不明）。何をハッシュするかが決まらないと冪等キーが作れない。

**3. 発生する具体的リスク**
Phase 5 の完了条件そのものが壊れる。具体的な入力：

1. なつみが「クライアント管理」で NCN に **2本目の動画契約**（例：ショート動画 月4本、別の投稿担当）を追加する。UI 上は正常に登録される。
2. 翌月生成を押す。`generate()` は NCN の動画契約の**先頭1件（月6本）しか見ない**ため、6本だけ生成する。
3. `merge()` は2本目の契約について `need = 4 - 0 = 4` を求めるが、`plan` に該当 `contractId` の行が無いので `fresh` は空。**何も追加されず、警告も出ない。**
4. クライアント管理画面の「目標」は `clientAgg()`（`:4366`）が全契約の `count` を合計するので **10本**と表示される。実際の行は6本。「4本足りない」状態が、原因不明のまま毎月続く。

契約終了日を見ない件では、「アシストタクシーとの契約が 2026-10 で終了」と登録しても 2026-11 分が生成され、担当者に存在しない仕事が割り当てられる。

**4. 推奨変更**
- **§12.4 の「処理内容は変えない」を撤回する。** 移植時に `generate()` を**契約単位のループ**へ書き換える。

```
for contract in service_contracts where status=active
                                    and starts_on <= 月末 and (ends_on is null or ends_on >= 月初):
    dates = distribute(bizDays, contract.monthly_count, phaseOf(位相キー))
    poster = contract.default_publisher_member_id
    ...
```

  クライアント単位の `interleave(動画n, 静止画m)` は「同一クライアントの投稿を種別混在で均等に散らす」ための処理なので、**クライアント単位の日付割り当て → 契約単位の本数配分**という2段構成にする。
- **`phaseOf()` の入力キーを明示的に固定する。** 現行は `phaseOf(client)` にクライアント**名の文字列**を渡している（`:1634` は `charCodeAt` の 31進ハッシュ）。移行後に `client_id`（UUID）を渡すと位相が変わり、投稿日の配置が丸ごと変わる。§24.6 の「`generate()` 同じ入力で同じ配置になる（`phaseOf` の決定性を確認）」を満たすには、**`clients.legacy_key`（＝現行のクライアント名）を位相キーとして使う**ことを設計書に書く必要がある。新規クライアントは名前を使えばよい。
- **`service_contracts` に `version integer` を追加**し、`contract_version_hash` を「対象月に有効な契約行の `(id, monthly_count, kind, lead_time_business_days, default_publisher_member_id, version)` を id 順に連結したハッシュ」と定義する。
- §12.4 の手順に「0. 対象月に有効な契約を `starts_on` / `ends_on` / `status` で絞る」を追加する。
- `merge()` 側で「`plan` に行が無い有効契約」を検出したら **overflow と同様に人に見える形で返す**（無音にしない）。

**5. 過剰設計にならない最小修正**
`ServiceContract` の履歴管理（temporal table）までは要らない。**`starts_on` / `ends_on` は既に §5.2 / §6.4 に存在するので、`generate()` の WHERE 句に足すだけ。** ループを client 単位から contract 単位に変えるのは移植時の作業であり、後から直すより安い。`version` 列1本と、`phaseOf` のキーを `legacy_key` にする明記。合計で設計書に3段落、実装で数十行。

---

### HIGH-7 — `workflow_runs` に期間キーが無く、「クライアント単位・月次の WorkflowRun」を一意に特定できない

**1. 該当設計**
§11.6「資料準備フロー / 企画ステータス」（「Client ごとに月次で `WorkflowRun` を生成する（`subject_type = client`）」「過去の月の状態が残るようになる」）、§6.2 `workflow_runs`（`id, workspace_id, template_id, current_state_id, subject_type, subject_id, started_at, completed_at, version` / `index(workspace_id, subject_type, subject_id)`）、§24.4（`clients[].materialStatus` → `workflow_runs`、「**当月の Run として作る**」）、§4.4。

**2. 問題**
`workflow_runs` に**期間（対象月）を表す列が無い**。`subject_type = client` / `subject_id = client_id` だけでは、同じクライアントの資料準備フローが月ごとに複数存在したときに**どれが当月の Run かを DB 上で特定できない**。`started_at` の年月から推測するしかないが、これは「9月分の資料準備を8月末に始めた」場合に破綻する（実運用では普通に起きる — 定例MTGの7日前に開始する Rule がまさにそれ）。

一意制約も張れない。`unique(workspace_id, template_id, subject_type, subject_id)` を張ると月次で複数持てなくなり、張らないと**同じ月の Run が複数作られるのを防げない**。

**3. 発生する具体的リスク**
- クライアント管理画面の資料準備チップ（`matChip()` `:4374`、`materialLate()` `:4383`）は「当月の状態」を1つ表示する。当月 Run を一意に引けないと、複数 Run がある場合にどれを出すかが不定になり、**画面をリロードするたびに違うステータスが出る**可能性がある。
- §13.5 の「月次分析サイクル（毎月1日）」と「定例資料 7日前」の Automation は、どちらも Run を生成する Action を持つ。§13.6 の冪等キーは `rule_id + 日付 + 対象リソースID` なので**同じ日に同じクライアントへ2回作ることは防げる**が、**別の日に走った別 Rule が同じ月の Run を重複作成することは防げない**。8月25日に「定例7日前」で作られた Run と、9月1日に「月次分析サイクル」で作られた Run が両方 9月分として存在する。
- §11.5 の規則3「現在どれかの Run が滞在している State は archive できない」の判定が、放置された古い Run のせいで通らなくなる（完了させる手段が UI に無いため）。
- 現行の `materialLate()`（`:4383`）は `TODAY > MONTH+"-12"` と**表示中の月**で判定している。月次 Run に移行すると「その Run の対象月の12日」で判定することになるが、Run に対象月が無いと判定式が書けない。

**4. 推奨変更**
- **`workflow_runs` に `period_key text null` を追加する**（月次なら `'2026-09'`、期間概念の無い Run は NULL）。Core は `period_key` の書式を解釈しない（`target_month` のような業務語を使わない）。
- **`unique(workspace_id, template_id, subject_type, subject_id, period_key)` を張る**（`period_key` が NULL の行を1件だけ許す部分ユニークインデックスとの組み合わせ）。これで「同一クライアント・同一テンプレート・同一月の Run は1つ」が DB で保証される。
- §13.4 の Action に「Run を作る」系（資料準備 / 企画 / 月次分析）を追加する場合、その Action の冪等性を **`period_key` を含む upsert** で担保する（§22.5 の「Action 側でも冪等にする」の具体例として明記）。
- §24.4 の `materialStatus` / `planningStatus` の行に「`period_key` = 移行実施月」と明記する。
- §5.1 の `WorkflowRun` の説明に `period_key` を追加する。

**5. 過剰設計にならない最小修正**
**列1本と複合 UNIQUE 1本。** `period_key` を Core の不透明な文字列（Module が意味を決める）にしておけば、§4.2 の禁止事項にも触れない。後から入れると既存 Run の backfill と、資料準備画面のクエリ全書き換えになる。

---

### HIGH-8 — §11.5 の4規則では Workflow 変更時の既存データ互換を守りきれない

**1. 該当設計**
§11.5「Workflow 変更時の既存データ互換」の4規則、§11.2 semantic category、§6.2 `workflow_states` / `workflow_transitions` / `workflow_run_transitions`、R8。

**2. 問題**
4規則は「State を消さない」「使用中の State を archive しない」を中心に組まれているが、**壊れ方が State の削除だけではない**。少なくとも3つの穴がある。

**(a) 規則2が `workflow_run_transitions.transition_id` の外部キーと矛盾する。**
規則2は「Transition の追加・**削除**は、進行中の Run の現在地には影響しない」と書いている。確かに現在地には影響しないが、`workflow_run_transitions` は `transition_id` で `workflow_transitions` を参照している（§6.2）。**Transition を物理削除すると過去の遷移履歴が外部キー違反で消せない、あるいは ON DELETE CASCADE なら履歴が消える。** §11.5 は State については「削除しない、archive する」と明記しているのに、Transition については削除を明示的に許可している。

**(b) `semantic` の変更が完全に無防備。**
§11.2 は「完了率」「停滞」「要確認」の計算を表示名ではなく `semantic` で行うと宣言している。つまり `semantic` は**集計とオートメーションの意味論そのもの**である。ところが4規則には `semantic` 変更の制限が一切無い。`is_terminal` / `is_initial` も同様。

**(c) 規則4（新 Template を作って `ServiceContract.workflow_template_id` を切り替える）に、進行中 Task の扱いが書かれていない。**
「既存 Run は古い Template のまま完了させる」とあるが、`tasks` は `workflow_template_id` と `workflow_run_id` の**両方**を持つ（§6.2）。契約側の Template を切り替えたときに既存 `tasks.workflow_template_id` を更新するのかしないのかが未定義で、Run の Template と Task の Template が食い違う状態を作れる。

**3. 発生する具体的リスク**
- **(b) の具体例：** なつみが「投稿待ち」の `semantic` を `ready` から `done` に変更する（「投稿待ちまで来たら実質完了として完了率に入れたい」という、業務上ありうる要望）。その瞬間、**過去12か月分の完了率がすべて跳ね上がり**、§13.5 の「締切超過」Rule が投稿待ちの案件を対象外にし、「今日」画面の `todayBuckets()` の `done` バケットに投稿待ちが流れ込む。取り消しても、その間に飛んだ通知と `AutomationRun` の記録は戻らない。§11.5 のどの規則も、この操作を止めない。
- **(a) の具体例：** 「確認中 → 要修正」の Transition が不要になったので削除する。過去に要修正へ落とした Run の履歴行が `transition_id` で参照しているため、DELETE が外部キー違反で失敗する（あるいは CASCADE で履歴が消える）。§11.5 の規則2を読んだ実装者は「削除してよい」と判断してこの実装を書く。

**4. 推奨変更**
§11.5 の規則を4→7に増やす。

1. State の追加・**表示名変更**・並び替えは既存 Run に影響しない。（現状維持）
2. **Transition も削除しない。`archived_at` を立てるだけにする。** 履歴が参照するため物理削除を禁じる（State と同じ扱い）。
3. 現在どれかの Run が滞在している State は archive できない。（現状維持）
4. **`semantic` / `is_terminal` / `is_initial` は、その State を参照する `workflow_run_transitions` が1件でも存在したら変更できない。** 意味を変えたい場合は新しい State を作り、古い State を archive する（規則2と同じ考え方）。
5. **`workflow_transitions.required_capability` の変更は既存 Run に影響しないが、Audit Log に必ず残す**（§20.2 の「特に強い監査対象」に Workflow Template 変更を追加）。
6. Template を大きく変えるときは新しい Template を作り、`ServiceContract.workflow_template_id` を切り替える。既存 Run は古い Template のまま完了させる。（現状維持）
7. **規則6を実行しても既存 `tasks` の Template 参照は変更しない。** 進行中 Task が参照する Template は Run 経由で解決する（MEDIUM-1 とセット）。

**5. 過剰設計にならない最小修正**
新テーブル不要。**`workflow_transitions` に `archived_at` を1列足す**（`workflow_states` に既にある扱いを揃えるだけ）。規則4・5・7は保存時のバリデーション1本ずつで、§25.4 の Workflow Test に3ケース追加する（既に「使用中の State の archive が拒否される」を書いているので、同じ形で書ける）。

---

### HIGH-9 — Slack webhook の重複排除キーが誤っており、別イベントを取りこぼす

**1. 該当設計**
§17.4「再送（`X-Slack-Retry-Num`）は `webhook_receipts` で弾く」、§6.3 `webhook_receipts`（`id, provider, channel_id, message_number, received_at, signature_valid, payload, processed_at`、`unique(provider, channel_id, message_number)`）、§22.4。

**2. 問題**
`webhook_receipts` のスキーマは Google の push notification（`X-Goog-Channel-ID` + `X-Goog-Message-Number`。チャンネル内で単調増加）を前提に設計されている。Slack はこの形をまったく持たない。

- `X-Slack-Retry-Num` は**同一イベントの再送回数**（0, 1, 2, …）であって、イベントの識別子ではない。初回配送では 0 か、そもそもヘッダが無い。
- Slack のイベント識別子は Events API の `event_id`（`Ev0XXXXX`）。**スラッシュコマンドとインタラクティブ payload には `event_id` が無く、`trigger_id` しか無い。**
- `channel_id` も、Slack では「Slack の会話チャンネル」を指すのか「webhook subscription の channel」を指すのか曖昧。Slack には後者の概念が無い。

**3. 発生する具体的リスク**
`message_number = X-Slack-Retry-Num` として実装すると、`unique(provider, channel_id, message_number)` は「provider=slack, channel=C123, message_number=0」で1行しか許さない。したがって、

1. りりかが `#shift` チャンネルで `/shift` を実行する → 受信、`(slack, C123, 0)` を INSERT、処理される。
2. 30分後、ゆかりが同じチャンネルで `/shift` を実行する → 受信、`(slack, C123, 0)` が重複キー違反 → **§22.4 の手順どおり「200 を返して終了（処理しない）」**。

**ゆかりのシフト変更申請は、200 OK が返り、Slack 上はエラーにならず、`ShiftChangeRequest` は作られず、どこにも記録されない。** 「無音で消えない」（§13.6 / §23.3）という設計原則が、入口で破られる。

逆に `channel_id` に何かユニークな値を入れて回避すると、今度は**本来弾くべき Slack の3秒タイムアウト再送が全部通り**、同じ申請が3件作られる。

**4. 推奨変更**
- `webhook_receipts` を **provider ごとの識別子を1本の列に抽象化**する。`message_number` を `external_event_key text not null` に置き換え、`unique(provider, connection_id, external_event_key)` にする（`connection_id` を入れることで Workspace 分離も効く）。
  - Google Drive / Calendar: `external_event_key = channel_id + ':' + message_number`
  - Slack Events API: `external_event_key = event_id`
  - Slack スラッシュコマンド / インタラクティブ: `external_event_key = trigger_id`（イベントごとに一意で、再送でも同一）
- §17.4 の記述を「**再送は `event_id` / `trigger_id` で弾く。`X-Slack-Retry-Num` は再送であることのログ用にのみ使う**」に修正する。
- §25.5 のテストに「**異なる2つの Slack イベントが同じチャンネルから来ても両方処理されること**」を追加する（現状は「同じ内容で2回送って1回しか処理されない」しか書かれておらず、この不具合を検出できない）。

**5. 過剰設計にならない最小修正**
**列1本のリネームと UNIQUE の定義変更、`IntegrationProvider` インターフェース（§15.1）に `dedupeKey(request): string` を1メソッド追加するだけ。** provider 固有の知識が Adapter に閉じるので §4.2 にも適合する。

---

### HIGH-10 — 退職時に Google アカウントを停止する運用が、その人が接続した Drive / Calendar Integration を同時に破壊する

**1. 該当設計**
§8.2 Identity の理由3（「退職時に Google アカウントを止めれば SOCIAL BASE も同時に閉じる」）、§6.3 `integration_connections`（`connected_by`）、§15 / §16、§26.5（「OAuth トークンの期限：期限7日前に通知」）、ADR-004。

**2. 問題**
§8.2 は Google アカウント停止を**オフボーディングの主要手段**として推奨している。一方 §15 / §16 の Integration は、`integration_connections` に個人ユーザーの OAuth トークン（`access_token_enc` / `refresh_token_enc`）を保存する設計で、`connected_by` が接続者を指す。

**Google Workspace のアカウントを停止すると、そのアカウントが発行した refresh token は失効する。** つまり §8.2 の推奨オフボーディング手順が、そのまま §15 / §16 の全 Integration を停止させる。設計書の2つの章が互いに矛盾しているが、どちらの章にもこの相互作用は書かれていない。

**3. 発生する具体的リスク**
具体的な入力：

1. 翔平（社長・`owner`）が Drive と Calendar を接続する。`integration_connections.connected_by = 翔平`。
2. 数か月後、翔平が退任し、情シスが Google アカウントを停止する（§8.2 の推奨どおり）。
3. Drive の refresh token が失効。`changes.watch` チャンネルの更新 Job（§15.4）が 401 で失敗。Calendar の `events.list(syncToken)` も失敗。
4. §23.3 の retry が5回走り、dead-letter へ落ちる。§26.5 の「dead-letter 1件でも通知」が発火するが、**通知先は「社員へ」であり、通知の配信自体が Job Runner 経由**（MEDIUM-7 と複合）。
5. 気付くまでの間、10社分の Drive フォルダ変更検知と定例MTGの取り込みが止まる。§13.5 の「定例資料 7日前」Rule は Calendar 由来の `ScheduleEntry` を条件にするため、**資料準備 Task が作られなくなる**。誰も「作られていないこと」には気付かない。

さらに、退職者個人の Drive 権限で接続していた場合、その人がアクセスできたフォルダにしか SOCIAL BASE はアクセスできない。**接続者が変わるたびに見えるフォルダの範囲が変わる**という、追跡困難な挙動になる。

**4. 推奨変更**
- **§15.1 の共通ルールに6つ目を追加する：「Integration の接続主体は Workspace であり、個人ではない」。** 具体的には Google Workspace の**サービスアカウント + ドメイン全体の委任**、または「退職しない前提の共有アカウント」を使う。`connected_by` は監査用の記録にとどめ、認可の主体にしない。
- サービスアカウントが使えない場合（Slack のように user token が必要な連携）は、**接続者が `WorkspaceMember.status != active` になった時点で `integration_connections.status = 'reconnect_required'` にし、`integration.manage` 保持者へ通知する Automation Rule を §13.5 に追加する**。
- §8.2 の「退職時に Google アカウントを止めれば SOCIAL BASE も同時に閉じる」に注記を足す：「ただし当該ユーザーが接続した Integration は同時に失効する。オフボーディング手順に『Integration の接続者付け替え』を含める」。
- §26.5 の監視表に「**接続者が非アクティブな `integration_connections` が存在する**」を追加する。

**5. 過剰設計にならない最小修正**
Google 側はサービスアカウント1つの発行と、`integration_connections.status` に `reconnect_required` を1値足すだけ。**Automation Rule 1本（§13.5 の表に1行）と、オフボーディング手順書への1行追記。** Phase 7 の着手前に決めればよいが、`integration_connections` のトークン保持方式に影響するので、Phase 2 のスキーマ確定前に方針だけ決める必要がある。

---

### HIGH-11 — §13.3 の jsonb 条件式 DSL は過剰設計。既知9ルールに対して式評価エンジンを自作することになる

**1. 該当設計**
§13.1「if 文の集合にしない」、§13.3「Conditions（AND / OR の入れ子を `jsonb` で持つ）」、§13.5 の初期9ルール、§6.2 `automation_rules`（`conditions jsonb, actions jsonb, schema_version`）、P4 / P5。

**2. 問題**
§13.3 は次の形の条件式言語を定義している。

```json
{ "all": [ { "field": "content_item.publish_date", "op": "in_days", "value": 14 },
           { "field": "workflow_run.semantic", "op": "not_in", "value": ["done"] } ] }
```

これは「フィールドパス解決 + 演算子ディスパッチ + AND/OR 入れ子評価 + 型検証 + エラー処理」を持つ**小さな式言語の実装**を意味する。ところが実際に必要な条件は §13.5 の9個で、そのすべてが**「N日前・N日後・特定日・未完了」の組み合わせ**である。可変にしたい部分は日数（14 / 7 / 3 / 12 / 90）と有効/無効だけで、**構造は変わらない**。

P4（設定をコードに埋めない）は「日数を変えるたびにデプロイが要るのは現実的でない」という要求であり、これは**パラメータをデータに置けば満たされる**。条件の構造まで動的にする必要はない。一方 P5（過剰設計をしない）は「No-code Workflow Builder は作らない」と明言している。§13.3 は事実上、その No-code Builder のバックエンドである。

また、DSL には次が付随して必要になるが、設計書のどこにも無い：条件式の妥当性検証（`field` に存在しないパスを書いたらどうなるか）、`op` と値の型整合、`schema_version` の移行方法、条件式を編集する UI、条件式のテスト方法。§25 の Testing Strategy に条件式評価器のテストが1行も無い。

**3. 発生する具体的リスク**
Phase 6 の工数が読めなくなる。「Automation Engine を作る」が「小さなインタプリタとその UI とそのテストを作る」に化ける。

さらに具体的な壊れ方として、`{"field": "content_item.publish_date"}` のような文字列パスは**リファクタリング耐性がゼロ**である。`publish_date` を将来 `scheduled_publish_date` に改名した瞬間、jsonb の中の文字列は誰も直さないので、**Rule が静かに条件不成立になり、通知が来なくなる**。型チェックもテストも効かない。§13.6 の「無音で消えない」保証は Job の失敗については語っているが、**条件が常に false になるケースは失敗ですらない**ので検出できない。

**4. 推奨変更**
v1 は **Rule を「登録済み述語 + パラメータ」の形にする**。

```
automation_rules:
  id, workspace_id, rule_key, params jsonb, enabled, schema_version, created_by
  例: rule_key='publish_date_approaching', params={"days":14}
      rule_key='monthly_analysis_overdue',  params={"day_of_month":12}
```

- `rule_key` ごとの条件判定は **TypeScript の関数として実装し、型で守る**。Module がレジストリに登録する（Capability キーと同じ仕組み）。
- 画面から変えられるのは `params` と `enabled` だけ。**P4 の要求（日数を画面から変える）は完全に満たす。**
- 将来、本当に自由な条件式が必要になったら `rule_key='custom_expression'` を1つ足して、そこにだけ DSL を実装する。**Core の構造は変えずに拡張できる。**
- §13.3 を「v1 は登録済み述語 + パラメータ。式 DSL は Non-Goal（§1.3 の No-code Workflow Builder と同じ理由）」に書き換える。§1.3 の Non-Goals に「Automation の汎用条件式言語」を明記する。

**5. 過剰設計にならない最小修正**
**列を `conditions jsonb` → `rule_key text` + `params jsonb` に変えるだけ。** 実装は9個の述語関数（各10行程度）とレジストリ1本。式評価器・パス解決・演算子テーブル・その検証とテストがまるごと不要になる。Phase 6 の規模が半分以下になる見込み。

---

### HIGH-12 — 並行稼働中の削除が同期されず、Parity ゲートがカットオーバー時のデータを検証しない

**1. 該当設計**
§24.2 Step 3（Read 移行・並行稼働。「artifact は引き続き本番。書き込みは artifact 側のみ」）、Step 4（Parity 確認）、Step 5（最終の STATE を再抽出して**差分 import**）、§24.3（「import は冪等にする。**`legacy_id` で UPSERT**」）、§24.6（「1件でも差分があれば Write 移行に進まない」）。

**2. 問題**
2つの穴がある。

**(a) UPSERT だけでは削除が反映されない。**
artifact 側では行が消える経路が実在する。`merge()`（`:5019`）は「未着手かつ未ロックの行」を新しい配置で**置き換える**ため、翌月生成を実行すると旧行が消えて別 `id` の新行が生まれる。「サンプルを削除」（`:2285`）は当月の全行を削除する。`legacy_id` による UPSERT だけを流すと、**消えた行が新環境に残り続ける**（ゴースト）。

Step 3〜4 の期間中は artifact が本番なので、この操作は普通に起こる。カットオーバー時の差分 import 後、`content_items` の件数が `STATE.rows` より多い状態でカットオーバーすることになる。ゴーストには `tasks` と `workflow_runs` がぶら下がるので、「今日」画面に**存在しないはずの案件が期限超過として出続ける**。

**(b) Parity ゲートが Step 4 で走り、実際に本番になるデータは Step 5 で入る。**
§24.6 は「1件でも差分があれば Write 移行に進まない」という強いゲートだが、その検証対象は Step 2 で import したスナップショットである。カットオーバーで実際に使われるのは Step 5 の再抽出データであり、**そちらは Parity を通っていない**。順序が逆になっている。

**3. 発生する具体的リスク**
金曜夜のカットオーバー当日、Step 5 の差分 import を流した直後に新環境を書き込み可にする。月曜朝、りりかが「今日」画面を開くと、8月の翌月生成で消えたはずの旧行が「期限超過 12件」として並んでいる。誰も消し方を知らない（UI に ContentItem の削除機能は無い — 現行にも無い）。Rollback（§24.7）は「Step 5 直後なら手で artifact へ反映」だが、この不整合は artifact 側には存在しないので戻しても解決しない。

**4. 推奨変更**
- **import を UPSERT ではなく「スナップショット同期」にする。** 抽出した `STATE.rows` の `legacy_id` 集合に含まれない `content_items` を `archived_at` でマークする（物理削除しない）。§6.1 の「物理削除は原則しない」に沿う。ぶら下がる `tasks` も同時に archive する。
- §24.3 の「`legacy_id` で UPSERT」を「**`legacy_id` をキーとした upsert + 差集合の archive**」に書き換える。
- **§24.2 の Step 4 と Step 5 の順序を入れ替える／Parity をカットオーバー当日にも走らせる。**
  ```
  Step 4  Parity リハーサル（Step 2 のスナップショットで全項目を通す。ここで落ちたら Step 2 からやり直し）
  Step 5  カットオーバー
          5-1 artifact を maintenance にして書き込みを止める
          5-2 最終 STATE を再抽出し、スナップショット同期を流す
          5-3 【必須】Parity を再実行する。ここで1件でも差分があれば artifact の maintenance を解除して撤退
          5-4 新環境を書き込み可にする
  ```
  Parity を**自動化されたスクリプト**にしておけば（§25.7 が既にそう言っている）、5-3 は数分で終わる。
- §24.4 の `localStorage` `mlboard.ops.v1`（「カットオーバー前に必ず0件にする」）について、**確認方法を書く**。未同期キューは端末ローカルなので、全員に自分の画面で「未同期 N件」バナー（`blockers()` `:2255`）が出ていないことを確認してもらう手順が要る。

**5. 過剰設計にならない最小修正**
import スクリプトに**差集合の archive を数行足す**のと、**§24.2 の Step 5 に「Parity 再実行」を1行足す**だけ。Parity スクリプトは §25.7 で既に自動化が要求されているので、再実行は追加コストゼロ。

---

### HIGH-13 — 業務日付の基準タイムゾーンが定義されておらず、すべての日付判定と通知が1日ずれ得る

**1. 該当設計**
§6.1（「時刻を伴うものは `timestamptz`（UTC保存、表示は Workspace の `timezone`）」）、§12（営業日・リードタイム）、§13.2 `date.reached`、§23.2（「日次：`date.reached` の Automation、Recurrence 展開」）、§24.6（「新環境の『今日』をテスト用に固定できるようにしておく（`TODAY` の注入。現行 `:5180`）」）。

**2. 問題**
現行実装は `TODAY = fromUTC(Date.now() + 9*3600*1000)`（`:5180`）で、**明示的に JST の暦日**を「今日」としている。この `TODAY` が `prioOf()`（`:2213`）、`judge()`（`:1671`）、`todayBuckets()`（`:3496`）、`loadOf()`（`:3910`）、`materialLate()`（`:4383`）、`daysSince()`（`:2196`）、`isPast()`、`generate()` の `genDate` と、**日付が絡むほぼ全ての判定**の基準になっている。

設計書は `workspaces.timezone` と `recurrence_rules.timezone` という列を定義しているが、**「業務上の『今日』はどのタイムゾーンの暦日か」「サーバー側 Domain のどこでその変換を行うか」がどの章にも書かれていない**。Serverless の実行環境と cron トリガーは通常 UTC で動く。

**3. 発生する具体的リスク**
`date.reached` の日次 Job が UTC の 00:00 に起動すると、JST では 09:00 である。ここで「今日」を UTC 暦日として計算すると：

- **毎月12日の分析期限アラート（§13.5）が、JST の13日の朝9時に発火する。** 「12日までに」という業務ルールに対して1日遅い通知になる。
- 逆に日次 Job を JST 00:00（= UTC 前日 15:00）に設定し、Domain 側が UTC 暦日で判定すると、**前日として扱われる**。
- 「投稿予定日の14日前」（§13.5）が、月末をまたぐケースで1日ずれる。
- `internal_due` の逆算（§12.3）で、`subBiz(営業日リスト, publish_planned, lead_time)` の起点日がずれると**締切が1営業日ずれる**。50件×毎月なので、ずれれば全件ずれる。
- §24.6 の Visual Regression で「同一データ・同一日付で撮る」ために `TODAY` を注入するとあるが、**注入する値がどのタイムゾーンの暦日かが決まっていないと、現行 artifact（JST 固定）と新環境で「今日」が1日違い、画素差0 が絶対に出ない。**

さらに厄介なのは、この種のずれは**日本時間の午前0時〜9時にだけ症状が出る**ため、日中のテストでは再現しないことである。

**4. 推奨変更**
- §6.1 に「**業務日付（business date）の定義**」を追加する：「日付のみの列（`date`）と、`date.reached` / 締切判定 / 営業日計算における『今日』は、すべて **Workspace の `timezone` における暦日**とする。UTC 暦日を業務日付として使わない」。
- Domain 層に `businessToday(workspace): LocalDate` を1本だけ用意し、**`new Date()` / `now()` を Domain から直接呼ぶことを禁止する**（lint ルール化する）。§3.3 の「同じ業務計算を両方に持たない」と同格の規約として書く。
- §23.2 の cron スケジュールに、実行時刻が UTC 表記か workspace tz 表記かを明記する。日次 Job は「Workspace tz の 00:05」に相当する UTC 時刻で起動する。
- §24.6 の `TODAY` 注入を「**Workspace timezone における暦日を注入する**」と明記する。
- §25.1 の Unit テストに、**JST 00:00〜09:00 に相当する UTC 時刻での `businessToday()` のテスト**を含める（この時間帯だけで壊れるため、固定時刻テストが必須）。

**5. 過剰設計にならない最小修正**
**関数1本（`businessToday`）と、それを使う規約の明文化。** タイムゾーンライブラリは既に必要（`workspaces.timezone` を持つ以上）なので追加依存も無い。後から直すと日付が絡む全テストの期待値を見直すことになる。

---

## 3. MEDIUM

### MEDIUM-1 — Task の「現在の状態」の持ち方が §5.1 と §6.2 で食い違い、Template 参照が二重化している

**1. 該当設計** §5.1 `Task`（`workflow_template_id` / **`workflow_state_id`**）、§6.2 `tasks`（`workflow_template_id`, **`workflow_run_id`**）、§7.1 ER（`tasks` に `workflow_run_id`）、§24.4（`rows[].status` → `workflow_runs.current_state_id`）。

**2. 問題** §5.1 は Task が `workflow_state_id` を直接持つと書き、§6.2 と §7.1 は `workflow_run_id` を持つと書いている。さらに `tasks.workflow_template_id` と `workflow_runs.template_id` が同じ情報を二重に持つ。どちらが正かが決まっていない。

**3. リスク** 実装者が §5.1 を読んで `tasks.workflow_state_id` も足すと、`workflow_runs.current_state_id` と2箇所に現在状態が生まれる。遷移時に片方の更新を落とすと、一覧画面（tasks を読む）と詳細画面（run を読む）で**同じ案件のステータスが違って見える**。楽観ロック（§22.1）は2つの version を持つことになり、どちらを送るかも不定になる（MEDIUM-4）。Template の二重化は §11.5 規則6（Template 切り替え）で必ず食い違う。

**4. 推奨変更** **`workflow_runs` を唯一の正とする。** §5.1 の `Task` から `workflow_state_id` と `workflow_template_id` を削除し、`workflow_run_id` のみにする。§6.2 の `tasks` からも `workflow_template_id` を削除する。Template は `task → run → template` で解決する。

加えて、Core の `tasks.source_type` / `source_id` は**外部キーを張れない多態参照**であり、ContentItem : Task = 1:1 という v1 の中心的な関係に整合性保証が無い。SOCIAL BASE Module 側に結合テーブルを置くことで、Core を汚さずに整合性を得られる。

```sql
create table content_item_tasks (
  workspace_id uuid not null,
  content_item_id uuid not null,
  task_id uuid not null,
  primary key (workspace_id, content_item_id, task_id),
  unique (task_id),                             -- v1 の 1:1 を保証
  foreign key (content_item_id, workspace_id) references content_items (id, workspace_id),
  foreign key (task_id, workspace_id)          references tasks (id, workspace_id)
);
```

**5. 最小修正** §5.1 / §6.2 から列を2本消し、Module 側に結合テーブルを1本足す（Module → Core の依存方向は §4.2 で許可されている）。将来 1:N にするときは `unique(task_id)` を落とすだけ。

---

### MEDIUM-2 — Read Model（§5.5）を支える索引が不足している

**1. 該当設計** §6.2 / §6.4 の索引定義、§5.5 の8つの Query Service。

**2. 問題** §5.5 の各 Query が必要とする索引のうち、次が定義されていない。

| Query | 必要なアクセス | 現状 |
|---|---|---|
| `MyTasksQuery` / `TeamLoadQuery` | メンバー別の担当 Task | `task_assignments` は `unique(task_id, workspace_member_id, assignment_role)` のみ。**`workspace_member_id` 先頭の索引が無い** |
| `HomeDashboardQuery`（停滞・KPI） | 状態別の集計 | `workflow_runs.current_state_id` に索引が無い |
| `ClientOverviewQuery` | クライアント別集計 | `content_items` に `client_id` / `service_contract_id` の索引が無い |
| §19.5 障害調査 | `request_id` でログ・Audit を引く | `audit_logs` に `request_id` の索引が無い |
| §14.4 通知の抑制 | `dedupe_key` の未読存在チェック | 列自体が無い（MEDIUM-3） |

**3. リスク** 現在の規模（月50件）では体感差は出ないが、`task_assignments` の索引欠落は「自分のタスク」というホーム画面の中心クエリが毎回シーケンシャルスキャンになることを意味し、Serverless の cold start と重なると初回表示が目に見えて遅くなる。`request_id` の索引欠落は、障害調査という**最も急いでいる場面**で `audit_logs` の全走査を強いる。

**4. 推奨変更** §6.2 / §6.4 に次を追加する。

```
task_assignments : index(workspace_id, workspace_member_id, assignment_role)
workflow_runs    : index(workspace_id, current_state_id)
content_items    : index(workspace_id, client_id, target_month)
                   index(workspace_id, service_contract_id, target_month)
audit_logs       : index(workspace_id, request_id)
```

**5. 最小修正** 索引5本の追記のみ。§25.2 の DB Integration Test に、主要 Query の `EXPLAIN` が Seq Scan にならないことを1ケース入れておくと、以後の追加漏れも防げる。

---

### MEDIUM-3 — 本文で導入した列がスキーマ表に存在しない（3箇所）

**1. 該当設計** §14.4（`Notification` に `dedupe_key` を持たせる）vs §6.2 `notifications`。§13.6（`AutomationRun` に実行時点の Rule スナップショットを保存する）vs §6.2 `automation_runs`。§24.5（`daily_notes` は Workspace 単位で1日1件）vs 一意制約の記載なし。

**2. 問題** 本文が機能を約束し、スキーマ表にその列・制約が無い。

**3. リスク** §14.4 の通知抑制は `dedupe_key` が無ければ実装できない。§13.5 の9ルールは日次で回るので、抑制が効かないと**毎日同じ通知が全員に届き、3日で誰も読まなくなる**（§13 の「■ オーナー向け説明」自身が懸念している事態が、スキーマの欠落で確定する）。§13.6 の Rule スナップショットが無いと「あとから Rule を変えても過去の Run が何をしたか追える」という保証が成立しない。`daily_notes` に一意制約が無いと、同じ日のメモが複数行できて現行の共有メモ（1日1件）の挙動が壊れる。

**4. 推奨変更**
```
notifications   : + dedupe_key text
                  + unique index (workspace_id, dedupe_key) where read_at is null
automation_runs : + rule_snapshot jsonb not null
daily_notes     : unique(workspace_id, date)
```

**5. 最小修正** 列2本、UNIQUE 2本。§6.2 の表に追記するだけ。

---

### MEDIUM-4 — 楽観ロックの `version` が3テーブルにあり、UI がどれを送るかが未定義

**1. 該当設計** §22.1（`tasks` / `content_items` / `workflow_runs` に `version`。「Frontend は Read Model で受け取った `version` をそのまま送り返す」）、§5.5（Read Model は複数テーブルを結合した画面向けの形）。

**2. 問題** Read Model の1行は ContentItem + Task + WorkflowRun を結合したものなので、`version` が3つ含まれる。「そのまま送り返す」がどれを指すか決まっていない。

**3. リスク** 工程を進める API（`POST /tasks/:id/transitions`）で `content_items.version` を検証すると、他人がタイトルを直しただけで工程が進められなくなる（過剰な 409）。逆に `workflow_runs.version` だけを検証すると、タイトル編集と工程進行が競合しない — これは正しい挙動だが、**実装者が明示されない限りどちらにもなり得る**。§25.2 の「`version` 不一致の UPDATE が0行になること」というテストは、どのテーブルの version かを決めないと書けない。

**4. 推奨変更** §22.1 に「**操作対象の集約(aggregate)の `version` のみを検証する**」と明記し、対応表を置く。

| 操作 | 検証する version |
|---|---|
| 工程を進める / 1段戻す | `workflow_runs.version`（+ §22.2 の `from_state` 一致） |
| タイトル / URL / メモ / 修正指示 | `content_items.version` |
| 担当変更 / 期限変更 | `tasks.version` |

Read Model は3つを別名（`contentVersion` / `taskVersion` / `runVersion`）で返す。なお §22.2 の `from_state` 一致検証があるため、遷移については version が実質冗長である旨も書いておくとよい。

**5. 最小修正** §22.1 に表を1つ追加し、Read Model のフィールド名を決めるだけ。

---

### MEDIUM-5 — `idempotency_keys` の主キーが Workspace 横断になっている

**1. 該当設計** §6.2 `idempotency_keys`（`key, workspace_id, endpoint, request_hash, response_status, response_body jsonb, ...` / **`pk(key)`**）、§22.3。

**2. 問題** 主キーが `key` 単独のため、`key` の名前空間が全 Workspace で共有される。§22.3 の手順2は「同じ key + 同じ request_hash → 保存済みのレスポンスをそのまま返す」なので、**別 Workspace のレスポンスボディを返す経路が原理的に存在する**。

**3. リスク** クライアントが `Idempotency-Key` を UUIDv4 で生成する限り実害は無いが、設計書自身が §22.3 で `workspace_id + target_month + contract_version_hash` という**決定的な（推測可能な）キー生成**を推奨している。同種のキー生成を別のエンドポイントで行い、そこに `workspace_id` を含め忘れると、`request_hash` がたまたま一致した場合に他 Workspace のレスポンスが返る。将来 Workspace が増えたときに顕在化する。

**4. 推奨変更** `pk(workspace_id, key)` にする。加えて `request_hash` に**リクエストパス（`:ws` を含む）と実行 Member ID を必ず含める**ことを §22.3 に明記する。

**5. 最小修正** 主キーの定義1行と、§22.3 に1文追記。

---

### MEDIUM-6 — `date.reached` に取りこぼしの catch-up 機構が無い

**1. 該当設計** §13.2 `date.reached`、§13.6 冪等性（`idempotency_key = rule_id + 日付 + 対象リソースID`）、§23.2（日次でドレイン）、§23.3 Retry / Dead-letter。

**2. 問題** 冪等キーに日付が入っているため「同じ日に2回実行されない」は保証されるが、**「実行されなかった日が後から実行される」保証が無い**。§13.6 の失敗対策は「Job の retry に乗る」だが、そもそも Job が enqueue されなかった日については retry する対象が存在しない。

**3. リスク** 金曜のデプロイで日次 cron が一時的に止まる、あるいは Serverless の関数タイムアウトで Job 投入の途中で落ちる。月曜に復旧しても、**土日に発火すべきだった「定例資料 7日前」Rule は永久に発火しない**。結果として資料準備 Task が作られず、定例MTG当日に誰も気付く。§13.6 の「無音で消えない」保証は、失敗した Run については機能するが、**そもそも Run が作られなかったケースには機能しない**。これは自動化を導入した後のほうが危険で、人が手で確認する習慣が失われた頃に起きる。

**4. 推奨変更** `automation_rules` に `last_evaluated_date date` を追加する。日次 Job は「`last_evaluated_date + 1` から `businessToday()` まで」をループして評価し、最後に `last_evaluated_date` を更新する。冪等キーに日付が入っているので、重複実行にはならない。catch-up の上限（例：7日）を設け、それを超えて遅れていたら通知する。

**5. 最小修正** 列1本と、日次 Job のループ1段。§26.5 の監視表に「`last_evaluated_date` が今日より2日以上前のルールが存在する」を1行追加する。

---

### MEDIUM-7 — 監視通知が監視対象自身（Job Runner）に依存している

**1. 該当設計** §26.5「監視で見るもの」（dead-letter 1件でも通知 / Integration 最終同期24時間 / トークン期限7日前 / `business_calendar` 残90日）、§26.6（「Job Runner 停止 → 滞留を監視で検知する」）、§14.2（channel = `in_app` / `slack_dm`）。

**2. 問題** §26.5 の通知はすべて §14 の `Notification` + `NotificationDelivery` を経由し、その配信は §23 の Job Runner が行う。**Job Runner が止まると、Job Runner が止まったことを知らせる通知も止まる。**

**3. リスク** スケジュール起動の cron トリガーが設定ミスや課金停止で無効になる。画面は正常に動くので誰も気付かない。§26.6 は「滞留を監視で検知する」と書いているが、その検知結果の通知経路が同じ仕組みの中にある。数週間、通知も外部同期も止まったまま運用が続く。

**4. 推奨変更** **システムの外側に1つだけ死活監視を置く。** 最小構成は、Job Runner が正常にドレインしたら「ハートビート URL」を叩き、外部の無料 uptime 監視（cron 監視サービス）が一定時間叩かれなければメールを送る、という形。SOCIAL BASE の内部に依存しない経路を1本だけ持つ。§26.5 の表に「**Job Runner のハートビート（外部監視）**」を1行追加し、§26.6 の「Job Runner 停止」の行にこの経路を書く。

**5. 最小修正** ドレイン Job の末尾に HTTP GET を1行足すのと、外部サービスの登録1回。追加の常駐プロセスもインフラも不要で、§26.1 の「常時稼働サーバーを持たない」という前提を崩さない。

---

### MEDIUM-8 — 「画素差0」の基準が二重定義されており、artifact 対 新環境では達成不能

**1. 該当設計** §3.4（「変えてよいもの：**非同期化に伴うローディング表現の追加**」「判定は Visual Regression で行う。**同一幅でのスクリーンショット画素差0** を Regression の基準にする」）、§24.6（「Desktop 1448 / Tablet 834 / Mobile 375 で、**現行 artifact と新環境のスクリーンショットを比較する**」）、§25.6（「変更前後を同一幅で撮って画素差0」）。

**2. 問題** 「画素差0」が2つの異なる比較に対して使われている。

- §3.4 / §25.6：**新環境内の変更前後**の比較 → 画素差0 は妥当な基準。
- §24.6：**現行 artifact と新環境**の比較 → 画素差0 は原理的に達成できない。

理由は3つ。(1) §3.4 自身が「ローディング表現の追加」を許可している。(2) 現行の `commit()`（`:1955`）は `applyOp` → `render()` を同期実行する楽観更新だが、移行後は API 往復が入るため描画タイミングが変わる。(3) 別オリジン・別配信経路でのフォントのサブピクセルレンダリング差、スクロールバーの有無などで、同一 HTML でも画素は一致しない。

**3. リスク** §24.6 は Write 移行のゲートである。達成不能な基準を置くと、**運用時に「画素差0 は無理だったので目視で OK にした」となり、ゲート全体の効力が失われる**。あるいは基準を満たすためにローディング表示を諦め、UI が API 応答中に無反応になる。

**4. 推奨変更**
- §25.6 / §3.4 の「画素差0」は**新環境内の Regression 基準**として維持する。
- §24.6 の artifact 対新環境の比較は、**構造比較**に変更する：同一 viewport・同一データ・同一 `TODAY` で、(a) 主要セレクタの DOM 実測値（幅・高さ・位置）が ±1px 以内、(b) 表示テキスト（ステータス表記・ボタン文言・件数）が完全一致、(c) スクリーンショットは目視差分レビュー（差分画像を残す）。現行の Visual QA 手法（実寸スクショ + DOM 実測）をそのまま使える。
- **ローディング表現の追加は §3.4 の許可どおり明示的に認め**、それが差分として現れることを §24.6 の既知差分リストに書く。

**5. 最小修正** §24.6 の1段落の書き換え。既存の QA ハーネス（実寸スクショ + DOM 実測）をそのまま使うため、実装追加はゼロ。

---

### MEDIUM-9 — Core のスキーマ記述に SOCIAL BASE 固有の語が混入している（P1 / §4.2 の自己違反）

**1. 該当設計** §7.2 ER の `schedule_entries.kind "publish_planned or shoot or meeting or **internal_due**"`、§12.1 の `kind` 一覧（`publish_planned` / `**client_meeting**` / `planning_due` / `analysis_due`）、§7.2 の `recommendations.kind "**publish_date** or assignment"`。§4.2 の禁止事項（「Core のテーブル・型・関数名に `client` / `video` / `instagram` / `drive` / `slack` が出てはいけない」）。

**2. 問題** `schedule_entries` と `recommendations` は Core のテーブルだが、その `kind` 列の取りうる値として SOCIAL BASE 固有の概念（`client_meeting`、`publish_planned`、`publish_date`）が ER 図と本文に enum のように列挙されている。`client_meeting` は §4.2 が禁じている `client` を literal に含む。

**3. リスク** 記述のとおり CHECK 制約や TypeScript の union 型として実装されると、営業部 Workspace を作るときに Core のスキーマを migration で変更することになる。§1.1 が「本書で最も強い制約であり、他のすべての判断に優先する」と宣言した P1 が、Core のスキーマ層で破られる。Capability キー（§8.3）と `scope_type`（§9.5）は「Module が登録する不透明な文字列」として正しく設計されているのに、`kind` だけ扱いが違う。

**4. 推奨変更** §12.1 / §7.2 に注記を追加する：「`schedule_entries.kind` および `recommendations.kind` は、**Capability キーと同様に Module が登録する不透明な文字列**である。Core は値を解釈せず、CHECK 制約も enum 型も作らない。§12.1 / §7.2 に挙げた値は SOCIAL BASE Module が登録する値の例である」。ER 図のコメントも「例：」を付ける。

**5. 最小修正** 注記2行。実装上はむしろ制約を作らないだけなので、作業が減る。

---

### MEDIUM-10 — OAuth トークンのリフレッシュに single-flight 制御が無い

**1. 該当設計** §15.1 `IntegrationProvider.refresh(connection)`、§6.3 `integration_connections`（`access_token_enc`, `refresh_token_enc`, `token_expires_at`）、§23.2（「1時間ごと：webhook チャンネルの期限更新、**トークン更新**」）、§23.3（at-least-once 配送）。

**2. 問題** Job は at-least-once であり、同時に複数の Job（Drive 同期・Calendar 同期・トークン更新 Job）が同じ `integration_connections` 行を見てリフレッシュを試みる。Google の refresh token rotation が有効な場合、**先に成功したリフレッシュが古い refresh token を無効化する**ため、後続のリフレッシュが失敗し、しかも DB には後続の（失敗した／古い）結果が書かれる可能性がある。§22.5 は「Action 側でも冪等にする」と書いているが、トークンリフレッシュについては触れていない。

**3. リスク** 1時間ごとのトークン更新 Job とユーザー操作起因の同期 Job が重なった瞬間に、connection が壊れて `status` が失効になる。復旧には人手による再接続が必要で、その間 Drive / Calendar 連携が止まる。断続的にしか起きないため原因特定に時間がかかる。

**4. 推奨変更** リフレッシュを **`SELECT ... FOR UPDATE` で `integration_connections` 行をロックした上で行う**（single-flight）。ロック取得後にもう一度 `token_expires_at` を確認し、既に有効なら何もしない（double-checked locking）。§15.1 の共通ルールに「トークンのリフレッシュは connection 行のロック下で行う」を1行追加する。

**5. 最小修正** リフレッシュ関数の先頭に `FOR UPDATE` を1行。`jobs` テーブルで既に `FOR UPDATE SKIP LOCKED` を使う設計なので、同じ道具立てで済む。

---

## 4. LATER

### LATER-1 — Read Model のページングとキャッシュ制御
§21.2 の `views/*` はページングパラメータを持たない。R7 が「Read Model をページング可能にしておく」と書いているが、API 定義には反映されていない。月350件・年4,200件のスケールでは全件返しでも動くが、`views/content-list` に `?cursor=` `&limit=` を最初から入れておくと後方互換の破壊を避けられる。ADR-014（ポーリング）と合わせて `ETag` / `If-None-Match` を返すようにしておくと、Serverless の実行時間と転送量が下がる。**推奨：API のクエリパラメータ定義だけ v1 で確定し、実装は全件返しでよい。**

### LATER-2 — Scope 機構の先行実装範囲
§9.5 は「v1 では全 Role が `workspace` スコープで足りる。Scope 機構だけ先に入れておく」としている。列（`scope_type` / `scope_id`）を持つのは正しいが、**スコープ解決エンジン（§8.4 の判定6）を v1 で実装・テストする必要は無い**。`check(scope_type = 'workspace' and scope_id is null)` を v1 の制約として入れ、要件が出たときに CHECK を外して解決器を足すほうが、テストしていないコードパスを本番に置くより安全。**推奨：列は入れる、評価器は入れない、CHECK で v1 の前提を固定する。**

### LATER-3 — 導出値の設定を変えたときの過去画面の再現性
§18.1 / §18.2 は `LOAD_CFG` と `capacity.hours_per_item` を `workspaces.settings` に出す。これは正しいが、設定を変えると**過去月の負荷スコアの見え方も変わる**。今は表示専用の指標なので実害は無い。将来これを評価や請求の根拠に使うなら、設定に有効期間を持たせる必要がある。**推奨：v1 は現状のままでよい。§28.3 の未決事項に「設定値の版管理」を1行追加しておく。**

### LATER-4 — Audit Log と Automation Run の保持期間・分割
§28.3 が「Audit Log の保持期間」を未決としている。月50〜350件の操作規模なら数年は無問題。`automation_runs` は9ルール × 日次 × リソース数で `audit_logs` より速く増える可能性がある。**推奨：`audit_logs` / `automation_runs` / `webhook_receipts` / `jobs`（完了分）の4つについて、保持期間と削除方法（月次パーティション or 期間削除 Job）を Phase 10 で決める。v1 では何もしない。**

---

## 5. 判定

# **B. 修正後に実装開始可能**

**Architecture の再設計は不要**である。Modular Monolith / Core と Module の分離 / PostgreSQL を SoT にする / Outbox + Job / Recommendation を提案に留める / 段階移行、という骨格はいずれも規模と目的に対して妥当で、不要な Microservices 化も無く、逆に強結合になってもいない。確定済み前提4点にも致命的欠陥は無い。ADR の書式と「■ オーナー向け説明」による判断の可視化は、この種の文書として質が高い。

一方で、そのまま Phase 2 に入ると **Workspace 分離という設計書自身の中心的な約束が、スキーマ層と実行環境の両方で成立しない**（BLOCKER-1 / BLOCKER-2）。また Identity を email で束ねる設計（BLOCKER-3）は、監査ログの信頼性という §19 の要件を根本から損なう。この3件はいずれも**今なら列とロール設定の追加で済み、後からは全外部キー・全クエリ・全ユーザーの再検証になる**。

HIGH 11件のうち5件（HIGH-1 / 2 / 3 / 4 / 5）は、**設計書が現行実装を誤って把握していることに起因する**。とくに `STAFF_MAP` を単なる名前対応表と見なした点（HIGH-2）と、現行 `STATE` がほぼ空のサンプルデータである事実（HIGH-5）は、§9.2 の権限表と §24 の移行計画の前提そのものを揺らす。§24.6 の Parity は移行の最終防衛線だが、**現状の期待値のままでは検証として機能しない**。

### 実装着手の条件

Phase 1 の完了条件（unresolved BLOCKER = 0 / unresolved HIGH = 0）に照らし、次の順で解消することを推奨する。

**Phase 2 のスキーマ確定前に必須（BLOCKER 3件 + スキーマに触る HIGH）**
BLOCKER-1 / BLOCKER-2 / BLOCKER-3 / HIGH-7（`period_key`）/ HIGH-9（`external_event_key`）/ HIGH-11（`rule_key` + `params`）/ MEDIUM-1 / MEDIUM-3 / MEDIUM-5。いずれも列・制約・ロール設定の追加で、実装量はごく小さい。

**Phase 3 着手前に必須**
HIGH-1（§9.2 / §9.3 の訂正。§28 の Q2 / Q3 と合わせてオーナー確認）/ HIGH-2（`STAFF_MAP` の移行先を `editor` Role と定義）/ HIGH-13（業務日付のタイムゾーン規約）。

**Phase 5 / 6 / 7 着手前に必須**
HIGH-6（`generate()` を契約単位へ・`phaseOf` のキー固定）/ HIGH-8（Workflow 変更規則を7条に）/ HIGH-10（Integration の接続主体）/ MEDIUM-6。

**移行フェーズ着手前に必須**
HIGH-3 / HIGH-4 / HIGH-5 / HIGH-12 / MEDIUM-8。§24 は数値の訂正と手順の入れ替えが中心で、**修正によってむしろ移行作業は軽くなる**（実データがほぼ無いため）。

以上の修正はいずれも Architecture の変更を伴わない。**修正後、Phase 2 から実装に入って差し支えない。**

---

## 付録 — 指摘ID一覧

| ID | 区分 | 章 | 要旨 |
|---|---|---|---|
| BLOCKER-1 | BLOCKER | §6.1 / §6.2 / §6.5 | Workspace 分離のスキーマ層防御が権限テーブルに存在しない |
| BLOCKER-2 | BLOCKER | §6.5 / §26.1 | Serverless + プーラ構成で RLS が機能しない／逆に漏れる |
| BLOCKER-3 | BLOCKER | §8.2 / §6.2 | Identity を email で束ねており OIDC `sub` を保存していない |
| HIGH-1 | HIGH | §9.2 / §9.3 | 既定 Role が現行挙動を再現していない・対応表に誤りと欠落 |
| HIGH-2 | HIGH | §24.4 / §10.5 | `STAFF_MAP` の破棄が誤り（編集担当ロスターである） |
| HIGH-3 | HIGH | §24.4 / §24.6 | Migration Matrix / Parity の期待値に事実誤認 |
| HIGH-4 | HIGH | §24.4 | `trans{}` の履歴展開が実データ上成立せず虚偽の監査履歴を作る |
| HIGH-5 | HIGH | §24 全体 | 現行 STATE がほぼ空のサンプルデータで移行計画と前提が乖離 |
| HIGH-6 | HIGH | §12.4 / §5.2 | 月次生成が ServiceContract を一級市民として扱っていない |
| HIGH-7 | HIGH | §11.6 / §6.2 | `workflow_runs` に期間キーが無く月次 Run を特定できない |
| HIGH-8 | HIGH | §11.5 | Workflow 変更時の4規則が不十分 |
| HIGH-9 | HIGH | §17.4 / §6.3 | Slack webhook の重複排除キーが誤りで別イベントを取りこぼす |
| HIGH-10 | HIGH | §8.2 / §15 / §16 | 退職時の Google アカウント停止が Integration を破壊する |
| HIGH-11 | HIGH | §13.3 | jsonb 条件式 DSL は過剰設計 |
| HIGH-12 | HIGH | §24.2 / §24.3 | UPSERT のみで削除が同期されず Parity ゲートの順序も逆 |
| HIGH-13 | HIGH | §6.1 / §12 / §13 / §23 | 業務日付の基準タイムゾーンが未定義 |
| MEDIUM-1 | MEDIUM | §5.1 / §6.2 | Task の状態保持が二重定義・ContentItem との整合性保証が無い |
| MEDIUM-2 | MEDIUM | §6.2 / §6.4 | Read Model を支える索引が不足 |
| MEDIUM-3 | MEDIUM | §14.4 / §13.6 / §24.5 | 本文で導入した列がスキーマ表に無い（3箇所） |
| MEDIUM-4 | MEDIUM | §22.1 | 楽観ロックの version が3つあり送る対象が未定義 |
| MEDIUM-5 | MEDIUM | §6.2 / §22.3 | `idempotency_keys` の主キーが Workspace 横断 |
| MEDIUM-6 | MEDIUM | §13 / §23 | `date.reached` に catch-up 機構が無い |
| MEDIUM-7 | MEDIUM | §26.5 / §26.6 | 監視通知が監視対象自身に依存している |
| MEDIUM-8 | MEDIUM | §3.4 / §24.6 / §25.6 | 「画素差0」の基準が二重で artifact 比較では達成不能 |
| MEDIUM-9 | MEDIUM | §7.2 / §12.1 / §4.2 | Core のスキーマ記述に Module 固有語が混入（P1 の自己違反） |
| MEDIUM-10 | MEDIUM | §15.1 / §23 | OAuth リフレッシュに single-flight 制御が無い |
| LATER-1 | LATER | §21.2 | Read Model のページングと ETag |
| LATER-2 | LATER | §9.5 | Scope 評価器の先行実装は不要（列のみ先行） |
| LATER-3 | LATER | §18.1 / §18.2 | 導出値の設定変更と過去画面の再現性 |
| LATER-4 | LATER | §28.3 | Audit / Automation Run の保持期間と分割 |
