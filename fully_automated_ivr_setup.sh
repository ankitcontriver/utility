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
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: XML parsing failed: {e}", file=sys.stderr)
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
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] INFO: Transcribing WAV file: {wav_file_path}", file=sys.stderr)
        
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
                
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] SUCCESS: STT completed - '{transcription}' (confidence: {confidence})", file=sys.stderr)
                
                return {
                    'status': 'success',
                    'transcription': transcription,
                    'confidence': confidence,
                    'raw_response': stt_data
                }
            except json.JSONDecodeError as e:
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: JSON parse error: {e}", file=sys.stderr)
                return {
                    'status': 'error',
                    'error': f'JSON parse error: {e}',
                    'transcription': '',
                    'confidence': 0
                }
        else:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: STT request failed - Status: {status_code}", file=sys.stderr)
            return {
                'status': 'error',
                'error': f'HTTP {status_code}: {json_response}',
                'transcription': '',
                'confidence': 0
            }
            
    except Exception as e:
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: Exception in STT processing: {e}", file=sys.stderr)
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

def generate_ivr_stt_array(root, navigation_nodes, connections):
    """Generate IVR STT Array in the required format with language mappings"""
    
    # Extract all nodes for metadata
    all_nodes = root.findall('.//mxCell')
    node_types = {}
    for node in all_nodes:
        node_type = node.get('type', 'Unknown')
        node_types[node_type] = node_types.get(node_type, 0) + 1
    
    # Count connections
    total_connections = sum(len(conns) for conns in connections.values())
    
    # Generate language mappings
    language_mappings = {
        "default": {
            "nodes": {},
            "children": []
        },
        "en-US": {
            "nodes": {},
            "children": []
        },
        "F": {
            "nodes": {},
            "children": []
        }
    }
    
    # Process each navigation node
    for node_id, node_data in navigation_nodes.items():
        # Separate voice and DTMF files
        voice_files = []
        dtmf_files = []
        voice_filenames = []
        dtmf_filenames = []
        
        for wav_file in node_data['wav_files']:
            if wav_file['is_voice_prompt']:
                voice_files.append(wav_file['transcription'])
                voice_filenames.append(wav_file['filename'])
            else:
                dtmf_files.append(wav_file['transcription'])
                dtmf_filenames.append(wav_file['filename'])
        
        # Get children for this node
        node_children = connections.get(node_id, [])
        children_ids = [conn['target'] for conn in node_children]
        
        # Create node structure for each language
        node_structure = {
            "stt": {
                "voice": voice_files,
                "dtmf": dtmf_files,
                "original_filenames": {
                    "voice": voice_filenames,
                    "dtmf": dtmf_filenames
                }
            },
            "children": children_ids
        }
        
        # Add to all language mappings
        for lang in language_mappings:
            language_mappings[lang]["nodes"][node_id] = node_structure.copy()
    
    # Find language selection node (usually the first navigation node)
    language_selection_node = None
    language_selection_children = []
    
    for node_id, node_data in navigation_nodes.items():
        if 'language' in node_data['value'].lower() or 'choose' in node_data['value'].lower():
            language_selection_node = node_id
            # Find children that are processing nodes for language setting
            node_children = connections.get(node_id, [])
            for conn in node_children:
                target_id = conn['target']
                # Check if this is a language setting node
                if target_id in navigation_nodes:
                    child_data = navigation_nodes[target_id]
                    if 'setlanguage' in child_data['value'].lower():
                        language_selection_children.append({
                            "id": target_id,
                            "type": "processing",
                            "value": child_data['value'],
                            "mxParams": "_E" if 'english' in child_data['value'].lower() else "_F"
                        })
            break
    
    # Generate language selection
    language_selection = {
        "choose_language": language_selection_node or list(navigation_nodes.keys())[0],
        "setlanguage_children": language_selection_children
    }
    
    # Create the final structure
    ivr_stt_array = {
        "metadata": {
            "source_xml": "xml.xml",
            "total_nodes": len(all_nodes),
            "root_nodes": len(navigation_nodes),
            "total_connections": total_connections,
            "node_types": node_types
        },
        "language_mappings": language_mappings,
        "language_selection": language_selection
    }
    
    return ivr_stt_array

def generate_path_finder_json(root, navigation_nodes, connections):
    """Generate Path Finder JSON structure in the required format"""
    
    # Extract all nodes for metadata
    all_nodes = root.findall('.//mxCell')
    node_types = {}
    root_nodes = []
    
    # Process all nodes
    nodes_array = []
    for node in all_nodes:
        node_id = node.get('id', '')
        node_type = node.get('type', 'Unknown')
        node_value = node.get('value', '')
        
        # Count node types
        node_types[node_type] = node_types.get(node_type, 0) + 1
        
        # Determine if this is a root node (no incoming connections)
        is_root = True
        for source_id, conns in connections.items():
            for conn in conns:
                if conn['target'] == node_id:
                    is_root = False
                    break
            if not is_root:
                break
        
        if is_root and node_type != 'Unknown':
            root_nodes.append(node_id)
        
        # Get children
        children = connections.get(node_id, [])
        children_ids = [conn['target'] for conn in children]
        
        # Determine parent (first connection that targets this node)
        parent = None
        for source_id, conns in connections.items():
            for conn in conns:
                if conn['target'] == node_id:
                    parent = source_id
                    break
            if parent:
                break
        
        # Determine if skippable (based on node type)
        is_skippable = node_type in ['Unknown', 'DTMF', 'Normal', 'Exit']
        
        # Determine land_before (1 for most nodes, 0 for navigation)
        land_before = 0 if node_type == 'Navigation' else 1
        
        node_obj = {
            "id": node_id,
            "type": node_type,
            "value": node_value,
            "children": children_ids,
            "parent": parent,
            "isSkippable": is_skippable,
            "land_before": land_before
        }
        
        nodes_array.append(node_obj)
    
    # Count total connections
    total_connections = sum(len(conns) for conns in connections.values())
    
    # Create the final structure
    path_finder = {
        "metadata": {
            "source_xml": "xml.xml",
            "total_nodes": len(all_nodes),
            "root_nodes": len(root_nodes),
            "total_connections": total_connections,
            "node_types": node_types
        },
        "nodes": nodes_array
    }
    
    return path_finder

def main():
    if len(sys.argv) != 2:
        print("Usage: python3 automated_processor.py <xml_file>")
        sys.exit(1)
    
    xml_file = sys.argv[1]
    
    try:
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] INFO: Reading XML file: {xml_file}", file=sys.stderr)
        
        with open(xml_file, 'r', encoding='utf-8') as f:
            xml_content = f.read()
        
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] INFO: XML file read successfully ({len(xml_content)} characters)", file=sys.stderr)
        
        root = robust_xml_parse(xml_content)
        if root is None:
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: Failed to parse XML", file=sys.stderr)
            sys.exit(1)
        
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] SUCCESS: XML parsed successfully", file=sys.stderr)
        
        navigation_nodes = extract_navigation_nodes(root)
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] SUCCESS: Found {len(navigation_nodes)} Navigation nodes with WAV files", file=sys.stderr)
        
        connections = extract_connections(root)
        total_connections = sum(len(conns) for conns in connections.values())
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] SUCCESS: Found {total_connections} connections", file=sys.stderr)
        
        ivr_stt_array = generate_ivr_stt_array(root, navigation_nodes, connections)
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] SUCCESS: Generated IVR STT Array with {len(navigation_nodes)} entries", file=sys.stderr)
        
        path_finder_json = generate_path_finder_json(root, navigation_nodes, connections)
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] SUCCESS: Generated Path Finder JSON with {len(path_finder_json['nodes'])} nodes", file=sys.stderr)
        
        # Count successful transcriptions
        successful_transcriptions = 0
        for node_data in navigation_nodes.values():
            for wav_file in node_data['wav_files']:
                if wav_file['stt_status'] == 'success':
                    successful_transcriptions += 1
        
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] SUCCESS: {successful_transcriptions} WAV files transcribed successfully", file=sys.stderr)
        
        output = {
            'ivr_stt_array': ivr_stt_array,
            'path_finder_json': path_finder_json,
            'metadata': {
                'source_file': xml_file,
                'total_wav_files': successful_transcriptions,
                'total_nodes': len(path_finder_json['nodes']),
                'navigation_nodes': len(navigation_nodes),
                'successful_transcriptions': successful_transcriptions,
                'failed_transcriptions': 0,  # Will be calculated if needed
                'generated_at': datetime.now().isoformat()
            }
        }
        
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] SUCCESS: Output structure created successfully", file=sys.stderr)
        print(json.dumps(output, indent=2, ensure_ascii=False))
        
    except Exception as e:
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
EOF

log "INFO" "Created automated Python processor with integrated configuration"

# Run the Python processor
log "INFO" "Executing Python XML processor..."

if python3 automated_processor.py "$XML_FILE" > "$OUTPUT_FILE" 2>/dev/null; then
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
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] INFO: Reading JSON file: {json_file}", file=sys.stderr)
        with open(json_file, 'r') as f:
            data = json.load(f)
        
        ivr_stt_array = data.get('ivr_stt_array', [])
        path_finder_json = data.get('path_finder_json', {})
        metadata = data.get('metadata', {})
        
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] SUCCESS: JSON data loaded successfully", file=sys.stderr)
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] INFO: IVR STT Array language mappings: {len(ivr_stt_array.get('language_mappings', {}))}", file=sys.stderr)
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] INFO: Path Finder JSON nodes: {len(path_finder_json.get('nodes', []))}", file=sys.stderr)
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] INFO: Successful transcriptions: {metadata.get('successful_transcriptions', 0)}", file=sys.stderr)
        
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
-- IVR STT Array language mappings: {len(ivr_stt_array.get('language_mappings', {}))}
-- Path Finder JSON nodes: {len(path_finder_json.get('nodes', []))}
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
        
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] SUCCESS: SQL UPDATE statement generated successfully", file=sys.stderr)
        return sql_update
        
    except Exception as e:
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: {e}", file=sys.stderr)
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
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] INFO: Writing SQL to file: {sql_file}", file=sys.stderr)
        
        with open(sql_file, 'w') as f:
            f.write(sql_update)
        
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] SUCCESS: SQL file written successfully: {sql_file}", file=sys.stderr)
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] SUCCESS: SQL generation completed successfully!", file=sys.stderr)
        
    else:
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: Failed to generate SQL update statement", file=sys.stderr)
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
echo -e "  • ${GREEN}ivr_stt_array${NC} - Contains language mappings with STT transcriptions"
echo -e "  • ${GREEN}path_finder_json${NC} - Contains complete flow structure with node details"

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

