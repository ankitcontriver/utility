-- Use the existing call_module database
USE call_module;

-- Create asr_llm_mapping table
CREATE TABLE IF NOT EXISTS asr_llm_mapping (
    id INT(11) AUTO_INCREMENT PRIMARY KEY,
    op_co VARCHAR(25) NOT NULL UNIQUE,
    stt_provider VARCHAR(25),
    stt_region VARCHAR(30),
    stt_key VARCHAR(100),
    llm_provider VARCHAR(25),
    llm_api VARCHAR(250),
    llm_key VARCHAR(100),
    tts_provider VARCHAR(25),
    tts_api VARCHAR(250),
    tts_key VARCHAR(100),
    perplexity_api VARCHAR(250),
    perplexity_key VARCHAR(100),
    perplexity_model VARCHAR(20),
    llm_model VARCHAR(25)
);

-- Insert sample data into asr_llm_mapping table
INSERT INTO asr_llm_mapping (op_co, stt_provider, stt_region, stt_key, llm_provider, llm_api, llm_key, tts_provider, tts_api, tts_key, perplexity_api, perplexity_key, perplexity_model, llm_model)
VALUES
('ETI_AF', 'azure', 'uaenorth', '7yAOU8Ce9WpRZnuBSBCKtnptzwRsgBwC41dZIFmKRSn34nc4A85xJQQJ99BIACF24PCXJ3w3AAAYACOGvMSy', 'azure', 'https://nexiva-etisalat-af-ai.openai.azure.com/openai/deployments/gpt-4.1-mini/chat/completions?api-version=2025-01-01-preview', '6JIUNO5wZzB7NX2DEj0vYbZ0N4YDkamrq68qqKOjFPAxLm98EkuBJQQJ99BIACF24PCXJ3w3AAABACOG4LvJ____', 'azure', 'https://uaenorth.tts.speech.microsoft.com/cognitiveservices/v1', '7yAOU8Ce9WpRZnuBSBCKtnptzwRsgBwC41dZIFmKRSn34nc4A85xJQQJ99BIACF24PCXJ3w3AAAYACOGvMSy', 'https://api.perplexity.ai/chat/completions', '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', 'sonar', 'gpt-4.1-mini');

-- Create voice_modulation table
CREATE TABLE IF NOT EXISTS voice_modulation (
    id BIGINT(20) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    voice_type VARCHAR(50) NOT NULL,
    freq_min INT(11) NOT NULL,
    freq_max INT(11) NOT NULL,
    tempo DECIMAL(4,1) NOT NULL,
    octave DECIMAL(4,2) NOT NULL,
    pitch DECIMAL(4,2) NOT NULL,
    rate DECIMAL(4,2) NOT NULL,
    timbre DECIMAL(4,1) NOT NULL
);

-- Insert sample data into voice_modulation table
INSERT INTO voice_modulation (voice_type, freq_min, freq_max, tempo, octave, pitch, rate, timbre)
VALUES
('Kid', 198, 202, -3.0, 1.00, 2.00, 1.00, 1.0),
('Cartoon', 218, 222, -3.0, 2.00, 2.00, 1.00, 1.0),
('Female', 148, 152, -19.5, 0.17, 1.15, 1.05, 1.0),
('Male', 93, 95, -1.0, 1.00, 2.00, 1.00, 1.0),
('King', 96, 97, -2.0, 1.00, 1.00, 1.00, 1.0),
('Boy', 205, 210, -6.0, 1.00, 2.00, 1.00, 1.0),
('GrandPa', 81, 81, -2.0, 1.00, 1.00, 1.00, 1.0),
('Monster', 88, 92, -10.0, 1.00, 1.00, 1.00, 2.0),
('Santa', 110, 110, -5.0, 1.00, 1.00, 1.00, 1.0),
('Ghost', 83, 84, -8.0, 2.00, 3.00, 1.00, 2.0),
('Bunny', 181, 181, -8.0, 2.00, 3.00, 1.00, 1.0),
('GrandMa', 160, 160, -2.0, 1.00, 1.00, 1.00, 1.0);

-- Use the existing database (replace with the correct database name if needed)
USE global;

-- Create Security_properties table
CREATE TABLE IF NOT EXISTS Security_properties (
    id INT(11) AUTO_INCREMENT PRIMARY KEY,
    operator VARCHAR(25) NOT NULL,
    country VARCHAR(25) NOT NULL,
    prop_key VARCHAR(100) NOT NULL,
    value TEXT NOT NULL
);

-- Insert sample data into Security_properties table
INSERT INTO Security_properties (operator, country, prop_key, value)
VALUES
('loadtest', 'loadtest', 'enableLogSecurity', 'false'),
('loadtest', 'loadtest', 'whitelistedNumbers', '+919315368346');
