# Contributing to Sentinel KQL Queries

Thank you for your interest in contributing to this repository! This document provides guidelines for contributing queries, documentation, and improvements.

## How to Contribute

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/your-feature-name`
3. **Make your changes**
4. **Test thoroughly**
5. **Commit your changes**: `git commit -m "Add: description of your changes"`
6. **Push to your fork**: `git push origin feature/your-feature-name`
7. **Submit a pull request**

## Query Submission Guidelines

### File Naming
- Use lowercase with hyphens: `failed-login-attempts.kql`
- Be descriptive and specific
- Include version if applicable: `malware-detection-v2.kql`

### Query Header Template
```kql
// Query: [Descriptive Name]
// Description: [What this query detects]
// Author: [Your name]
// Created: [YYYY-MM-DD]
// Last Modified: [YYYY-MM-DD]
// Severity: [High/Medium/Low]
// MITRE ATT&CK: [T1234 - Technique Name]
// Data Sources: [Required tables]
// False Positive Rate: [High/Medium/Low]
// Tags: [detection, hunting, compliance, etc.]
```

### Quality Requirements
- Include proper time range filters
- Add meaningful comments
- Optimize for performance
- Document known false positives
- Provide example output or screenshots
- Test in production-like environment

## Code of Conduct

- Be respectful and professional
- Help others learn and improve
- Provide constructive feedback
- Follow security best practices
- Never include sensitive or proprietary information

## Questions?

Open an issue or reach out to the maintainers.
