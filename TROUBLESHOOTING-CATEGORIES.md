# Troubleshooting: Categories Not Showing

If you're seeing "Security Policy Violation" instead of actual categories, use this guide to debug.

## Quick Diagnosis

### Step 1: Check Logs

```bash
docker-compose logs block-handler
```

Look for:
- API response details
- Category extraction messages
- Any error messages

### Step 2: Test API Directly

Use the included test script:

```bash
# From your deployment directory
docker exec -it block-handler node /app/test-api.js https://example.com
```

Or copy it out and run locally:
```bash
node test-api.js https://example.com
```

This will show you exactly what the API is returning.

## Common Issues

### Issue 1: API Authentication Error

**Symptoms:**
- Logs show HTTP 401 or 403
- "Security Policy Violation" always displayed

**Solution:**
```bash
# Check your API token
docker-compose logs block-handler | grep "API Response Status"

# Update token in docker-compose.yml
nano docker-compose.yml
# Update line 40: API_TOKEN=your_correct_token

# Restart
docker-compose restart block-handler
```

### Issue 2: Wrong API Response Structure

**Symptoms:**
- Logs show successful API call (200 OK)
- But still showing "Security Policy Violation"
- Logs say "No categories found in response"

**Solution:**
The API response structure might be different than expected. Check logs for the actual structure:

```bash
docker-compose logs block-handler | grep -A 20 "API Response Parsed"
```

Common variations:
```javascript
// Expected structure
{
  "result": [
    {
      "categories": [
        {"name": "Adult Content"},
        {"name": "Pornography"}
      ]
    }
  ]
}

// Possible alternative structures
{
  "data": { "categories": [...] }  // Different root key
}

{
  "result": {
    "categories": [...] // Not an array
  }
}

{
  "categories": [...]  // Direct categories
}
```

### Issue 3: API Returns Empty Categories

**Symptoms:**
- API call succeeds
- Response has correct structure
- But categories array is empty

**Possible Reasons:**
- URL is not categorized in Netskope database
- URL needs DNS lookup (try setting `disable_dns_lookup: false`)
- Category type "swg" doesn't match your setup

**Solution:**
Edit `block-handler/server.js` line 19 to try different settings:

```javascript
// Try enabling DNS lookup
query: {
    disable_dns_lookup: false,  // Changed from true
    category: "swg",
    urls: [`https://${hostname}`]
}

// Or try different category type
query: {
    disable_dns_lookup: true,
    category: "all",  // Changed from "swg"
    urls: [`https://${hostname}`]
}
```

## Debugging Steps

### 1. Enable Detailed Logging

The updated `server.js` already has detailed logging. Check logs:

```bash
docker-compose logs -f block-handler
```

Make a test request:
```bash
curl -k https://example.com:5656
```

Watch the logs for:
```
=== New Request ===
Hostname: example.com
Querying Netskope API for: example.com
API Response Status: 200
API Response Body: {...}
Extracting categories from response...
Found categories array: [...]
```

### 2. Inspect API Response

```bash
# Get last 100 lines of logs
docker-compose logs --tail=100 block-handler > api-debug.log

# Look for "API Response Parsed"
grep -A 30 "API Response Parsed" api-debug.log
```

### 3. Test Different URLs

```bash
# Test with different URLs to see if some work
curl -k https://google.com:5656
curl -k https://facebook.com:5656
curl -k https://example.com:5656
```

Check logs for each request.

### 4. Validate API Credentials

```bash
# Extract and test credentials manually
docker exec block-handler printenv | grep API

# Test with curl
API_TOKEN="your_token_here"
curl -X POST https://nskp-io.goskope.com/api/v2/nsiq/urllookup \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "query": {
      "disable_dns_lookup": true,
      "category": "swg",
      "urls": ["https://example.com"]
    }
  }'
```

## Fix Based on API Response Structure

Once you know the actual API response structure, update `server.js`:

### Example Fix 1: Different Path

If categories are at `data.categories` instead of `result[0].categories`:

```javascript
function extractCategories(apiResponse) {
    if (apiResponse && apiResponse.data && apiResponse.data.categories) {
        const categoryNames = apiResponse.data.categories.map(cat => cat.name);
        // ... rest of code
    }
    return 'Security Policy Violation';
}
```

### Example Fix 2: Categories Not Nested

If categories are directly in result:

```javascript
function extractCategories(apiResponse) {
    if (apiResponse && apiResponse.categories) {
        const categoryNames = apiResponse.categories.map(cat => cat.name);
        // ... rest of code
    }
    return 'Security Policy Violation';
}
```

### Example Fix 3: Category is String Not Object

If categories are strings not objects:

```javascript
function extractCategories(apiResponse) {
    if (apiResponse && apiResponse.result && apiResponse.result[0] && apiResponse.result[0].categories) {
        // Categories might be strings directly
        const categoryNames = apiResponse.result[0].categories.map(cat => 
            typeof cat === 'string' ? cat : cat.name
        );
        // ... rest of code
    }
    return 'Security Policy Violation';
}
```

## Test Script Usage

The `test-api.js` script is your best debugging tool:

```bash
# Test from inside container
docker exec -it block-handler node /app/test-api.js https://adult-site.com

# Or run locally
cd caddy-deploy
API_URL=your_api_url API_TOKEN=your_token node test-api.js https://test.com
```

The script will show:
- Request being sent
- Response status
- Raw response body
- Parsed JSON
- Extracted categories (if found)
- Field names available

## After Fixing

1. Update `block-handler/server.js` with your fix
2. Restart the container:
   ```bash
   docker-compose restart block-handler
   ```
3. Test:
   ```bash
   curl -k https://example.com:5656
   ```
4. Check logs:
   ```bash
   docker-compose logs block-handler | tail -50
   ```

## Getting Help

If you're still stuck, gather this information:

1. **API Response:**
   ```bash
   docker-compose logs block-handler | grep -A 20 "API Response Parsed"
   ```

2. **Test Script Output:**
   ```bash
   docker exec block-handler node /app/test-api.js https://test.com
   ```

3. **Current Configuration:**
   ```bash
   cat docker-compose.yml | grep -A 2 API_
   ```

This information will help diagnose the issue!
