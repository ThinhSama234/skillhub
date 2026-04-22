---
title: Storage SPI
sidebar_position: 2
description: Storage service provider extension
---

# Storage SPI

## SPI Interface

```java
public interface ObjectStorageService {
    void store(String key, InputStream content, String contentType);
    InputStream retrieve(String key);
    void delete(String key);
    boolean exists(String key);
}
```

## Built-in Implementations

### LocalFileStorageService

Local filesystem implementation, intended for development environments.

### S3StorageService

S3 protocol-compatible implementation, supporting:
- AWS S3
- MinIO
- Alibaba Cloud OSS
- Tencent Cloud COS
- Other S3-compatible storage

## Configuration

```bash
# Choose storage provider
SKILLHUB_STORAGE_PROVIDER=s3

# S3 configuration
SKILLHUB_STORAGE_S3_ENDPOINT=https://s3.example.com
SKILLHUB_STORAGE_S3_BUCKET=skillhub
SKILLHUB_STORAGE_S3_ACCESS_KEY=xxx
SKILLHUB_STORAGE_S3_SECRET_KEY=xxx
```

## Custom Implementation

Implement the `ObjectStorageService` interface and register it as a Spring Bean.

## Next Steps

- [FAQ](../../reference/faq) - Frequently asked questions
