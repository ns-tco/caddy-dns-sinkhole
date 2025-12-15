const http = require('http');
const https = require('https');
const fs = require('fs');
const path = require('path');

const API_URL = process.env.API_URL || 'https://nskp-io.goskope.com/api/v2/nsiq/urllookup';
const PORT = 3000;

// Read the HTML template
const templatePath = path.join(__dirname, 'blocked.html');
let htmlTemplate = fs.readFileSync(templatePath, 'utf8');

async function queryNetskopeAPI(url) {
    return new Promise((resolve, reject) => {
        const postData = JSON.stringify({
            query: {
                disable_dns_lookup: true,
                category: "swg",
                urls: [url]
            }
        });

        const urlObj = new URL(API_URL);
        const options = {
            hostname: urlObj.hostname,
            port: urlObj.port || 443,
            path: urlObj.pathname,
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': Buffer.byteLength(postData)
            }
        };

        const req = https.request(options, (res) => {
            let data = '';
            res.on('data', (chunk) => data += chunk);
            res.on('end', () => {
                try {
                    const result = JSON.parse(data);
                    resolve(result);
                } catch (e) {
                    reject(e);
                }
            });
        });

        req.on('error', reject);
        req.write(postData);
        req.end();
    });
}

function extractCategory(apiResponse) {
    // Parse the API response to extract category
    // Adjust this based on actual API response structure
    if (apiResponse && apiResponse.data && apiResponse.data[0]) {
        return apiResponse.data[0].category || 'Security Policy Violation';
    }
    return 'Security Policy Violation';
}

const server = http.createServer(async (req, res) => {
    const fullUrl = `https://${req.headers.host}${req.url}`;
    
    try {
        // Query the Netskope API
        const apiResponse = await queryNetskopeAPI(fullUrl);
        const category = extractCategory(apiResponse);
        
        // Replace placeholders in HTML
        let html = htmlTemplate
            .replace('{{URL}}', fullUrl)
            .replace('{{CATEGORY}}', category);
        
        res.writeHead(200, { 'Content-Type': 'text/html' });
        res.end(html);
    } catch (error) {
        console.error('Error querying API:', error);
        
        // Fallback to default category
        let html = htmlTemplate
            .replace('{{URL}}', fullUrl)
            .replace('{{CATEGORY}}', 'Security Policy Violation');
        
        res.writeHead(200, { 'Content-Type': 'text/html' });
        res.end(html);
    }
});

server.listen(PORT, () => {
    console.log(`Block handler listening on port ${PORT}`);
});
