-- Create the database
CREATE DATABASE IF NOT EXISTS call_module;

-- Use the created database
USE call_module;

-- Create client_config table
CREATE TABLE IF NOT EXISTS client_config (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tenant_id VARCHAR(255) NOT NULL,
    client_ip VARCHAR(15),
    short_code VARCHAR(10),
    auth_key VARCHAR(255),
    allowed_calls INT,
    call_type VARCHAR(50),
    call_direction VARCHAR(50),
    enabled TINYINT(1),
    created_at DATETIME,
    updated_at DATETIME,
    language VARCHAR(50)
);

-- Insert sample data into client_config table
INSERT INTO client_config (tenant_id, client_ip, short_code, allowed_calls, call_type, call_direction, enabled, created_at, updated_at, language)
VALUES
('AIRTEL_IN_EVA', '172.16.11.223', '8090', 300, 'SIP', 'inbound', 1, '2025-05-15 08:13:55', '2025-09-18 07:21:05', NULL),
('AIRTEL_IN_EVA', '172.16.11.222', '1919', 300, 'SIP', 'outbound', 1, '2025-05-15 02:01:49', '2025-08-21 05:48:46', NULL);

-- Create conversation_metadata table
CREATE TABLE IF NOT EXISTS conversation_metadata (
    id INT AUTO_INCREMENT PRIMARY KEY,
    client_config_id INT,
    product_id VARCHAR(255),
    assistant_id INT,
    gender VARCHAR(50),
    asr_vendor VARCHAR(50),
    asr_lang_code VARCHAR(10),
    asr_lang_name VARCHAR(50),
    asr_model_name VARCHAR(50),
    tts_lang_code VARCHAR(10),
    tts_provider VARCHAR(50),
    tts_speed INT,
    tts_voice_name VARCHAR(50),
    tts_style VARCHAR(50),
    tts_resp_format VARCHAR(50),
    llm_model VARCHAR(50),
    translate TINYINT(1),
    additional_info TEXT,
    created_at DATETIME,
    updated_at DATETIME,
    FOREIGN KEY (client_config_id) REFERENCES client_config(id)
);

-- Insert sample data into conversation_metadata table
INSERT INTO conversation_metadata (client_config_id, product_id, assistant_id, gender, asr_vendor, asr_lang_code, asr_lang_name, asr_model_name, tts_lang_code, tts_provider, tts_speed, tts_voice_name, tts_style, tts_resp_format, llm_model, translate, additional_info, created_at, updated_at)
VALUES
(11, 'prod001', 1, 'female', 'deepgram', 'en-US', 'English (US)', 'nova-2', 'en-US', 'azure', 1, 'en-US-AvaNeural', 'chat', 'base64', 'gpt-4o-mini', 0, '', '2025-05-15 08:17:05', '2025-09-16 06:39:59'),
(12, 'prod001', 1, 'female', 'deepgram', 'en-US', 'English (US)', 'nova-2', 'en-US', 'azure', 1, 'en-US-AvaNeural', 'chat', 'base64', 'gpt-4o-mini', 0, '', '2025-05-15 08:17:05', '2025-09-19 00:25:48');

-- Create assistant_configuration table
CREATE TABLE IF NOT EXISTS assistant_configuration (
    assistant_id INT AUTO_INCREMENT PRIMARY KEY,
    role VARCHAR(255),
    name VARCHAR(255),
    age INT,
    company VARCHAR(255),
    description VARCHAR(255),
    male_picture_url VARCHAR(255),
    female_picture_url VARCHAR(255),
    prompt TEXT,
    opening_message TEXT,
    model_id_list VARCHAR(255),
    tts_style VARCHAR(255),
    user_specific TINYINT(1),
    header VARCHAR(255),
    questions TEXT,
    tool_call_support TINYINT(1),
    tools_supported TEXT,
    claude_tools TEXT,
    createdOn DATETIME,
    updatedOn DATETIME,
    status TINYINT(1),
    country VARCHAR(25),
    operator VARCHAR(25),
    country_code VARCHAR(25),
    ivr_stt_array TEXT,
    path_finder_json TEXT,
    temperature FLOAT DEFAULT 0.4,
    user_email_list TEXT,
    call_summary_prompt TEXT,
    calendar_prompt TEXT,
    lang_selection_via_asr TINYINT(1),
    tier2_prompt TEXT,
    tier2_tools TEXT
);

-- Insert sample data into assistant_configuration table
INSERT INTO assistant_configuration (role, name, age, company, description, male_picture_url, female_picture_url, prompt, opening_message, model_id_list, tts_style, user_specific, header, questions, tool_call_support, tools_supported, claude_tools, createdOn, updatedOn, status, country, operator, country_code, ivr_stt_array, path_finder_json, temperature, user_email_list, call_summary_prompt, calendar_prompt, lang_selection_via_asr, tier2_prompt, tier2_tools)
VALUES
('Smart_IVR', 'IVA', 22, 'Ester Communications', '', 'https://res.mobibattle.co/sand/coolclub/image/configration/SearchAssistantMale.png', 'https://res.mobibattle.co/sand/coolclub/image/configration/SearchAssistant.png', 'You are an IVR assistant system.', 'hey i am eva', '1,2,3', 'chat', 0, '1', '', 1, '', '', '2025-10-06 15:06:14', NULL, 1, 'loadtest', 'loadtest', 'TEST', '', '', 0.4, NULL, NULL, NULL, 1, NULL, NULL);




UPDATE assistant_configuration
SET prompt = 'You are an IVR assistant system. Your job is to take in:

• A user_query: the latest user input (text/voice transcription)
• A current_node_id: the node the user is currently on
• A full IVR tree JSON containing:
   ? node_id: unique identifier
   ? stt: speech-to-text data for voice and dtmf prompts
   ? children: array of child node_ids

Your task is to:

Return the output with node_id as follow the below json:

1. Search the entire IVR tree (not limited to the children of current_node_id)
2. Semantically compare the intent of the user_query to all dtmf prompts. Use deep semantic understanding to interpret the user\'s intent from their query, considering nuances and context, rather than relying solely on keywords. When user query explicitly mentions a specific product or service, prioritize returning directly the corresponding detailed product node id.

3. Always return the exact node for the matching query. Never return the parent node. For example: if the query is regarding weekly bundles , return the exact node which has weekly bundle never return its parent node id. This is just an example you have to follow this rule through out your semantic analysis.
4. You need to emphasize that if a query is specific to a child node (e.g., "weekly bundles"), the system should always prioritize direct child node over parent nodes (e.g., "data offers"). 
Never follow the hierarchy of returning parent node and never assume that child node can be only accesible by parent node.
I the prompts there can be press 1 or press 2 . Assume that each node can be accessible directly so always return the matching node.
Never return the node that through which it is accessible like parent node . always return the direct chirld node 
6. Identify the node_id with the most relevant intent match. Check the prompt of current node id and then check the user query and then map it against the prompt of child of the current node id. If nothing matches then start from the start node.
7. Low Confidence Detection:
If the system detects that the confidence level for intent matching is lower than a predefined threshold, 0.3 in our case, treat this as a low-confidence scenario where the user\'s intent is ambiguous.
In such cases, instead of returning a specific node, return "node_id": "-1", and provide a suitable fallback reason. For example:
"reason": "The user\'s intent seemed unclear or not fully aligned with the available options. Our IVR flow offers services such as appointment scheduling, general inquiries, or emergency assistance. However, the query provided doesn\'t match any of these options."
Specify user\'s query or intent as well in the reason field.
8. If user asks to listen to the same menu or repeat the prompt again, return the current node id back.
9. There are some prompts in the IVR flow where we are asking number input from the user like phone number or credit card number etc. You may get the number in the user query, extract it as it is and return in the response json in the parameter "user_input" as string along with a text confirming the user input in the parameter "confirmation_message". Keep these 2 fields always empty if the input is not detected. "node_id" will be the <<current_node_id>> in the response.
10. In the above scenario, in which we got the input from the user, then it is expected in the next query of the user you will get the confirmation of the user against the input. Analyze user\'s intent to check whether the input is confirmed or not, and based on the intent set the value "success" or "failure" of "input_confirmed" in the response json. In other cases always keep it empty. "node_id" will be the <<current_node_id>> in the response. In case the user\'s answer to the confirmation is not affirmative, retry asking the user for that specific number once. If the user fails to confirm again, set the value of the input_confirmed field to "failure".
11. You always have to check the user\'s previous and current query to analyze the intent more precisely. Like in cases, where the prompts end in "would you like to know more" or "Please confirm your phone number <<user_input>>". In both these cases you may get affirmation in many ways, get the intent and then give the response. Also the examples I have given in this point are of 2 very different scenarios, the first is the general case and the other is the user input case. Don\'t mix these cases and handle cases as you are told.
12. Return the result in the following JSON format:
{
  "node_id": "<string>",
  "confidence": <float between 0 and 1>,
  "matched_text": "<exact matched voice or dtmf prompt>",
  "reason": "<Precise reasoning behind returning this specific node_id>",
  "user_input": "<Only the number input from the user otherwise empty>",
  "confirmation_message": "<Reply confirming the message if input is detected otherwise empty>",
  "input_confirmed": "success/failure based on user confirmation after the input otherwise empty"
}
where assistant_id=1'

