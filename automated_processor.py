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

def test_azure_stt_connection():
    """Test Azure STT API connection"""
    try:
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] INFO: Testing Azure STT API connection...", file=sys.stderr)
        
        # Test with a simple curl command to check API availability
        test_cmd = [
            'curl', '-s', '-w', '%{http_code}',
            '-X', 'POST', STT_URL,
            '-H', f'Ocp-Apim-Subscription-Key: {AZURE_STT_KEY}',
            '-H', f'Ocp-Apim-Subscription-Region: {AZURE_STT_REGION}',
            '-H', 'Accept: application/json'
        ]
        
        result = subprocess.run(test_cmd, capture_output=True, text=True, timeout=10)
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] DEBUG: Test curl return code: {result.returncode}", file=sys.stderr)
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] DEBUG: Test response: {result.stdout[:200]}", file=sys.stderr)
        
        return True
    except Exception as e:
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: Azure STT test failed: {e}", file=sys.stderr)
        return False

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
    local_file_path = wav_file_path
    
    # Check if file exists locally (on server)
    if not os.path.exists(wav_file_path):
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] ERROR: WAV file not found: {wav_file_path}", file=sys.stderr)
        return {
            'status': 'error',
            'error': f'File not found: {wav_file_path}',
            'transcription': '',
            'confidence': 0
        }
    
    try:
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] INFO: Transcribing WAV file: {local_file_path}", file=sys.stderr)
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] DEBUG: File size: {os.path.getsize(local_file_path)} bytes", file=sys.stderr)
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] DEBUG: STT URL: {STT_URL}", file=sys.stderr)
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] DEBUG: Azure Key: {AZURE_STT_KEY[:10]}...", file=sys.stderr)
        
        curl_cmd = [
            'curl', '-s', '-w', '%{http_code}',
            '-X', 'POST', STT_URL,
            '-H', 'Content-Type: audio/wav; codecs=audio/pcm; samplerate=16000',
            '-H', f'Ocp-Apim-Subscription-Key: {AZURE_STT_KEY}',
            '-H', f'Ocp-Apim-Subscription-Region: {AZURE_STT_REGION}',
            '-H', 'Accept: application/json',
            '--data-binary', f'@{local_file_path}'
        ]
        
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] DEBUG: Executing curl command...", file=sys.stderr)
        result = subprocess.run(curl_cmd, capture_output=True, text=True)
        
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] DEBUG: Curl return code: {result.returncode}", file=sys.stderr)
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] DEBUG: Curl stdout length: {len(result.stdout)}", file=sys.stderr)
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] DEBUG: Curl stderr: {result.stderr}", file=sys.stderr)
        
        response_text = result.stdout.strip()
        status_code = response_text[-3:] if response_text[-3:].isdigit() else 'unknown'
        json_response = response_text[:-3] if status_code != 'unknown' else response_text
        
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] DEBUG: Status code: {status_code}", file=sys.stderr)
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] DEBUG: JSON response: {json_response[:200]}...", file=sys.stderr)
        
        if status_code == '200' and json_response:
            try:
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] DEBUG: Parsing JSON response...", file=sys.stderr)
                stt_data = json.loads(json_response)
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] DEBUG: Parsed STT data keys: {list(stt_data.keys())}", file=sys.stderr)
                
                transcription = stt_data.get('DisplayText', '')
                confidence = stt_data.get('Confidence', 0)
                
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] DEBUG: Raw transcription: '{transcription}'", file=sys.stderr)
                print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] DEBUG: Confidence: {confidence}", file=sys.stderr)
                
                if transcription:
                    print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] SUCCESS: STT completed - '{transcription}' (confidence: {confidence})", file=sys.stderr)
                else:
                    print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] WARNING: Empty transcription received", file=sys.stderr)
                
                # No cleanup needed - using original file path
                
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
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] DEBUG: Full response: {response_text}", file=sys.stderr)
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

def clean_filename(filename):
    """Remove number prefix from filename (e.g., '3316-filename.wav' -> 'filename.wav')"""
    if '-' in filename and filename[0].isdigit():
        # Find the first dash and remove everything before it
        dash_index = filename.find('-')
        if dash_index > 0:
            return filename[dash_index + 1:]
    return filename

def extract_navigation_nodes(root):
    """Extract Navigation nodes with WAV files and transcribe them"""
    navigation_nodes = {}
    
    for mx_cell in root.findall('.//mxCell'):
        if mx_cell.get('type') == 'Navigation':
            cell_id = mx_cell.get('id')
            cell_value = mx_cell.get('value', '')
            
            mx_params = mx_cell.find('mxParams')
            if mx_params is not None:
                wav_files = []
                
                # Look for mxParam elements with promptfile attribute
                for mx_param in mx_params.findall('mxParam'):
                    promptfile = mx_param.get('promptfile')
                    if promptfile and '.wav' in promptfile:
                        # Clean the filename to remove number prefix
                        clean_name = clean_filename(promptfile.strip())
                        
                        # Transcribe the WAV file using the cleaned path
                        stt_result = transcribe_wav_with_curl(clean_name)
                        
                        wav_files.append({
                            'path': clean_name,  # Store the complete cleaned path
                            'filename': clean_name.split('/')[-1] if '/' in clean_name else clean_name,
                            'original_promptfile': promptfile.strip(),  # Keep original for reference
                            'is_voice_prompt': '_VOICEPROMPT' in clean_name,
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
                    voice_filenames.append(wav_file['path'])  # Store complete path
                else:
                    dtmf_files.append(wav_file['transcription'])
                    dtmf_filenames.append(wav_file['path'])  # Store complete path
        
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
        # Test Azure STT connection first
        if not test_azure_stt_connection():
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] WARNING: Azure STT connection test failed, but continuing...", file=sys.stderr)
        
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
        failed_transcriptions = 0
        for node_data in navigation_nodes.values():
            for wav_file in node_data['wav_files']:
                if wav_file['stt_status'] == 'success':
                    successful_transcriptions += 1
                else:
                    failed_transcriptions += 1
        
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] SUCCESS: {successful_transcriptions} real STT transcriptions completed, {failed_transcriptions} failed", file=sys.stderr)
        
        output = {
            'ivr_stt_array': ivr_stt_array,
            'path_finder_json': path_finder_json,
            'metadata': {
                'source_file': xml_file,
                'total_wav_files': successful_transcriptions + failed_transcriptions,
                'total_nodes': len(path_finder_json['nodes']),
                'navigation_nodes': len(navigation_nodes),
                'successful_stt_transcriptions': successful_transcriptions,
                'failed_stt_transcriptions': failed_transcriptions,
                'total_transcriptions': successful_transcriptions + failed_transcriptions,
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
