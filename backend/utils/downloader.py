import yt_dlp
import os
from fastapi.responses import FileResponse
DOWNLOAD_DIR = "/storage/emulated/0/Download"

def get_video_info(url):
    try:
        ydl_opts = {"quiet": True}
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=False)
            formats = [
                {
                    "format_id": f["format_id"],
                    "format": f"{f['ext'].upper()} - {f.get('format_note', '')}",
                    "resolution": f.get("resolution", ""),
                }
                for f in info["formats"]
                if f.get("vcodec") != "none" or f.get("acodec") != "none"
            ]

            return {
                "title": info.get("title"),
                "duration": info.get("duration"),
                "thumbnail": info.get("thumbnail"),
                "formats": formats,
            }
    except Exception as e:
        return {"error": str(e)}

def download_video(url, format_code):
    try:
        ydl_opts = {
            "format": format_code,
            "outtmpl": os.path.join(DOWNLOAD_DIR, "%(title)s.%(ext)s"),
        }
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info_dict = ydl.extract_info(url, download=True)
            filename = ydl.prepare_filename(info_dict)

        return FileResponse(
            path=filename,
            filename=os.path.basename(filename),
            media_type='application/octet-stream',
        )
    except Exception as e:
        return {"status": "failed", "message": str(e)}
