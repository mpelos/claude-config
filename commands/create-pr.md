---
name: create-pr
description:
    Create a pull request with a well-crafted description. Commits all staged/unstaged changes, pushes the branch,
    and opens a PR against main with a concise, narrative description written for senior developers.
---

# Create Pull Request

Create a pull request for the current branch with a professional, concise description.

## Steps

1. **Gather context:**
   - Run `git status` to see all changes
   - Run `git diff main...HEAD` to see the full diff against main
   - Run `git log main..HEAD --oneline` to see all commits on this branch
   - Identify the ticket number from the branch name (e.g., `ENG-584` from `marcelo/eng-584-...` or `ENG-584`)

2. **Commit any uncommitted changes** if there are unstaged or staged changes, commit them with a descriptive message before proceeding.

3. **Push the branch** to origin with `-u` flag if not already pushed.

4. **Create the PR** using `gh pr create` with:
   - **Title:** Follow the repo's commit convention (e.g., `fix: [ENG-584] Short description`)
   - **Body:** Follow the description guidelines below

## PR Description Guidelines

Write the description as concise paragraphs in a narrative style, aimed at senior developers who already have large context of the application. The description should follow this structure:

### Structure

1. **Reported problem:** What is happening and who is affected. Keep it brief, one or two sentences.
2. **Technical problem:** What was identified as the cause. Frame it as a hypothesis if the issue was not fully reproducible. Explain just enough for a senior developer to understand the root cause without over-explaining framework internals they already know.
3. **Solution:** What was changed and why. Be direct and concise.

### Writing Rules

- Write in **paragraphs only**. No bullet points, no checklists, no headers inside the body (except `## Summary` at the top).
- Write for **senior developers** who know the codebase. Do not over-explain obvious things.
- **Never use "we" or "our"**. Use passive voice or impersonal constructions instead (e.g., "it was possible to see" instead of "we could see", "the hypothesis is" instead of "our hypothesis").
- **Never use em dashes (—)**. Use commas, periods, or parentheses instead.
- Keep it **short**. Three paragraphs is usually enough. If you need more, the description is too detailed.
- Do not include a test plan unless explicitly asked.
- Do not include `Co-Authored-By` lines.

### Example

```
## Summary

A customer reported that charts on the Home Dashboard flicker and resize rapidly, making the UI unusable. The issue is intermittent and tied to specific monitor setups and resolutions, so it is not reliably reproducible.

From the LogRocket session, it was possible to see the chart scrollbars appearing and disappearing in an infinite loop, preventing the charts from ever rendering. The hypothesis is that `overflowY: "auto"` on the chart container creates a layout thrashing loop: the chart overflows, a scrollbar appears, the width shrinks, Chart.js re-renders, the content fits, the scrollbar disappears, and the cycle repeats.

The fix changes the container overflow to `hidden` to prevent the scrollbar from toggling and moves deprecated Chart.js config options to their correct location. Since the issue is not reproducible on demand, there is no guarantee this fully resolves the flickering, but it addresses the most likely root cause based on the LogRocket evidence.
```

## PR Creation

Use a HEREDOC to pass the body:

```bash
gh pr create --title "fix: [TICKET] Short description" --body "$(cat <<'EOF'
## Summary

<paragraphs here>
EOF
)"
```

Return the PR URL when done.
