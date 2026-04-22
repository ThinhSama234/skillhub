---
title: SkillHub Documentation Center
sidebar_position: 1
description: Enterprise-grade AI Skill Registry - A secure and controlled platform for skill publishing, discovery, and management
---

# SkillHub

<section className="hero-section">
  <div className="container">
    <h1 className="hero-section__title">🏢 Enterprise-grade AI Skill Registry</h1>
    <p className="hero-section__tagline">
      A secure and controlled platform for skill publishing, discovery, and management — safeguarding enterprise data sovereignty
    </p>
    <div className="hero-section__cta">
      <a href="/getting-started/quick-start" className="btn-primary">Deploy Now</a>
      <a href="/getting-started/overview" className="btn-secondary">Learn More</a>
    </div>
  </div>
</section>

---

## Enterprise Value

<div className="row" style={{ marginTop: '40px', marginBottom: '40px' }}>
  <div className="col col--3">
    <div className="enterprise-value-card">
      <div className="enterprise-value-card__icon">🔐</div>
      <h3 className="enterprise-value-card__title">Data Sovereignty</h3>
      <p className="enterprise-value-card__description">
        Self-hosted deployment — data never leaves the enterprise network; supports private S3/MinIO storage; complete audit trail
      </p>
    </div>
  </div>
  <div className="col col--3">
    <div className="enterprise-value-card">
      <div className="enterprise-value-card__icon">🏢</div>
      <h3 className="enterprise-value-card__title">Robust Governance</h3>
      <p className="enterprise-value-card__description">
        Namespace isolation; two-tier review mechanism; fine-grained RBAC permission control
      </p>
    </div>
  </div>
  <div className="col col--3">
    <div className="enterprise-value-card">
      <div className="enterprise-value-card__icon">🔌</div>
      <h3 className="enterprise-value-card__title">Strong Integration</h3>
      <p className="enterprise-value-card__description">
        Compatible with ClawHub CLI; standard REST API; OAuth2 enterprise SSO integration
      </p>
    </div>
  </div>
  <div className="col col--3">
    <div className="enterprise-value-card">
      <div className="enterprise-value-card__icon">📊</div>
      <h3 className="enterprise-value-card__title">Full Observability</h3>
      <p className="enterprise-value-card__description">
        Complete audit logs; Prometheus metrics; operation tracing and lineage
      </p>
    </div>
  </div>
</div>

---

## Core Features

<div style={{ textAlign: 'center', marginTop: '40px' }}>
  <div className="feature-tags">
    <span className="feature-tag">Version Control</span>
    <span className="feature-tag">Full-text Search</span>
    <span className="feature-tag">Namespaces</span>
    <span className="feature-tag">Review Workflow</span>
    <span className="feature-tag">Semantic Versioning</span>
    <span className="feature-tag">Multi-dimensional Filtering</span>
    <span className="feature-tag">RBAC Permissions</span>
    <span className="feature-tag">Audit Logs</span>
  </div>
</div>

---

## Quick Start

<div style={{ textAlign: 'center', marginTop: '40px' }}>
  <div className="quick-start-code">
    <code>$ curl -fsSL https://raw.githubusercontent.com/iflytek/skillhub/main/scripts/runtime.sh | sh -s -- up</code>
  </div>
  <p style={{ marginTop: '16px', color: 'var(--ifm-font-color-secondary)' }}>
    Visit <a href="http://localhost:3000">http://localhost:3000</a> to get started
  </p>
</div>

---

## Next Steps

- [Quick Start](./getting-started/quick-start) - Launch SkillHub with a single command
- [Product Overview](./getting-started/overview) - Learn more about product features
- [Deployment Guide](./administration/deployment/single-machine) - Production environment deployment
