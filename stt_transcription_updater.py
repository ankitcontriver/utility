#!/usr/bin/env python3

import json
import os
import subprocess
import sys
from datetime import datetime
import tempfile
import shutil

# Azure STT Configuration
AZURE_STT_KEY = "7yAOU8Ce9WpRZnuBSBCKtnptzwRsgBwC41dZIFmKRSn34nc4A85xJQQJ99BIACF24PCXJ3w3AAAYACOGvMSy"
AZURE_STT_REGION = "uaenorth"
STT_URL = f"https://{AZURE_STT_REGION}.stt.speech.microsoft.com/speech/recognition/conversation/cognitiveservices/v1?language=en-US&format=detailed"

def log(level, message):
    """Log with timestamp"""
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    print(f"[{timestamp}] {level}: {message}", file=sys.stderr)

def transcribe_wav_file(wav_file_path):
    """Transcribe a single WAV file using Azure STT API"""
    log("INFO", f"Transcribing WAV file: {wav_file_path}")
    
    try:
        # Check if file exists
        if not os.path.exists(wav_file_path):
            log("ERROR", f"WAV file not found: {wav_file_path}")
            return {
                'status': 'error',
                'transcription': '',
                'confidence': 0,
                'error': f'File not found: {wav_file_path}'
            }
        
        file_size = os.path.getsize(wav_file_path)
        log("DEBUG", f"File size: {file_size} bytes")
        
        # Perform STT transcription
        curl_cmd = [
            'curl', '-s', '-w', '%{http_code}',
            '-X', 'POST', STT_URL,
            '-H', 'Content-Type: audio/wav; codecs=audio/pcm; samplerate=16000',
            '-H', f'Ocp-Apim-Subscription-Key: {AZURE_STT_KEY}',
            '-H', f'Ocp-Apim-Subscription-Region: {AZURE_STT_REGION}',
            '-H', 'Accept: application/json',
            '--data-binary', f'@{wav_file_path}'
        ]
        
        log("DEBUG", "Executing STT request...")
        result = subprocess.run(curl_cmd, capture_output=True, text=True, timeout=60)
        
        log("DEBUG", f"Curl return code: {result.returncode}")
        if result.stderr:
            log("DEBUG", f"Curl stderr: {result.stderr}")
        
        response_text = result.stdout.strip()
        status_code = response_text[-3:] if response_text[-3:].isdigit() else 'unknown'
        json_response = response_text[:-3] if status_code != 'unknown' else response_text
        
        log("DEBUG", f"Status code: {status_code}")
        
        if status_code == '200' and json_response:
            try:
                stt_data = json.loads(json_response)
                transcription = stt_data.get('DisplayText', '')
                confidence = stt_data.get('Confidence', 0)
                
                if transcription:
                    log("SUCCESS", f"STT completed - '{transcription}' (confidence: {confidence})")
                    return {
                        'status': 'success',
                        'transcription': transcription,
                        'confidence': confidence,
                        'raw_response': stt_data
                    }
                else:
                    log("WARNING", "Empty transcription received")
                    return {
                        'status': 'error',
                        'transcription': '',
                        'confidence': 0,
                        'error': 'Empty transcription from Azure STT'
                    }
            except json.JSONDecodeError as e:
                log("ERROR", f"JSON parse error: {e}")
                return {
                    'status': 'error',
                    'transcription': '',
                    'confidence': 0,
                    'error': f'JSON parse error: {e}'
                }
        else:
            log("ERROR", f"STT request failed - Status: {status_code}")
            log("DEBUG", f"Response: {response_text}")
            return {
                'status': 'error',
                'transcription': '',
                'confidence': 0,
                'error': f'HTTP {status_code}: {json_response}'
            }
            
    except subprocess.TimeoutExpired:
        log("ERROR", "STT request timeout")
        return {
            'status': 'error',
            'transcription': '',
            'confidence': 0,
            'error': 'Request timeout'
        }
    except Exception as e:
        log("ERROR", f"Exception in STT processing: {e}")
        return {
            'status': 'error',
            'transcription': '',
            'confidence': 0,
            'error': str(e)
        }

def clean_filename(filename):
    """Remove number prefix from filename (e.g., '3316-filename.wav' -> 'filename.wav')"""
    if '-' in filename and filename[0].isdigit():
        # Find the first dash and remove everything before it
        dash_index = filename.find('-')
        if dash_index > 0:
            return filename[dash_index + 1:]
    return filename

def collect_wav_files_from_json(json_file):
    """Collect all WAV file paths from the JSON file"""
    log("INFO", f"Reading JSON file: {json_file}")
    
    try:
        with open(json_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        wav_files = []
        ivr_stt_array = data.get('ivr_stt_array', {})
        language_mappings = ivr_stt_array.get('language_mappings', {})
        
        # Collect WAV files from all language mappings
        for lang, lang_data in language_mappings.items():
            nodes = lang_data.get('nodes', {})
            for node_id, node_data in nodes.items():
                stt_data = node_data.get('stt', {})
                original_filenames = stt_data.get('original_filenames', {})
                
                # Collect voice files
                for filename in original_filenames.get('voice', []):
                    # Filename is already clean and complete path
                    wav_files.append({
                        'path': filename,
                        'filename': filename.split('/')[-1] if '/' in filename else filename,
                        'original_filename': filename,
                        'type': 'voice',
                        'node_id': node_id,
                        'language': lang
                    })
                
                # Collect DTMF files
                for filename in original_filenames.get('dtmf', []):
                    # Filename is already clean and complete path
                    wav_files.append({
                        'path': filename,
                        'filename': filename.split('/')[-1] if '/' in filename else filename,
                        'original_filename': filename,
                        'type': 'dtmf',
                        'node_id': node_id,
                        'language': lang
                    })
        
        # Remove duplicates based on path
        unique_wav_files = []
        seen_paths = set()
        for wav_file in wav_files:
            if wav_file['path'] not in seen_paths:
                unique_wav_files.append(wav_file)
                seen_paths.add(wav_file['path'])
        
        log("SUCCESS", f"Found {len(unique_wav_files)} unique WAV files")
        log("DEBUG", f"Sample cleaned filenames:")
        for wav_file in unique_wav_files[:3]:  # Show first 3 as examples
            log("DEBUG", f"  Original: {wav_file['original_filename']} -> Clean: {wav_file['filename']}")
        
        return unique_wav_files, data
        
    except Exception as e:
        log("ERROR", f"Failed to read JSON file: {e}")
        return [], None

def update_json_with_transcriptions(data, transcription_results):
    """Update the JSON data with transcription results"""
    log("INFO", "Updating JSON with transcription results")
    
    ivr_stt_array = data.get('ivr_stt_array', {})
    language_mappings = ivr_stt_array.get('language_mappings', {})
    
    successful_transcriptions = 0
    failed_transcriptions = 0
    
    # Update transcriptions in all language mappings
    for lang, lang_data in language_mappings.items():
        nodes = lang_data.get('nodes', {})
        for node_id, node_data in nodes.items():
            stt_data = node_data.get('stt', {})
            
            # Update voice transcriptions
            voice_transcriptions = []
            for filename in stt_data.get('original_filenames', {}).get('voice', []):
                # Filename is already clean and complete path
                if filename in transcription_results:
                    result = transcription_results[filename]
                    if result['status'] == 'success':
                        voice_transcriptions.append(result['transcription'])
                        successful_transcriptions += 1
                    else:
                        voice_transcriptions.append('')
                        failed_transcriptions += 1
                else:
                    voice_transcriptions.append('')
                    failed_transcriptions += 1
            
            # Update DTMF transcriptions
            dtmf_transcriptions = []
            for filename in stt_data.get('original_filenames', {}).get('dtmf', []):
                # Filename is already clean and complete path
                if filename in transcription_results:
                    result = transcription_results[filename]
                    if result['status'] == 'success':
                        dtmf_transcriptions.append(result['transcription'])
                        successful_transcriptions += 1
                    else:
                        dtmf_transcriptions.append('')
                        failed_transcriptions += 1
                else:
                    dtmf_transcriptions.append('')
                    failed_transcriptions += 1
            
            # Update the stt data
            stt_data['voice'] = voice_transcriptions
            stt_data['dtmf'] = dtmf_transcriptions
    
    # Update metadata
    metadata = data.get('metadata', {})
    metadata['successful_stt_transcriptions'] = successful_transcriptions
    metadata['failed_stt_transcriptions'] = failed_transcriptions
    metadata['total_transcriptions'] = successful_transcriptions + failed_transcriptions
    metadata['last_stt_update'] = datetime.now().isoformat()
    
    log("SUCCESS", f"Updated JSON: {successful_transcriptions} successful, {failed_transcriptions} failed")
    return data

def generate_sql_update(json_file, assistant_id):
    """Generate SQL UPDATE statement for assistant configuration"""
    log("INFO", f"Generating SQL update for assistant ID {assistant_id}")
    
    try:
        with open(json_file, 'r') as f:
            data = json.load(f)
        
        ivr_stt_array = data.get('ivr_stt_array', {})
        path_finder_json = data.get('path_finder_json', {})
        metadata = data.get('metadata', {})
        
        # Convert to JSON strings
        ivr_stt_array_json = json.dumps(ivr_stt_array, indent=2)
        path_finder_json_str = json.dumps(path_finder_json, indent=2)
        
        # Escape single quotes for SQL
        ivr_stt_array_sql = ivr_stt_array_json.replace("'", "''")
        path_finder_json_sql = path_finder_json_str.replace("'", "''")
        
        sql_update = f"""-- Update Assistant Configuration for Assistant ID {assistant_id}
-- Generated on: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
-- Source JSON file: {json_file}
-- IVR STT Array language mappings: {len(ivr_stt_array.get('language_mappings', {}))}
-- Path Finder JSON nodes: {len(path_finder_json.get('nodes', []))}
-- Successful STT transcriptions: {metadata.get('successful_stt_transcriptions', 0)}

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
        
        sql_file = f"update_assistant_{assistant_id}_with_stt.sql"
        with open(sql_file, 'w') as f:
            f.write(sql_update)
        
        log("SUCCESS", f"SQL file generated: {sql_file}")
        return sql_file
        
    except Exception as e:
        log("ERROR", f"Failed to generate SQL: {e}")
        return None

def execute_database_update(sql_file, db_config):
    """Execute the database update"""
    log("INFO", f"Executing database update: {sql_file}")
    
    try:
        # Build mysql command
        mysql_cmd = [
            'mysql',
            f'-h{db_config["host"]}',
            f'-P{db_config["port"]}',
            f'-u{db_config["username"]}'
        ]
        
        if db_config["password"]:
            mysql_cmd.append(f'-p{db_config["password"]}')
        
        mysql_cmd.extend([db_config["database"], f'< {sql_file}'])
        
        # Execute the command
        cmd_str = ' '.join(mysql_cmd)
        log("DEBUG", f"Executing: {cmd_str}")
        
        result = subprocess.run(cmd_str, shell=True, capture_output=True, text=True)
        
        if result.returncode == 0:
            log("SUCCESS", "Database update executed successfully!")
            return True
        else:
            log("ERROR", f"Database update failed: {result.stderr}")
            return False
            
    except Exception as e:
        log("ERROR", f"Failed to execute database update: {e}")
        return False

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 stt_transcription_updater.py <json_file> [assistant_id] [--execute-db]")
        print("Example: python3 stt_transcription_updater.py ivr_stt_output.json 1 --execute-db")
        sys.exit(1)
    
    json_file = sys.argv[1]
    assistant_id = int(sys.argv[2]) if len(sys.argv) > 2 else 1
    execute_db = '--execute-db' in sys.argv
    
    # Database configuration
    db_config = {
        'host': '127.0.0.1',
        'port': '3306',
        'username': 'root',
        'password': '',  # Empty password
        'database': 'call_module'
    }
    
    log("INFO", f"Starting STT transcription update process")
    log("INFO", f"JSON file: {json_file}")
    log("INFO", f"Assistant ID: {assistant_id}")
    log("INFO", f"Execute DB: {execute_db}")
    
    # Step 1: Collect WAV files from JSON
    wav_files, data = collect_wav_files_from_json(json_file)
    if not wav_files:
        log("ERROR", "No WAV files found in JSON")
        sys.exit(1)
    
    # Step 2: Perform STT transcription
    log("INFO", f"Starting STT transcription for {len(wav_files)} files")
    transcription_results = {}
    
    for i, wav_file in enumerate(wav_files, 1):
        log("INFO", f"Processing file {i}/{len(wav_files)}: {wav_file['filename']}")
        result = transcribe_wav_file(wav_file['path'])
        transcription_results[wav_file['path']] = result
    
    # Step 3: Update JSON with transcriptions
    updated_data = update_json_with_transcriptions(data, transcription_results)
    
    # Step 4: Save updated JSON
    backup_file = f"{json_file}.backup.{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    shutil.copy2(json_file, backup_file)
    log("INFO", f"Created backup: {backup_file}")
    
    with open(json_file, 'w', encoding='utf-8') as f:
        json.dump(updated_data, f, indent=2, ensure_ascii=False)
    
    log("SUCCESS", f"Updated JSON file: {json_file}")
    
    # Step 5: Generate SQL update
    sql_file = generate_sql_update(json_file, assistant_id)
    if not sql_file:
        log("ERROR", "Failed to generate SQL file")
        sys.exit(1)
    
    # Step 6: Execute database update if requested
    if execute_db:
        if execute_database_update(sql_file, db_config):
            log("SUCCESS", "Database update completed successfully!")
        else:
            log("ERROR", "Database update failed!")
            sys.exit(1)
    else:
        log("INFO", f"SQL file ready for manual execution: {sql_file}")
    
    # Final summary
    metadata = updated_data.get('metadata', {})
    log("SUCCESS", "STT transcription update process completed!")
    log("INFO", f"Successful transcriptions: {metadata.get('successful_stt_transcriptions', 0)}")
    log("INFO", f"Failed transcriptions: {metadata.get('failed_stt_transcriptions', 0)}")
    log("INFO", f"Total files processed: {len(wav_files)}")

if __name__ == "__main__":
    main()

