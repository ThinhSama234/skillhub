# Frequently Asked Questions

## Q: What is the difference between SkillHub and ClawHub?

A: SkillHub is an enterprise-grade self-hosted solution that provides stronger permission control, review mechanisms, and governance capabilities. ClawHub is a public registry, similar to npm.

**Main differences:**

| Feature | SkillHub | ClawHub |
|------|----------|---------|
| **Deployment** | Self-hosted | Public cloud |
| **Permission control** | Namespace RBAC | Basic permissions |
| **Review mechanism** | Multi-level review | None |
| **Security scanning** | Built-in Skill Scanner | None |
| **Data sovereignty** | Fully in your control | Hosted in the cloud |
| **Use case** | Enterprise internal | Public sharing |

## Q: How do I back up data?

A: SkillHub's data is stored in PostgreSQL and object storage. Regular backups of both are sufficient.

**Backing up PostgreSQL:**
```bash
pg_dump -h localhost -U postgres skillhub > backup.sql
```

**Backing up object storage:**
- If using MinIO, back up the MinIO data directory
- If using S3, use the AWS CLI or an S3 backup tool

## Q: What authentication methods are supported?

A: SkillHub supports multiple authentication methods:

- **OAuth2**: GitHub, Google, GitLab, etc.
- **Local accounts**: Username and password login (built-in admin: admin / ChangeMe!2026)
- **Enterprise SSO**: Can be integrated with LDAP, SAML, etc.

Refer to the authentication configuration section in the project README for setup instructions.

## Q: Is there a size limit for skill packages?

A: The default limit is **100MB**. This can be adjusted via configuration:

```yaml
# application.yml
spring:
  servlet:
    multipart:
      max-file-size: 100MB
      max-request-size: 100MB
```

## Q: How do I use the CLI tool to manage skill packages?

A: SkillHub is compatible with the OpenClaw CLI. Simply use the `npx clawhub` command:

```bash
# Configure the registry address
export CLAWHUB_REGISTRY=http://your-skillhub-host:8080

# Search for skill packages
npx clawhub search email

# Install a skill package
npx clawhub install my-skill

# Publish a skill package
npx clawhub publish ./my-skill
```

## Q: How do I configure HTTPS?

A: It is recommended to use Nginx or Traefik as a reverse proxy in production environments with an SSL certificate configured.

**Nginx configuration example:**
```nginx
server {
    listen 443 ssl;
    server_name skillhub.example.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        proxy_pass http://localhost:3000;
    }
    
    location /api {
        proxy_pass http://localhost:8080;
    }
}
```

## Q: How do I monitor SkillHub?

A: SkillHub provides multiple monitoring options:

- **Health check**: `GET /actuator/health`
- **Scanner health check**: `GET http://localhost:8000/health`
- **Metrics monitoring**: `GET /actuator/metrics` (Prometheus format)
- **Audit logs**: All critical operations are recorded in the audit log
- **Application logs**: Use ELK or Loki to collect logs

## Q: Is multi-tenancy supported?

A: SkillHub implements logical multi-tenant isolation through namespaces. Each namespace is equivalent to a tenant with independent members, permissions, and skill packages.

If physical isolation is required, you can deploy an independent SkillHub instance for each tenant.

## Q: How do I upgrade SkillHub?

A: Upgrade using a curl command:

```bash
# Pull the latest image and restart
curl -fsSL https://imageless.oss-cn-beijing.aliyuncs.com/runtime.sh | sh -s -- pull
curl -fsSL https://imageless.oss-cn-beijing.aliyuncs.com/runtime.sh | sh -s -- down
curl -fsSL https://imageless.oss-cn-beijing.aliyuncs.com/runtime.sh | sh -s -- up

# Or directly specify a version to upgrade
curl -fsSL https://imageless.oss-cn-beijing.aliyuncs.com/runtime.sh | sh -s -- up --version v0.2.0
```

> **Note**: It is recommended to back up the database and object storage before upgrading. Database migrations are executed automatically by Flyway.

## Q: Why can neither admin nor regular users create namespaces?

A: Older versions of SkillHub do not support creating namespaces. This feature was added in a later release. Please upgrade your SkillHub to the latest version.
Example upgrade command:
```bash
curl -fsSL https://imageless.oss-cn-beijing.aliyuncs.com/runtime.sh | sh -s -- up --version latest
```

## Q: How do I search for or operate on skill packages (Skills) in a specific namespace?

A: When using the OpenClaw CLI tool, you can specify a namespace using the `<namespace>--<skill-name>` format (e.g., for searching or installing). If you encounter issues searching on the web interface, you can also try exporting the skill first and then importing it to the target namespace as a cross-namespace workaround.

## Q: What should I do if I encounter a problem?

A: You can get help through the following channels:

- **GitHub Issues**: https://github.com/iflytek/skillhub/issues
- **Documentation**: Refer to the project README.md
- **Community discussions**: https://github.com/iflytek/skillhub/discussions

## Q: What should I do if local development fails to start?

A: When the backend fails to start after `make dev-all`, detailed error messages will be shown. Common issues:

### 1. Maven dependency download failure (network timeout)

**Symptom:** Backend logs show `Could not transfer artifact` or connection timeout

**Solution:** Configure the Aliyun mirror

```bash
# Copy the project's built-in mirror configuration to the user directory
mkdir -p ~/.m2
cp server/.mvn/settings.xml ~/.m2/settings.xml
```

Or manually create `~/.m2/settings.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<settings>
  <mirrors>
    <mirror>
      <id>aliyun</id>
      <url>https://maven.aliyun.com/repository/public</url>
      <mirrorOf>central</mirrorOf>
    </mirror>
  </mirrors>
</settings>
```

Reference: [Aliyun Maven Mirror Configuration Guide](https://maven.aliyun.com/mvn/guide)

### 2. Java version mismatch

**Symptom:** `Unsupported class file major version` or `java.lang.NoSuchMethodError`

**Solution:** Install Java 21+

```bash
# macOS
brew install openjdk@21

# Verify version
java -version
```

### 3. Port already in use

**Symptom:** `Port 8080 already in use`

**Solution:**

```bash
# View the process using the port
lsof -i :8080

# Terminate the process
kill -9 <PID>
```

### 4. View detailed logs

If the above solutions don't resolve the issue, view the backend logs:

```bash
make dev-logs SERVICE=backend
# Or view directly
cat .dev/server.log
```
