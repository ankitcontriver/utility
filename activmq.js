#!/usr/bin/env node

/**
 * ActiveMQ Queue Debugger
 * Helps debug queue issues by testing different scenarios
 */

const rhea = require('rhea');

class ActiveMQDebugger {
    constructor(options = {}) {
        this.config = {
            host: options.host || process.env.ACTIVEMQ_HOST || '127.0.0.1',
            port: options.port || Number(process.env.ACTIVEMQ_PORT) || 5672,
            username: options.username || process.env.ACTIVEMQ_USER || 'admin',
            password: options.password || process.env.ACTIVEMQ_PASS || 'admin',
            containerId: `debugger-${process.pid}-${Date.now()}`,
            reconnectDelay: 5000,
            heartbeatInterval: 30000
        };
        
        this.connection = null;
        this.isConnected = false;
    }

    async connect() {
        return new Promise((resolve, reject) => {
            console.log(`🔌 Connecting to ActiveMQ at ${this.config.host}:${this.config.port}`);
            
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

            setTimeout(() => {
                if (!this.isConnected) {
                    console.error('❌ Connection timeout');
                    reject(new Error('Connection timeout'));
                }
            }, 30000);
        });
    }

    async listQueues() {
        console.log('\n📋 Attempting to list available queues...');
        
        // Try to discover queues by attempting to create receivers
        const commonQueueNames = [
            'cm2wrapper',
            'freeswitch_events',
            'call_start',
            'call_message',
            'test_queue',
            'queue.cm2wrapper',
            '/queue/cm2wrapper',
            'queue://cm2wrapper'
        ];

        const availableQueues = [];

        for (const queueName of commonQueueNames) {
            try {
                const receiver = this.connection.open_receiver({
                    source: { address: queueName },
                    autoaccept: false
                });

                receiver.on('receiver_open', () => {
                    console.log(`✅ Queue accessible: ${queueName}`);
                    availableQueues.push(queueName);
                    receiver.close();
                });

                receiver.on('receiver_error', (error) => {
                    console.log(`❌ Queue not accessible: ${queueName} - ${error.message}`);
                    receiver.close();
                });

                // Wait a bit for the receiver to open
                await this.sleep(500);

            } catch (error) {
                console.log(`❌ Error testing queue ${queueName}: ${error.message}`);
            }
        }

        return availableQueues;
    }

    async testSendAndReceive(queueName) {
        console.log(`\n🧪 Testing send and receive for queue: ${queueName}`);
        
        const testMessage = JSON.stringify({
            test: true,
            timestamp: Date.now(),
            queue: queueName
        });

        // Send message
        console.log('📤 Sending test message...');
        const sender = this.connection.open_sender({
            target: { address: queueName },
            settle_mode: 'settled',
            auto_settle: true
        });

        sender.send({ body: testMessage });
        console.log('✅ Test message sent');

        // Wait a bit
        await this.sleep(1000);

        // Try to receive message
        console.log('📥 Attempting to receive message...');
        const receiver = this.connection.open_receiver({
            source: { address: queueName },
            autoaccept: true
        });

        let messageReceived = false;
        const timeout = setTimeout(() => {
            if (!messageReceived) {
                console.log('⏰ No message received within timeout');
                receiver.close();
            }
        }, 5000);

        receiver.on('message', (context) => {
            messageReceived = true;
            clearTimeout(timeout);
            console.log('✅ Message received successfully!');
            console.log(`📄 Received: ${context.message.body}`);
            receiver.close();
        });

        receiver.on('receiver_error', (error) => {
            clearTimeout(timeout);
            console.log(`❌ Receiver error: ${error.message}`);
            receiver.close();
        });

        // Wait for result
        await this.sleep(6000);
    }

    async sleep(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    async disconnect() {
        if (this.connection) {
            console.log('👋 Disconnecting...');
            this.connection.close();
            this.isConnected = false;
        }
    }
}

async function main() {
    const debugger = new ActiveMQDebugger();
    
    try {
        await debugger.connect();
        await debugger.sleep(1000);

        const queueName = process.argv[2] || 'cm2wrapper';
        
        console.log(`\n🔍 Debugging queue: ${queueName}`);
        
        // List available queues
        const availableQueues = await debugger.listQueues();
        
        if (availableQueues.length > 0) {
            console.log(`\n📋 Available queues: ${availableQueues.join(', ')}`);
        } else {
            console.log('\n⚠️ No accessible queues found');
        }

        // Test send and receive
        await debugger.testSendAndReceive(queueName);

    } catch (error) {
        console.error('❌ Debug failed:', error);
    } finally {
        await debugger.disconnect();
    }
}

if (require.main === module) {
    main().catch(console.error);
}

module.exports = ActiveMQDebugger;

