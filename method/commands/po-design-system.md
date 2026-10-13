---
description: Record the project's design system once — find its visual source, inventory tokens and components, measure every text/surface contrast in light and dark, and commit docs/design-system.md on the target branch
allowed-tools:
  - Read
  - Glob
  - Grep
  - Write
  - Edit
  - Bash
  - AskUserQuestion
---
# /po-design-system

Reads settings: `Target branch`

Screens hold together when each one is composed from the same recorded system. This command writes that record, `docs/design-system.md`, from what already exists: the base's tokens and components, or a direction the user supplies. It records and measures; it does not write the product's code and it does not make up a look.

## Checks
1. No `AGENTS.local.md` → stop: "Run /po-setup first."
2. Work from the repository root, on `Target branch`. Any other branch → stop and say so; never switch, check out or stash to get there.
3. `docs/design-system.md` already exists → this is a rerun: amend that file rather than starting over, and measure again every pair whose tokens changed.

Read the `design-doctrine` skill before step 1; every step below follows it.

## Step 1 — The source
A system in the base is detected when the repository holds any of:
- theme or token files: CSS custom properties, a Tailwind theme, a theme module;
- a folder of UI components;
- a « UI components » row in `docs/architecture.md`;
- a boilerplate profile with a UI inventory, when Polype's repository is at hand (`boilerplates/<name>/profile.md`).

Then ask whether the user has a visual direction: a brand guide, a logo and palette, an existing product or site to follow, mockups from the design tool. This is something the user hands over, never a setting.

This command never invents an identity: with no visual direction and no system in the base, stop and ask for the source, in one AskUserQuestion. When no source comes back, the command ends here, having written nothing.

## Step 2 — Inventory
Apply the `codebase-analysis` skill to the UI layer, starting from the profile's UI inventory when there is one. From it, list:
- every token: its role (text, surface, border, accent, focus…), its light value, its dark value, and the `path:line` where it is defined;
- every component: its path, its variants, the states it handles.

Only name what you opened. A token without a dark value, a state no component handles, a component the screens will obviously need: each goes to `## Gaps`, never filled in.

## Step 3 — Measure contrast
This is the only stage that measures. Later design and review steps look at the result and trust these numbers.

Measure every text/surface pair, in light and in dark: each text token on each surface token the system actually puts it on. Border, focus ring and icon tokens are measured against their surfaces too.

The computation (WCAG 2):
1. Convert each colour to sRGB channels between 0 and 1, whatever notation it was written in (hex, `rgb()`, `hsl()`, `oklch()`…).
2. Linearise each channel `c`: `c / 12.92` when `c <= 0.04045`, otherwise `((c + 0.055) / 1.055) ^ 2.4`.
3. Relative luminance `L = 0.2126 R + 0.7152 G + 0.0722 B`.
4. Ratio `(L1 + 0.05) / (L2 + 0.05)`, with `L1` the lighter of the two.

Thresholds: 4.5:1 for text, 3:1 for large text and for non-text UI (borders, focus rings, icons).

Do the arithmetic through Bash with `python3` or `node`, whichever exists; with neither, stop and say so — ratios are never estimated by eye.

Then fix the failing tokens: move the token's lightness as little as it takes to pass, keep its hue, and measure again. Each fix is recorded in the `## Contrast` table as before → after. The command edits no source file: the corrected values are handed to the person, who applies them as a quick fix they name or through a story. Say plainly that until then the code still carries the old values.

Forced dark mode: every colour token needs a dark value. A light-only system is recorded as a gap, because browsers and operating systems that force a dark theme recolour it in ways nobody measured.

## Step 4 — Patterns and rules
Write the state patterns — empty, loading, error, success, disabled, focus — as the inventory shows them: how each looks, which components carry it. Write the do / don't lists from the same inventory, never from taste. A pattern the system does not have is a gap.

## Approval and commit
1. Draft `docs/design-system.md` from `templates/design-system.md`.
2. Put the draft to the user with AskUserQuestion, one token group, one contrast fix or one gap per question, each of which the user answers Approve / Change / Set aside.
   - A token group is the tokens of one role (text, surface, border, accent, focus…), with their light and dark values and the measured ratios of their pairs. The state patterns and the do / don't lists then come as one last item.
   - The summary aims short and grows when the subject needs it: no fact needed to decide is cut to keep it short.
   - Each item is written only once approved, and the commit asks for no rereading.
   - Change → back to the step the item belongs to, then ask about it again.
   - Set aside → a token group or a gap is left out of the file and named in the final message; a contrast fix set aside leaves its pair recorded as failing, with no fix.
3. Write the file.
4. Check `git status --porcelain`: an environment file listed there → stop. On `Target branch`, commit `docs/design-system.md` as `docs: design system`.

Finish with: "Design system recorded. Next: /po-research <first story id>"
