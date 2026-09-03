# SOCIAL BASE Development Instructions

このリポジトリを変更する前に、必ず以下を参照してください。UI/UXの変更は「UI仕様書」を、システム（データ・権限・Workflow・外部連携）の変更は「システム設計書」を正とします。

## システム設計書
- `SOCIAL_BASE_SYSTEM_DESIGN.md` — システム設計の唯一の正典（v6）。データモデル、権限、Workflow、外部連携、移行手順。**Source of Truth は §5.6 の表を唯一の正とする**（D1 = 業務トランザクション / Notion = 人が保守するマスタ / Drive = ファイル本体）。
- `SOCIAL_BASE_ARCHITECTURE_REASSESSMENT.md` — 2026-09-03 のアーキテクチャ再評価（確定）。**Source of Truth の役割分担・D1 採用・Artifact を本番にしない判定の根拠**。設計書の前提を変えた文書なので、設計判断の背景を知りたいときはここを読む。
- `SOCIAL_BASE_SENIOR_REVIEW.md` / `_2` / `_3` / `_4` / `_5` / `SOCIAL_BASE_REVIEW_RESOLUTION.md` — 設計レビューと採否判断。有効な仕様は必ず正典へ反映されているため、仕様確認は正典だけを見ればよい。

## UI仕様書
- `SOCIAL_BASE_UI_IMPLEMENTATION_SPEC.md`
- `SOCIAL_BASE_TODAY_RESPONSIVE_SPEC.md`
- `SOCIAL_BASE_CLIENT_MANAGEMENT_RESPONSIVE_SPEC.md`

## 完成イメージ
- `01_home.png` — ホーム
- `02_today.png` — 今日
- `03_alldata.png` — 動画一覧 + 進行トラック統合
- `04_team.png` — チーム負荷
- `05_calendar.png` — 投稿カレンダー
- `06_client.png` — クライアント管理

## レスポンシブ仕様
- 「今日」画面のTablet/Mobile実装は `SOCIAL_BASE_TODAY_RESPONSIVE_SPEC.md` を正とする。
- 「クライアント管理」画面のDesktop Visual QAおよびTablet/Mobile実装は `SOCIAL_BASE_CLIENT_MANAGEMENT_RESPONSIVE_SPEC.md` を正とする。
- その他の画面については `SOCIAL_BASE_UI_IMPLEMENTATION_SPEC.md` のレスポンシブ方針を正とする。
- スマホ版・タブレット版はPC版の単純縮小にしない。

## 正式ロゴ
- `rogo.png`

## 仕様の優先順位
仕様同士で判断に迷った場合は、以下の順に優先する。

1. 該当画面専用の最新仕様書
2. `SOCIAL_BASE_UI_IMPLEMENTATION_SPEC.md`
3. 該当画面の完成イメージ画像
4. 現在の実装

ただし、完成イメージ画像内のダミーデータ・古いロゴ・古い文言・古いステータスは再現しない。
完成イメージ画像は主にレイアウト、サイズ比率、余白、情報階層、カード構造のVisual Specificationとして扱う。

## 重要ルール
- 仕様書と参考画像を確認せずにUIを独自判断で再設計しない。
- 既存機能を壊さず、段階的に改修する。
- 色、ステータス、文言、レスポンシブ仕様は仕様書を正とする。
- 「進行トラック」は独立ページにせず「動画一覧」へ統合する。
- 「クライアント管理」は社員のみに表示する。
- 正式ロゴは `rogo.png` のデザインを基準にする。
- 参考画像は単なる雰囲気参考ではなくVisual Specificationとして扱う。
- Visual QAでは、可能な限り参考画像と同じviewportでスクリーンショットを取得して比較する。
- 「概ね似ている」だけで完了扱いにしない。人間が目視確認してFIXするまでVisual QA中として扱う。

## 実装前
1. 現在のコード構造を確認する。
2. `SOCIAL_BASE_UI_IMPLEMENTATION_SPEC.md` を読む。
3. 対象画面専用の仕様書が存在する場合は必ず読む。
4. 該当画面の参考画像を確認する。
5. 変更対象と変更しない範囲を確認する。
6. 変更計画を簡潔に整理してから実装する。

## 実装後
1. `SOCIAL_BASE_UI_IMPLEMENTATION_SPEC.md` の Acceptance Criteria を使って自己チェックする。
2. 対象画面専用の仕様書がある場合は、その Acceptance Criteria も確認する。
3. Desktop / Tablet / Mobile の指定viewportでVisual QAする。
4. 横崩れ、コンソールエラー、既存機能の破損がないことを確認する。
5. 人間の目視確認前に「完全FIX」と判断しない。
