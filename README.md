# Ask Data

Natural-language → read-only SQL against PostgreSQL (Rails + Ollama). See `docs/ask-data-plan.md` for the full roadmap.

Implementation notes (blog-style, updated as we build): [`docs/blog.md`](docs/blog.md).

## Security warning — no authentication (Ticket 1.2)

**This app ships without authentication** (no Devise, sessions, HTTP Basic, or API tokens for the UI). That keeps the learning and localhost demo path minimal.

**Do not expose this stack to the public internet as-is.** Anyone who can reach the web UI can run the natural-language query flow against your machine’s Postgres and Ollama. **Read-only SQL validation protects the database from writes**, but it does **not** protect you from **unauthorized use** of the app, resource exhaustion, or abuse of your Ollama endpoint. If you ever deploy beyond a trusted network, add **authentication, rate limiting, and operational hardening** (see Phase 2 in the plan) or keep access private (VPN, SSH tunnel, etc.).

## NL query exposure (Ticket 0.1)

- **Single source of truth:** `config/nl_query.yml` defines which **tables** may be used in NL queries and which **columns** are forbidden (patterns + per-table list).
- **Changing exposure:** edit that file (and redeploy/restart); run tests under `test/services/nl_query/` after changes.
- **Runtime API:** `NlQuery::Exposure` filters columns for LLM schema text (`filter_columns_for_llm`, `llm_schema_lines_for_table`) and strips forbidden keys from result rows (`redact_result_row`).

## Ollama + RubyLLM (Ticket 0.2)

- **Gem:** [`ruby_llm`](https://rubygems.org/gems/ruby_llm) — all LLM calls go through RubyLLM (no ad-hoc HTTP to Ollama in `app/`).
- **Config:** `config/initializers/ruby_llm.rb` sets `ollama_api_base` from **`OLLAMA_BASE_URL`** (default `http://127.0.0.1:11434`; normalized to `…/v1` for RubyLLM’s OpenAI-compatible endpoint), **`OLLAMA_MODEL`** (default `qwen2.5-coder:7b`), optional **`OLLAMA_API_KEY`**, and optional **`RUBYLLM_REQUEST_TIMEOUT`** (seconds).
- **NL→SQL:** `NlQuery::TextToSqlClient` builds system/user messages and returns `NlQuery::TextToSqlResult` (`sql`, `rationale`, `raw`). Inject a fake `completion` in tests so CI does not need Ollama.
- **Live smoke:** with Ollama running and the model pulled, `ollama list` should include `OLLAMA_MODEL`; then run a manual ask from `rails console` if you want to confirm end-to-end.

## Mini-shop schema & seeds (Ticket 0.3)

- **Tables:** `categories`, `products`, `customers` (includes nullable `internal_memo` for redaction demos), `orders`, `order_items` — see migration `db/migrate/*_create_mini_shop.rb` and `db/schema.rb`.
- **Reproducible counts** after `bin/rails db:seed` (or `bin/rails db:reset`):
  - **10** categories  
  - **42** products (**2** never appear on any line item: **SEED-041**, **SEED-042**)  
  - **24** customers (**4** have zero orders: emails `nosale01@seed.example.com` … `nosale04@seed.example.com`)  
  - **75** orders (`placed_at` from **2024** through **2026**; **20** orders strictly after **2025-12-10** for date-range demos)  
  - **225** order line items (1–5 lines per order; **SEED-007** appears on more than one order)  
  - **Whale** customer `whale@seed.example.com`: **38** orders with slightly marked-up line prices for high `total_cents` totals.

## Product policy & safe errors (Ticket 0.4)

- **In-app:** **`/`** and **`GET /ask`** render the Ask form (`QuestionsController#ask`); **`POST /ask`** runs the NL pipeline (`QuestionsController#create`); **`/policy`** is the “what this can do” page (`StaticPagesController#policy`). The full ticket text is **`docs/ask-data-plan.md`** (section **Ticket 0.4**).
- **Pipeline:** `NlQuery::NaturalLanguageQuery` runs **ambiguity hints** → `NlQuery::TextToSqlClient` (prompts require SELECT-only, no invented columns, clarify or omit SQL when needed) → **`NlQuery::SqlGuard`** (minimal read-only gate: no DDL/DML keywords, single statement, `WITH`/`SELECT` only).
- **User-visible strings** live in `NlQuery::ProductPolicy::MESSAGES`; **`NlQuery::QueryResult#user_safe_payload`** omits SQL and internals for UI layers.
- **Suggested questions** for clarification UX: `NlQuery::ProductPolicy::SUGGESTED_QUESTIONS` (keep in sync with README / Epic 6 golden list when you add it).

## Rails UI — Slim + Tailwind (Ticket 1.1)

- **Templates:** [`slim-rails`](https://github.com/slim-template/slim-rails) is in the Gemfile. App layout and feature screens use **`.html.slim`** (`app/views/layouts/application.html.slim`, `questions/`, `static_pages/`). Mailer layouts remain **ERB** under `app/views/layouts/mailer*`; PWA stubs may stay **ERB** as generated.
- **CSS:** [tailwindcss-rails](https://github.com/rails/tailwindcss-rails) — `app/assets/tailwind/application.css` imports Tailwind; use utility classes in Slim (`class="..."` / `.class` chains). Run `bin/dev` or `bin/rails tailwindcss:watch` in development so CSS rebuilds.

## Ask UI + browse tables (Tickets 1.3–1.4)

- **Ask:** `questions/ask` — textarea, **`POST /ask`** to run **`NlQuery::NaturalLanguageQuery`** with a live **`NlQuery::SchemaSnapshot`** from `information_schema`, then **`NlQuery::RunQuery`** on success paths only. Suggested questions and chips read from **`NlQuery::ProductPolicy::SUGGESTED_QUESTIONS`** (single source of truth). Stimulus **`ask-form`** handles example chips and a disabled “Running…” submit state.
- **Browse (read-only):** **`GET /customers`**, **`GET /products`**, **`GET /orders`** — simple index tables to sanity-check NL results against seed data (Ticket 1.4 scope folded in so verification links work).
- **Nav:** layout partial `layouts/_nav` links Ask, browse routes, and policy.

## No authentication by design (Ticket 1.2)

- **Gemfile:** no `devise`, OAuth, JWT, or similar auth gems for the web app (`bcrypt` remains commented unless you add it for something else).
- **Routes:** no `/login`, `/sessions`, or OAuth callbacks. **No tests** assert `401 Unauthorized` for the Ask or browse flows—that would be the wrong goal for v1.
- **Reminder:** read the **Security warning** section at the top of this README before exposing the app to a network.

## Ruby version

See `.ruby-version`.

## Setup

```bash
bundle install
bin/rails db:create db:migrate db:seed
# or recreate everything from migrations + seeds:
bin/rails db:reset
```

(PostgreSQL must be running; database names come from `config/database.yml`.)

## Tests

```bash
bin/rails test
```

## Manual QA

(To be expanded in Epic 5 — see plan.)
