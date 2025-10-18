import json
import xml.etree.ElementTree as ET
from typing import Dict, Any, List
from logger.__init__ import get_logger
import html
import re
from config.ivr_path_config import get_land_before, get_non_skippable_types, get_is_skippable

logger = get_logger(__name__)

class XMLToFlatArrayConverter:
    def __init__(self):
        self.nodes = {}
        self.connections = {}
        self.node_types = {}
        
def parse_xml_string_to_flat_array(self, xml_string: str) -> Dict[str, Any]:
    """
    Parse XML string and convert to flat array structure
    Args:
        xml_string (str): XML content as string
    Returns:
        dict: Flat array with metadata
    """
    logger.info(f"Creating flat_array from XM")
    
    # Unescape HTML entities and unicode escapes
    xml_string = html.unescape(xml_string)
    xml_string = re.sub(r'\\u003c', '<', xml_string)
    xml_string = re.sub(r'\\u003e', '>', xml_string)
    xml_string = re.sub(r'\\u0022', '"', xml_string)
    xml_string = xml_string.strip()
    
    # Try decoding unicode escapes
    try:
        xml_string = xml_string.encode('utf-8').decode('unicode_escape')
    except Exception as e:
        logger.error(f"Unicode escape decode failed: {e}")
    
    # ULTIMATE SOLUTION: Multiple robust strategies
    strategies = [
        # Strategy 1: Clean problematic attributes
        lambda x: re.sub(r'xmlParamsData="[^"]*"', 'xmlParamsData=""', x),
        # Strategy 2: Remove attributes completely
        lambda x: re.sub(r'\s+xmlParamsData="[^"]*"', '', x),
        # Strategy 3: Remove any attribute with problematic content
        lambda x: re.sub(r'\s+[a-zA-Z_][a-zA-Z0-9_]*="[^"]*<[^"]*"', '', x),
        # Strategy 4: Remove any attribute with > in value
        lambda x: re.sub(r'\s+[a-zA-Z_][a-zA-Z0-9_]*="[^"]*>[^"]*"', '', x),
        # Strategy 5: Remove any attribute with & in value
        lambda x: re.sub(r'\s+[a-zA-Z_][a-zA-Z0-9_]*="[^"]*&[^"]*"', '', x),
        # Strategy 6: Remove any attribute with quotes in value
        lambda x: re.sub(r'\s+[a-zA-Z_][a-zA-Z0-9_]*="[^"]*"[^"]*"', '', x),
    ]
    
    # Try each strategy
    for i, strategy in enumerate(strategies, 1):
        try:
            logger.info(f"Trying strategy {i}")
            cleaned_xml = strategy(xml_string)
            root = ET.fromstring(cleaned_xml)
            logger.info(f"XML parsing succeeded with strategy {i}")
            break
        except ET.ParseError as e:
            logger.error(f"Strategy {i} failed: {e}")
            if i == len(strategies):
                # Last strategy failed, try lxml
                try:
                    from lxml import etree
                    root = etree.fromstring(cleaned_xml)
                    logger.info("XML parsing succeeded with lxml")
                    break
                except ImportError:
                    logger.error("lxml not available")
                except Exception as e:
                    logger.error(f"lxml parsing failed: {e}")
                    raise ValueError(f"Failed to parse XML after all attempts: {e}")
    
    root_element = root.find('root')
    if root_element is None:
        logger.error("No 'root' element found in XML")
        raise ValueError("No 'root' element found in XML")
    
    # Rest of your existing code...
    self.nodes = {}
    self.connections = {}
    self.node_types = {}
    
    for mx_cell in root_element.findall('mxCell'):
        cell_id = mx_cell.get('id')
        cell_type = mx_cell.get('type', 'Unknown')
        cell_value = mx_cell.get('value', '')
        promptfiles = []
        if cell_type == 'Navigation':
            mx_params = mx_cell.find('mxParams')
            if mx_params is not None:
                for mx_param in mx_params.findall('mxParam'):
                    promptfile = mx_param.get('promptfile')
                    if promptfile:
                        promptfiles.append(promptfile)
        if cell_id:
            self.nodes[cell_id] = {
                'id': cell_id,
                'type': cell_type,
                'value': cell_value,
                'children': [],
                'parent': None,
                'promptfiles': promptfiles
            }
            self.node_types[cell_id] = cell_type
    
    for mx_cell in root_element.findall('mxCell'):
        source = mx_cell.get('source')
        target = mx_cell.get('target')
        if source and target:
            if source not in self.connections:
                self.connections[source] = []
            self.connections[source].append(target)
    
    self._build_parent_child_relationships()
    flat_array = self._convert_to_flat_array()
    metadata = self._generate_metadata()
    return {
        'metadata': metadata,
        'nodes': flat_array
    }

    def parse_xml_to_flat_array(self, xml_file_path: str) -> Dict[str, Any]:
        """
        Parse XML file and convert to flat array structure
        Args:
            xml_file_path (str): Path to XML file
        Returns:
            dict: Flat array with metadata
        """
        with open(xml_file_path, 'r', encoding='utf-8') as f:
            xml_string = f.read()
        return self.parse_xml_string_to_flat_array(xml_string)

    def _build_parent_child_relationships(self):
        for source, targets in self.connections.items():
            if source in self.nodes:
                self.nodes[source]['children'] = targets
        for source, targets in self.connections.items():
            for target in targets:
                if target in self.nodes:
                    self.nodes[target]['parent'] = source

    def _convert_to_flat_array(self) -> List[Dict[str, Any]]:
        flat_array = []
        NON_SKIPPABLE_TYPES = get_non_skippable_types()
        for node_id, node_data in self.nodes.items():
            node_type = node_data['type']
            node_value = node_data['value']
            # Determine if node is non-skippable
            # logger.info(f"Node {node_id} (Navigation) data: {node_data}")

            is_skippable = get_is_skippable(node_type)
            if node_type == "Navigation":
                promptfiles = node_data.get('promptfiles', [])
                is_skippable = any('_VOICEPROMPT.wav' in pf for pf in promptfiles)
                
              
            land_before = get_land_before(node_type)
            flat_node = {
                'id': node_id,
                'type': node_type,
                'value': node_value,
                'children': node_data['children'],
                'parent': node_data['parent'],
                'isSkippable': is_skippable,
                'land_before': land_before
            }
            # logger.info(f"Node {node_id} (Navigation) flat_node: {flat_node}")
            flat_array.append(flat_node)
        flat_array.sort(key=lambda x: int(x['id']) if x['id'].isdigit() else x['id'])
        return flat_array

    def _generate_metadata(self) -> Dict[str, Any]:
        total_nodes = len(self.nodes)
        root_nodes = sum(1 for node in self.nodes.values() if node['parent'] is None)
        total_connections = sum(len(targets) for targets in self.connections.values())
        type_counts = {}
        for node_type in self.node_types.values():
            type_counts[node_type] = type_counts.get(node_type, 0) + 1
        return {
            'source_xml': 'xml.xml',
            'total_nodes': total_nodes,
            'root_nodes': root_nodes,
            'total_connections': total_connections,
            'node_types': type_counts
        }

# CLI code removed for service usage in Sakura

