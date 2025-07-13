from fastapi import FastAPI, File, UploadFile, HTTPException, BackgroundTasks
from fastapi.responses import JSONResponse, FileResponse
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
import os
import sys
from pathlib import Path
import cv2
import numpy as np
from typing import List, Dict, Any
import json
import uuid
from datetime import datetime
import asyncio
from pydantic import BaseModel

# Add the pre_analysis directory to the path
current_dir = Path(__file__).parent
pre_analysis_path = current_dir / "pre_analysis"
sys.path.insert(0, str(pre_analysis_path))

try:
    from pre_analysis.standardizer import VideoStandardizer
except ImportError as e:
    print(f"Error importing standardizer: {e}")
    print(f"Looking for standardizer.py in: {pre_analysis_path}")
    print(f"Current sys.path: {sys.path}")
    raise

# FastAPI app configuration
app = FastAPI(
    title="SwishScan Basketball Analysis API",
    description="A FastAPI-based basketball shot analysis application",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS middleware for web interface
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configuration
UPLOAD_FOLDER = 'uploads'
RESULTS_FOLDER = 'results'
MAX_FILE_SIZE = 100 * 1024 * 1024  # 100MB
ALLOWED_EXTENSIONS = {'mp4', 'avi', 'mov', 'mkv', 'wmv', 'flv', 'webm'}

# Ensure directories exist
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(RESULTS_FOLDER, exist_ok=True)

# Pydantic models for API documentation
class AnalysisResult(BaseModel):
    shot_id: str
    segment_info: Dict[str, Any]
    analysis: Dict[str, Any]
    timestamp: str

class ProcessingResponse(BaseModel):
    status: str
    message: str
    total_shots: int
    results_file: str
    timestamp: str

class ErrorResponse(BaseModel):
    error: str
    status: str
    timestamp: str

def allowed_file(filename: str) -> bool:
    """Check if the uploaded file has an allowed extension"""
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

class BasketballAnalysisApp:
    def __init__(self):
        self.standardizer = VideoStandardizer()
        
    async def process_video(self, video_path: str) -> Dict[str, Any]:
        """
        Process a basketball video and return analysis results
        
        Args:
            video_path (str): Path to the uploaded video file
            
        Returns:
            Dict containing processed shot data and analysis results
        """
        try:
            # Validate video file exists
            if not os.path.exists(video_path):
                raise FileNotFoundError(f"Video file not found: {video_path}")
            
            print(f"Processing video: {video_path}")
            
            # Run standardizer in a thread pool to avoid blocking
            loop = asyncio.get_event_loop()
            shot_data = await loop.run_in_executor(
                None, self.standardizer.standardize_video, video_path
            )
            
            # Process each shot and return results
            results = {
                "original_video": video_path,
                "total_shots": len(shot_data),
                "shots": shot_data,
                "processing_status": "completed",
                "timestamp": datetime.now().isoformat()
            }
            
            return results
            
        except Exception as e:
            print(f"Error processing video: {str(e)}")
            return {
                "error": str(e),
                "processing_status": "failed",
                "timestamp": datetime.now().isoformat()
            }
    
    def save_results(self, results: Dict[str, Any], output_path: str = None) -> str:
        """
        Save the analysis results to a JSON file
        
        Args:
            results (Dict): Analysis results from process_video
            output_path (str): Optional path to save results
            
        Returns:
            Path to the saved results file
        """
        if output_path is None:
            output_path = os.path.join(RESULTS_FOLDER, f"analysis_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json")
            
        with open(output_path, 'w') as f:
            json.dump(results, f, indent=2, default=str)
        
        print(f"Results saved to: {output_path}")
        return output_path

# Initialize the basketball analysis app
basketball_app = BasketballAnalysisApp()

@app.get("/", response_class=JSONResponse)
async def root():
    """Root endpoint with API information"""
    return {
        "message": "SwishScan Basketball Analysis API",
        "version": "1.0.0",
        "docs": "/docs",
        "endpoints": {
            "upload": "/upload",
            "status": "/api/status",
            "results": "/results/{filename}"
        }
    }

@app.post("/upload", response_model=ProcessingResponse)
async def upload_video(
    background_tasks: BackgroundTasks,
    video: UploadFile = File(...)
):
    """
    Upload and process a basketball video
    
    - **video**: Basketball video file (MP4, AVI, MOV, MKV, WMV, FLV, WEBM)
    - **Returns**: Processing results with shot analysis
    """
    try:
        # Validate file size
        if video.size and video.size > MAX_FILE_SIZE:
            raise HTTPException(
                status_code=413,
                detail=f"File too large. Maximum size is {MAX_FILE_SIZE / (1024*1024):.0f}MB"
            )
        
        # Check file extension
        if not allowed_file(video.filename):
            raise HTTPException(
                status_code=400,
                detail=f"Invalid file type. Allowed types: {', '.join(ALLOWED_EXTENSIONS)}"
            )
        
        # Generate unique filename
        filename = video.filename
        unique_filename = f"{uuid.uuid4().hex}_{filename}"
        file_path = os.path.join(UPLOAD_FOLDER, unique_filename)
        
        # Save uploaded file
        with open(file_path, "wb") as buffer:
            content = await video.read()
            buffer.write(content)
        
        # Process the video
        results = await basketball_app.process_video(file_path)
        
        if results.get("processing_status") == "failed":
            raise HTTPException(
                status_code=500,
                detail=results.get("error", "Video processing failed")
            )
        
        # Save results to file
        results_file = basketball_app.save_results(results)
        
        # Clean up uploaded video file in background
        background_tasks.add_task(cleanup_file, file_path)
        
        return ProcessingResponse(
            status="success",
            message="Video processed successfully",
            total_shots=results["total_shots"],
            results_file=results_file,
            timestamp=results["timestamp"]
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

async def cleanup_file(file_path: str):
    """Clean up uploaded file after processing"""
    try:
        if os.path.exists(file_path):
            os.remove(file_path)
            print(f"Cleaned up file: {file_path}")
    except Exception as e:
        print(f"Error cleaning up file {file_path}: {e}")

@app.get("/results/{filename}")
async def download_results(filename: str):
    """
    Download analysis results file
    
    - **filename**: Name of the results file to download
    - **Returns**: File download response
    """
    try:
        file_path = os.path.join(RESULTS_FOLDER, filename)
        if os.path.exists(file_path):
            return FileResponse(
                path=file_path,
                filename=filename,
                media_type='application/json'
            )
        else:
            raise HTTPException(status_code=404, detail="Results file not found")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/status", response_class=JSONResponse)
async def api_status():
    """API status endpoint"""
    return {
        "status": "running",
        "timestamp": datetime.now().isoformat(),
        "upload_folder": UPLOAD_FOLDER,
        "results_folder": RESULTS_FOLDER,
        "max_file_size_mb": MAX_FILE_SIZE / (1024*1024),
        "allowed_extensions": list(ALLOWED_EXTENSIONS)
    }

@app.get("/api/shots", response_class=JSONResponse)
async def list_processed_shots():
    """List all processed shot analysis files"""
    try:
        files = []
        for filename in os.listdir(RESULTS_FOLDER):
            if filename.endswith('.json'):
                file_path = os.path.join(RESULTS_FOLDER, filename)
                stat = os.stat(file_path)
                files.append({
                    "filename": filename,
                    "size_bytes": stat.st_size,
                    "created": datetime.fromtimestamp(stat.st_ctime).isoformat(),
                    "modified": datetime.fromtimestamp(stat.st_mtime).isoformat()
                })
        
        return {
            "total_files": len(files),
            "files": sorted(files, key=lambda x: x["modified"], reverse=True)
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/api/results/{filename}")
async def delete_results(filename: str):
    """
    Delete a results file
    
    - **filename**: Name of the results file to delete
    - **Returns**: Deletion confirmation
    """
    try:
        file_path = os.path.join(RESULTS_FOLDER, filename)
        if os.path.exists(file_path):
            os.remove(file_path)
            return {"message": f"File {filename} deleted successfully"}
        else:
            raise HTTPException(status_code=404, detail="Results file not found")
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Serve static files for web interface (optional)
if os.path.exists("static"):
    app.mount("/static", StaticFiles(directory="static"), name="static")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True) 