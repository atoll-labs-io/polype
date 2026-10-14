# Research — s76-bounds-guard-against-mistakes

[Story](../stories.md)

## Structuring facts
- The lexer drops every redirection operator but keeps its fd number and its target as ordinary words (`method/hooks/po-bounds.sh:523` `else if (c == "<" || c == ">") { endword(sp); i++ }`). So `2>/dev/null` gives the git call two more words, `2` and `/dev/null`, and `check_temp_paths` (`:600-621`) refuses `/dev/null`. Checked: exit 2 today.
- `2>&1 | head` already passes today, by luck: `&` ends the command at `:486`, so `1` becomes a separate command. `&>/dev/null` passes the same way. The story's list of cases is broader than the actual bug.
- Unknown to the story: a relative redirection target is resolved from git's `-C` dir, not from the shell's dir. `git -C <tmp>/probe log > out.txt`, run from the main checkout, passes today (checked, exit 0), yet bash writes `out.txt` into the main checkout. In the same way, qa mode refuses `git symbolic-ref HEAD 2>/dev/null`, because `2` and `/dev/null` count as a target (`:570-578`). Checked: exit 2.
- Two existing tests pin exact frontmatter lines that this story must change: `tests/bounds.test.sh:589` expects `superseded-by: [ADR-0051]`, and `tests/post-m7-texts.test.sh:36` expects `supersedes: [ADR-0037]` for ADR-0041.
- The story's Owns does not include a new test file `tests/<slug>.test.sh`. Its tests go in `tests/bounds.test.sh`, `tests/installer.test.sh` and `tests/post-m7-texts.test.sh`, as s74 did. ADR-0052 is new and named by the plan, which counts as in scope (precedent: s74's review, Scope check).

## Story
`po-bounds` is described and tuned as a guard against an agent's mistakes, not as a barrier against deliberate bypass (option A, user, 2026-10-08). The story fixes s74 review M1, M2 and M3, plus M1, m1, m2 and m4 of the s75 review.

ACs:
- `bounds_threat_model_is_written`: an ADR, partly replacing ADR-0047 and ADR-0051, states the threat model, lists the known accepted bypasses and names the sandbox as deferred. ADR-0047 and ADR-0051 name it in `superseded-by`. ADR-0034 and ADR-0041 are linked.
- `redirections_are_not_git_paths`: in reviewer mode, a redirection is not read as a git path. A redirection to a main-checkout file is still refused.
- `installation_matches_the_hook`: the "Le mode reviewer" section cites ADR-0051 and the new ADR. It states the temp-zone path rule and the `core.worktree` refusals, and frames the hook as a guard against mistakes. The « et … ni » sentence is rewritten.
- `test_variables_are_local`: the loop variable in `tests/post-m7-texts.test.sh` is declared `local`.

## Current code
- `method/hooks/po-bounds.sh` (768 lines):
  - header comment `:1-45`;
  - `lex_command` `:309-549` (POSIX awk). It prints one line per simple command: words joined by `\037`, each prefixed `c` (command position), `q` (quoted part) or `u`. The comment at `:305-308` mentions only u/q.
  - `endword` `:322-326`, `endcmd` `:350-372` (type letter built at `:356`, line printed at `:363`), `cmdpos` `:330-345`, `push` `:312-315`;
  - the command-frame operator chain `:483-524`: `||`, `|&`, `|`, `;`/`&` at `:483-486`, `<(`/`>(` at `:517`, `<<<` at `:518`, `<<` at `:519-522`, generic `<`/`>` at `:523`.
- `check_bash` `:629-739`:
  - splits each line into `words` (with type) and `vals` (without) at `:640-643`;
  - in reviewer mode, refuses `GIT_DIR=` and the like at `:644-651`;
  - follows `cd` through `cur` at `:655-664`, then parses the global options and the verb (`:667-688`).
  - In reviewer mode it then branches into story worktree (`check_git_read`/`check_restore`), temp zone (`check_temp_paths "$dir" "$j"` at `:704`) or deny.
- `check_temp_paths` `:600-621`: each word after the verb becomes a candidate (`--x=v` → `v`, `-o<v>` → `v` via `${a:2}`, other `-*` skipped, bare word). The candidate is resolved from `$base` (git's dir) and must be `under_temp`.
- `resolve_path` `:98-115`: it denies a relative path, and resolves `/dev/null` to `/dev/null`, which is not under the temp dir.
- `docs/installation.md`:
  - `### Le hook des bornes de l'implementer` `:80-110`. The « et … ni » sentence is at `:94-96`.
  - `### Le mode reviewer` `:112-123`. It cites only ADR-0047, says « n'importe quel verbe sauf `push` », and says nothing of ADR-0051's rules.
- ADR frontmatter:
  - ADR-0047 `:9` `superseded-by: [ADR-0051]`;
  - ADR-0051 `:57-58` `supersedes: [ADR-0047]`, `superseded-by: []`;
  - ADR-0034 `superseded-by: []`;
  - ADR-0041 `supersedes: [ADR-0037]`. Its body at `:35` replaces ADR-0034's neutral consequences, which justifies the link.
- `tests/post-m7-texts.test.sh:8`: `for p in …` with `p` not in `local` (`:5` declares `doc sub bounds`).

## Attachment points
- Lexer: the `<`/`>` branch at `:523`, plus a new `&>` branch placed before the `;`/`&` branch at `:486`. `endword` records the redirection flag; `endcmd` emits the type letter `r`; `cmdpos` and the interpreter/shell detection (`:358-361`, `:366-367`) skip `r` words.
- `check_bash` `:640-643`: split the `r` words out of `words`/`vals` into a `redirs` array, so the git parsing indexes stay unchanged.
- The temp-zone branch `:703-704`: next to `check_temp_paths`, a new `check_redirects "$cur"`.
- ADR frontmatter lines listed above.

## Verified interfaces
- `expect`, `rev_bash`, `rev_status`, `reviewer_lane` (`TMPROOT`, `TMPROOT/probe`, `SCRATCH`, `WT`), `qa_status`, `bash_status`: `tests/bounds.test.sh:47,387-388,378-385,156,45`. `hook_input` passes `cwd: $SCRATCH`, the main checkout (`:34-37`).
- `frontmatter`, `contains`, `require_file`, `fail`: `tests/lib.sh` (`frontmatter` at `:13`).
- `tests/run.sh` runs each `test_*` in `bash -c "set -eu; …"` and accepts file names relative to `tests/`.
- The reserved ADR-0052 is written by the planner: `docs/decisions/ADR-0052-po-bounds-est-un-garde-fou-contre-les-erreurs.md`.

## Traps
- **Exact-line pins**:
  - `bounds.test.sh:589` (ADR-0047 `superseded-by`);
  - `post-m7-texts.test.sh:36` (ADR-0041 `supersedes`);
  - `leftovers.test.sh:12` pins ADR-0024/0029/0037. These are untouched here, and that file is outside Owns.
- **Pins on `docs/installation.md`**, which must survive the rewrite:
  - `installer.test.sh:182-189` checks the implementer section for `git update-ref`, `-D`, `--force`, `cherry-pick`, `pull`, `story/*`, `ADR-0050`, `git fetch . HEAD:main` and `GIT_DIR=`;
  - `post-m7-texts.test.sh:8-13` checks the reviewer section for `po-bounds.sh reviewer`, `d'avant s70`, `polype init <projet>` and `ADR-0047`. It also checks that the bounds section has `ADR-0050`, and that `ADR-0039` appears nowhere;
  - `bounds.test.sh:223-227` checks `relance \`polype init <projet>\``, the closed-hook sentence and `` `jq` ``;
  - `global-install.test.sh:119-126`. The two section headings must stay as they are.
- **Lexer cases the change must keep**:
  - `cat > $WT/docs/x.md <<'EOF'` (heredoc tests `bounds.test.sh:310-316,446-450,479`): the `>` target becomes an `r` word, and `<<` is still matched before the generic branch;
  - `echo ok > /tmp/x` (`:118`).
  - The `ar` frame keeps `<`/`>` as text (`:516`), and process substitutions (`:517`) and `<<<` (`:518`) come first.
- **BWK awk/mawk**: the lexer must stay POSIX awk (comment `:308`). No `gensub`, no `\<` classes; the regex `^[0-9]+$` is fine.
- **Overlap test**: `tests/overlap.test.sh` scans `method/`. Only the hook's comment lines change there.
- **Installed copies**: `.polype/hooks/po-bounds.sh` and `.claude/` are installed copies, never edited (AGENTS.local.md). They are refreshed after ship.
- **No other running lane**: `git worktree list` shows only main and this worktree.
- **Migration**: none.

## Open questions
- `method/agents/reviewer.md` is outside Owns. Its Limits paragraph (`:35`) keeps describing the hook without the "guard against mistakes" framing, and without the rule that a deliberate-bypass finding goes to an ADR rather than a fix. Should a later story align it? The plan does not touch it.
- Clustered short options (s74 M1): the story accepts them, so ADR-0051's flawed rule « ce qui suit les deux premiers caractères » stays in the hook as written.
- Should redirection targets of a git call in the story worktree, or of non-git commands, be judged? ADR-0052 says no (ADR-0047's accepted gap), so nothing changes there.

## Complexity
Story 3 → 3. It touches one lexer rule with careful ordering, one new check function, text in an ADR and a doc, and frontmatter links. That is more than it looked, because of the resolution-from-shell-dir subtlety and the two exact-line test pins, but it is still a single cohesive change.

## Split
Not needed (below 5).
