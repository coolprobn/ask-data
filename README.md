# Ask Data

Natural-language → read-only SQL against PostgreSQL (Rails + Ollama). See `docs/ask-data-plan.md` for the full roadmap.

Implementation notes (blog-style, updated as we build): [`docs/blog.md`](docs/blog.md).

## NL query exposure (Ticket 0.1)

- **Single source of truth:** `config/nl_query.yml` defines which **tables** may be used in NL queries and which **columns** are forbidden (patterns + per-table list).
- **Changing exposure:** edit that file (and redeploy/restart); run tests under `test/services/nl_query/` after changes.
- **Runtime API:** `NlQuery::Exposure` filters columns for LLM schema text (`filter_columns_for_llm`, `llm_schema_lines_for_table`) and strips forbidden keys from result rows (`redact_result_row`).

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
