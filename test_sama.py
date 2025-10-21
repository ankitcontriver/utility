import re

# Sample message content
msg_content = '{"current_node_id": 12345}'
# New node ID to replace
new_node_id = 67890

# Regular expression to match and replace the current_node_id
pattern = r'("current_node_id"\s*:\s*)[0-9]+'

# Perform the substitution
try:
    new_content = re.sub(
        pattern,
        f'\\g<1>{new_node_id}',  # Using the correct backreference syntax for Python
        msg_content
    )
    print("Original Content: ", msg_content)
    print("Updated Content: ", new_content)
except re.error as e:
    print("Regex error:", e)

