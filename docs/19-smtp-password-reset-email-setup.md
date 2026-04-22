# SkillHub SMTP Configuration Guide (Verification Code Emails)

This document explains how to configure SMTP for SkillHub to send "password reset verification code" emails.

Applicable scenarios:
- Production/staging environments (`compose.release.yml` + `.env.release`)
- Local development environments (inject backend environment variables directly)

Additional notes:
- SMTP is fundamentally an email transport protocol, not a single vendor's product.
- You can use a corporate mailbox, a cloud mailbox, or a local test SMTP service (such as MailHog) as the SMTP server.

Current password reset page entry note:
- The frontend currently uses the `/reset-password` page uniformly.
- This page includes both the "send verification code" step and the "submit new password" step; `/forgot-password` is no longer used separately.

## 1. Environment Variables to Configure

The following variables are read by the backend:

| Variable | Description | Example |
|---|---|---|
| `SPRING_MAIL_HOST` | SMTP server address | `smtp.example.com` |
| `SPRING_MAIL_PORT` | SMTP port | `465` |
| `SPRING_MAIL_USERNAME` | SMTP username | `noreply@example.com` |
| `SPRING_MAIL_PASSWORD` | SMTP password / authorization code | `xxxxxx` |
| `SPRING_MAIL_SMTP_AUTH` | Whether to enable SMTP AUTH | `true` |
| `SPRING_MAIL_SMTP_STARTTLS_ENABLE` | Whether to enable STARTTLS | `false` |
| `SPRING_MAIL_PROPERTIES_MAIL_SMTP_SSL_ENABLE` | Whether to enable SMTP SSL direct connection | `true` |
| `SPRING_MAIL_PROPERTIES_MAIL_SMTP_SSL_TRUST` | SSL trusted host (used to bypass certificate chain validation failures in some environments) | `smtp.mail.example` |
| `SKILLHUB_AUTH_PASSWORD_RESET_CODE_EXPIRY` | Verification code validity period (ISO-8601 Duration) | `PT10M` |
| `SKILLHUB_AUTH_PASSWORD_RESET_FROM_ADDRESS` | Sender email address | `noreply@example.com` |
| `SKILLHUB_AUTH_PASSWORD_RESET_FROM_NAME` | Sender display name | `SkillHub` |

Notes:
- This document uses the `465 + SSL` configuration uniformly; the `587 + STARTTLS` approach is not covered here.
- When using port `465`, configure: `STARTTLS=false`, `SSL_ENABLE=true`.
- If you encounter `PKIX path building failed` / `SSLHandshakeException`, try adding `SPRING_MAIL_PROPERTIES_MAIL_SMTP_SSL_TRUST=<SMTP_HOST>` (commonly used in local development).
- In production environments, `SPRING_MAIL_PROPERTIES_MAIL_SMTP_SSL_TRUST` is not recommended by default; enable it temporarily only when certificate chain issues occur.
- `SKILLHUB_AUTH_PASSWORD_RESET_CODE_EXPIRY` supports values such as `PT5M`, `PT10M`, `PT30M`.

## 1.1 Quick Configuration Reference (Recommended)

### A. Generic SMTP Mailbox (Local direct connection to a real mailbox)

```dotenv
SPRING_MAIL_HOST=smtp.mail.example
SPRING_MAIL_PORT=465
SPRING_MAIL_USERNAME=mailer@example.com
SPRING_MAIL_PASSWORD=your-smtp-app-password
SPRING_MAIL_SMTP_AUTH=true
SPRING_MAIL_SMTP_STARTTLS_ENABLE=false
SPRING_MAIL_PROPERTIES_MAIL_SMTP_SSL_ENABLE=true
SPRING_MAIL_PROPERTIES_MAIL_SMTP_SSL_TRUST=smtp.mail.example
SKILLHUB_AUTH_PASSWORD_RESET_CODE_EXPIRY=PT10M
SKILLHUB_AUTH_PASSWORD_RESET_FROM_ADDRESS=mailer@example.com
SKILLHUB_AUTH_PASSWORD_RESET_FROM_NAME=your-from-name
```

Local `export` example:

```bash
export SPRING_MAIL_PROPERTIES_MAIL_SMTP_SSL_TRUST=smtp.mail.example
export SPRING_MAIL_HOST=smtp.mail.example
export SPRING_MAIL_PORT=465
export SPRING_MAIL_USERNAME=mailer@example.com
export SPRING_MAIL_PASSWORD=your-smtp-app-password
export SPRING_MAIL_SMTP_AUTH=true
export SPRING_MAIL_SMTP_STARTTLS_ENABLE=false
export SPRING_MAIL_PROPERTIES_MAIL_SMTP_SSL_ENABLE=true
export SKILLHUB_AUTH_PASSWORD_RESET_CODE_EXPIRY=PT10M
export SKILLHUB_AUTH_PASSWORD_RESET_FROM_ADDRESS=mailer@example.com
export SKILLHUB_AUTH_PASSWORD_RESET_FROM_NAME=your-from-name
```

### B. MailHog (Recommended for local development)

```dotenv
SPRING_MAIL_HOST=127.0.0.1
SPRING_MAIL_PORT=1025
SPRING_MAIL_USERNAME=
SPRING_MAIL_PASSWORD=
SPRING_MAIL_SMTP_AUTH=false
SPRING_MAIL_SMTP_STARTTLS_ENABLE=false
SPRING_MAIL_PROPERTIES_MAIL_SMTP_SSL_ENABLE=false
SKILLHUB_AUTH_PASSWORD_RESET_FROM_ADDRESS=noreply@skillhub.local
SKILLHUB_AUTH_PASSWORD_RESET_FROM_NAME=SkillHub
```

### C. Production Deployment (Port 465 example)

```dotenv
SPRING_MAIL_HOST=smtp.mail.example
SPRING_MAIL_PORT=465
SPRING_MAIL_USERNAME=mailer@example.com
SPRING_MAIL_PASSWORD=your-smtp-app-password
SPRING_MAIL_SMTP_AUTH=true
SPRING_MAIL_SMTP_STARTTLS_ENABLE=false
SPRING_MAIL_PROPERTIES_MAIL_SMTP_SSL_ENABLE=true
SPRING_MAIL_PROPERTIES_MAIL_SMTP_SSL_TRUST=smtp.mail.example
SKILLHUB_AUTH_PASSWORD_RESET_CODE_EXPIRY=PT10M
SKILLHUB_AUTH_PASSWORD_RESET_FROM_ADDRESS=mailer@example.com
SKILLHUB_AUTH_PASSWORD_RESET_FROM_NAME=your-from-name
```

## 2. Single-Machine Delivery (Compose) Configuration Steps

1. Copy the environment template (if not yet created):

```bash
cp .env.release.example .env.release
```

2. Edit `.env.release` and fill in the SMTP variables:

```dotenv
SPRING_MAIL_HOST=smtp.mail.example
SPRING_MAIL_PORT=465
SPRING_MAIL_USERNAME=mailer@example.com
SPRING_MAIL_PASSWORD=your-smtp-app-password
SPRING_MAIL_SMTP_AUTH=true
SPRING_MAIL_SMTP_STARTTLS_ENABLE=false
SPRING_MAIL_PROPERTIES_MAIL_SMTP_SSL_ENABLE=true
SPRING_MAIL_PROPERTIES_MAIL_SMTP_SSL_TRUST=smtp.mail.example

SKILLHUB_AUTH_PASSWORD_RESET_CODE_EXPIRY=PT10M
SKILLHUB_AUTH_PASSWORD_RESET_FROM_ADDRESS=mailer@example.com
SKILLHUB_AUTH_PASSWORD_RESET_FROM_NAME=your-from-name
```

3. Restart the backend container to apply the configuration:

```bash
docker compose --env-file .env.release -f compose.release.yml up -d server
```

4. Check backend logs to confirm successful startup:

```bash
docker compose --env-file .env.release -f compose.release.yml logs -f server
```

## 3. Local Development Configuration and Verification

### 3.1 One-Time Temporary Effect (Recommended)

Suitable for temporary testing in the current terminal session; expires when the terminal is closed.

```bash
SPRING_MAIL_HOST=smtp.mail.example \
SPRING_MAIL_PORT=465 \
SPRING_MAIL_USERNAME=mailer@example.com \
SPRING_MAIL_PASSWORD=your-smtp-app-password \
SPRING_MAIL_SMTP_AUTH=true \
SPRING_MAIL_SMTP_STARTTLS_ENABLE=false \
SPRING_MAIL_PROPERTIES_MAIL_SMTP_SSL_ENABLE=true \
SPRING_MAIL_PROPERTIES_MAIL_SMTP_SSL_TRUST=smtp.mail.example \
SKILLHUB_AUTH_PASSWORD_RESET_CODE_EXPIRY=PT10M \
SKILLHUB_AUTH_PASSWORD_RESET_FROM_ADDRESS=mailer@example.com \
SKILLHUB_AUTH_PASSWORD_RESET_FROM_NAME=your-from-name \
make dev-server
```

### 3.2 Persistent Effect (Shell Configuration)

If you write variables to `~/.zshrc`, note:
- You must run `source ~/.zshrc` or open a new terminal before the variables take effect
- You need to start `make dev-server` in the same terminal where the variables were configured

You can first confirm whether the variables are in the current shell:

```bash
env | rg '^(SPRING_MAIL_|SKILLHUB_AUTH_PASSWORD_RESET_)'
```

### 3.3 Recommended Local Testing Method (MailHog)

If you only need to verify the verification code flow locally, it is recommended to use MailHog as a local SMTP service:

1. Start MailHog:

```bash
docker run -d --name skillhub-mailhog \
  -p 1025:1025 \
  -p 8025:8025 \
  mailhog/mailhog
```

2. Start dependency services (Postgres/Redis):

```bash
make dev
```

3. Start the backend with SMTP environment variables injected (example):

```bash
SPRING_MAIL_HOST=127.0.0.1 \
SPRING_MAIL_PORT=1025 \
SPRING_MAIL_USERNAME= \
SPRING_MAIL_PASSWORD= \
SPRING_MAIL_SMTP_AUTH=false \
SPRING_MAIL_SMTP_STARTTLS_ENABLE=false \
SPRING_MAIL_PROPERTIES_MAIL_SMTP_SSL_ENABLE=false \
SKILLHUB_AUTH_PASSWORD_RESET_FROM_ADDRESS=noreply@skillhub.local \
SKILLHUB_AUTH_PASSWORD_RESET_FROM_NAME=SkillHub \
make dev-server
```

4. Open the MailHog Web UI to view emails:

```text
http://localhost:8025
```

5. Verify the flow in the SkillHub page:
- Open `/reset-password`
- Enter your email and click "Send Verification Code"
- Check the verification code email in MailHog
- Enter the email + verification code + new password to complete the reset

6. You can also use the API for quick verification (example):

```bash
curl -X POST http://localhost:8080/api/v1/auth/local/password-reset/request \
  -H 'Content-Type: application/json' \
  -d '{"email":"your-email@example.com"}'
```

## 4. Feature Verification (Verification Code Emails)

### 4.1 Self-Service User Recovery

After the user clicks "Send Verification Code" on the `/reset-password` page, the system will attempt to send a verification code email.

Notes:
- To prevent account enumeration, the self-service endpoint always returns a generic success message.
- Even if the email fails to send, the endpoint may return success; please check the backend logs to confirm the actual sending result.

### 4.2 Administrator-Triggered Reset

When an administrator triggers "Reset Password" on the user management page, the system will force-send the verification code; if the SMTP send fails, an error will be returned (to help with operational troubleshooting).

## 5. Common Troubleshooting

### 5.1 Authentication Failure (`535 Authentication failed`)

Troubleshooting directions:
- Is the username/password correct?
- Does the mail service require a "client authorization code" rather than the login password?
- Has SMTP service been enabled for the sending account?

### 5.2 Connection Timeout or Refused Connection

Troubleshooting directions:
- Is port `465` of the SMTP server reachable from the host?
- Has the security group/firewall allowed outbound connections?
- Is the SMTP server address correct?

### 5.3 Variables Are Configured Locally But Do Not Take Effect

Troubleshooting directions:
- Did you only edit `~/.zshrc` without running `source ~/.zshrc`?
- Is the terminal that started the backend the same terminal where the variables were configured?
- Is port `8080` occupied by an old process, causing the new process not to start?

Run the following commands for a quick check:

```bash
# Check if port 8080 is occupied by an old process
lsof -nP -iTCP:8080 -sTCP:LISTEN

# Check whether the current shell has SMTP environment variables
env | rg '^(SPRING_MAIL_|SKILLHUB_AUTH_PASSWORD_RESET_)'
```

### 5.4 Sender Rejected

Troubleshooting directions:
- Is `SKILLHUB_AUTH_PASSWORD_RESET_FROM_ADDRESS` consistent with the SMTP account or already verified?
- Does the mail service restrict alias sending?

### 5.5 Does the Health Check Validate SMTP?

Under the default configuration, the mail health check is disabled and will not cause a `health` failure due to SMTP being unreachable.

To include SMTP connectivity in the health check, set:

```dotenv
MANAGEMENT_HEALTH_MAIL_ENABLED=true
```

### 5.6 SMTP Reports `PKIX path building failed` (Certificate Chain Validation Failure)

Typical log messages:
- `SSLHandshakeException`
- `unable to find valid certification path to requested target`

Recommended handling (local development):
- Add:

```dotenv
SPRING_MAIL_PROPERTIES_MAIL_SMTP_SSL_TRUST=smtp.mail.example
```

- Then restart the backend and trigger "Send Verification Code" again.

Additional notes:
- This configuration specifies a trusted host and is suitable for local troubleshooting and development.
- In production environments, it is not recommended to keep this configuration enabled long-term. It is preferable to use a proper CA certificate chain or import the enterprise CA into the Java truststore.

## 6. Security Recommendations

- Do not commit SMTP passwords to the repository; write them only to a controlled `.env.release` or a secrets management system.
- Use a dedicated sending account; avoid using a personal mailbox master password.
- In production environments, it is recommended to rotate the SMTP authorization code regularly.
