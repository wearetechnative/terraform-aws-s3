# Lifecycle rule configuration

Can create simple lifecycle rules to the S3 bucket. This excludes rules that uses an AND in the filter argument. the Dynamic block would be to complicated with dynamic blocks nested within each other.

```hcl
lifecycle_configuration = {
        "garbarge_collector_rule" : {
            "bucket_prefix" : null,
            "transition": null #{"storage_class": "STANDARD_IA", "transition_days" : 1},
            "expiration_days": null,
            "noncurrent_version_expiration" : null #{ "newer_noncurrent_versions" : null, "noncurrent_days" : null },
            "status": "Disabled"
        }
    }
```