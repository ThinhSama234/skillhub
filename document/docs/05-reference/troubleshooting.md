---
title: Troubleshooting
sidebar_position: 2
description: Common issue diagnosis and solutions
---

# Troubleshooting

## Service Fails to Start

### Checklist

1. Check container status: `docker compose ps`
2. View service logs: `docker compose logs <service>`
3. Verify environment variables: check `.env.release` configuration
4. Check port conflicts: `netstat -tlnp`

### Common Causes

- Port already in use
- Database connection failure
- Redis connection failure
- Missing environment variables

## Upload Failures

### Skill Package Upload Failure

1. Check file size
2. Check file type
3. Check `SKILL.md` format
4. View server-side logs

## Authentication Issues

### Cannot Log In

1. Check OAuth configuration
2. Check callback URL configuration
3. Check `SKILLHUB_PUBLIC_BASE_URL` configuration

## Performance Issues

### Slow Search

1. Check PostgreSQL full-text index
2. Consider upgrading to Elasticsearch (future version)

### Slow Downloads

1. Check object storage configuration
2. Check network bandwidth

## Getting Help

If the above solutions do not resolve the issue:
1. Review logs
2. Submit an Issue
3. Contact technical support

## Next Steps

- [Changelog](./changelog) - Version history
