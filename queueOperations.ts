import { getActiveMqClient } from './activeMqConnection';
import { _getFileLogger } from '../logger/fileLogger';
import { FreeSwitchEventData } from 'esl-lite';
import { eventFilterService, FilterResult } from './eventFilterService';

const logger = _getFileLogger("QueueOperations");

/**
 * Send a raw string message to ActiveMQ queue
 */
export async function sendMessage(queueName: string, message: string): Promise<void> {
    try {
        const client = await getActiveMqClient();
        const headers = {
            destination: `/queue/${queueName}`,
            'content-type': 'text/plain',
        };

        const frame = client.send(headers);
        frame.write(message);
        frame.end();

        logger.info(`Message sent to ${queueName}`);
    } catch (error) {
        if (error instanceof Error) {
            logger.error(`Failed to send message to queue: ${error.message}`);
        } else {
            logger.error(`Unexpected error during message sending: ${JSON.stringify(error)}`);
        }
    }
}

/**
 * Send a filtered FreeSWITCH event to ActiveMQ queue
 * This applies event filtering based on configuration before sending
 */
export async function sendFilteredMessage(queueName: string, freeSwitchEvent: FreeSwitchEventData): Promise<void> {
    try {
        // Apply event filtering
        const filterResult: FilterResult = eventFilterService.filterEvent(freeSwitchEvent);
        
        // Send the filtered event
        const filteredMessage = JSON.stringify(filterResult.filtered);
        await sendMessage(queueName, filteredMessage);
        
    } catch (error) {
        if (error instanceof Error) {
            logger.error(`Failed to send filtered message to queue ${queueName}: ${error.message}`);
        } else {
            logger.error(`Unexpected error during filtered message sending: ${JSON.stringify(error)}`);
        }
        throw error;
    }
}

/**
 * Legacy compatibility function that automatically filters FreeSWITCH events
 * This can be used as a drop-in replacement for existing sendMessage calls with FreeSWITCH events
 */
export async function sendFreeSwitchEvent(queueName: string, freeSwitchEvent: FreeSwitchEventData): Promise<void> {
    return sendFilteredMessage(queueName, freeSwitchEvent);
}


