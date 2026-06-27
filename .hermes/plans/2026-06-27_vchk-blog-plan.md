# Plan: vchk Blog — Pseudo-Anonymous Dev Blog

> **Para Hermes:** Plan de proyecto para repurpose vchk.eu de una creepypasta redirect page a un dev blog standalone, completamente desconectado de la identidad de Vichoko.

**Goal:** Crear un developer blog pseudo-anónimo en vchk.eu, sin ningún link a vichoko.cl, sin datos personales, sin referencias a Uber, y sin "about me" que conecte con la identidad real.

**Current Context:** vchk.eu actualmente apunta a Cloudflare → GCS (mismo bucket que vichoko.cl) con un meta-refresh redirect a vichoko.cl. El nombre "vchk" suena similar a "vichoko" pero no es directamente vinculable. Vichoko es Applied Scientist II en Uber — pero el blog no debe mencionarlo.

---

## Metadata
- **Title:** vchk Blog — Pseudo-Anonymous Dev Blog
- **Created:** 2026-06-27
- **Status:** Draft
- **Type:** Plan
- **Tags:** vchk.eu, blog, pseudo-anonymous, static-site

## Goals
- Crear un dev blog standalone en vchk.eu
- Desconectarlo completamente de la identidad Vichoko (sin cross-links, sin información personal)
- Publicar contenido dev útil/interesante firmado como "vchk"
- Mantener separación total de infraestructura con vichoko.cl

## Anti-Goals
- NO conectado a vichoko.cl ni a la identidad Vichoko
- NO información personal (nombre, trabajo, empleador, ubicación)
- NO cross-links entre vchk.eu y vichoko.cl
- NO "about me" que conecte con la identidad real
- NO mencionar Uber, Applied Scientist, o cualquier detalle laboral

---

## 🏗️ Proposed Architecture

### Option A: Separate GCS bucket + separate GHA workflow (keep in same repo) ⭐ RECOMMENDED
- **Pros:** Un solo repo para mantener, CI/CD ya conocido, reuse de patrones existentes
- **Cons:** El repo owner sigue siendo "Vichoko" — semi-linkable pero aceptable si no hay menciones en el código
- **Details:**
  - Nuevo bucket `vchk-blog` en GCS (separado del bucket de vichoko.cl)
  - Nuevo workflow `.github/workflows/deploy-vchk.yaml`
  - Source en `blog/` en vez de `src/`
  - Sin cross-contamination con `src/` (homepage)
  - DNS: vchk.eu CNAME → `c.storage.googleapis.com` apuntando al nuevo bucket

### Option B: Separate repo entirely
- **Pros:** Aislamiento total, cero posibilidad de leak accidental en el código
- **Cons:** El repo owner sigue siendo "Vichoko/Vichoko" — igualmente semi-linkable. Más overhead de mantenimiento.
- **Details:**
  - Nuevo repo `vchk/blog` en github.com/Vichoko/vchk-blog
  - Separate CI/CD, separate GCS bucket
  - No connection whatsoever al homepage repo
  - **Riesgo:** El nombre del repo en GitHub still links to Vichoko account

### Option C: Cloudflare Pages (no GCS)
- **Pros:** Fuera de Google infra, separación natural, free tier generoso
- **Cons:** Otro proveedor que configurar, otro deploy pipeline
- **Details:**
  - DNS: vchk.eu apunta a Cloudflare Pages (no a GCS)
  - Deploy via `wrangler` CLI o GitHub integration
  - Sin relación con GCP project de Vichoko

---

## 🎨 Design & Aesthetic

### Visual Style
- **Theme:** Dark terminal (fondo negro #0a0a0a o #1a1a1a, texto verde/cyan, tipografía monospace)
- **Fonts:** `JetBrains Mono`, `Fira Code`, o `IBM Plex Mono` — consistentes con aesthetic dev
- **Accent color:** Lime green `#66ff66` y cyan `#00ffff` — vagamente similar al homepage pero sin ser idéntico
- **No brand connection** a vichoko.cl (diferente palette, diferente layout, diferente header)

### Layout
- Single-column content, minimalista
- Post list con título + fecha + tags
- Sin avatars, sin "about the author", sin foto
- Footer minimal: `© vchk` o nada

### Content Signature
- Artículos firmados como `— vchk` o sin firma
- Sin "escrito por Vichoko", sin "About Me"
- Sin bio, sin foto de perfil

---

## 📝 Content Strategy

### Topics
- CLI tips and tricks (bash, zsh, tmux, git)
- Tool configs (neovim, kitty, lazygit, fzf)
- Python/ML dev tips (no mentioning Uber or work context)
- Linux/system administration notes
- Interesting technical findings
- Code snippets with explanations

### Tone & Voice
- Neutro, técnico, directo
- Sin historias personales, sin "when I worked at X", sin viajes
- Sin "my journey" posts
- First-person plural ("we can...", "one approach is...") o imperativo ("use x to...")
- Evitar primera persona singular ("I do this at work...")

### Structure
- Posts categorizados/tagged para fácil discovery
- RSS feed automático (si el SSG lo soporta)
- Search básico (JS client-side o nada)

---

## 🚧 Implementation Steps

### Phase 1: Detach vchk.eu from homepage infra

1. **Crear nuevo bucket GCS** `vchk-blog` (o decidir Option C: Cloudflare Pages)
   ```bash
   gsutil mb -l us-central1 gs://vchk-blog
   gsutil iam ch allUsers:objectViewer gs://vchk-blog
   gsutil web set -m index.html gs://vchk-blog
   ```

2. **Remover contenido actual** (Memory Capsule) del bucket/dominio
   - Si comparte bucket con vichoko.cl: mover/eliminar los archivos de vchk.eu
   - Asegurar que no queda ningún archivo referenciando vichoko.cl

3. **Actualizar DNS en Cloudflare:**
   - Cambiar vchk.eu CNAME de GCS bucket compartido al nuevo bucket
   - O cambiar a Cloudflare Pages si se elige Option C
   - Remover el meta-refresh redirect

4. **Verificar no cross-contamination:**
   ```bash
   curl -sI https://vchk.eu | head -5   # No redirect
   curl -sL https://vchk.eu | grep -i vichoko  # Empty
   curl -sL https://vichoko.cl | grep -i vchk  # Empty (should already be)
   ```

### Phase 2: Set up blog framework

1. **Elegir static site generator**

   | SSG | Pros | Cons |
   |-----|------|------|
   | **Zola** | Rust-based, rápido, single binary, built-in tags/RSS | Menos themes, syntax highlighting limitado |
   | **Plain HTML+JS** | Zero dependencies, máximo control | No RSS automático, más trabajo manual |
   | **Hugo** | Muy maduro, muchos themes | Dependencia Go, heavy para blog chico |

   **Recommendation:** Zola — balance between features and simplicity. Single binary, no runtime deps.

2. **Crear blog skeleton**
   ```bash
   cd ~/git/homepage
   mkdir -p blog
   cd blog
   # Zola init
   zola init .
   ```

3. **Implementar dark terminal theme**
   - Crear template `templates/index.html` (post list)
   - Crear template `templates/page.html` (individual post)
   - Crear template `templates/tags.html` (tag overview)
   - CSS: terminal aesthetic, monospace, lime/cyan palette
   - No header/footer shared with homepage

4. **Set up deploy GHA workflow**
   - Archivo: `.github/workflows/deploy-vchk.yaml`
   - Trigger: push a `main` con cambios en `blog/`
   - Build: `zola build` en `blog/`
   - Deploy: `gsutil rsync` a `gs://vchk-blog`
   - O: `wrangler pages publish` si Option C

   ```yaml
   name: Deploy vchk Blog
   on:
     push:
       branches: [main]
       paths: ['blog/**']
   jobs:
     deploy:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v4
         - name: Install Zola
           run: |
             wget -q https://github.com/getzola/zola/releases/download/v0.19.2/zola-v0.19.2-x86_64-unknown-linux-gnu.tar.gz
             tar xzf zola-v0.19.2-x86_64-unknown-linux-gnu.tar.gz
             sudo mv zola /usr/local/bin/
         - name: Build
           working-directory: blog
           run: zola build
         - name: Deploy to GCS
           run: |
             gsutil -m rsync -r blog/public gs://vchk-blog
             gsutil web set -m index.html gs://vchk-blog
   ```

### Phase 3: Seed content

1. **Escribir 3-5 posts iniciales** sobre temas dev útiles:
   - Ej: "Tmux for the Terminally Lazy" — basic tmux workflow
   - Ej: "Fzf + Ripgrep: The Only Search You'll Ever Need"
   - Ej: "Git Aliases That Actually Stick"
   - Ej: "Minimal Neovim Setup for Python Dev"
   - Ej: "Why Your Terminal Needs a Color Scheme"

2. **Set up RSS feed** (built-in con Zola, configurar en `config.toml`)

3. **Agregar tag system** para descubrimiento:
   - Tags: `tmux`, `git`, `neovim`, `python`, `cli`, `linux`, `productivity`
   - Tag pages generadas automáticamente por Zola

4. **Primer post de "presentación"** — sin personal info:
   ```
   ## Hello, World
   
   This is vchk. This blog is about developer tools, CLI workflows,
   and interesting technical things I find worth sharing.
   
   No bios, no backstories, no "about me" — just code and configs.
   
   — vchk
   ```

### Phase 4: Identity hardening

1. **Review todo el contenido** para referencias personales accidentales:
   - `grep -ri 'vichoko\|uber\|applied scientist\|santiago\|chile' blog/` — debe ser 0
   - Checkear que ningún post menciona empleador, ubicación, nombre real

2. **WHOIS check:**
   ```bash
   whois vchk.eu | grep -i 'person\|name\|org\|email'
   ```
   Resultado esperado: GDPR-redacted ✅ (ya verificado)

3. **Cloudflare proxy** ya hides real IP ✅

4. **Contact method:** Decidir si incluir:
   - Sin contacto (no email, no social links)
   - O: GitHub issues del repo (semi-linkable pero aceptable)
   - O: `mailto:vchk@vchk.eu` con email dedicado (si se crea)

5. **GitHub repo audit:**
   - El repo owner es "Vichoko" — aceptable porque no hay cross-links
   - No mencionar el blog desde el README del homepage repo
   - No mencionar el homepage repo desde el blog

---

## 🔄 PR Strategy

| PR | Branch | Files | Description |
|----|--------|-------|-------------|
| **PR #1** | `plan/vchk-blog` | `.hermes/plans/2026-06-27_vchk-blog-plan.md` | This plan document |
| **PR #2** | `feat/vchk-blog-infra` | `.github/workflows/deploy-vchk.yaml`, `blog/`, DNS change docs | Phase 1 + Phase 2: infrastructure + blog skeleton |
| **PR #3** | `feat/vchk-blog-content` | `blog/content/**` | Phase 3: seed content (3-5 posts) |

---

## ⚠️ Risks & Pitfalls

### DNS History
- vchk.eu previamente redirect a vichoko.cl — evidencia clara en Wayback Machine.
- **Assessment:** Aceptable. El nombre "vchk" es un hint pero no es evidencia directa. Cualquier persona con curiosidad puede deducir la conexión, pero no hay confirmación explícita.

### Registrar Data
- NETIM tiene los datos reales de Vichoko pero GDPR los redacta públicamente.
- **Assessment:** ✅ Riesgo bajo. Los datos no son públicos.

### Payment Method
- La tarjeta de crédito usada para comprar el dominio podría linkear.
- **Assessment:** ⚠️ Fuera de nuestro control. Si alguien tiene acceso a los registros de pago de NETIM, podría conectar. Riesgo bajo pero no mitigable.

### GCS Project Name
- El nombre del GCP project de Vichoko no debe aparecer en la bucket URL.
- **Assessment:** ✅ Si el bucket se llama `vchk-blog` y el CNAME es directo, el project name no se expone.

### Accidental Cross-Reference
- Error humano: poner un link a vichoko.cl en un post, o viceversa.
- **Assessment:** ⚠️ Mitigar con revisión en PR y grep checks automáticos en CI.

### GitHub Profile Connection
- El GitHub account "Vichoko" es el owner del repo. No podemos evitarlo si usamos el mismo account.
- **Assessment:** Aceptable. Muchos devs tienen repos no relacionados. No hay link explícito desde el blog al perfil.

---

## Verification Checklist (post-deploy)

```bash
# 1. vchk.eu returns blog, not redirect
curl -sI https://vchk.eu | grep -E 'HTTP|location'
# Expected: HTTP/2 200 (no Location header)

# 2. No references to Vichoko anywhere on vchk.eu
curl -sL https://vchk.eu | grep -ic 'vichoko'
# Expected: 0

# 3. No links from vchk.eu to vichoko.cl
curl -sL https://vchk.eu | grep -c 'vichoko.cl'
# Expected: 0

# 4. No links from vichoko.cl to vchk.eu (sanity check)
curl -sL https://vichoko.cl | grep -c 'vchk.eu\|vchk'
# Expected: 0

# 5. No personal info exposed
curl -sL https://vchk.eu | grep -ciE 'uber|applied.scientist|santiago|chile|about.me'
# Expected: 0

# 6. WHOIS shows NOT DISCLOSED
whois vchk.eu 2>/dev/null | grep -c 'NOT DISCLOSED\|REDACTED\|GDPR'
# Expected: > 0
```

---

## Files likely to change

- `.github/workflows/deploy-vchk.yaml` — new file
- `blog/` — new directory (entire blog source)
- `blog/config.toml` — Zola configuration
- `blog/templates/*.html` — templates
- `blog/content/*.md` — blog posts
- `blog/static/style.css` — blog CSS

## Files that do NOT change

- `src/` — homepage source (no cross-contamination)
- `.github/workflows/deploy.yaml` — homepage deploy (unchanged)
- `src/header.html` — no changes
- `.github/workflows/` — existing workflows (only adding new one)

---

## Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-06-27 | Keep in same repo (`~/git/homepage/`) with `blog/` subdirectory | Single repo management, reuse existing GHA patterns, avoids creating new GitHub repo tied to same account anyway |
| 2026-06-27 | Use Zola as SSG (tentative) | Fast, single binary, built-in RSS/tags, minimal deps |
| 2026-06-27 | Separate GCS bucket (Option A, tentative) | Keeps infra in Google ecosystem, clear separation from vichoko.cl bucket |

**Note:** SSG choice (Zola vs Hugo vs plain HTML) and hosting (GCS vs Cloudflare Pages) are still open for final decision during Phase 2 implementation.
