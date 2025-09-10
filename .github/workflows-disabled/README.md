# GitHub Workflows - DISABLED

This directory contains GitHub Actions workflows that have been temporarily disabled to prevent automatic triggers during development and testing.

## 📋 Disabled Workflows

The following workflows have been disabled:

- `security-and-lint.yml` - Security scanning and code linting
- `cis-compliance-check.yml` - CIS benchmark compliance checks  
- `azure-sentinel-deploy.yml` - Azure Sentinel deployment
- `deploy-test-infrastructure.yml` - Test infrastructure deployment
- `test-k8s-checker.yml` - Kubernetes security checks
- `emergency-cleanup.yml` - Emergency resource cleanup

## 🔄 Re-enabling Workflows

When you're ready to enable GitHub Actions workflows:

1. **Review and update workflow configurations** as needed
2. **Test workflows in a feature branch** first
3. **Rename directory back**:
   ```bash
   mv .github/workflows-disabled .github/workflows
   ```

## ⚠️ Important Notes

- Workflows are **completely disabled** while in `workflows-disabled` directory
- No GitHub Actions will trigger on push, pull request, or schedule
- This includes security scans, deployments, and compliance checks
- Remember to re-enable when ready for production use

## 🛡️ Security Considerations

While workflows are disabled:
- Manual security reviews are required
- No automated compliance checking
- No automatic deployment validation
- Consider enabling critical security workflows in production

## 📞 When to Re-enable

Re-enable workflows when:
- ✅ AWS Control Tower setup is complete and tested
- ✅ All Terraform configurations are validated
- ✅ Ready for automated CI/CD pipeline
- ✅ Security scanning requirements are defined
- ✅ Deployment targets are confirmed
