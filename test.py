from google import genai

client = genai.Client(
    api_key="AQ.Ab8RN6I2l55fqGg4c5Yk0IPoLWR8RS-_qUYB1gvT_91UVMiWcQ"
)

response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents="Hello, are you working?"
)

print(response.text)