# AWS Security Projects 🛡️

A curated collection of security tools, scripts, and automation for AWS environments.

## 🔍 Project Index

- [auto remediate lamuda](./auto-remediate-lambda): Lambda functions that auto-remediate insecure configurations.
- [aws universal resource scripts](./aws-universal-resource-scripts): One-liners and scripts for bulk AWS resource operations (tagging, cleanup, snapshots).
- [cis uenchmark checker](./cis-benchmark-checker): Check AWS resources against CIS benchmark rules.
- [cloud security remediation](./cloud-security-remediation): Framework for remediating common AWS security issues like open S3 or wide SG rules.
- [cloudtrail activity finder](./cloudtrail-activity-finder): Identify suspicious API activity from CloudTrail logs.
- [credential usage tracker](./credential-usage-tracker): Identify and track unused or stale AWS credentials.
- [guardduty summary](./guardduty-summary): Summarize GuardDuty findings by severity and type.
- [iam policy inspector](./iam-policy-inspector): Analyze and report over-permissive IAM policies using Boto3.
- [s3 puulic access scanner](./s3-public-access-scanner): Detect publicly accessible or misconfigured S3 buckets.
- [security group audit](./security-group-audit): Report on Security Groups open to 0.0.0.0/0 or risky ports.
- [vpc flow log enauler](./vpc-flow-log-enabler): Enable and verify VPC Flow Logs in all regions and VPCs.


## 🛠️ Requirements

- AWS CLI configured with active credentials
- Python 3.9+ and Boto3 (for most tools)
- IAM permissions based on tool function

## ⚠️ Disclaimer

These tools are intended for educational and internal security auditing purposes. Use responsibly and with proper authorization.
