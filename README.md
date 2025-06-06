# 📥 YT Downloader - YouTube Video Downloader App

🚀 **A Cross-Platform YouTube Video Downloader App built using Flutter & FastAPI**

YT Downloader is an educational mobile application that demonstrates how YouTube videos can be downloaded within a Flutter app using a Python backend (FastAPI). This project showcases full-stack mobile development, API integration, and file handling techniques.

> ⚠️ **Disclaimer**  
> This project is intended strictly for **educational and learning purposes only**. It does **not** promote the downloading of copyrighted material or violate [YouTube’s Terms of Service](https://www.youtube.com/t/terms).  
> Please use this app responsibly.

---

## ✨ Features

- 📱 Beautiful splash screen with smooth UI transitions
- 🔗 Paste any valid YouTube URL to fetch video metadata
- 🖼️ Preview video thumbnail, title, and duration
- 🎞️ Choose from multiple formats and resolutions
- 📊 Real-time download progress with visual indicator
- 📁 Download management with storage permission handling (Android)
- ⚡ Fast and reliable downloads using Dio
- 🔌 Backend API (FastAPI) handles video metadata extraction and streaming

---

## 🧰 Tech Stack

### Frontend (Mobile App)
- **Flutter (Dart)**
- **Dio** – for file downloading
- **Provider** – for state management
- **Material UI** – for clean and responsive UI
- **android_path_provider** & **permission_handler** – for file access and permissions

### Backend (API Server)
- **Python** with **FastAPI**
- **pytube / yt-dlp** – for retrieving metadata and video streams
- **Uvicorn** – ASGI server for running FastAPI app

---

## 📷 Screenshots
![IMG_20250505_004203_939](https://github.com/user-attachments/assets/d7e6d9dc-396c-42d7-8794-25d877c9a02a)
