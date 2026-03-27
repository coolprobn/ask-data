# Ask Data

Natural-language → read-only SQL against PostgreSQL (Rails + Ollama). See `docs/ask-data-plan.md` for the full roadmap.

Implementation notes (blog-style, updated as we build): [`docs/blog.md`](docs/blog.md).

## NL query exposure (Ticket 0.1)

- **Single source of truth:** `config/nl_query.yml` defines which **tables** may be used in NL queries and which **columns** are forbidden (patterns + per-table list).
- **Changing exposure:** edit that file (and redeploy/restart); run tests under `test/services/nl_query/` after changes.
- **Runtime API:** `NlQuery::Exposure` filters columns for LLM schema text (`filter_columns_for_llm`, `llm_schema_lines_for_table`) and strips forbidden keys from result rows (`redact_result_row`).

## Ollama + RubyLLM (Ticket 0.2)

- **Gem:** [`ruby_llm`](https://rubygems.org/gems/ruby_llm) — all LLM calls go through RubyLLM (no ad-hoc HTTP to Ollama in `app/`).
- **Config:** `config/initializers/ruby_llm.rb` sets `ollama_api_base` from **`OLLAMA_BASE_URL`** (default `http://127.0.0.1:11434`; normalized to `…/v1` for RubyLLM’s OpenAI-compatible endpoint), **`OLLAMA_MODEL`** (default `qwen2.5-coder:7b`), optional **`OLLAMA_API_KEY`**, and optional **`RUBYLLM_REQUEST_TIMEOUT`** (seconds).
- **NL→SQL:** `NlQuery::TextToSqlClient` builds system/user messages and returns `NlQuery::TextToSqlResult` (`sql`, `rationale`, `raw`). Inject a fake `completion` in tests so CI does not need Ollama.
- **Live smoke:** with Ollama running and the model pulled, `ollama list` should include `OLLAMA_MODEL`; then run a manual ask from `rails console` if you want to confirm end-to-end.

## Ruby version

See `.ruby-version`.

## Setup

```bash
bundle install
bin/rails db:create db:migrate db:seed
```

(PostgreSQL must be running; database names come from `config/database.yml`.)

## Tests

```bash
bin/rails test
```

## Manual QA

(To be expanded in Epic 5 — see plan.)
