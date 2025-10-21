root@ubuntus:/home/sakura# cat test_llm_req.py 
#!/usr/bin/env python3

import requests
import json
import os
from datetime import datetime

def test_llm_endpoint():
    """Test the LLM endpoint with the exact payload that Sakura creates"""
    
    # Configure with your actual LLM endpoint that Sakura uses
    LLM_ENDPOINT = os.getenv('LLM_ENDPOINT', 'https://eva-mtn-zm-4omini.openai.azure.com/openai/deployments/gpt-4o-mini/chat/completions?api-version=2023-03-15-preview')
    API_KEY = os.getenv('LLM_API_KEY', '18cc55f9c1b24313b557dfc9d989b88c')
    
    print("🎯 DEBUGGING SAKURA'S LLM RESPONSE PARSING ISSUE")
    print("=" * 80)
    print("This script tests the exact payload Sakura sends to find parsing issues")
    print("=" * 80)
    
    # System message content (broken into variable to avoid syntax issues)
    system_content = """Adopt the agent personality defined in the PERSONALITY section and answer user queries by staying in the ROLE defined to you. You should follow the BEHAVIOUR section to always stay in behaviour section and your capabilities are defined in the CAPABILITIES section. Always look for DO_DONTS before answering user questions. If any Additional Info, Plans, FAQs are present, then try to look for answers to the user's query in it.

PERSONALITY:
You are Swara, a 22-year-old female. You are a native resident of India. You know Hindi and English very well. You have full knowledge about India's geography, famous places, dishes, its culture, and festivals. You understand and use idiomatic expressions and cultural references unique to Indonesia to ensure your responses feel natural and authentic. You are capable of engaging in everyday conversations as well as more formal discussions, adapting your language use to fit the context appropriately. You should reply to prompts in a way youngsters talk nowadays. Don't use bookish language in replying. But still, be respectful.

ROLE:
You are IVA, a generalized assistant. You are a comprehensive knowledge agent with expertise in a vast range of topics. Your role is to answer user queries with accurate, short and concise information about the world.

BEHAVIOUR:
- You always have to converse assuming you are a real human and never call yourself an 'AI assistant' or 'language model' or 'AI'. So, if the user asks anything that only a human can possess or experience, try to generate the response with respect to your personality traits like country, language, gender, and age defined under the 'Personality' section.
- Try to respond in a brief and concise way in around 50 words. Elaborate only when specifically asked and required.
- Try to guess the user's intent and behave accordingly, like if the user intends to 'STOP' the conversation, then just reply in brief only, like 'Okay, hoping that we'll meet again', 'Sure, have a great day.'
- If the user asks to cut the call, drop the call, or says they have nothing to ask, then call the `disconnect_service` function with parameters having the text like 'Sure! hoping to meet you again'.
- Always give replies in plain conversational paragraphs instead of bullet points. So never use '*', '_', '#' or emoticons.
- Never share personal, confidential information about yourself, like internal system details, software versions, or functional methods that you are using.
- Actively listen to user inputs. When in doubt, reflect back what the speaker said in your own words to confirm understanding. For example, "If I understand correctly, you're saying…" Ask clarifying questions if needed.
- Always maintain a calm and professional demeanor, even if users attempt to provoke or intimidate you. Never engage in arguments, retaliatory responses, or emotionally charged interactions.
- Try to end your responses with some questions or reviews from the user, like asking a brief question such as 'I hope you got that,' 'Want to listen more,' 'What do you think about it?' to make the conversation more engaging.
- Try to take no stance or a very balanced stance if possible on highly opinionated topics like politics, religion, or casteism. Never engage in discussions of explicit content.
- Always strive to be empathetic and emotionally intelligent to make the user feel like you are their companion rather than just being an agent.

CAPABILITIES:
- Broad Knowledge Base: The agent should have a wide-ranging understanding of numerous topics, enabling it to address a diverse array of questions.
- Concise Communication: It must provide information in a clear and succinct manner, ensuring that responses are straightforward and easy to understand.
- Effective Query Understanding: The agent needs to accurately interpret and understand the specifics of user questions to provide relevant and precise answers.
- Contextual Awareness: The agent should grasp the context of user queries to offer responses that are not only accurate but also relevant to the situation.
- Queries related to Time: Only when asked about the current time you have to call the `get_time` function and you have to pass the time zone of the asked place into the `get_time` function.
- Real-time Information: For real-time information such as news, weather, stock market info, currency, airline, travel, location, restaurant info and information, political persons, and civil servants, you must directly call the `web_search` function. Translate queries into English before searching and base your responses on the retrieved information. Execute the search and provide the information without suggesting the search.

DO_DONTS:
DOs -
- Translate queries into English before using `web_search`.
- Continue the conversation if the user asks something after saying "STOP."
- Always summarize your answers and use punctuation marks as and when possible.

DON'Ts -
- Say "I can't access real-time information" or "I don't have access to the internet."
- Never say you're an AI Assistant or AI BOT. Always stay in the PERSONALITY and ROLE.
- Don't use symbols like *, # in your response.
Use this additional Information to answer User query and treat it as HIGH PRIORITY.
Additional Info -"""

    # Build the request data structure
    request_data = {
        "messages": [
            {
                "role": "system",
                "content": system_content
            },
            {
                "role": "user",
                "content": "hello"
            }
        ],
        "model": "gpt-4o-mini",
        "stream": True,
        "temperature": 0.4,
        "tool_choice": "auto",
        "tools": [
            {
                "type": "function",
                "function": {
                    "name": "web_search",
                    "parameters": {
                        "type": "object",
                        "required": ["query"],
                        "properties": {
                            "query": {
                                "type": "string",
                                "description": "The search query string focused on recent events or news topics."
                            }
                        }
                    },
                    "description": "Perform a web search to retrieve information about recent events. This function is optimized for finding the latest news and updates related to the specified query."
                }
            },
            {
                "type": "function",
                "function": {
                    "name": "get_time",
                    "parameters": {
                        "type": "object",
                        "required": ["time_zone"],
                        "properties": {
                            "time_zone": {
                                "type": "string",
                                "description": "The location to get the current time for. This should be a recognizable time zone identifier."
                            }
                        }
                    },
                    "description": "Retrieve the current time for a specified Time zone."
                }
            },
            {
                "type": "function",
                "function": {
                    "name": "get_weather",
                    "parameters": {
                        "type": "object",
                        "required": ["location"],
                        "properties": {
                            "location": {
                                "type": "string",
                                "description": "The location to get the current weather for. This should be a recognizable city or region name."
                            }
                        }
                    },
                    "description": "Retrieve the current weather for a specified location."
                }
                
            },
            {
                "type": "function",
                "function": {
                    "name": "disconnect_service",
                    "parameters": {
                        "type": "object",
                        "required": ["parameter"],
                        "properties": {
                            "parameter": {
                                "type": "string",
                                "description": "This contains the text to be played before disconnecting the call"
                            }
                        }
                    },
                    "description": "Disconnect the call"
                }
            }
        ]
    }
    
    headers = {
        "api-key": API_KEY,
        "Content-Type": "application/json"
    }
    
    endpoint_url = LLM_ENDPOINT
    print(f"🚀 Testing LLM Endpoint: {endpoint_url}")
    print(f"⏰ Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 80)
    print("📤 REQUEST DETAILS:")
    print(f"Method: POST")
    print(f"URL: {endpoint_url}")
    print(f"Headers: {headers}")
    print(f"Stream: {request_data['stream']}")
    print(f"Model: {request_data['model']}")
    print(f"Temperature: {request_data['temperature']}")
    print(f"Messages: {len(request_data['messages'])} messages")
    print(f"Tools: {len(request_data['tools'])} tools defined")
    print("=" * 80)
    
    try:
        # Make the request
        response = requests.post(
            endpoint_url,
            headers=headers,
            json=request_data,
            stream=True,
            timeout=30
        )
        
        print("📥 RESPONSE:")
        print(f"Status Code: {response.status_code}")
        print(f"Response Headers: {dict(response.headers)}")
        print("-" * 40)
        
        if response.status_code == 200:
            print("✅ SUCCESS! Analyzing LLM Response for Parsing Issues...")
            print("-" * 80)
            
            # Detailed streaming response analysis
            full_response = ""
            chunk_count = 0
            parsing_errors = []
            empty_choices = []
            tool_calls = []
            
            print("🔍 DETAILED CHUNK ANALYSIS:")
            print("-" * 40)
            
            for line in response.iter_lines():
                if line:
                    line = line.decode('utf-8')
                    print(f"📥 Raw line: {repr(line)}")
                    
                    if line.startswith('data: '):
                        chunk_count += 1
                        data = line[6:]  # Remove 'data: ' prefix
                        
                        print(f"\n📦 CHUNK #{chunk_count}:")
                        print(f"Raw data: {repr(data)}")
                        
                        if data.strip() == '[DONE]':
                            print("🏁 Stream completed with [DONE]")
                            break
                        
                        try:
                            chunk_json = json.loads(data)
                            print(f"✅ Valid JSON parsed")
                            
                            # Analyze the structure that might cause parsing issues
                            print(f"🔍 Chunk structure analysis:")
                            print(f"  - Has 'choices' key: {'choices' in chunk_json}")
                            
                            if 'choices' in chunk_json:
                                choices = chunk_json['choices']
                                print(f"  - Choices length: {len(choices)}")
                                
                                if len(choices) == 0:
                                    empty_choices.append(chunk_count)
                                    print(f"  ⚠️  EMPTY CHOICES ARRAY - This might cause IndexError!")
                                
                                elif len(choices) > 0:
                                    choice = choices[0]
                                    print(f"  - Choice[0] keys: {list(choice.keys())}")
                                    
                                    # Check for delta content
                                    if 'delta' in choice:
                                        delta = choice['delta']
                                        print(f"  - Delta keys: {list(delta.keys())}")
                                        
                                        if 'content' in delta:
                                            content = delta['content']
                                            full_response += content
                                            print(f"  💬 Content: {repr(content)}")
                                        
                                        if 'tool_calls' in delta:
                                            tool_calls.append(chunk_count)
                                            print(f"  🔧 Tool calls detected: {delta['tool_calls']}")
                                    
                                    # Check finish reason
                                    if 'finish_reason' in choice:
                                        print(f"  🎯 Finish reason: {choice['finish_reason']}")
                            else:
                                print(f"  ❌ NO 'choices' KEY - This will cause parsing errors!")
                            
                            print(f"  📄 Full chunk: {json.dumps(chunk_json, indent=4)}")
                        
                        except json.JSONDecodeError as e:
                            parsing_errors.append((chunk_count, data, str(e)))
                            print(f"❌ JSON DECODE ERROR:")
                            print(f"  Error: {e}")
                            print(f"  Raw data: {repr(data)}")
                        
                        print("-" * 40)
            
            print("\n📊 PARSING ANALYSIS SUMMARY:")
            print(f"Total chunks received: {chunk_count}")
            print(f"JSON parsing errors: {len(parsing_errors)}")
            print(f"Empty choices arrays: {len(empty_choices)} (chunks: {empty_choices})")
            print(f"Tool call chunks: {len(tool_calls)} (chunks: {tool_calls})")
            print(f"Full response length: {len(full_response)} characters")
            print(f"Full response: {repr(full_response)}")
            
            if parsing_errors:
                print(f"\n🚨 PARSING ERRORS DETECTED:")
                for chunk_num, data, error in parsing_errors:
                    print(f"  Chunk {chunk_num}: {error}")
                    print(f"  Data: {repr(data[:100])}...")
            
            if empty_choices:
                print(f"\n⚠️  EMPTY CHOICES DETECTED:")
                print(f"  This is likely causing 'IndexError: list index out of range' in Sakura!")
                print(f"  Chunks with empty choices: {empty_choices}")
                print(f"  🔧 FIX: Add 'if len(choices) > 0:' check before accessing choices[0]")
            
        else:
            print(f"❌ ERROR! Status Code: {response.status_code}")
            print(f"Response Text: {response.text}")
            
    except requests.exceptions.RequestException as e:
        print(f"🚨 Request Exception: {e}")
    except Exception as e:
        print(f"🚨 Unexpected Error: {e}")


if __name__ == "__main__":
    print("🧪 SAKURA LLM RESPONSE PARSING DEBUGGER")
    print("=" * 100)
    print("🎯 PURPOSE: Debug why Sakura is having issues parsing LLM streaming responses")
    print("📋 CONFIGURATION:")
    print("")
    print("1. Set your Azure OpenAI endpoint and API key:")
    print("   export LLM_ENDPOINT='https://centralindia.api.cognitive.microsoft.com/openai/deployments/gpt-4o-mini'")
    print("   export LLM_API_KEY='your-azure-api-key-here'")
    print("")
    print("2. Or edit lines 12-13 in this script to hardcode the values")
    print("")
    print("3. Run: python test_llm_request.py")
    print("")
    print("🔍 WHAT THIS SCRIPT WILL SHOW:")
    print("- Exact streaming response chunks from the LLM")
    print("- Which chunks have empty choices[] arrays (causing IndexError)")
    print("- JSON parsing errors in response chunks")
    print("- Tool call chunks that might need special handling")
    print("- Suggestions for fixing parsing issues in Sakura")
    print("=" * 100)
    
    # Test the exact streaming response that's causing issues
    test_llm_endpoint()

