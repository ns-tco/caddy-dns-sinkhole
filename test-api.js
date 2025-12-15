#!/usr/bin/env node

// Test script to debug Netskope API responses

const https = require('https');

const API_URL = process.env.API_URL || 'https://nskp-io.goskope.com/api/v2/nsiq/urllookup';
const API_TOKEN = process.env.API_TOKEN || 'cmJhY3YzOm5haWthRzRDcnlySTg2dnIwZnNqMg==';

// Test URL
const testUrl = process.argv[2] || 'https://example.com';

console.log('=================================');
console.log('Netskope API Test');
console.log('=================================');
console.log('API URL:', API_URL);
console.log('Test URL:', testUrl);
console.log('=================================\n');

const postData = JSON.stringify({
    query: {
        disable_dns_lookup: true,
        category: "swg",
        urls: [testUrl]
    }
});

console.log('Request Body:');
console.log(postData);
console.log('\n=================================\n');

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
    console.log('Response Status:', res.statusCode);
    console.log('Response Headers:', JSON.stringify(res.headers, null, 2));
    console.log('\n=================================\n');
    
    let data = '';
    res.on('data', (chunk) => data += chunk);
    res.on('end', () => {
        console.log('Response Body:');
        console.log(data);
        console.log('\n=================================\n');
        
        try {
            const result = JSON.parse(data);
            console.log('Parsed Response:');
            console.log(JSON.stringify(result, null, 2));
            console.log('\n=================================\n');
            
            // Try to extract categories
            if (result && result.result && result.result[0]) {
                console.log('First result object:');
                console.log(JSON.stringify(result.result[0], null, 2));
                console.log('\n=================================\n');
                
                if (result.result[0].categories) {
                    console.log('Categories found:');
                    result.result[0].categories.forEach((cat, idx) => {
                        console.log(`  ${idx + 1}. ${cat.name || cat}`);
                    });
                } else {
                    console.log('❌ No categories array found in result[0]');
                    console.log('Available fields:', Object.keys(result.result[0]));
                }
            } else {
                console.log('❌ No result[0] found in response');
                if (result.result) {
                    console.log('Result array length:', result.result.length);
                }
            }
        } catch (e) {
            console.error('❌ Error parsing JSON:', e.message);
        }
    });
});

req.on('error', (e) => {
    console.error('❌ Request error:', e.message);
    console.error(e);
});

req.write(postData);
req.end();
