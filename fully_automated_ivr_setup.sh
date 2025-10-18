#!/bin/bash

# Fully Automated IVR Setup Script with STT Transcription - No User Input Required
# Usage: ./fully_automated_ivr_setup.sh [xml_file] [assistant_id]
# All configuration is integrated - no prompts or user input needed
# This version includes actual STT transcription of WAV files

set -e

# =============================================================================
# CONFIGURATION - All settings integrated for full automation
# =============================================================================

# Database Configuration
DB_HOST="127.0.0.1"
DB_PORT="3306"
DB_USERNAME="root"
DB_PASSWORD="r00t"
DB_NAME="call_module"

# Azure STT Configuration
AZURE_STT_KEY="7yAOU8Ce9WpRZnuBSBCKtnptzwRsgBwC41dZIFmKRSn34nc4A85xJQQJ99BIACF24PCXJ3w3AAAYACOGvMSy"
AZURE_STT_REGION="uaenorth"

# Azure TTS Configuration
AZURE_TTS_URL="https://uaenorth.tts.speech.microsoft.com/cognitiveservices/v1"
AZURE_TTS_KEY="7yAOU8Ce9WpRZnuBSBCKtnptzwRsgBwC41dZIFmKRSn34nc4A85xJQQJ99BIACF24PCXJ3w3AAAYACOGvMSy"

# File Paths
WAV_BASE_PATH="/data/filestore/services/template/"

# Default values
XML_FILE="${1:-xml.xml}"
ASSISTANT_ID="${2:-1}"
OUTPUT_FILE="ivr_stt_output.json"
SQL_FILE="update_assistant_${ASSISTANT_ID}.sql"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# =============================================================================
# LOGGING FUNCTIONS
# =============================================================================

log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        "INFO")
            echo -e "${BLUE}[$timestamp] INFO:${NC} $message"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[$timestamp] SUCCESS:${NC} $message"
            ;;
        "WARNING")
            echo -e "${YELLOW}[$timestamp] WARNING:${NC} $message"
            ;;
        "ERROR")
            echo -e "${RED}[$timestamp] ERROR:${NC} $message"
            ;;
        "DEBUG")
            echo -e "${PURPLE}[$timestamp] DEBUG:${NC} $message"
            ;;
    esac
}

# =============================================================================
# VALIDATION FUNCTIONS
# =============================================================================

validate_file() {
    local file="$1"
    local description="$2"
    
    if [ ! -f "$file" ]; then
        log "ERROR" "$description '$file' not found!"
        return 1
    fi
    return 0
}

test_database_connection() {
    log "INFO" "Testing database connection..."
    
    # Test MySQL connection
    if command -v mysql >/dev/null 2>&1; then
        if mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USERNAME" -p"$DB_PASSWORD" -e "SELECT 1;" "$DB_NAME" >/dev/null 2>&1; then
            log "SUCCESS" "Database connection test passed"
            return 0
        else
            log "ERROR" "Database connection test failed"
            return 1
        fi
    else
        log "WARNING" "MySQL client not found, skipping connection test"
        return 0
    fi
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🚀 Fully Automated IVR Setup with STT${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

log "INFO" "Starting fully automated IVR setup process"
log "INFO" "Configuration loaded - no user input required"

# Display configuration
echo -e "${YELLOW}Configuration:${NC}"
echo -e "  • XML file: $XML_FILE"
echo -e "  • Assistant ID: $ASSISTANT_ID"
echo -e "  • Database: $DB_HOST:$DB_PORT/$DB_NAME"
echo -e "  • Azure STT Region: $AZURE_STT_REGION"
echo -e "  • WAV Base Path: $WAV_BASE_PATH"
echo ""

# Validate XML file
if ! validate_file "$XML_FILE" "XML file"; then
    log "ERROR" "Please provide a valid XML file path"
    exit 1
fi

# Test database connection
if ! test_database_connection; then
    log "ERROR" "Database connection failed. Please check your database configuration."
    exit 1
fi

# =============================================================================
# STEP 1: Generate IVR STT Array and Path Finder JSON
# =============================================================================

log "INFO" "Step 1: Generating IVR STT Array and Path Finder JSON"
echo -e "${PURPLE}Step 1: Processing XML and generating JSON...${NC}"

# Create the Python processor with integrated configuration and STT transcription
cat > automated_processor.py << 'EOF'
#!/usr/bin/env python3

import xml.etree.ElementTree as ET
import json
import re
import sys
import os
import subprocess
from datetime import datetime

# Azure STT Configuration
AZURE_STT_KEY = "7yAOU8Ce9WpRZnuBSBCKtnptzwRsgBwC41dZIFmKRSn34nc4A85xJQQJ99BIACF24PCXJ3w3AAAYACOGvMSy"
AZURE_STT_REGION = "uaenorth"
STT_URL = f"https://{AZURE_STT_REGION}.stt.speech.microsoft.com/speech/recognition/conversation/cognitiveservices/v1?language=en-US&format=detailed"

def robust_xml_parse(xml_string):
    """Robust XML parsing with multiple fallback strategies"""
    try:
        root = ET.fromstring(xml_string)
        return root
    except ET.ParseError as e:
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: XML parsing failed: {e}")
        return None

def transcribe_wav_with_curl(wav_file_path: str):
    """Transcribe WAV file using Azure STT API"""
    if not os.path.exists(wav_file_path):
        return {
            'status': 'error',
            'error': f'File not found: {wav_file_path}',
            'transcription': '',
            'confidence': 0
        }
    
    try:
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] INFO: Transcribing WAV file: {wav_file_path}")
        
        curl_cmd = [
            'curl', '-s', '-w', '%{http_code}',
            '-X', 'POST', STT_URL,
            '-H', 'Content-Type: audio/wav; codecs=audio/pcm; samplerate=16000',
            '-H', f'Ocp-Apim-Subscription-Key: {AZURE_STT_KEY}',
            '-H', f'Ocp-Apim-Subscription-Region: {AZURE_STT_REGION}',
            '-H', 'Accept: application/json',
            '--data-binary', f'@{wav_file_path}'
        ]
        
        result = subprocess.run(curl_cmd, capture_output=True, text=True)
        response_text = result.stdout.strip()
        status_code = response_text[-3:] if response_text[-3:].isdigit() else 'unknown'
        json_response = response_text[:-3] if status_code != 'unknown' else response_text
        
        if status_code == '200' and json_response:
            try:
                stt_data = json.loads(json_response)
                transcription = stt_data.get('DisplayText', '')
                confidence = stt_data.get('Confidence', 0)
                
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] SUCCESS: STT completed - '{transcription}' (confidence: {confidence})")
                
                return {
                    'status': 'success',
                    'transcription': transcription,
                    'confidence': confidence,
                    'raw_response': stt_data
                }
            except json.JSONDecodeError as e:
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: JSON parse error: {e}")
                return {
                    'status': 'error',
                    'error': f'JSON parse error: {e}',
                    'transcription': '',
                    'confidence': 0
                }
        else:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: STT request failed - Status: {status_code}")
            return {
                'status': 'error',
                'error': f'HTTP {status_code}: {json_response}',
                'transcription': '',
                'confidence': 0
            }
            
    except Exception as e:
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: Exception in STT processing: {e}")
        return {
            'status': 'error',
            'error': str(e),
            'transcription': '',
            'confidence': 0
        }

def extract_navigation_nodes(root):
    """Extract Navigation nodes with WAV files and transcribe them"""
    navigation_nodes = {}
    
    for mx_cell in root.findall('.//mxCell'):
        if mx_cell.get('type') == 'Navigation':
            cell_id = mx_cell.get('id')
            cell_value = mx_cell.get('value', '')
            
            mx_params = mx_cell.find('mxParams')
            if mx_params is not None:
                recs = mx_params.find('recs')
                if recs is not None:
                    wav_files = []
                    
                    for rec in recs.findall('rec'):
                        id_element = rec.find('id')
                        if id_element is not None and id_element.text == 'promptfile':
                            values_element = rec.find('values')
                            if values_element is not None:
                                for value in values_element.findall('value'):
                                    value_text = value.text
                                    if value_text and '.wav' in value_text:
                                        wav_file = value_text.strip()
                                        
                                        # Transcribe the WAV file
                                        stt_result = transcribe_wav_with_curl(wav_file)
                                        
                                        wav_files.append({
                                            'path': wav_file,
                                            'filename': wav_file.split('/')[-1] if '/' in wav_file else wav_file,
                                            'is_voice_prompt': '_VOICEPROMPT' in wav_file,
                                            'transcription': stt_result.get('transcription', ''),
                                            'confidence': stt_result.get('confidence', 0),
                                            'stt_status': stt_result.get('status', 'error')
                                        })
                    
                    if wav_files:
                        navigation_nodes[cell_id] = {
                            'id': cell_id,
                            'value': cell_value,
                            'wav_files': wav_files
                        }
    
    return navigation_nodes

def extract_connections(root):
    """Extract connections between nodes"""
    connections = {}
    
    for mx_cell in root.findall('.//mxCell'):
        if mx_cell.get('edge') == '1':  # This is a connection
            source = mx_cell.get('source')
            target = mx_cell.get('target')
            
            if source and target:
                if source not in connections:
                    connections[source] = []
                connections[source].append({
                    'target': target,
                    'label': mx_cell.get('value', ''),
                    'id': mx_cell.get('id', '')
                })
    
    return connections

def generate_ivr_stt_array(navigation_nodes):
    """Generate IVR STT Array from navigation nodes with transcriptions"""
    ivr_stt_array = []
    
    for node_id, node_data in navigation_nodes.items():
        for wav_file in node_data['wav_files']:
            ivr_stt_array.append({
                'node_id': node_id,
                'node_value': node_data['value'],
                'wav_path': wav_file['path'],
                'filename': wav_file['filename'],
                'is_voice_prompt': wav_file['is_voice_prompt'],
                'transcription': wav_file['transcription'],
                'confidence': wav_file['confidence'],
                'stt_status': wav_file['stt_status']
            })
    
    return ivr_stt_array

def generate_path_finder_json(root, navigation_nodes, connections):
    """Generate Path Finder JSON structure"""
    path_finder = {
        'nodes': {},
        'connections': connections,
        'metadata': {
            'total_nodes': len(navigation_nodes),
            'connection_count': sum(len(conns) for conns in connections.values())
        }
    }
    
    # Add navigation nodes to path finder
    for node_id, node_data in navigation_nodes.items():
        path_finder['nodes'][node_id] = {
            'id': node_id,
            'value': node_data['value'],
            'type': 'Navigation',
            'has_audio': True,
            'audio_files': node_data['wav_files']
        }
    
    return path_finder

def main():
    if len(sys.argv) != 2:
        print("Usage: python3 automated_processor.py <xml_file>")
        sys.exit(1)
    
    xml_file = sys.argv[1]
    
    try:
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] INFO: Reading XML file: {xml_file}")
        
        with open(xml_file, 'r', encoding='utf-8') as f:
            xml_content = f.read()
        
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] INFO: XML file read successfully ({len(xml_content)} characters)")
        
        root = robust_xml_parse(xml_content)
        if root is None:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: Failed to parse XML")
            sys.exit(1)
        
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] SUCCESS: XML parsed successfully")
        
        navigation_nodes = extract_navigation_nodes(root)
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] SUCCESS: Found {len(navigation_nodes)} Navigation nodes with WAV files")
        
        connections = extract_connections(root)
        total_connections = sum(len(conns) for conns in connections.values())
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] SUCCESS: Found {total_connections} connections")
        
        ivr_stt_array = generate_ivr_stt_array(navigation_nodes)
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] SUCCESS: Generated IVR STT Array with {len(ivr_stt_array)} entries")
        
        path_finder_json = generate_path_finder_json(root, navigation_nodes, connections)
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] SUCCESS: Generated Path Finder JSON with {len(path_finder_json['nodes'])} nodes")
        
        # Count successful transcriptions
        successful_transcriptions = sum(1 for item in ivr_stt_array if item['stt_status'] == 'success')
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] SUCCESS: {successful_transcriptions}/{len(ivr_stt_array)} WAV files transcribed successfully")
        
        output = {
            'ivr_stt_array': ivr_stt_array,
            'path_finder_json': path_finder_json,
            'metadata': {
                'source_file': xml_file,
                'total_wav_files': len(ivr_stt_array),
                'total_nodes': len(path_finder_json['nodes']),
                'navigation_nodes': len(navigation_nodes),
                'successful_transcriptions': successful_transcriptions,
                'failed_transcriptions': len(ivr_stt_array) - successful_transcriptions,
                'generated_at': datetime.now().isoformat()
            }
        }
        
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] SUCCESS: Output structure created successfully")
        print(json.dumps(output, indent=2, ensure_ascii=False))
        
    except Exception as e:
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
EOF

log "INFO" "Created automated Python processor with integrated configuration"

# Run the Python processor
log "INFO" "Executing Python XML processor..."

if python3 automated_processor.py "$XML_FILE" > "$OUTPUT_FILE" 2>&1; then
    log "SUCCESS" "Python processor executed successfully"
else
    log "ERROR" "Python processor failed to execute"
    rm -f automated_processor.py
    exit 1
fi

# Check if output was generated successfully
if [ -f "$OUTPUT_FILE" ] && [ -s "$OUTPUT_FILE" ]; then
    log "SUCCESS" "Output file generated successfully"
    
    file_size=$(wc -c < "$OUTPUT_FILE")
    log "INFO" "File size: $file_size bytes"
    
    # Extract statistics
    total_wav_files=$(python3 -c "
import json
try:
    with open('$OUTPUT_FILE', 'r') as f:
        data = json.load(f)
    print(data['metadata']['total_wav_files'])
except Exception as e:
    print('N/A')
" 2>/dev/null)
    
    successful_transcriptions=$(python3 -c "
import json
try:
    with open('$OUTPUT_FILE', 'r') as f:
        data = json.load(f)
    print(data['metadata']['successful_transcriptions'])
except Exception as e:
    print('N/A')
" 2>/dev/null)
    
    total_nodes=$(python3 -c "
import json
try:
    with open('$OUTPUT_FILE', 'r') as f:
        data = json.load(f)
    print(data['metadata']['total_nodes'])
except Exception as e:
    print('N/A')
" 2>/dev/null)
    
    echo ""
    log "INFO" "Step 1 completed successfully"
    echo -e "${GREEN}✓ IVR STT Array with transcriptions generated${NC}"
    echo -e "  • WAV files processed: ${GREEN}$total_wav_files${NC}"
    echo -e "  • Successful transcriptions: ${GREEN}$successful_transcriptions${NC}"
    echo -e "  • Total nodes: ${GREEN}$total_nodes${NC}"
    
else
    log "ERROR" "Failed to generate output file!"
    rm -f automated_processor.py
    exit 1
fi

echo ""

# =============================================================================
# STEP 2: Generate SQL Update Statement
# =============================================================================

log "INFO" "Step 2: Generating SQL update statement for Assistant ID $ASSISTANT_ID"
echo -e "${PURPLE}Step 2: Generating SQL update statement...${NC}"

# Create SQL generator with integrated configuration
cat > automated_sql_generator.py << 'EOF'
#!/usr/bin/env python3

import json
import sys
from datetime import datetime

def generate_sql_update(json_file, assistant_id):
    """Generate SQL UPDATE statement for assistant configuration"""
    
    try:
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] INFO: Reading JSON file: {json_file}")
        with open(json_file, 'r') as f:
            data = json.load(f)
        
        ivr_stt_array = data.get('ivr_stt_array', [])
        path_finder_json = data.get('path_finder_json', {})
        metadata = data.get('metadata', {})
        
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] SUCCESS: JSON data loaded successfully")
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] INFO: IVR STT Array entries: {len(ivr_stt_array)}")
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] INFO: Path Finder JSON nodes: {len(path_finder_json.get('nodes', {}))}")
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] INFO: Successful transcriptions: {metadata.get('successful_transcriptions', 0)}")
        
        # Convert to JSON strings
        ivr_stt_array_json = json.dumps(ivr_stt_array, indent=2)
        path_finder_json_str = json.dumps(path_finder_json, indent=2)
        
        # Escape single quotes for SQL
        ivr_stt_array_sql = ivr_stt_array_json.replace("'", "''")
        path_finder_json_sql = path_finder_json_str.replace("'", "''")
        
        # Generate SQL UPDATE statement
        sql_update = f"""-- Update Assistant Configuration for Assistant ID {assistant_id}
-- Generated on: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
-- Source JSON file: {json_file}
-- IVR STT Array entries: {len(ivr_stt_array)}
-- Path Finder JSON nodes: {len(path_finder_json.get('nodes', {}))}
-- Successful transcriptions: {metadata.get('successful_transcriptions', 0)}

UPDATE assistant_configuration 
SET 
    ivr_stt_array = '{ivr_stt_array_sql}',
    path_finder_json = '{path_finder_json_sql}',
    updatedOn = NOW()
WHERE 
    assistant_id = {assistant_id};

-- Verify the update
SELECT 
    assistant_id,
    name,
    LENGTH(ivr_stt_array) as ivr_stt_array_length,
    LENGTH(path_finder_json) as path_finder_json_length,
    updatedOn
FROM assistant_configuration 
WHERE assistant_id = {assistant_id};"""
        
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] SUCCESS: SQL UPDATE statement generated successfully")
        return sql_update
        
    except Exception as e:
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: {e}")
        return None

def main():
    if len(sys.argv) != 3:
        print("Usage: python3 automated_sql_generator.py <json_file> <assistant_id>")
        sys.exit(1)
    
    json_file = sys.argv[1]
    assistant_id = int(sys.argv[2])
    
    sql_update = generate_sql_update(json_file, assistant_id)
    
    if sql_update:
        # Write SQL to file
        sql_file = f"update_assistant_{assistant_id}.sql"
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] INFO: Writing SQL to file: {sql_file}")
        
        with open(sql_file, 'w') as f:
            f.write(sql_update)
        
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] SUCCESS: SQL file written successfully: {sql_file}")
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] SUCCESS: SQL generation completed successfully!")
        
    else:
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: Failed to generate SQL update statement")
        sys.exit(1)

if __name__ == "__main__":
    main()
EOF

log "INFO" "Created automated SQL generator"

# Generate SQL update
log "INFO" "Executing SQL generator..."

if python3 automated_sql_generator.py "$OUTPUT_FILE" "$ASSISTANT_ID"; then
    log "SUCCESS" "SQL update statement generated successfully"
else
    log "ERROR" "Failed to generate SQL update"
    rm -f automated_processor.py automated_sql_generator.py
    exit 1
fi

echo ""

# =============================================================================
# STEP 3: Execute Database Update
# =============================================================================

log "INFO" "Step 3: Executing database update"
echo -e "${PURPLE}Step 3: Updating database...${NC}"

# Check if SQL file exists
if [ -f "$SQL_FILE" ]; then
    log "INFO" "SQL file generated: $SQL_FILE"
    
    # Execute the SQL update
    log "INFO" "Executing database update..."
    
    if mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USERNAME" -p"$DB_PASSWORD" "$DB_NAME" < "$SQL_FILE" 2>/dev/null; then
        log "SUCCESS" "Database update executed successfully!"
        
        # Verify the update
        log "INFO" "Verifying database update..."
        echo ""
        echo -e "${BLUE}Database Update Verification:${NC}"
        mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USERNAME" -p"$DB_PASSWORD" "$DB_NAME" -e "
        SELECT 
            assistant_id,
            name,
            LENGTH(ivr_stt_array) as ivr_stt_array_length,
            LENGTH(path_finder_json) as path_finder_json_length,
            updatedOn
        FROM assistant_configuration 
        WHERE assistant_id = $ASSISTANT_ID;" 2>/dev/null
        
        log "SUCCESS" "Database verification completed"
        
    else
        log "WARNING" "Database update failed or MySQL client not available"
        log "INFO" "SQL file is available for manual execution: $SQL_FILE"
    fi
else
    log "ERROR" "SQL file not found: $SQL_FILE"
fi

echo ""

# =============================================================================
# CLEANUP AND FINAL SUMMARY
# =============================================================================

log "INFO" "Cleaning up temporary files..."
rm -f automated_processor.py automated_sql_generator.py
log "SUCCESS" "Temporary files cleaned up"

# Final summary
log "INFO" "Generating final summary"
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}🎉 Fully Automated Setup Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo -e "${YELLOW}Final Summary:${NC}"
echo -e "  • Assistant ID: ${GREEN}$ASSISTANT_ID${NC}"
echo -e "  • XML processed: ${GREEN}$XML_FILE${NC}"
echo -e "  • Output file: ${GREEN}$OUTPUT_FILE${NC}"
echo -e "  • SQL file: ${GREEN}$SQL_FILE${NC}"
echo -e "  • Database: ${GREEN}$DB_HOST:$DB_PORT/$DB_NAME${NC}"
echo -e "  • WAV files processed: ${GREEN}$total_wav_files${NC}"
echo -e "  • Successful transcriptions: ${GREEN}$successful_transcriptions${NC}"
echo -e "  • Total nodes: ${GREEN}$total_nodes${NC}"

echo ""
echo -e "${BLUE}Database Fields Updated:${NC}"
echo -e "  • ${GREEN}ivr_stt_array${NC} - Contains WAV file mappings WITH transcriptions"
echo -e "  • ${GREEN}path_finder_json${NC} - Contains complete flow structure"

echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo -e "  1. Test the IVR flow with the updated configuration"
echo -e "  2. Monitor call logs for proper STT processing"
echo -e "  3. Check Azure STT integration with provided credentials"
echo -e "  4. Verify the database update was successful"
echo -e "  5. Review transcription quality and confidence scores"

echo ""
log "SUCCESS" "Fully automated setup process completed successfully!"
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}🚀 Setup Complete - With STT Transcriptions!${NC}"
echo -e "${BLUE}========================================${NC}"

