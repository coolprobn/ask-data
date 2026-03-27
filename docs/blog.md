# Ask Data — build log (blog)

Technical notes from implementing [ask-data-plan.md](./ask-data-plan.md). Newest entries first.

### Continuing to the next ticket

After each completed ticket, the implementer will state **what’s next** (per the plan’s dependency order) and how to verify. To move on, send a short message such as:

- **“Continue with the next ticket”** or **“Implement Ticket 1.3”** (replace with the ID named in the last summary).

That keeps scope clear and matches the “stop after each ticket” loop.

---

## Ticket 2.1 — Schema snapshot builder (allowlist + redaction + PK/FK)

**2025-03-27**

**`NlQuery::SchemaSnapshot`** now builds LLM-facing text per allowlisted table: **`information_schema`** column metadata filtered through **`Exposure.column_exposed?`** before formatting (forbidden columns never appear). **`connection.primary_key`** drives a **Primary key:** line (only exposed parts). **`connection.foreign_keys`** emits **Foreign keys:** lines when the target table is allowlisted and both ends of the relationship pass exposure checks.

**Tests:** `schema_snapshot_test.rb` asserts no `internal_memo` / `api_token_digest` substrings, PK/FK substrings for the mini-shop FK graph, and that private column loading drops forbidden names.

**Verification:** `bin/rails test`, `bin/rails zeitwerk:check` — green.

**Next:** Ticket **2.2** — confirm NL→SQL is fully exercised via RubyLLM with stubbed tests (already largely true); tighten docs or add integration smoke notes if needed. Then **2.3** prompts polish.

---

## Ticket 1.3 — Ask UI + verification hints (browse indexes)

**2025-03-27**

**Ask** (`questions/ask.html.slim`): textarea, **`POST /ask`** → **`NlQuery::SchemaSnapshot.for_llm`** (allowlisted tables via `information_schema`) + **`NlQuery::NaturalLanguageQuery`**, then **`NlQuery::RunQuery`** when the pipeline returns **`success`** (guarded execution; SQL never rendered in the HTML). User-facing errors use **`ProductPolicy::MESSAGES`**; execution failures add **`execution_failed`**. **Suggested questions** expanded to **9** strings in **`NlQuery::ProductPolicy::SUGGESTED_QUESTIONS`**; chips use **`button_tag`** + Stimulus **`ask-form`** (`fill` params, submit loading state).

**Browse / Ticket 1.4 overlap:** `customers#index`, `products#index`, `orders#index` (read-only tables) plus **`layouts/_nav`** so Ask verification hints use real `link_to` targets and browse is discoverable. Optional **`categories#index`** remains if you want parity with the plan’s “optional” row.

**Tests:** service tests for **`SchemaSnapshot`** and **`RunQuery`**; integration tests for **`POST /ask`** (ambiguous question, stubbed success + table, stubbed execution failure) plus one **`GET`** per browse controller; **`QuestionsController.nl_query_executor`** hook for fakes.

**Verification:** `bin/rails test`, `bin/rails zeitwerk:check` — green.

**Next:** Epic **2 / Ticket 2.1** (full allowlist/redaction schema snapshot) or add **`categories#index`** to close Ticket **1.4** optional scope.

---

## Ticket 1.2 — No authentication (by design)

**2025-03-27**

v1 intentionally has **no login**: no Devise, OAuth, HTTP Basic, or session gates on Ask or static pages. The **Gemfile** stays free of auth gems; **`bcrypt`** remains commented with a note. **Routes** have no `/login` or session resources. Read-only SQL guards are about **data writes**, not about who can open the UI—README now has a **prominent warning** that exposing the app to the internet without auth/hardening is unsafe.

**Verification:** repo review + README; no “unauthorized” tests added (they would fight the product goal).

**Next:** Ticket **1.3** — Ask UI with suggested questions, verification hints, and DRY example strings.

---

## Ticket 1.1 — Slim layouts + Tailwind for feature views

**2025-03-27**

The app already used **tailwindcss-rails**; this ticket adds **`slim-rails`** and converts the **main layout** and **feature views** (`questions/ask`, `static_pages/policy`) from ERB to **`.html.slim`**. Mailer layouts stay **ERB** (email-friendly defaults); PWA JSON/JS stubs remain as generated.

**Tailwind** is still driven from `app/assets/tailwind/application.css` (`@import "tailwindcss"`); Slim markup uses the same utility classes (`container`, `max-w-3xl`, `text-gray-700`, etc.). Policy copy uses `raw(...)` for static HTML fragments (`<strong>`, `<code>`) to match the previous ERB output without fighting Slim’s inline-tag rules.

**Verification:** `bin/rails test` and `bin/rails zeitwerk:check` — green. Browse/index tables are **Ticket 1.4**, not this ticket.

---

## Ticket 0.4 — Product policy: prompts, safe errors, minimal guard

**2025-03-27**

Ticket 0.4 makes the “honest limitations” and “product policy” from the plan **real code**, not README-only prose. **`NlQuery::ProductPolicy`** holds user-facing copy, suggested NL questions for the clarification path, and a simple **`ambiguous?`** heuristic (very short or too-few-word questions get **clarification** with deterministic suggestions, not a risky LLM guess). **`NlQuery::SqlGuard`** is a minimal **read-only** gate: no `INSERT`/`UPDATE`/etc., no multi-statement `;`, and the statement must start as **`WITH`** or **`SELECT`**. Epic 3 will replace this with a fuller parser + allowlist walk.

**`NlQuery::NaturalLanguageQuery`** ties it together: ambiguity → optional early exit; otherwise NL→SQL; empty SQL → **schema gap** message; failing guard → **guard rejected** without echoing the bad SQL; **`LlMUnavailableError`** → a short connectivity message (no stack traces). **`NlQuery::QueryResult`** exposes **`user_safe_payload`** for future controllers so the UI never gets raw SQL on error paths.

**Prompts:** `TextToSqlClient::SYSTEM_PROMPT` now explicitly tells the model not to invent columns, to **clarify** when underspecified, and to **omit SQL** when the schema cannot support the question.

**In-app:** **`/`** and **`/ask`** serve **`QuestionsController#ask`** (placeholder Ask UI); **`/policy`** is **`StaticPagesController#policy`** (Slim since Ticket 1.1). Policy points at `docs/ask-data-plan.md`.

**Verification:** `bin/rails test` covers SqlGuard, NL pipeline with **stubbed** bad SQL (asserts no `INSERT` in user copy), schema gap, and LLM-unavailable mapping. Integration tests cover **`GET /policy`**, **`GET /`**, and **`GET /ask`** separately.

---

## Ticket 0.3 — Mini-shop Postgres schema + deterministic seeds

**2025-03-27**

This ticket adds the **locked** e-commerce demo from the plan: one migration creates `categories`, `products`, `customers` (with **`internal_memo`** for redaction demos), `orders`, and `order_items`, plus indexes on FKs and on `orders.placed_at` / `orders.status`. ActiveRecord models wire associations and validate order **status** against the four string values the plan expects.

**Seeds** live in **`db/seeds/mini_shop.rb`** and are loaded from **`db/seeds.rb`**. The script is fully deterministic: fixed category names, `SEED-001`…`SEED-042` SKUs, and a scripted split of products across categories (8×4 + 2×5 = **42** products). The last two SKUs are never attached to an order. **Whale Wholesale LLC** (`whale@seed.example.com`) takes **38** orders with a 10% line-price bump so aggregates and `ORDER BY` demos have a clear outlier. **Four** customers (`nosale01`…`nosale04`) never receive orders. **75** orders use a fixed status array (enough **cancelled** and **pending** rows for filter examples). **55** orders sit in the 2024–2025 range; **20** are scheduled from **2025-12-11** onward so “after 10 December 2025”–style questions have plenty of rows. **SEED-007** is duplicated across two orders to exercise join semantics.

**Verification:** `bin/rails db:reset` (or test DB migrate + seed) completes cleanly; README documents the final counts; **`bin/rails test`** includes light model tests for associations and status validation.

---

## Ticket 0.2 — RubyLLM + Ollama: config, wrapper, stubbable tests

**2025-03-27**

Ticket 0.2 wires the **ruby_llm** gem to a local **Ollama** instance using the same env vars we document for readers: **`OLLAMA_BASE_URL`** (defaults to `http://127.0.0.1:11434`) and **`OLLAMA_MODEL`** (defaults to `qwen2.5-coder:7b`). RubyLLM’s docs expect an OpenAI-compatible base URL ending in **`/v1`**, so **`NlQuery::OllamaEnv.normalize_ollama_openai_base`** appends `/v1` when it’s missing—no manual `/v1` in env unless you want to be explicit.

**Initializer:** `config/initializers/ruby_llm.rb` calls `RubyLLM.configure` with `ollama_api_base`, optional `ollama_api_key` (for authenticated remote Ollama only), `default_model`, Rails logger, and a configurable request timeout (`RUBYLLM_REQUEST_TIMEOUT`, default 300s).

**Thin wrappers:**

- **`NlQuery::OllamaChatCompletion`** — one place that builds `RubyLLM.chat(..., provider: :ollama, assume_model_exists: true)`, sets instructions, and `ask`s the user payload. Network and RubyLLM API failures are mapped to **`NlQuery::LlmUnavailableError`** so callers (and later the orchestrator) can show a safe message.
- **`NlQuery::TextToSqlClient`** — owns the NL→SQL **system prompt** (SELECT-only, schema-bound; fuller Ticket 0.4 policy lands in Epic 4) and the user message shape (`Schema:` / `Question:`). It takes **`completion:`** in the constructor so tests inject a stub object that responds to `complete(system:, user:)`—**no Ollama process required in CI**.
- **`NlQuery::ModelReplyParser`** — extracts SQL from ```sql fences (with a small fallback for a bare `SELECT` / `WITH` line).

**Verification:** `bin/rails test` covers URL normalization, parsing, and the client with a fake completion. **`bin/rails zeitwerk:check`** should stay green.

**Next:** Ticket **0.3** — Postgres migrations + deterministic mini-shop seeds (`db:reset`).

---

## Ticket 0.1 — Column allow/deny: one config, two surfaces

**2025-03-27**

Ask Data will send a **schema snapshot** to a local LLM and show **tabular query results** in the browser. Both are trust boundaries: you do not want internal memos, token digests, or password-ish column names in either place. Ticket 0.1 fixes that at the source with a single YAML file and a small Ruby API—before any SQL generation or execution exists.

### The problem in one sentence

If the model never *sees* a sensitive column and the UI never *renders* it, you have halved the accidental leak surface for a teaching demo.

### What we shipped

1. **`config/nl_query.yml`**  
   - **`allowed_tables`:** the mini-shop tables the NL feature is allowed to reason about (`categories`, `products`, `customers`, `orders`, `order_items`). Anything else is treated as off-limits.  
   - **`forbidden_column_patterns`:** Ruby regexp *sources* matched against **column names only**—e.g. things starting with `password` or `encrypted_`, or ending with `_digest`.  
   - **`explicit_forbidden_columns`:** per-table denials for columns that are not caught by a generic pattern. For the demo domain we block `customers.internal_memo` and `customers.api_token_digest` so a future migration can add them without forgetting to hide them.

   Rails loads this via `Rails.application.config_for(:nl_query)` with the usual `default` / per-environment YAML merge, so changing exposure is a config edit plus deploy (or restart in dev).

2. **`NlQuery::Exposure`** (`app/services/nl_query/exposure.rb`)  
   One module answers: “Is this table in scope?” and “Is this column safe to expose?” It exposes helpers for:
   - **LLM-facing text:** `filter_columns_for_llm`, `llm_schema_lines_for_table` — forbidden columns are **omitted**, not redacted in place, so the model’s world matches your policy.  
   - **Result rows:** `redact_result_row` — drops keys that fail the same checks (for when execution returns a hash-like row keyed by column name).

   There is a **`reload!`** for tests or consoles that need to pick up config changes without a full process restart.

3. **Tests** (`test/services/nl_query/exposure_test.rb`)  
   Unit tests assert that explicit forbids, pattern forbids, LLM line joining, row redaction, and unknown tables all behave as expected—no database fixtures required.

4. **README**  
   A short “NL query exposure” section points readers at the YAML and `NlQuery::Exposure` so the repo stays navigable without rereading the full plan.

### Design choice worth naming

**Patterns operate on column names, not cell values.** That keeps the rule set small and fast. Row-level redaction for *values* is a different product (PII in a “safe” column); v1 stays at name-based exposure.

### How to verify locally

```bash
bin/rails test test/services/nl_query/exposure_test.rb
```

Optional sanity check:

```bash
bin/rails runner 'p NlQuery::Exposure.filter_columns_for_llm("customers", %w[email internal_memo])'
# => ["email"]
```

### What comes next (per plan)

Ticket **0.2** wires **ruby_llm** + Ollama with env-based config and a stubbable prompt wrapper so CI never depends on `localhost:11434`. This exposure layer will plug into the schema snapshot builder in Epic 2 and result rendering in Epic 4.

---

*End of entry — Ticket 0.1*
