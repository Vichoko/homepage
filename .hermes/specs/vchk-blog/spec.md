---
id: SPEC-001
title: "vchk Blog — Pseudo-Anonymous Dev Blog"
status: draft
layer: system
tags: [vchk.eu, blog, zola, static-site, pseudo-anonymous]
acceptance: .hermes/specs/vchk-blog/acceptance/blog.feature
depends_on: [PR #8 - plan]
owner: Vichoko
created: 2026-06-27
---

## Purpose

The vchk blog exists to provide a standalone pseudo-anonymous developer blog at **vchk.eu**, fully disconnected from the identity of Vichoko and from vichoko.cl. Previously vchk.eu served as a meta-refresh redirect to vichoko.cl; this spec governs its repurposing into an independent technical blog focused on developer tools, CLI workflows, Linux administration, and code-level content — all signed as "vchk" with zero personal identifiers.

The core constraint is **pseudo-anonymity**: the domain name "vchk" bears a loose resemblance to "Vichoko" but no explicit link exists. The blog must never confirm the connection through cross-links, personal details, employment references, location data, or any identifier that would tie it to Vichoko's real-world identity. This enables candid technical writing without the baggage of an established professional persona, while accepting that determined observers may infer the connection from DNS history, GitHub ownership, or payment records.

---

## Requirements

### Functional Requirements

| ID | Title | Description | Priority | Rationale |
|----|-------|-------------|----------|-----------|
| REQ-F001 | Blog Accessibility | The blog SHALL be accessible at https://vchk.eu via browser and curl/HTTP clients. | P0 | The domain is the primary entry point; without this the blog does not exist. |
| REQ-F002 | Post Listing | The blog SHALL display a reverse-chronological list of all published posts on the homepage. | P0 | Blog readers expect to see latest content first. A homepage without post listings is not a blog. |
| REQ-F003 | Individual Post Pages | Each post SHALL have its own URL at `/posts/<slug>/`. | P0 | Required for permalink sharing, bookmarking, and SEO. |
| REQ-F004 | RSS Feed | The blog SHALL provide an RSS/Atom feed at `/atom.xml` or `/rss.xml`. | P1 | Allows feed readers to subscribe without visiting the site; critical for regular readership. |
| REQ-F005 | Tag System | Posts SHALL be taggable, with auto-generated tag index pages at `/tags/<tag>/`. | P1 | Content discovery across posts; enables readers to find related content by topic. |
| REQ-F006 | 404 Handling | The blog SHALL return a proper 4xx status for unknown URLs (not a soft-200 with error text). | P1 | HTTP semantics matter; a missing page should signal to search engines that content does not exist. |
| REQ-F007 | Empty State Gracefulness | The blog SHALL render a placeholder message (e.g., "No posts yet") when zero posts are published. | P2 | Prevents a broken-looking empty homepage on initial deployment. |

### Non-Functional Requirements

| ID | Title | Description | Priority | Rationale |
|----|-------|-------------|----------|-----------|
| REQ-N001 | Anonymity Enforcement | The blog MUST NOT contain any text linking it to Vichoko's real identity. | P0 | Core requirement — the blog is pseudo-anonymous. Any identity leak defeats the purpose. |
| REQ-N002 | No Cross-Link | The blog MUST NOT contain any hyperlinks or URLs to vichoko.cl. | P0 | Prevents identity linkage via navigation. A visible link from vchk.eu → vichoko.cl would confirm the connection. |
| REQ-N003 | No Analytics Tracking | The blog MUST NOT use Google Analytics, Plausible, or any external tracking that could link to Vichoko's analytics account. | P1 | Tracking cookies and shared analytics properties could expose identity via account associations. |
| REQ-N004 | Zero External Dependencies (Build) | The blog build SHALL not require npm, pip, or any language runtime except the SSG binary. | P1 | Minimal dependencies = minimal maintenance. No lockfiles, no node_modules, no build chain fragility. |
| REQ-N005 | Build Failure Isolation | If the Zola build fails, the deployment pipeline MUST abort and NOT sync stale or partial content to GCS. | P1 | Stale deploys from a failed build could serve broken pages indefinitely. |
| REQ-N006 | Responsive Layout | The blog SHALL render legibly on mobile viewports (320px width minimum). | P2 | A notable fraction of readers will access via mobile; monospace terminal aesthetic should not break on small screens. |

### Security & Privacy Requirements

| ID | Title | Description | Priority | Rationale |
|----|-------|-------------|----------|-----------|
| REQ-S001 | No Personal Identifiers | The blog MUST display zero instances of: real name, job title (Uber, Applied Scientist), location (Santiago, Chile), GitHub handle (Vichoko), or any other personal identifier. | P0 | Direct exposure of identity via any of these fields would destroy pseudo-anonymity. |
| REQ-S002 | HTTPS Only | All traffic to vchk.eu MUST be served over HTTPS with a valid TLS certificate. | P0 | Security baseline. Unencrypted HTTP exposes content to MITM and betrays poor operational hygiene. |
| REQ-S003 | WHOIS Privacy | The domain WHOIS MUST NOT expose registrant personal data. | P0 | GDPR redaction from EURid is the default for .eu domains but must be verified during setup. |
| REQ-S004 | No Origin IP Exposure | The origin server IP (GCS bucket or Cloudflare Pages) MUST NOT be directly reachable by clients. | P1 | Prevents bypass of Cloudflare's security layers and hides the underlying infrastructure. |
| REQ-S005 | Content Review Gate | Every post MUST undergo manual review for accidental personal references before merging. | P1 | Human error (e.g., accidentally mentioning a workplace tool or colleague) is the most likely leak vector. |

---

## Design

### Architecture Overview

```
                           ┌─────────────────────────────────────┐
                           │         GitHub Repository            │
                           │  ~/git/homepage/                    │
                           │  ├── .github/workflows/             │
                           │  │   ├── deploy.yaml       [home]   │
                           │  │   └── deploy-vchk.yaml  [blog]   │
                           │  ├── src/                 [home]    │
                           │  ├── blog/                [blog]    │
                           │  └── .hermes/             [meta]    │
                           └──────────┬──────────────────────────┘
                                      │ git push main (blog/**)
                                      ▼
                           ┌──────────────────────┐
                           │   GitHub Actions      │
                           │   deploy-vchk.yaml    │
                           │                      │
                           │   1. checkout         │
                           │   2. install zola     │
                           │   3. zola build       │
                           │   4. gsutil rsync     │
                           └──────────┬───────────┘
                                      │ blog/public/
                                      ▼
                           ┌──────────────────────┐
                           │   GCS Bucket          │
                           │   gs://vchk-blog      │
                           │   (static files)      │
                           │   index.html /atom.xml│
                           │   posts/*             │
                           │   tags/*              │
                           │   style.css           │
                           └──────────┬───────────┘
                                      │ Cloudflare CNAME
                                      │ vchk.eu → c.storage.googleapis.com
                                      ▼
                           ┌──────────────────────┐
                           │   Cloudflare DNS      │
                           │   + Proxy (orange)    │
                           │   TLS termination     │
                           └──────────┬───────────┘
                                      │
                                      ▼
                           ┌──────────────────────┐
                           │   End Users           │
                           │   https://vchk.eu     │
                           └──────────────────────┘
```

### Component Responsibilities

1. **Zola Static Site Generator** — Builds static HTML from Markdown content + Tera templates. Produces the `public/` directory containing index pages, individual post pages, tag index pages, RSS feed, and static assets. Single Rust binary with no language runtime dependencies.

2. **GitHub Actions (deploy-vchk.yaml)** — Triggered by pushes to `main` that include changes under `blog/`. Runs `zola build` and, on success, syncs the output to GCS via `gsutil rsync`. If the build step fails (non-zero exit), the workflow aborts before reaching the deploy step, preventing stale content from being served.

3. **GCS Bucket (gs://vchk-blog)** — Serves static files as a simple web host. Configured with `allUsers:objectViewer` IAM and `gsutil web set -m index.html` for directory index behavior. Entirely separate from the vichoko.cl bucket — no shared files, no shared IAM bindings.

4. **Cloudflare DNS** — Provides TLS termination, DDoS protection, and origin IP masking. DNS: `vchk.eu` CNAME → `c.storage.googleapis.com` (GCS bucket public URL). Cloudflare proxy (orange cloud) hides the bucket's raw IP.

5. **No Shared Infra with vichoko.cl** — The blog and homepage share a GitHub repository but no other infrastructure. Separate GCS bucket, separate GHA workflow, separate DNS CNAME. The repo owner ("Vichoko") is an accepted semi-linkable artifact.

### Data Flow

1. **Author writes:** Markdown post created in `blog/content/posts/<slug>/index.md`.
2. **Build trigger:** Commit pushed to `main` with changes under `blog/`.
3. **Static generation:** Zola reads `blog/config.toml` + `blog/content/` + `blog/templates/` → produces `blog/public/`.
4. **Deployment:** `gsutil -m rsync -r blog/public/ gs://vchk-blog` syncs only changed files.
5. **Serving:** Cloudflare receives request at `https://vchk.eu/posts/hello-world/`, proxies to GCS which serves the pre-generated `public/posts/hello-world/index.html`.
6. **RSS:** Zola generates `public/atom.xml` at build time; feed readers poll this static URL.

### Directory Structure

```
blog/
├── config.toml              # Zola configuration
├── content/                 # Markdown content
│   ├── _index.md            # Blog index (optional frontmatter)
│   └── posts/               # Individual blog posts
│       └── <slug>/
│           └── index.md     # Post content with frontmatter (title, date, tags)
├── templates/               # Zola Tera templates
│   ├── index.html           # Post list (homepage)
│   ├── page.html            # Individual post page
│   └── tags/                # Tag system templates
│       ├── list.html        # /tags/ — tag overview page
│       └── single.html      # /tags/<tag>/ — posts for a specific tag
├── static/                  # Static assets (served as-is)
│   └── style.css            # Blog CSS (dark terminal theme)
└── public/                  # Build output (gitignored)
    ├── index.html           # Generated homepage
    ├── atom.xml             # RSS feed
    ├── posts/               # Generated post pages
    ├── tags/                # Generated tag pages
    └── style.css            # Copied from static/
```

### Deployment Pipeline

1. Developer writes a post as Markdown in `blog/content/posts/<slug>/index.md`.
2. Post is reviewed locally (grep for identity leaks, proofreading).
3. Commit is pushed to `main` on the `~/git/homepage/` repository.
4. GitHub Actions workflow `deploy-vchk.yaml` triggers (paths: `['blog/**']`).
5. Workflow installs Zola via prebuilt binary download.
6. `zola build` runs in the `blog/` working directory.
7. **On success:** `gsutil -m rsync -r blog/public/ gs://vchk-blog` syncs output.
8. **On failure:** Workflow exits non-zero; GCS bucket is untouched.
9. Cloudflare serves the updated content from GCS at `https://vchk.eu`.

---

## Edge Cases

The following edge cases could break or degrade the system and should be addressed during implementation:

| Case | Description | Mitigation |
|------|-------------|------------|
| **Empty blog** | Fresh deployment with zero posts; homepage lists nothing. | Template should detect `section.pages` is empty and render "No posts yet" or equivalent placeholder. |
| **Post with no tags** | A post without frontmatter tags should still render without error. | Template must handle missing/empty `page.tags` gracefully; no tag section should appear. |
| **Post with extremely long title** | Title wraps poorly or breaks layout. | CSS: `word-break: break-word` and `overflow-wrap: break-word` on title elements; max-width constraints. |
| **Very old dates** | Date in frontmatter set to year 1900 or earlier. | Zola's date parsing may fail on out-of-range dates. Validate frontmatter dates at build time or constrain to reasonable range. |
| **Special characters in slug/title** | Unicode, spaces, or HTML entities in URLs. | Zola URL-encodes slugs automatically; verify no double-encoding or 404s on non-ASCII characters. |
| **Large number of posts (100+)** | Single homepage lists all posts → slow render or huge page. | Zola's `paginate_by` config: set `paginate_by = 20` in `config.toml` with auto-generated `/page/2/`, `/page/3/`, etc. |
| **Post content with raw HTML** | HTML injection in Markdown body. | Zola defaults to escaping HTML; if `safe` filter or `markdown_inline` with raw HTML is used, ensure no script injection is possible. |
| **Build failure mid-deploy** | Zola build fails; GCS should not be updated. | GHA workflow: deploy step runs only if build step succeeds (default GHA behavior — sequential steps fail fast). |
| **Accidental identity leak in post** | Author writes "when I worked at Uber" inadvertently. | CI check: add a step that greps built output for blocked terms (`vichoko`, `uber`, `applied scientist`, `santiago`, `chile`) and fails the build if any match. |
| **DNS propagation delay** | After bucket swap, old content (redirect) may still serve due to TTL. | Set Cloudflare DNS TTL low (300s) during cutover; verify with `curl -sI https://vchk.eu` until 200 + no Location header. |
| **Bucket name collision** | `vchk-blog` GCS bucket name already taken. | Use a globally unique suffix or verify availability with `gsutil ls`. |
| **Cloudflare proxy not enabled** | Visitors reach GCS bucket directly, exposing origin. | Verify orange cloud icon in Cloudflare dashboard for the vchk.eu DNS record. |
| **GitHub Actions secret missing** | GCP service account key not set. | Workflow should fail early with a clear error; document required secrets in the workflow file comment. |

---

## Open Questions

The following decisions remain unresolved and should be finalized during Phase 2 implementation:

| # | Question | Options | Recommendation | Decision Driver |
|---|----------|---------|----------------|-----------------|
| 1 | **SSG choice** | Zola / Hugo / Plain HTML | **Zola** — single Rust binary, built-in RSS and tags, minimal deps | Verify Zola's syntax highlighting and taxonomies meet requirements before committing. |
| 2 | **Hosting platform** | GCS bucket / Cloudflare Pages | **GCS** (Option A) — stays in Google ecosystem, reuse existing GCP project, straightforward gsutil deploy | Cloudflare Pages offers simpler deploy (no GCP secrets), but requires wrangler CLI. Evaluate during implementation. |
| 3 | **Contact method** | None / GitHub issues / `mailto:vchk@vchk.eu` | **None initially** — zero identity exposure; can add later if reader engagement demands it | GitHub issues link back to Vichoko's repo; dedicated email requires mail infrastructure. Defer. |
| 4 | **CSS framework** | From scratch / Simple.css / MVP.css / water.css | **From scratch** — dark terminal aesthetic is unique; frameworks like simple.css add unwanted visual style | Terminal aesthetic (#0a0a0a bg, JetBrains Mono, lime/cyan accents) is too specific for off-the-shelf CSS. |
| 5 | **CI/CD secrets** | GCP service account JSON stored as GHA secret | **Required** — create dedicated GCP service account with minimal permissions (only `storage.objectAdmin` on `gs://vchk-blog`) | Need to generate and store the service account key; document the setup process. |
| 6 | **Search functionality** | Client-side JS (lunr.js / fuse.js) / None | **None initially** — keep zero external dependencies; add later if content volume justifies it | Zola has no built-in search; client-side JS adds complexity and a JS dependency. Defer. |
| 7 | **CI identity leak check** | grep in GHA workflow / separate linting step | **grep step in GHA** — simple, effective, no extra tooling | `grep -riE 'vichoko|uber|applied.scientist|santiago|chile' blog/content/` as a pre-build check. |
| 8 | **Post frequency guarantee** | None / weekly / monthly | **None** — write when there's something worth sharing; quality over cadence | A schedule would pressure content quality and risk personal-story filler posts. No commitment. |
