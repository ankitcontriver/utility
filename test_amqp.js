#!/usr/bin/env node
/**
 * Simple Node.js script to test AMQP message sending with durability
 */

const rhea = require("rhea");
const crypto = require("crypto");

// Configure logging
const logger = {
    info: (msg) => console.log(`[INFO] ${new Date().toISOString()} - ${msg}`),
    error: (msg) => console.error(`[ERROR] ${new Date().toISOString()} - ${msg}`),
    debug: (msg) => console.log(`[DEBUG] ${new Date().toISOString()} - ${msg}`)
};

function generateCallId() {
    return Math.random().toString(36).substring(2, 15).toUpperCase();
}

function generateLogId() {
    return Math.random().toString(36).substring(2, 10).toLowerCase();
}

function createChannelCreateEvent() {
    const callId = generateCallId();
    const logId = generateLogId();
    const timestamp = Date.now() * 1000; // Microseconds timestamp
    
    return {
        body: {
            uniqueID: callId,
            data: {
                "Event-Name": "CHANNEL_CREATE",
                "Event-Date-Timestamp": timestamp.toString(),
                "Unique-ID": callId,
                "Caller-Caller-ID-Number": `+1${Math.floor(Math.random() * 9000000000) + 1000000000}`,
                "Caller-Callee-ID-Number": `+1${Math.floor(Math.random() * 9000000000) + 1000000000}`,
                "Caller-Context": "default",
                "variable_sip_received_ip": `192.168.1.${Math.floor(Math.random() * 254) + 1}`,
                "variable_sip_req_uri": `sip:+1${Math.floor(Math.random() * 9000000000) + 1000000000}@example.com`,
                "wrapperToCallModule": "cm2wrapper",
                "logId": logId,
                "callId": callId,
                "llmCdrId": Math.floor(Math.random() * 900000) + 100000,
                "vId": Math.floor(Math.random() * 1000) + 1,
                "operator": ["Verizon", "AT&T", "T-Mobile", "Sprint"][Math.floor(Math.random() * 4)],
                "country": ["US", "UK", "DE", "FR", "IN", "AU", "CA"][Math.floor(Math.random() * 7)],
                "language": ["en", "es", "fr", "de", "ja", "ko", "zh", "hi", "ar", "id"][Math.floor(Math.random() * 10)],
                "msisdn": `+1${Math.floor(Math.random() * 9000000000) + 1000000000}`,
                "otp": Math.floor(Math.random() * 900000) + 100000,
                "decrypted_timestamp": Date.now().toString()
            }
        }
    };
}

async function sendMessageWithDurability() {
    return new Promise((resolve, reject) => {
        const connection = rhea.connect({
            host: '127.0.0.1',
            port: 5672,
            username: 'admin',
            password: 'admin',
            container_id: `test-sender-${crypto.randomBytes(4).toString('hex')}`,
        });

        connection.on('connection_open', () => {
            logger.info("Connected to AMQP broker");
            
            // Create sender with durability settings
            const sender = connection.open_sender({
                target: { address: 'cm2wrapper' },
                settle_mode: 'settled',
                auto_settle: true
            });

            sender.on('sendable', () => {
                const eventData = createChannelCreateEvent();
                const message = JSON.stringify(eventData);
                
                logger.info(`Sending message to cm2wrapper queue...`);
                logger.info(`Message: ${message}`);
                
                // Send message with durability properties
                sender.send({
                    body: message,
                    // Add durability properties
                    durable: true,
                    persistent: true,
                    // Add message properties
                    message_id: crypto.randomUUID(),
                    content_type: 'text/plain',
                    creation_time: Date.now(),
                    // Add TTL (time to live) - 1 hour
                    ttl: 3600000
                });
                
                logger.info("✅ Message sent with durability properties");
                
                // Close connection after sending
                setTimeout(() => {
                    connection.close();
                    resolve();
                }, 1000);
            });

            sender.on('accepted', () => {
                logger.info("✅ Message accepted by broker");
            });

            sender.on('rejected', (context) => {
                logger.error(`❌ Message rejected: ${context.reason}`);
                reject(new Error(`Message rejected: ${context.reason}`));
            });
        });

        connection.on('connection_error', (error) => {
            logger.error(`Connection error: ${error}`);
            reject(error);
        });

        connection.on('connection_close', () => {
            logger.info("Connection closed");
        });
    });
}

async function main() {
    try {
        await sendMessageWithDurability();
        logger.info("Script completed successfully");
    } catch (error) {
        logger.error(`Error: ${error.message}`);
        process.exit(1);
    }
}

// Run the script
if (require.main === module) {
    main().catch(console.error);
}

