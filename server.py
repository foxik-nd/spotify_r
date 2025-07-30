from fastapi import FastAPI, HTTPException
from fastapi.responses import RedirectResponse
import requests
import base64
from urllib.parse import urlencode

CLIENT_ID = ''
CLIENT_SECRET = ''
REDIRECT_URI = "http://localhost:8000/callback"
AUTH_URL = "https://accounts.spotify.com/authorize"
TOKEN_URL = "https://accounts.spotify.com/api/token"

app = FastAPI()
current_token = None

@app.get("/")
async def home():
    return {"message": "Bienvenue", "login_url": "/login"}

@app.get("/login")
async def login():
    params = {
        "client_id": CLIENT_ID,
        "response_type": "code",
        "redirect_uri": REDIRECT_URI,
        "scope": "user-read-private user-read-email user-top-read",
    }
    return RedirectResponse(f"{AUTH_URL}?{urlencode(params)}")

@app.get("/callback")
async def callback(code: str):
    auth_header = base64.b64encode(f"{CLIENT_ID}:{CLIENT_SECRET}".encode()).decode()
    headers = {"Authorization": f"Basic {auth_header}"}
    data = {"grant_type": "authorization_code", "code": code, "redirect_uri": REDIRECT_URI}
    response = requests.post(TOKEN_URL, headers=headers, data=data)
    if response.status_code == 200:
        global current_token
        current_token = response.json()
        return {"message": "Authentification réussie", "token_info": current_token}
    raise HTTPException(status_code=400, detail="Erreur lors de l'échange du token")

@app.get("/me")
async def get_me():
    if not current_token:
        raise HTTPException(status_code=401, detail="Non authentifié")
    headers = {"Authorization": f"Bearer {current_token['access_token']}"}
    response = requests.get("https://api.spotify.com/v1/me", headers=headers)
    return response.json() if response.status_code == 200 else HTTPException(status_code=response.status_code)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
