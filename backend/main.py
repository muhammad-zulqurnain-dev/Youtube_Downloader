from fastapi import FastAPI, Form
from fastapi.middleware.cors import CORSMiddleware
from utils.downloader import get_video_info, download_video

app = FastAPI()

# Allow Flutter Web/App to communicate
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.post("/info")
def fetch_info(url: str = Form(...)):
    return get_video_info(url)

@app.post("/download")
def download(url: str = Form(...), format_code: str = Form(...)):
    return download_video(url, format_code)
