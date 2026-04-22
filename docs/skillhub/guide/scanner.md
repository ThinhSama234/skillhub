# Skill Scanner Security Scanning

## Feature Description

SkillHub includes a built-in **Skill Scanner** security scanning service that automatically detects potential security risks when skill packages are published. This is an important line of defense for protecting the security of enterprise-internal skill packages.

Every skill package is subjected to a security scan after being published. The scan results influence review decisions and help admins quickly determine whether a skill package is safe and reliable.

**Core features**:

- **Automatic trigger**: Security scanning is triggered automatically after a skill package is published; no manual action required
- **Multi-engine analysis**: Supports behavioral analysis, LLM analysis, metadata analysis, and other engines
- **Configurable policies**: Built-in `balanced` policy preset; custom scanning policies are supported
- **Severity threshold**: Configurable severity level at which publishing is automatically blocked
- **Scan report**: Detailed scan results are displayed on the skill package detail page

**Analysis engines**:

| Engine | Description | Default State |
|------|------|----------|
| **Metadata analysis** | Checks package structure, file types, sizes, etc. | Enabled |
| **Behavioral analysis** | Analyzes code behavior patterns to detect malicious operations | Optional |
| **LLM analysis** | Uses a large model to analyze code security | Optional |
| **AI Defense** | Cisco AI Defense integration | Optional |
| **VirusTotal** | VirusTotal virus scanning | Optional |

## Use Cases

**Scenario 1: Automatic scan on publish**

After a developer publishes a skill package, the Scanner automatically runs in the background — no additional action needed.

**Scenario 2: Admin views scan report**

When reviewing a skill package, admins can view the scan report to help make their review decision.

**Scenario 3: Custom scanning policy**

Enterprise admins can configure scanning policies and severity thresholds based on their security requirements.

## Workflow

```
Developer publishes skill package
    ↓
SkillHub backend receives upload
    ↓
Security scan triggered (via Redis Stream)
    ↓
Skill Scanner runs multi-engine analysis
    ↓
Scan results written to database
    ↓
Skill package detail page displays scan report
    ↓
Admin reviews combined with scan results
```

## Configuration

### Basic Configuration

Configure in the `.env` file or as environment variables:

| Environment Variable | Description | Default |
|----------|------|--------|
| `SKILLHUB_SECURITY_SCANNER_ENABLED` | Enable security scanning | `true` |
| `SKILLHUB_SECURITY_SCANNER_URL` | Scanner service address | `http://localhost:8000` |
| `SKILLHUB_SECURITY_SCANNER_MODE` | Scan mode (local / upload) | `local` |
| `SKILLHUB_SCANNER_POLICY_PRESET` | Policy preset | `balanced` |
| `SKILLHUB_SCANNER_FAIL_ON_SEVERITY` | Severity level that automatically blocks publishing | `high` |

### LLM Analysis Configuration (optional)

Enabling the LLM analysis engine can improve the accuracy of security detection:

| Environment Variable | Description | Default |
|----------|------|--------|
| `SKILLHUB_SCANNER_USE_LLM` | Enable LLM analysis | `false` |
| `SKILLHUB_SCANNER_LLM_PROVIDER` | LLM provider (anthropic / openai / azure) | `anthropic` |
| `SKILL_SCANNER_LLM_API_KEY` | LLM API key | - |

### Deployment Notes

When using one-click deployment, the Scanner service is enabled by default. If security scanning is not needed, it can be disabled with the `--no-scanner` parameter:

```bash
# Deploy without Scanner
curl -fsSL https://imageless.oss-cn-beijing.aliyuncs.com/runtime.sh | sh -s -- up --no-scanner
```

## Notes

> **Scanning does not block publishing**: Security scanning runs asynchronously and does not block the skill package upload process. Scan results are updated on the skill package detail page after the scan completes.

- **Scan duration**: Depending on the size of the skill package and the number of engines enabled, scanning may take a few seconds to a few minutes
- **LLM analysis cost**: Enabling LLM analysis incurs API call costs; it is recommended to evaluate costs in production environments
- **Policy tuning**: The `balanced` policy is suitable for most scenarios; enterprises can customize the policy based on their security requirements
- **Health check**: Check the Scanner service status via `GET http://localhost:8000/health`
