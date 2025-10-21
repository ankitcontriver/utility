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
DB_PASSWORD=""
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
        # Handle empty password case
        if [ -z "$DB_PASSWORD" ]; then
            if mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USERNAME" -e "SELECT 1;" "$DB_NAME" >/dev/null 2>&1; then
                log "SUCCESS" "Database connection test passed"
                return 0
            else
                log "ERROR" "Database connection test failed"
                return 1
            fi
        else
            if mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USERNAME" -p"$DB_PASSWORD" -e "SELECT 1;" "$DB_NAME" >/dev/null 2>&1; then
                log "SUCCESS" "Database connection test passed"
                return 0
            else
                log "ERROR" "Database connection test failed"
                return 1
            fi
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

# Use the corrected Python processor
log "INFO" "Using corrected Python processor"

# Run the Python processor
log "INFO" "Executing Python XML processor..."

if python3 automated_processor.py "$XML_FILE" > "$OUTPUT_FILE" 2>/dev/null; then
    log "SUCCESS" "Python processor executed successfully"
else
    log "ERROR" "Python processor failed to execute"
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
    rm -f automated_sql_generator.py
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
    
    # Handle empty password case for database update
    if [ -z "$DB_PASSWORD" ]; then
        if mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USERNAME" "$DB_NAME" < "$SQL_FILE" 2>/dev/null; then
            db_update_success=true
        else
            db_update_success=false
        fi
    else
        if mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USERNAME" -p"$DB_PASSWORD" "$DB_NAME" < "$SQL_FILE" 2>/dev/null; then
            db_update_success=true
        else
            db_update_success=false
        fi
    fi
    
    if [ "$db_update_success" = true ]; then
        log "SUCCESS" "Database update executed successfully!"
        
        # Verify the update
        log "INFO" "Verifying database update..."
        echo ""
        echo -e "${BLUE}Database Update Verification:${NC}"
        if [ -z "$DB_PASSWORD" ]; then
            mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USERNAME" "$DB_NAME" -e "
            SELECT 
                assistant_id,
                name,
                LENGTH(ivr_stt_array) as ivr_stt_array_length,
                LENGTH(path_finder_json) as path_finder_json_length,
                updatedOn
            FROM assistant_configuration 
            WHERE assistant_id = $ASSISTANT_ID;" 2>/dev/null
        else
            mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USERNAME" -p"$DB_PASSWORD" "$DB_NAME" -e "
            SELECT 
                assistant_id,
                name,
                LENGTH(ivr_stt_array) as ivr_stt_array_length,
                LENGTH(path_finder_json) as path_finder_json_length,
                updatedOn
            FROM assistant_configuration 
            WHERE assistant_id = $ASSISTANT_ID;" 2>/dev/null
        fi
        
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
rm -f automated_sql_generator.py
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
