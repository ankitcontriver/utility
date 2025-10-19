import { getActiveMqClient } from './activeMqConnection';
import { getLogger } from '../logger/logger';
import { FreeSwitchEventData } from 'esl-lite';
import { eventFilterService, FilterResult } from './eventFilterService';

const logger = getLogger('QueueOperations');

/* ---------- Helpers ---------- */

function normalizeEvent(input: unknown): any {
  // 0) Fast path
  if (input && typeof input === 'object' && !Buffer.isBuffer(input)) return input;

  // 1) Buffer → string
  if (Buffer.isBuffer(input)) input = input.toString('utf8');

  // 2) If string, try to parse (handles double-encoding too)
  if (typeof input === 'string') {
    let s = input.trim();

    // Try outer parse first (may yield an object or an inner JSON string)
    try {
      const outer = JSON.parse(s);
      if (typeof outer === 'string') s = outer; // double-encoded; fallthrough to inner parse
      else return outer; // already object
    } catch {
      // keep s as-is and try inner parse below
    }

    // Remove a single trailing quote if braces are already balanced+1 (…}}}" → …}}})
    if (s.endsWith('"')) {
      const open = (s.match(/{/g) || []).length;
      const close = (s.match(/}/g) || []).length;
      if (close > open) s = s.slice(0, -1);
    }

    try {
      return JSON.parse(s);
    } catch (e) {
      const msg = (e as Error).message;
      throw new Error(`Invalid JSON after normalization: ${msg}`);
    }
  }

  // 3) Anything else: return as-is
  return input;
}

function safeStringify(obj: any): string {
  const seen = new WeakSet();
  return JSON.stringify(
    obj,
    (k, v) => {
      if (typeof v === 'bigint') return v.toString();
      if (typeof v === 'function' || typeof v === 'undefined') return undefined;
      if (v && typeof v === 'object') {
        if (seen.has(v)) return '[Circular]';
        seen.add(v);
      }
      return v;
    }
  );
}

/* ---------- Core send ---------- */

export async function sendMessage(queueName: string, message: string): Promise<void> {
  try {
    if (logger.isDebugEnabled()) {
      logger.debug(`[QUEUE OPERATIONS] 📨 COMPLETE MESSAGE TO SEND:`);
      logger.debug(`[QUEUE OPERATIONS] Target Queue: "${queueName}"`);
      logger.debug(`[QUEUE OPERATIONS] Message Length: ${message.length} bytes`);
      logger.debug(`[QUEUE OPERATIONS] Complete Message Content: ${message}`);
      logger.debug(`[QUEUE OPERATIONS] ────────────────────────────────────────────────────────────`);
    }

    const client = await getActiveMqClient();
    const headers = {
      destination: `/queue/${queueName}`,
      'content-type': 'application/json', // JSON over the wire
    };

    if (logger.isDebugEnabled()) {
      logger.debug(`[QUEUE OPERATIONS] 🔧 AMQP Headers: ${JSON.stringify(headers)}`);
      logger.debug(`[QUEUE OPERATIONS] Sending to AMQP client...`);
    }

    const frame = client.send(headers);
    frame.write(message);
    frame.end();

    logger.info(`Message sent to ${queueName}`);

    if (logger.isDebugEnabled()) {
      logger.debug(`[QUEUE OPERATIONS] DELIVERY COMPLETED:`);
      logger.debug(`[QUEUE OPERATIONS] Queue: "${queueName}" | Size: ${message.length} bytes | Status: SUCCESS`);
      logger.debug(`[QUEUE OPERATIONS] Delivery timestamp: ${new Date().toISOString()}`);
      logger.debug(`[QUEUE OPERATIONS] Message successfully written to AMQP connection and frame ended`);
    }
  } catch (error) {
    if (error instanceof Error) {
      logger.error(`Failed to send message to queue: ${error.message}`);
      if (logger.isDebugEnabled()) {
        logger.debug(`[QUEUE OPERATIONS] SEND FAILED:`);
        logger.debug(`[QUEUE OPERATIONS] Queue: "${queueName}" | Message Size: ${message.length} bytes`);
        logger.debug(`[QUEUE OPERATIONS] Error: ${error.message}`);
        logger.debug(`[QUEUE OPERATIONS] Stack: ${error.stack}`);
        logger.debug(`[QUEUE OPERATIONS] Failed Message Content: ${message}`);
      }
    } else {
      const em = safeStringify(error);
      logger.error(`Unexpected error during message sending: ${em}`);
      if (logger.isDebugEnabled()) {
        logger.debug(`[QUEUE OPERATIONS] UNEXPECTED SEND ERROR:`);
        logger.debug(`[QUEUE OPERATIONS] Queue: "${queueName}" | Message Size: ${message.length} bytes`);
        logger.debug(`[QUEUE OPERATIONS] Error: ${em}`);
        logger.debug(`[QUEUE OPERATIONS] Failed Message Content: ${message}`);
      }
    }
    throw error;
  }
}

/* ---------- Filtered send with normalization ---------- */

export async function sendFilteredMessage(queueName: string, freeSwitchEvent: FreeSwitchEventData): Promise<void> {
  try {
    // NEW: normalize first so downstream always sees an object
    const eventObj = normalizeEvent(freeSwitchEvent);

    const eventName = (eventObj as any)?.['Event-Name'] || 'unknown';
    const uniqueId  = (eventObj as any)?.['Unique-ID']  || 'unknown';

    // STAGE 1
    const originalMessage = safeStringify(eventObj);
    if (logger.isDebugEnabled()) {
      const preview = originalMessage.slice(0, 240);
      logger.debug(`[QUEUE OPERATIONS] 📋 STAGE 1 - ORIGINAL MESSAGE (before filtering):`);
      logger.debug(`[QUEUE OPERATIONS] Event: "${eventName}" | Call ID: ${uniqueId} | Queue: "${queueName}"`);
      logger.debug(`[QUEUE OPERATIONS] Size: ${originalMessage.length} bytes`);
      logger.debug(`[QUEUE OPERATIONS] Preview: ${preview}${originalMessage.length > 240 ? '…' : ''}`);
      logger.debug(`[QUEUE OPERATIONS] Complete Original Content: ${originalMessage}`);
      logger.debug(`[QUEUE OPERATIONS] ────────────────────────────────────────────────────────────────`);
    }

    // Filter
    const filterResult: FilterResult = eventFilterService.filterEvent(eventObj);

    // STAGE 2
    const filteredMessage = safeStringify(filterResult.filtered);
    if (logger.isDebugEnabled()) {
      const originalSize = originalMessage.length;
      const filteredSize = filteredMessage.length;
      const reductionPercent = Math.round(((originalSize - filteredSize) / Math.max(originalSize, 1)) * 100);

      logger.debug(`[QUEUE OPERATIONS] STAGE 2 - FILTERED MESSAGE (after filtering):`);
      logger.debug(`[QUEUE OPERATIONS] Filter Results: Original ${originalSize} bytes → Filtered ${filteredSize} bytes (${reductionPercent}% reduction)`);
      logger.debug(`[QUEUE OPERATIONS] ${filterResult.filtered !== eventObj ? 'Event was modified by filtering' : 'Event passed through filter unchanged'}`);
      logger.debug(`[QUEUE OPERATIONS] Complete Filtered Content: ${filteredMessage}`);
      logger.debug(`[QUEUE OPERATIONS] ────────────────────────────────────────────────────────────────`);
    }

    // STAGE 3
    if (logger.isDebugEnabled()) {
      logger.debug(`[QUEUE OPERATIONS] STAGE 3 - SENDING MESSAGE:`);
      logger.debug(`[QUEUE OPERATIONS] Target Queue: "${queueName}"`);
      logger.debug(`[QUEUE OPERATIONS] Message Size: ${filteredMessage.length} bytes`);
      logger.debug(`[QUEUE OPERATIONS] About to send complete message to AMQP...`);
    }

    await sendMessage(queueName, filteredMessage);

    // STAGE 4
    if (logger.isDebugEnabled()) {
      logger.debug(`[QUEUE OPERATIONS] STAGE 4 - DELIVERY CONFIRMED:`);
      logger.debug(`[QUEUE OPERATIONS] Event "${eventName}" (Call ID: ${uniqueId}) successfully delivered to queue "${queueName}"`);
      logger.debug(`[QUEUE OPERATIONS] Final message size: ${filteredMessage.length} bytes`);
      logger.debug(`[QUEUE OPERATIONS] Delivery timestamp: ${new Date().toISOString()}`);
      logger.debug(`[QUEUE OPERATIONS] ================================================================================`);
    }

  } catch (error) {
    if (error instanceof Error) {
      logger.error(`Failed to send filtered message to queue ${queueName}: ${error.message}`);
      if (logger.isDebugEnabled()) {
        logger.debug(`[QUEUE OPERATIONS] Filtered send failed for queue: "${queueName}" | Error: ${error.message}`);
      }
    } else {
      const em = safeStringify(error);
      logger.error(`Unexpected error during filtered message sending: ${em}`);
      if (logger.isDebugEnabled()) {
        logger.debug(`[QUEUE OPERATIONS] Unexpected filtered send error for queue: "${queueName}" | Error: ${em}`);
      }
    }
    throw error;
  }
}

/* ---------- Legacy wrapper ---------- */

export async function sendFreeSwitchEvent(queueName: string, freeSwitchEvent: FreeSwitchEventData): Promise<void> {
  return sendFilteredMessage(queueName, freeSwitchEvent);
}

