#!/usr/bin/env python3
"""
Test script for the basketball video standardizer and FastAPI application
"""

import os
import sys
from pathlib import Path

# Add the pre_analysis directory to the path
sys.path.append(str(Path(__file__).parent / "pre_analysis"))

from standardizer import VideoStandardizer

def test_standardizer():
    """
    Test the video standardizer with a sample video
    """
    print("Testing Basketball Video Standardizer")
    print("=" * 50)
    
    # Initialize the standardizer
    standardizer = VideoStandardizer()
    
    # Test video path - replace with your actual video file
    test_video_path = input("Enter path to test video (or press Enter to skip): ").strip()
    
    if not test_video_path:
        print("No video provided. Creating sample data structure...")
        
        # Create sample data structure
        sample_shot_data = [
            {
                "shot_id": "shot_001",
                "segment_info": {
                    "start_frame": 0,
                    "end_frame": 90,
                    "start_time": 0.0,
                    "end_time": 3.0,
                    "duration": 3.0
                },
                "analysis": {
                    "frame_count": 90,
                    "duration": 3.0,
                    "resolution": "1920x1080",
                    "fps": 30.0,
                    "motion_analysis": {
                        "max_motion": 45.2,
                        "avg_motion": 23.1,
                        "motion_variance": 156.7
                    }
                },
                "timestamp": "2024-01-01T12:00:00"
            }
        ]
        
        # Save sample data
        standardizer.save_standardized_data(sample_shot_data, "sample_standardized_shots.json")
        print("Sample data created and saved to 'sample_standardized_shots.json'")
        
    else:
        # Test with actual video
        if not os.path.exists(test_video_path):
            print(f"Error: Video file not found: {test_video_path}")
            return
        
        try:
            print(f"Processing video: {test_video_path}")
            
            # Process the video
            shot_data = standardizer.standardize_video(test_video_path)
            
            # Save results
            standardizer.save_standardized_data(shot_data, "test_standardized_shots.json")
            
            print(f"\nProcessing complete!")
            print(f"Total shots detected: {len(shot_data)}")
            
            # Display summary of each shot
            for i, shot in enumerate(shot_data):
                print(f"\nShot {i+1}:")
                print(f"  ID: {shot['shot_id']}")
                print(f"  Duration: {shot['segment_info']['duration']:.2f}s")
                print(f"  Frames: {shot['analysis']['frame_count']}")
                print(f"  Resolution: {shot['analysis']['resolution']}")
                
        except Exception as e:
            print(f"Error processing video: {str(e)}")

def test_fastapi_app():
    """
    Test the FastAPI application endpoints
    """
    print("\nTesting FastAPI Application")
    print("=" * 30)
    
    try:
        from app import app
        print("✓ FastAPI app imported successfully")
        
        # Test app configuration
        from app import UPLOAD_FOLDER, RESULTS_FOLDER, MAX_FILE_SIZE, ALLOWED_EXTENSIONS
        print(f"✓ Upload folder: {UPLOAD_FOLDER}")
        print(f"✓ Results folder: {RESULTS_FOLDER}")
        print(f"✓ Max file size: {MAX_FILE_SIZE / (1024*1024):.0f}MB")
        print(f"✓ Allowed extensions: {', '.join(ALLOWED_EXTENSIONS)}")
        
        # Test Pydantic models
        from app import ProcessingResponse, AnalysisResult, ErrorResponse
        print("✓ Pydantic models loaded successfully")
        
        print("\nFastAPI app is ready to run!")
        print("Run 'python run.py' or 'python app.py' to start the API server")
        print("API documentation will be available at:")
        print("  - http://localhost:8000/docs (Swagger UI)")
        print("  - http://localhost:8000/redoc (ReDoc)")
        
    except ImportError as e:
        print(f"✗ Error importing FastAPI app: {e}")
    except Exception as e:
        print(f"✗ Error testing FastAPI app: {e}")

def test_api_endpoints():
    """
    Test API endpoints using requests (if available)
    """
    print("\nTesting API Endpoints")
    print("=" * 25)
    
    try:
        import requests
        import time
        
        # Start the server in background (this would need to be done manually)
        print("Note: Make sure the FastAPI server is running on http://localhost:8000")
        print("You can start it with: python run.py")
        
        # Test root endpoint
        try:
            response = requests.get("http://localhost:8000/", timeout=5)
            if response.status_code == 200:
                print("✓ Root endpoint working")
                data = response.json()
                print(f"  Message: {data.get('message')}")
                print(f"  Version: {data.get('version')}")
            else:
                print(f"✗ Root endpoint failed: {response.status_code}")
        except requests.exceptions.RequestException:
            print("✗ Could not connect to API server")
            print("  Make sure the server is running on http://localhost:8000")
        
        # Test status endpoint
        try:
            response = requests.get("http://localhost:8000/api/status", timeout=5)
            if response.status_code == 200:
                print("✓ Status endpoint working")
                data = response.json()
                print(f"  Status: {data.get('status')}")
                print(f"  Max file size: {data.get('max_file_size_mb')}MB")
            else:
                print(f"✗ Status endpoint failed: {response.status_code}")
        except requests.exceptions.RequestException:
            print("✗ Could not connect to status endpoint")
            
    except ImportError:
        print("✗ Requests library not available. Install with: pip install requests")
    except Exception as e:
        print(f"✗ Error testing API endpoints: {e}")

if __name__ == "__main__":
    test_standardizer()
    test_fastapi_app()
    test_api_endpoints() 