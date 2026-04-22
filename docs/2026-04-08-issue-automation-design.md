# Issue Auto-Triage MVP Design

## Goals

Reduce maintainer burden by automatically triaging GitHub issues into three queues:

- `triage/deferred`: Low-priority issues that will gradually surface over time
- `triage/core`: High-priority or high-risk issues that need a core maintainer to take over
- `triage/agent-ready`: High-priority, low-risk issues suitable as future agent execution candidates

This MVP version does not automatically fix issues. It focuses on scoring, routing, labeling, and keeping the backlog moving.

The current version supports two execution modes:

- Rules-only triage
- Rules + OpenAI-compatible LLM assistance

## Why This Split

The original approach mixed priority and execution difficulty into the same decision. In practice, separating them makes the system easier to tune:

- `Priority`: Is this issue worth investing time in right now?
- `Route`: Once it's worth addressing, who should handle it?

This way, high-value but high-difficulty issues can still maintain high priority while continuing to route to `triage/core`.

## Inputs

The automation reads the live title, body, labels, comments, and timestamps of issues.

Structured issue form fields come from:

- [bug_report.yml](../.github/ISSUE_TEMPLATE/bug_report.yml)
- [feature_request.yml](../.github/ISSUE_TEMPLATE/feature_request.yml)
- [reward-task.yml](../.github/ISSUE_TEMPLATE/reward-task.yml)

## Scoring Model

Each issue is scored along four dimensions:

- `impact` (1-5): Impact on users and workflows
- `urgency` (1-5): Release time pressure, feature breakage, or frequency of repeated discussion
- `effort` (1-5): Estimated change size and collaboration cost
- `confidence` (1-5): Completeness and executability of the issue description

Priority calculation formula:

```text
priority = impact * 0.45 + urgency * 0.35 + age_boost + engagement_boost
```

Where:

- `age_boost`: SLA-based escalation mechanism
  - Days 7-9: warm-up phase, minimum boost to `priority/p2`
  - Days 10-13: forced removal from `triage/deferred`, minimum boost to `priority/p1`
  - Day 14 and beyond: at the next triage/rescore, treat the issue as SLA-violated and boost to at least `priority/p0`
- `engagement_boost`: determined jointly by comment pressure and reward amount, capped at +1.0

In the MVP, `effort` does not directly reduce priority; it only influences routing.

## LLM-Assisted Triage

When configured, the workflow can call an OpenAI-compatible chat completions API.

The LLM does not replace the rules engine. It is only used to assist with:

- Generating issue summaries
- Making minor adjustments to soft scores
- Generating follow-up questions for `needs-info`
- Providing maintainers with better judgment context
- Generating maintainer handoff summaries for `triage/core`

Hard thresholds remain controlled by rules:

- Missing required information
- High-risk areas such as auth, schema, migration, SDK, or public contract changes
- Final determination of whether to escalate to `triage/agent-ready`

Issue bodies and comments are treated as untrusted input. The workflow will:

- Truncate overly long bodies and comments before sending to the model
- Explicitly tell the model that issue text is data, not instructions
- Validate model output using strict JSON schema
- Fall back to rules-only mode if the provider call fails or JSON validation fails

### Modes

- `off`: Rules only
- `shadow`: Call LLM and display its suggestions, but still use rules-only routing and labels
- `assist`: Allow the LLM to adjust soft scores by at most `+/-1`, then re-apply hard thresholds

### When to Use LLM

The workflow only calls the LLM when an issue appears ambiguous or high-value, for example:

- `triage/needs-info`
- `triage/core`
- Issues near the routing threshold
- Low-confidence cases
- Issues with long bodies or many comments
- Feature or reward issues requiring more judgment

## Routing Rules

1. `triage/needs-info`
   Triggered when required fields are missing or `confidence <= 2`.

2. `triage/deferred`
   Triggered when `priority < 3.6`, the issue is not blocked by missing information, and the issue age is still below the SLA escalation floor.

3. `triage/core`
   Triggered when `priority >= 3.6` and any of the following apply:
   - The issue blocks core OpenClaw/ClawHub workflows such as install, publish, update, sync, or namespace-based publishing
   - `effort >= 4`
   - `confidence <= 3`
   - High-risk keywords or contract-affecting fields are present

4. `triage/agent-ready`
   Triggered when `priority >= 3.6`, `effort <= 3`, `confidence >= 4`, and no high-risk signals are present.

In `assist` mode, LLM suggestions can adjust `impact`, `urgency`, `effort`, and `confidence` by at most 1 point each. The rules engine then recalculates priority and routing.

Issues involving OpenClaw/ClawHub core workflows are a hard gate for `triage/core`; LLM assistance does not relax this rule.

## Managed Labels

The automation manages the following label prefixes:

- `triage/`
- `priority/`
- `effort/`
- `risk/`

Specific labels currently in use:

- `triage/needs-info`
- `triage/deferred`
- `triage/core`
- `triage/agent-ready`
- `priority/p0`
- `priority/p1`
- `priority/p2`
- `priority/p3`
- `effort/s`
- `effort/m`
- `effort/l`
- `risk/high`

All other labels remain unchanged.

In addition, the automation recognizes one manually-operated label that it does not manage:

- `triage-manual`: Freezes automated triage updates for that issue

## Workflows

### 1. Issue Triage

File: [issue-triage.yml](../.github/workflows/issue-triage.yml)

Triggers:

- `issues.opened`
- `issues.edited`
- `issues.reopened`
- `issue_comment.created` when a comment contains `/retriage`
- `workflow_dispatch`

Actions:

- Fetch issue and comments
- Calculate scores and routing
- Update or create managed labels
- Update or create a triage comment containing both human-readable reasoning and hidden machine state
- Optionally call an OpenAI-compatible provider and merge results

### 2. Deferred Backlog Rescore

File:
[issue-backlog-rescore.yml](../.github/workflows/issue-backlog-rescore.yml)

Triggers:

- Every 6 hours
- `workflow_dispatch`

Actions:

- List all open issues with the `triage/deferred` label
- Recalculate priority with age and engagement boosts
- Decide whether to escalate or retain each issue
- Update triage comments in place
- Reuse cached LLM results when issue content has not changed

Pilot notes:

- The scheduled rescore currently only scans issues in the `triage/deferred` queue
- This ensures low-priority backlog items do not idle in `deferred` past day 10
- Once an issue has been escalated out of `deferred`, the further escalation at day 14 depends on a new triage event or a manual `/retriage`
- During the pilot phase, the 14-day rule should be treated as an operational SLA target, not a hard repo-wide timer

## Scripts

The new GitHub automation scripts are located in
[`.github/scripts`](/Users/wowo/workspace/skillhub/.github/scripts):

- [github.ts](/Users/wowo/workspace/skillhub/.github/scripts/github.ts): Lightweight GitHub REST client
- [issue-triage-config.ts](/Users/wowo/workspace/skillhub/.github/scripts/issue-triage-config.ts): Labels, thresholds, and keyword rules
- [issue-llm-config.ts](/Users/wowo/workspace/skillhub/.github/scripts/issue-llm-config.ts): LLM modes, environment variables, and call heuristics
- [issue-llm-provider.ts](/Users/wowo/workspace/skillhub/.github/scripts/issue-llm-provider.ts): OpenAI-compatible chat completions client
- [issue-llm-evaluator.ts](/Users/wowo/workspace/skillhub/.github/scripts/issue-llm-evaluator.ts): Prompt construction, JSON validation, and cache key generation
- [issue-triage-lib.ts](/Users/wowo/workspace/skillhub/.github/scripts/issue-triage-lib.ts): Parsing, scoring, routing, and comment rendering
- [issue-triage-merge.ts](/Users/wowo/workspace/skillhub/.github/scripts/issue-triage-merge.ts): Bounded merging and hard threshold re-application
- [issue-triage.ts](/Users/wowo/workspace/skillhub/.github/scripts/issue-triage.ts): Single-issue entry point
- [issue-backlog-rescore.ts](/Users/wowo/workspace/skillhub/.github/scripts/issue-backlog-rescore.ts): Deferred queue rescore entry point

## Configuration

Set the following GitHub repository variables and secrets to enable LLM-assisted triage:

Repository variables:

- `ISSUE_TRIAGE_LLM_MODE`
- `ISSUE_TRIAGE_LLM_BASE_URL`
- `ISSUE_TRIAGE_LLM_MODEL`
- `ISSUE_TRIAGE_LLM_TIMEOUT_MS` (optional)
- `ISSUE_TRIAGE_LLM_TEMPERATURE` (optional)
- `ISSUE_TRIAGE_LLM_MAX_COMMENTS` (optional)
- `ISSUE_TRIAGE_LLM_MAX_COMMENT_CHARS` (optional)
- `ISSUE_TRIAGE_LLM_MAX_BODY_CHARS` (optional)

Repository secrets:

- `ISSUE_TRIAGE_LLM_API_KEY`

Recommended first rollout approach:

- `ISSUE_TRIAGE_LLM_MODE=shadow`
- Observe triage comments for a few days
- Switch to `assist` once LLM suggestions appear stable

Example OpenAI-compatible variable configuration:

```text
ISSUE_TRIAGE_LLM_MODE=shadow
ISSUE_TRIAGE_LLM_BASE_URL=https://your-provider.example.com/v1
ISSUE_TRIAGE_LLM_MODEL=gpt-4.1-mini
```

## Rollout Plan

### Phase 1: Current Stage

- Enable triage and backlog rescore
- Fine-tune thresholds after observing a few weeks of issue traffic
- Allow maintainers to freeze specific issues from automation via `triage-manual`
- If using LLM, start with `shadow` mode

### Phase 2: Maintainer Handoff

Add an issue-brief generator for `triage/core` issues, outputting:

- Reproduction hints
- Likely modules involved
- Risk notes
- Verification checklist

These outputs can be used directly in local coding agent sessions and in the existing parallel worktree workflow.

The current MVP already embeds a `Maintainer Brief` section directly in the triage comment for `triage/core` issues. This summary includes:

- A concise issue summary
- Why the issue was escalated to core
- Notes on reproduction path or operation path
- Suspected related modules or workflow owners
- Risk warnings
- Verification checklist

### Phase 3: Self-Hosted Issue Agent

Add a self-hosted runner that listens to `triage/agent-ready` and executes:

- Creates an isolated branch and worktree
- Runs an agent to resolve the issue
- Executes the minimal relevant test set
- Opens a draft PR

At this stage, the following scenarios should retain hard blocks:

- Auth and permission changes
- Security-sensitive changes
- Schema or migration-related work
- Public API, SDK, or CLI contract changes

## Tuning Questions

- Is looking only at comment count sufficient for the engagement boost, or should reactions also be fetched?
- Should reward issues receive a stronger value boost than in the current MVP?
- Should `agent-ready` require `effort <= 2` instead of `<= 3`?
- Should certain areas (such as `scanner`) be treated as high-risk by default?
- Should certain teams remain in `shadow` mode long-term, with `assist` applied only to a narrower subset of repositories?
