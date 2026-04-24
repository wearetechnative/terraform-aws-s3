# CORS Configuration

CORS (Cross-Origin Resource Sharing) configuration allows web browsers to make requests to your S3 bucket from different origins (domains). This is essential for web applications that need to fetch resources directly from S3.

## Example 1: Simple Read-Only Access

For SaaS applications like Documenso that need to fetch documents from S3 for display in a web browser.

```hcl
module "storage" {
  source      = "git@github.com:wearetechnative/terraform-aws-s3.git"
  name        = "my-app-storage"
  kms_key_arn = aws_kms_key.default.arn

  cors_rules = [{
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["https://app.example.com"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }]
}
```

This configuration:
- Allows GET and HEAD requests (read-only)
- Only from `https://app.example.com` (specific origin for security)
- Accepts any request headers
- Exposes the ETag header to the browser
- Caches the CORS preflight response for 3000 seconds (50 minutes)

## Example 2: Multiple Origins

For applications with multiple environments (staging, production) or multiple frontend domains.

```hcl
module "storage" {
  source      = "git@github.com:wearetechnative/terraform-aws-s3.git"
  name        = "multi-env-storage"
  kms_key_arn = aws_kms_key.default.arn

  cors_rules = [{
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = [
      "https://app.example.com",
      "https://staging.example.com",
      "https://app.example.dev"
    ]
  }]
}
```

## Example 3: File Upload from Browser

For applications that allow users to upload files directly from the browser to S3 (using presigned URLs or similar).

```hcl
module "storage" {
  source      = "git@github.com:wearetechnative/terraform-aws-s3.git"
  name        = "upload-storage"
  kms_key_arn = aws_kms_key.default.arn

  cors_rules = [{
    allowed_headers = [
      "Authorization",
      "Content-Type",
      "x-amz-date",
      "x-amz-security-token"
    ]
    allowed_methods = ["GET", "PUT", "POST"]
    allowed_origins = ["https://app.example.com"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3600
  }]
}
```

This configuration:
- Allows PUT and POST for uploads
- Specifies exact headers needed for authenticated uploads
- Single trusted origin

## Example 4: Multiple CORS Rules

For buckets serving different types of content with different CORS requirements.

```hcl
module "storage" {
  source      = "git@github.com:wearetechnative/terraform-aws-s3.git"
  name        = "multi-rule-storage"
  kms_key_arn = aws_kms_key.default.arn

  cors_rules = [
    {
      # Public assets (images, CSS, JS) - read-only from any app subdomain
      allowed_headers = ["*"]
      allowed_methods = ["GET", "HEAD"]
      allowed_origins = ["https://*.example.com"]
    },
    {
      # API access for document management - more restrictive
      allowed_headers = ["Authorization", "Content-Type"]
      allowed_methods = ["GET", "POST", "PUT", "DELETE"]
      allowed_origins = ["https://api.example.com"]
      max_age_seconds = 7200
    }
  ]
}
```

## Using with CloudFront

If you're using CloudFront in front of your S3 bucket, you have two options for handling CORS:

### Option 1: S3 CORS (Forward Headers)

Configure CORS on S3 (using this module) and have CloudFront forward the necessary headers:

```hcl
# S3 bucket with CORS
module "storage" {
  source      = "git@github.com:wearetechnative/terraform-aws-s3.git"
  name        = "cdn-storage"
  kms_key_arn = aws_kms_key.default.arn

  cors_rules = [{
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["https://app.example.com"]
  }]
}

# CloudFront distribution (separate resource)
# Configure to forward Origin, Access-Control-Request-Headers, and
# Access-Control-Request-Method headers to S3
```

### Option 2: CloudFront Response Headers Policy

Use CloudFront's Response Headers Policy to add CORS headers (no S3 CORS configuration needed):

```hcl
# S3 bucket without CORS
module "storage" {
  source      = "git@github.com:wearetechnative/terraform-aws-s3.git"
  name        = "cdn-storage"
  kms_key_arn = aws_kms_key.default.arn
  # No cors_rules needed
}

# CloudFront distribution (separate resource)
# Use response_headers_policy with cors_config to add CORS headers
```

**Which to choose?**
- Use **Option 1** if you need S3 to make CORS decisions based on the request
- Use **Option 2** for simpler, static CORS headers applied by CloudFront
- Both options work; Option 2 is often simpler for static content delivery

## Security Considerations

### Wildcard Origins

**Avoid wildcard origins with write methods:**

```hcl
# DANGEROUS - allows any origin to upload files
cors_rules = [{
  allowed_origins = ["*"]
  allowed_methods = ["PUT", "POST", "DELETE"]  # Risk: CSRF attacks
  allowed_headers = ["*"]
}]
```

**Safe use of wildcards:**

```hcl
# ACCEPTABLE - read-only access from any origin
cors_rules = [{
  allowed_origins = ["*"]
  allowed_methods = ["GET", "HEAD"]  # Read-only is safer
  allowed_headers = ["*"]
}]
```

### Method Permissiveness

Only allow the HTTP methods your application actually needs:

- **GET, HEAD**: Reading objects (safest)
- **PUT, POST**: Uploading/creating objects (requires authentication)
- **DELETE**: Removing objects (most dangerous, requires strong authentication)

### CORS vs Public Access

**Important:** CORS configuration does NOT make your bucket public.

- **CORS**: Controls whether *browsers* can make cross-origin requests
- **Bucket Policy**: Controls who can actually access the objects

Example of private bucket with CORS (common pattern):

```hcl
module "storage" {
  source      = "git@github.com:wearetechnative/terraform-aws-s3.git"
  name        = "private-with-cors"
  kms_key_arn = aws_kms_key.default.arn

  # CORS enabled for browser access
  cors_rules = [{
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["https://app.example.com"]
  }]

  # Bucket is still private - access via presigned URLs or IAM
  enable_public_read_access = false
}
```

Users authenticate with your application, which generates presigned URLs. Browsers can then fetch those URLs thanks to CORS configuration.

### Specific Origins Over Wildcards

Always prefer specific origins when possible:

```hcl
# BETTER
allowed_origins = ["https://app.example.com", "https://staging.example.com"]

# ACCEPTABLE (subdomain wildcard)
allowed_origins = ["https://*.example.com"]

# AVOID (unless truly needed for public assets)
allowed_origins = ["*"]
```

### Header Filtering

Consider restricting allowed headers for write operations:

```hcl
# More restrictive (better for uploads)
allowed_headers = ["Authorization", "Content-Type", "x-amz-date"]

# Less restrictive (acceptable for simple reads)
allowed_headers = ["*"]
```
