#!/usr/bin/env node

/**
 * Standalone Node.js Script to Connect to ActiveMQ using AMQP (port 5672)
 * Publishes CHANNEL_CREATE event to ActiveMQ queue
 * Based on the queueOperations.ts implementation
 */

const rhea = require('rhea');

class ActiveMQPublisher {
    constructor(options = {}) {
        this.config = {
            host: options.host || process.env.ACTIVEMQ_HOST || '127.0.0.1',
            port: options.port || Number(process.env.ACTIVEMQ_PORT) || 5672,
            username: options.username || process.env.ACTIVEMQ_USER || 'admin',
            password: options.password || process.env.ACTIVEMQ_PASS || 'admin',
            containerId: `standalonePublisher-${process.pid}-${Date.now()}`,
            reconnectDelay: 5000,
            heartbeatInterval: 30000
        };
        
        this.connection = null;
        this.senders = new Map();
        this.isConnected = false;
    }

    /**
     * Connect to ActiveMQ using AMQP protocol
     */
    async connect() {
        return new Promise((resolve, reject) => {
            console.log(`🔌 Connecting to ActiveMQ at ${this.config.host}:${this.config.port}`);
            console.log(`📋 Using credentials: ${this.config.username} / ${'*'.repeat(this.config.password.length)}`);
            
            this.connection = rhea.connect({
                host: this.config.host,
                port: this.config.port,
                username: this.config.username,
                password: this.config.password,
                container_id: this.config.containerId,
                reconnect: true,
                initial_reconnect_delay: this.config.reconnectDelay,
                max_reconnect_delay: 60000,
                idle_time_out: this.config.heartbeatInterval
            });

            this.connection.on('connection_open', () => {
                console.log('✅ Connected to ActiveMQ successfully');
                this.isConnected = true;
                resolve();
            });

            this.connection.on('connection_error', (error) => {
                console.error('❌ Connection error:', error.message || error);
                this.isConnected = false;
                reject(error);
            });

            this.connection.on('connection_close', () => {
                console.log('⚠️ Connection closed');
                this.isConnected = false;
            });

            this.connection.on('disconnected', () => {
                console.log('⚠️ Disconnected - will attempt reconnection');
                this.isConnected = false;
            });

            // Connection timeout
            setTimeout(() => {
                if (!this.isConnected) {
                    console.error('❌ Connection timeout');
                    reject(new Error('Connection timeout'));
                }
            }, 30000);
        });
    }

    /**
     * Send message to ActiveMQ queue
     * Uses AMQP protocol but configured for maximum JMS compatibility
     */
    async sendMessage(queueName, message) {
        if (!this.isConnected) {
            throw new Error('Not connected to ActiveMQ');
        }

        try {
            let sender = this.senders.get(queueName);
            
            if (!sender) {
                // Create sender with options for plain text compatibility
                sender = this.connection.open_sender({
                    target: { address: queueName },
                    // Configure for text messages compatible with JMS
                    settle_mode: 'settled',
                    auto_settle: true
                });
                this.senders.set(queueName, sender);
                console.log(`📡 Created sender for queue: ${queueName}`);
            }

            console.log(`\n📤 Sending message to queue: ${queueName}`);
            console.log(`📄 Message length: ${message.length} bytes`);
            console.log(`📄 Message content:`);
            console.log(JSON.stringify(JSON.parse(message), null, 2));

            // Send message with minimal AMQP formatting for JMS compatibility
            sender.send({
                body: message
            });

            console.log(`✅ Message sent successfully to ${queueName}`);
            return true;

        } catch (error) {
            console.error(`❌ Failed to send message to ${queueName}:`, error);
            throw error;
        }
    }

    /**
     * Publish the specific CHANNEL_CREATE event
     */
    async publishChannelCreateEvent(queueName = 'freeswitch_events') {
        const channelCreateEvent = {
            "event": "CHANNEL_CREATE",
            "headers": {
                "contentLength": 4896,
                "contentType": "text/event-json",
                "headers": {}
            },
            "body": {
                "eventName": "CHANNEL_CREATE",
                "uniqueID": "f421fa2b-5928-4718-aa57-1b8532ab04c3",
                "data": {
                    "Event-Name": "CHANNEL_CREATE",
                    "Event-Date-Timestamp": "1760861122512039",
                    "Unique-ID": "f421fa2b-5928-4718-aa57-1b8532ab04c3",
                    "Caller-Caller-ID-Number": "+917048990554",
                    "Caller-Context": "public",
                    "variable_sip_received_ip": "103.194.44.2",
                    "variable_sip_req_uri": "1818@13.201.2.235:5060",
                    "wrapperToCallModule": "callsModule4",
                    "logId": "[IIxFjwhL462]",
                    "llmCdrId": 1760861129274,
                    "operator": "",
                    "country": "",
                    "language": "",
                    "msisdn": "",
                    "otp": "",
                    "decrypted_timestamp": "",
                    "vId": 500
                }
            }
        };

        const message = JSON.stringify(channelCreateEvent);
        
        console.log('🎯 Publishing CHANNEL_CREATE event');
        console.log('==================================');
        
        return await this.sendMessage(queueName, message);
    }

    /**
     * Disconnect from ActiveMQ
     */
    async disconnect() {
        if (this.connection) {
            console.log('👋 Disconnecting from ActiveMQ...');
            
            // Close all senders
            this.senders.forEach((sender) => {
                try {
                    sender.close();
                } catch (e) {
                    // Ignore cleanup errors
                }
            });
            this.senders.clear();
            
            // Close connection
            this.connection.close();
            this.isConnected = false;
            
            console.log('✅ Disconnected successfully');
        }
    }
}

/**
 * Main function
 */
async function main() {
    console.log('📞 Standalone ActiveMQ Publisher');
    console.log('================================');
    console.log('Publishing CHANNEL_CREATE event using AMQP protocol');
    console.log('');
    
    const publisher = new ActiveMQPublisher();
    
    try {
        // Connect to ActiveMQ
        await publisher.connect();
        await sleep(1000); // Wait for connection to stabilize

        // Get queue name from command line argument or use default
        const queueName = process.argv[2] || 'freeswitch_events';
        
        console.log(`📋 Target queue: ${queueName}`);
        
        // Publish the CHANNEL_CREATE event
        await publisher.publishChannelCreateEvent(queueName);
        
        console.log('\n✅ Event published successfully!');

    } catch (error) {
        console.error('❌ Publishing failed:', error);
        process.exit(1);
    } finally {
        await publisher.disconnect();
    }
}

/**
 * Utility function for delays
 */
function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

// Handle graceful shutdown
process.on('SIGINT', async () => {
    console.log('\n⏹️ Publisher interrupted by user');
    process.exit(0);
});

process.on('SIGTERM', async () => {
    console.log('\n⏹️ Publisher terminated');
    process.exit(0);
});

// Run the publisher
if (require.main === module) {
    main().catch(console.error);
}

module.exports = ActiveMQPublisher;

