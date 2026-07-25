import os
import json
import urllib.request
import urllib.error
import subprocess
import sys

# Load local config
script_dir = os.path.dirname(os.path.abspath(__file__))
config_path = os.path.join(script_dir, "config.json")

try:
    with open(config_path, "r") as f:
        config = json.load(f)
except Exception as e:
    print(f"Error loading config.json: {e}")
    sys.exit(1)

api_key = os.environ.get("DEEPSEEK_API_KEY")
if not api_key:
    print("Error: DEEPSEEK_API_KEY environment variable not found.")
    print("Please make sure ~/.config/deepseek/env is sourced.")
    sys.exit(1)

def speak_text(text):
    url = f"{config['voicebox_url']}/generate"
    headers = {"Content-Type": "application/json"}
    
    # Payload structured for Voicebox's REST API endpoint
    payload = {
        "text": text,
        "profile_id": config["voice_profile"],
        "engine": "qwen_custom_voice",
        "instruct": "conversational"
    }
    
    req = urllib.request.Request(
        url, 
        data=json.dumps(payload).encode("utf-8"), 
        headers=headers, 
        method="POST"
    )
    
    try:
        temp_audio = "/tmp/voice_response.wav"
        # Download wave output directly from local Voicebox server
        with urllib.request.urlopen(req) as response:
            with open(temp_audio, "wb") as out_file:
                out_file.write(response.read())
        
        # Play the audio using system player (pw-play on PipeWire)
        player = config.get("audio_player", "pw-play")
        subprocess.run([player, temp_audio], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        
    except urllib.error.URLError:
        print(f"\n[Voicebox: Off - Could not connect to Voicebox at {config['voicebox_url']}]")
    except Exception as e:
        print(f"\n[Audio Playback Error: {e}]")

def query_deepseek(messages):
    url = "https://api.deepseek.com/chat/completions"
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {api_key}"
    }
    payload = {
        "model": config["deepseek_model"],
        "messages": messages,
        "stream": False
    }
    
    req = urllib.request.Request(
        url, 
        data=json.dumps(payload).encode("utf-8"), 
        headers=headers, 
        method="POST"
    )
    
    try:
        print("AI is thinking...", end="\r")
        with urllib.request.urlopen(req) as response:
            res_data = json.loads(response.read().decode("utf-8"))
            return res_data["choices"][0]["message"]["content"]
    except urllib.error.HTTPError as e:
        error_body = e.read().decode("utf-8")
        print(f"\nAPI Error: {e.code} - {error_body}")
        return None
    except Exception as e:
        print(f"\nConnection Error: {e}")
        return None

def main():
    print("=" * 60)
    print("        🤖 AI VOICE TALKBACK CHAT (DEEPSEEK + VOICEBOX)        ")
    print("=" * 60)
    print("Instructions:")
    print("  1. Ensure Voicebox is running in the background.")
    print("  2. Use F7 or F1 to dictate your message, then press Enter.")
    print("  3. Type 'exit' or 'quit' to end the session.")
    print("-" * 60)
    
    messages = [
        {"role": "system", "content": config["system_prompt"]}
    ]
    
    while True:
        try:
            user_input = input("\nYou: ").strip()
            if not user_input:
                continue
            if user_input.lower() in ["exit", "quit"]:
                print("Goodbye!")
                break
                
            messages.append({"role": "user", "content": user_input})
            
            # Send message to DeepSeek
            answer = query_deepseek(messages)
            if answer:
                print(f"\nAI: {answer}")
                messages.append({"role": "assistant", "content": answer})
                
                # Convert response to speech and play it
                speak_text(answer)
                
        except KeyboardInterrupt:
            print("\nGoodbye!")
            break

if __name__ == "__main__":
    main()
