import socketio
import json
import time
import asyncio
from datetime import datetime

class SmartIVRTester:
    def __init__(self, server_url="http://localhost:8400"):
        self.sio = socketio.AsyncClient()
        self.server_url = server_url
        self.call_id = int(time.time() * 1000)
        self.message_received = False
        self.end_chunk_received = False
        
        self.setup_handlers()
    
    def setup_handlers(self):
        @self.sio.event
        async def connect():
            print(f"✅ Connected to server at {self.server_url}")
            print(f"📞 Call ID: {self.call_id}")
        
        @self.sio.event
        async def disconnect():
            print("❌ Disconnected from server")
        
        @self.sio.event
        async def call_message(data):
            print(f"📨 Received response: {json.dumps(data, indent=2)}")
            
            if data.get('isEndChunk') == True:
                print("🏁 End chunk received - ready to send call_end")
                self.end_chunk_received = True
                self.message_received = True
        
        @self.sio.event
        async def error(data):
            print(f"❌ Error received: {data}")
    
    async def test_smart_ivr(self):
        try:
            print("🔌 Connecting to Sakura server...")
            await self.sio.connect(self.server_url)
            await asyncio.sleep(1)
            
            # Send call_start event with proper operator and country
            call_start_data = {
                "callId": self.call_id,
                "gender": "male",
                "isTranslate": False,
                "assistantId": "1",
                "languageCode": "en-US",
                "llmModel": "gpt-4o-mini",
                "voiceName": "en-US-AvaNeural",
                "additionalInfo": "",
                "ttsProvider": "azure",
                "assistantName": "",
                "assistantStyle": "",
                "questionPerCall": 0,
                "isSendEmail": False,
                "aParty": "+93730333001",
                "bParty": "8882",
                "serviceType": "SMART_IVR",
                "userName": "",
                "handleTelemarketingCalls": False,
                "telemarketingKeywords": "",
                "node_id": 5,
                "operator": "JIO",  # Added operator
                "country": "IN"    # Added country
            }
            
            print("📞 Sending call_start event...")
            await self.sio.emit('call_start', json.dumps(call_start_data))
            await asyncio.sleep(2)
            
            # Send call_message event
            call_message_data = {
                "callId": self.call_id,
                "eventType": "call",
                "transcript": "Activate a package.",
                "startTime": int(time.time() * 1000),
                "endTime": int(time.time() * 1000),
                "langCode": "en-US",
                "voiceName": "en-US-AvaNeural",
                "messageId": "1_Avatar",
                "node_id": 5
            }
            
            print("💬 Sending call_message event...")
            await self.sio.emit('call_message', json.dumps(call_message_data))
            
            # Wait for response
            print("⏳ Waiting for response...")
            timeout = 30
            start_time = time.time()
            
            while not self.end_chunk_received and (time.time() - start_time) < timeout:
                await asyncio.sleep(0.5)
            
            if self.end_chunk_received:
                print("✅ Response received successfully!")
                
                call_end_data = {"callId": self.call_id}
                print("🔚 Sending call_end event...")
                await self.sio.emit('call_end', json.dumps(call_end_data))
                await asyncio.sleep(1)
            else:
                print("⏰ Timeout waiting for response")
            
        except Exception as e:
            print(f"❌ Error during test: {e}")
        
        finally:
            print("🔌 Disconnecting...")
            await self.sio.disconnect()
    
    def run_test(self):
        print("🚀 Starting Smart IVR Test")
        print("=" * 50)
        asyncio.run(self.test_smart_ivr())
        print("=" * 50)
        print("🏁 Test completed")

if __name__ == "__main__":
    tester = SmartIVRTester()
    tester.run_test()

