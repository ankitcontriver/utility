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

