const http = require('http');
const https = require('https');
const fs = require('fs');
const path = require('path');

const API_URL = process.env.API_URL || 'https://nskp-io.goskope.com/api/v2/nsiq/urllookup';
const API_TOKEN = process.env.API_TOKEN || '';
const PORT = 3000;

// HTML escape function to prevent XSS
function escapeHtml(text) {
    const map = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#039;'
    };
    return text.replace(/[&<>"']/g, (m) => map[m]);
}

// Validate hostname to prevent header injection attacks
// Note: For DNS sinkholing, we need to accept ANY hostname including
// localhost and private IPs, since malicious domains resolve to our IP
function isValidHostname(hostname) {
    if (!hostname || typeof hostname !== 'string') {
        return false;
    }

    // Length validation
    if (hostname.length > 253 || hostname.length === 0) {
        return false;
    }

    // Prevent header injection attacks by blocking control characters
    // Allow: alphanumeric, dots, hyphens, and IPv6 characters (colons, brackets)
    const invalidChars = /[\x00-\x1F\x7F<>'"\\]/;
    if (invalidChars.test(hostname)) {
        return false;
    }

    // Block obvious injection attempts
    if (hostname.includes('\r') || hostname.includes('\n')) {
        return false;
    }

    return true;
}

// Read the HTML template
const templatePath = path.join(__dirname, 'blocked.html');
let htmlTemplate = fs.readFileSync(templatePath, 'utf8');

async function queryNetskopeAPI(hostname) {
    return new Promise((resolve, reject) => {
        const postData = JSON.stringify({
            query: {
                disable_dns_lookup: true,
                category: "swg",
                urls: [`https://${hostname}`]
            }
        });

        const urlObj = new URL(API_URL);
        const options = {
            hostname: urlObj.hostname,
            port: urlObj.port || 443,
            path: urlObj.pathname,
            method: 'POST',
            headers: {
                'Accept': 'application/json',
                'Authorization': `Bearer ${API_TOKEN}`,
                'Content-Type': 'application/json',
                'Content-Length': Buffer.byteLength(postData)
            }
        };

        const req = https.request(options, (res) => {
            let data = '';
            res.on('data', (chunk) => data += chunk);
            res.on('end', () => {
                try {
                    if (res.statusCode !== 200) {
                        console.error('API returned non-200 status:', res.statusCode);
                    }

                    const result = JSON.parse(data);
                    resolve(result);
                } catch (e) {
                    console.error('Error parsing API response:', e.message);
                    reject(e);
                }
            });
        });

        req.on('error', reject);
        req.write(postData);
        req.end();
    });
}

function extractCategories(apiResponse) {
    // Extract category names from the API response
    if (apiResponse && apiResponse.result && apiResponse.result[0] && apiResponse.result[0].categories) {
        const categoryNames = apiResponse.result[0].categories.map(cat => cat.name);

        // Return formatted string with all categories
        if (categoryNames.length === 1) {
            return categoryNames[0];
        } else if (categoryNames.length > 1) {
            return categoryNames.join('; ');
        }
    }

    return 'Security Policy Violation';
}

const server = http.createServer(async (req, res) => {
    // Health check endpoint
    if (req.url === '/health') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ status: 'ok', service: 'block-handler' }));
        return;
    }

    // Serve the logo file
    if (req.url === '/netskope-logo.png') {
        const logoPath = path.join(__dirname, 'netskope-logo.png');
        try {
            const logoData = fs.readFileSync(logoPath);
            res.writeHead(200, { 'Content-Type': 'image/png' });
            res.end(logoData);
            return;
        } catch (error) {
            console.error('Error serving logo:', error);
        }
    }

    // Validate Host header exists
    if (!req.headers.host) {
        console.error('Missing Host header');
        res.writeHead(400, { 'Content-Type': 'text/plain' });
        res.end('Bad Request: Missing Host header');
        return;
    }

    // Extract just the hostname from the request
    const hostname = req.headers.host.split(':')[0]; // Remove port if present

    // Validate hostname to prevent SSRF and header injection
    if (!isValidHostname(hostname)) {
        console.error('Invalid hostname:', hostname);
        res.writeHead(400, { 'Content-Type': 'text/plain' });
        res.end('Bad Request: Invalid hostname');
        return;
    }

    const fullUrl = `https://${req.headers.host}${req.url}`;

    console.log('Request for hostname:', hostname);

    try {
        // Query the Netskope API with the hostname
        const apiResponse = await queryNetskopeAPI(hostname);
        const categories = extractCategories(apiResponse);

        console.log(`Blocked: ${hostname} - Categories: ${categories}`);

        // Replace placeholders in HTML with escaped values to prevent XSS
        let html = htmlTemplate
            .replace('{{URL}}', escapeHtml(fullUrl))
            .replace('{{CATEGORY}}', escapeHtml(categories));

        res.writeHead(200, {
            'Content-Type': 'text/html; charset=utf-8',
            'X-Content-Type-Options': 'nosniff',
            'X-Frame-Options': 'DENY'
        });
        res.end(html);
    } catch (error) {
        console.error('Error querying API:', error.message);

        // Fallback to default category with escaped values
        let html = htmlTemplate
            .replace('{{URL}}', escapeHtml(fullUrl))
            .replace('{{CATEGORY}}', escapeHtml('Security Policy Violation'));

        res.writeHead(200, {
            'Content-Type': 'text/html; charset=utf-8',
            'X-Content-Type-Options': 'nosniff',
            'X-Frame-Options': 'DENY'
        });
        res.end(html);
    }
});

server.listen(PORT, () => {
    console.log(`Block handler listening on port ${PORT}`);
});

