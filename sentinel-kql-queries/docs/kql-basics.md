# KQL Basics for Microsoft Sentinel

## Introduction
Kusto Query Language (KQL) is used to analyze data in Microsoft Sentinel. This guide covers essential concepts for security analysts.

## Basic Syntax

### Time Filtering
```kql
// Last 24 hours
| where TimeGenerated > ago(24h)

// Specific time range
| where TimeGenerated between (datetime(2025-01-01) .. datetime(2025-01-02))
```

### Filtering and Searching
```kql
// Exact match
| where Account == "user@domain.com"

// Contains
| where Account contains "admin"

// Multiple conditions
| where Account contains "admin" and ResultType != "0"
```

### Aggregations
```kql
// Count by field
| summarize count() by Account

// Multiple aggregations
| summarize 
    Total = count(),
    UniqueUsers = dcount(Account),
    FirstSeen = min(TimeGenerated)
    by SourceIP
```

### Common Functions
- `ago()` - Time relative to now
- `bin()` - Time bucketing
- `count()` - Count rows
- `dcount()` - Distinct count
- `make_set()` - Create array of unique values
- `extend` - Add calculated columns
- `project` - Select specific columns

## Performance Tips
1. Always include time filters
2. Use `where` clauses early
3. Limit result sets with `limit`
4. Use `sample` for testing large datasets
