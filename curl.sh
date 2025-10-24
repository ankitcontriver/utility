#!/bin/bash

# Define the URL for the API endpoint
url="https://uaenorth.stt.speech.microsoft.com/speech/recognition/conversation/cognitiveservices/v1?format=detailed&language=fa-IR"

# Define the subscription key and region
subscription_key="7yAOU8Ce9WpRZnuBSBCKtnptzwRsgBwC41dZIFmKRSn34nc4A85xJQQJ99BIACF24PCXJ3w3AAAYACOGvMSy"
subscription_region="uaenorth"

# Define the path to the WAV file
wav_file="/data/filestore/services/template/Prompts/greeting_VOICEPROMPT_faIR.wav"

# Check if the WAV file exists
if [[ ! -f "$wav_file" ]]; then
  echo "Error: File $wav_file does not exist."
  exit 1
fi

# Send the curl request and capture both response and status code
response=$(curl -s -w "%{http_code}" -X POST "$url" \
  -H "Ocp-Apim-Subscription-Key: $subscription_key" \
  -H "Ocp-Apim-Subscription-Region: $subscription_region" \
  -H "Accept: application/json" \
  --data-binary @"$wav_file")

# Extract the HTTP status code from the response
http_code="${response: -3}"
# Extract the response body (everything except the last 3 characters, which are the HTTP code)
response_body="${response:0:${#response}-3}"

# Print the HTTP status code and the response body
echo "HTTP Status Code: $http_code"
echo "Response Body:"
echo "$response_body"

# Check the HTTP status code
if [[ "$http_code" -eq 200 ]]; then
  echo "Request successful. Response received."
else
  echo "Request failed with HTTP status code $http_code."
fi

