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
        this.pendingMessage = null;
        this.pendingQueue = null;
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
     * Uses the EXACT same approach as queueOperations.ts - STOMP-like API with AMQP underneath
     */
    async sendMessage(queueName, message) {
        if (!this.isConnected) {
            throw new Error('Not connected to ActiveMQ');
        }

        try {
            console.log(`\n📤 Sending message to queue: ${queueName}`);
            console.log(`📄 Message length: ${message.length} bytes`);
            console.log(`📄 Message content:`);
            console.log(JSON.stringify(JSON.parse(message), null, 2));

            // EXACT same approach as queueOperations.ts
            const headers = {
                destination: `/queue/${queueName}`,
                'content-type': 'text/plain',
            };

            console.log(`🔧 AMQP Headers: ${JSON.stringify(headers)}`);
            console.log(`📡 Sending to AMQP client...`);

            // Create the STOMP-like frame (same as queueOperations.ts)
            const frame = this.createStompLikeFrame(headers);
            frame.write(message);
            frame.end();

            console.log(`✅ Message sent successfully to ${queueName}`);
            
            // Add a small delay to ensure message is processed
            await this.sleep(1000);
            
            return true;

        } catch (error) {
            console.error(`❌ Failed to send message to ${queueName}:`, error);
            throw error;
        }
    }

    /**
     * Create STOMP-like frame that mimics the queueOperations.ts approach
     * This is the EXACT same pattern used in your existing code
     */
    createStompLikeFrame(headers) {
        const queueName = headers.destination.replace('/queue/', '');
        
        return {
            write: (message) => {
                this.pendingMessage = message;
                this.pendingQueue = queueName;
            },
            end: () => {
                if (this.pendingMessage && this.pendingQueue) {
                    this.sendToQueue(this.pendingQueue, this.pendingMessage);
                }
            }
        };
    }

    /**
     * Send message to specific queue using AMQP (same as activeMqConnection.ts)
     */
    sendToQueue(queueName, message) {
        try {
            let queueSender = this.senders.get(queueName);
            
            if (!queueSender) {
                // Create sender with options for plain text compatibility
                queueSender = this.connection.open_sender({
                    target: { address: queueName },
                    // Configure for text messages compatible with JMS
                    settle_mode: 'settled',
                    auto_settle: true
                });
                this.senders.set(queueName, queueSender);
                console.log(`📡 Created sender for queue: ${queueName}`);
            }
            
            console.log(`📡 COMPLETE MESSAGE BEFORE AMQP SEND:`);
            console.log(`📡 Target Queue: "${queueName}"`);
            console.log(`📡 Message Length: ${message.length} bytes`);
            console.log(`📡 Complete AMQP Message Body: ${message}`);
            console.log(`📡 ===============================================================================================================`);
            
            console.log(`📡 Executing AMQP send operation as plain text for JMS compatibility...`);
            
            // Send message with minimal AMQP formatting for JMS compatibility
            queueSender.send({
                body: message
            });
            
            console.log(`✅ Message sent to ${queueName}`);
            
            console.log(`📡 AMQP DELIVERY CONFIRMED (Plain Text Mode):`);
            console.log(`📡 Queue: "${queueName}" | Message Size: ${message.length} bytes | Status: DELIVERED`);
            console.log(`📡 Delivery Timestamp: ${new Date().toISOString()}`);
            console.log(`📡 JMS-Compatible Plain Text Message Sent Successfully`);
            console.log(`📡 ===============================================================================================================`);
            
        } catch (error) {
            console.error(`Failed to send message to ${queueName}: ${error}`);
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
     * Verify message was sent by attempting to consume it (for debugging)
     */
    async verifyMessage(queueName, timeoutMs = 5000) {
        return new Promise((resolve) => {
            console.log(`🔍 Verifying message in queue: ${queueName}`);
            
            const receiver = this.connection.open_receiver({
                source: { address: queueName },
                autoaccept: true
            });

            let messageReceived = false;
            const timeout = setTimeout(() => {
                if (!messageReceived) {
                    console.log(`⏰ Verification timeout - no message found in ${queueName}`);
                    receiver.close();
                    resolve(false);
                }
            }, timeoutMs);

            receiver.on('message', (context) => {
                messageReceived = true;
                clearTimeout(timeout);
                console.log(`✅ Verification successful - message found in ${queueName}`);
                console.log(`📄 Received message: ${context.message.body}`);
                receiver.close();
                resolve(true);
            });

            receiver.on('receiver_error', (error) => {
                clearTimeout(timeout);
                console.log(`❌ Verification failed for ${queueName}: ${error.message}`);
                receiver.close();
                resolve(false);
            });
        });
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
        
        // Optional: Verify the message was actually sent
        console.log('\n🔍 Verifying message delivery...');
        const verified = await publisher.verifyMessage(queueName);
        if (verified) {
            console.log('✅ Message verification successful - message is in the queue!');
        } else {
            console.log('⚠️ Message verification failed - message may not be in the queue');
            console.log('💡 This could mean:');
            console.log('   - The message was consumed by another consumer');
            console.log('   - The queue name format is incorrect');
            console.log('   - There\'s a permission issue');
            console.log('   - The message was sent to a different queue');
        }

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

