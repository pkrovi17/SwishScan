#!/usr/bin/env python3
"""
Client script for testing SwishScan FastAPI endpoints
"""

import requests
import json
import os
from pathlib import Path

class SwishScanClient:
    def __init__(self, base_url="http://localhost:8000"):
        self.base_url = base_url
        
    def check_status(self):
        """Check API status"""
        try:
            response = requests.get(f"{self.base_url}/api/status")
            if response.status_code == 200:
                return response.json()
            else:
                print(f"Status check failed: {response.status_code}")
                return None
        except requests.exceptions.RequestException as e:
            print(f"Connection error: {e}")
            return None
    
    def upload_video(self, video_path):
        """Upload and process a video"""
        if not os.path.exists(video_path):
            print(f"Video file not found: {video_path}")
            return None
            
        try:
            with open(video_path, 'rb') as f:
                files = {'video': (os.path.basename(video_path), f, 'video/mp4')}
                response = requests.post(f"{self.base_url}/upload", files=files)
                
            if response.status_code == 200:
                return response.json()
            else:
                print(f"Upload failed: {response.status_code}")
                print(f"Error: {response.text}")
                return None
                
        except requests.exceptions.RequestException as e:
            print(f"Upload error: {e}")
            return None
    
    def download_results(self, filename):
        """Download analysis results"""
        try:
            response = requests.get(f"{self.base_url}/results/{filename}")
            if response.status_code == 200:
                return response.json()
            else:
                print(f"Download failed: {response.status_code}")
                return None
        except requests.exceptions.RequestException as e:
            print(f"Download error: {e}")
            return None
    
    def list_shots(self):
        """List all processed shots"""
        try:
            response = requests.get(f"{self.base_url}/api/shots")
            if response.status_code == 200:
                return response.json()
            else:
                print(f"List shots failed: {response.status_code}")
                return None
        except requests.exceptions.RequestException as e:
            print(f"List shots error: {e}")
            return None
    
    def delete_results(self, filename):
        """Delete a results file"""
        try:
            response = requests.delete(f"{self.base_url}/api/results/{filename}")
            if response.status_code == 200:
                return response.json()
            else:
                print(f"Delete failed: {response.status_code}")
                return None
        except requests.exceptions.RequestException as e:
            print(f"Delete error: {e}")
            return None

def main():
    """Main function to demonstrate client usage"""
    print("🏀 SwishScan FastAPI Client")
    print("=" * 40)
    
    client = SwishScanClient()
    
    # Check API status
    print("1. Checking API status...")
    status = client.check_status()
    if status:
        print(f"✓ API is running")
        print(f"  Status: {status['status']}")
        print(f"  Max file size: {status['max_file_size_mb']}MB")
        print(f"  Allowed extensions: {', '.join(status['allowed_extensions'])}")
    else:
        print("✗ API is not running. Please start the server with: python run.py")
        return
    
    # List existing shots
    print("\n2. Listing existing shots...")
    shots = client.list_shots()
    if shots:
        print(f"✓ Found {shots['total_files']} processed files")
        for file_info in shots['files'][:3]:  # Show first 3
            print(f"  - {file_info['filename']} ({file_info['size_bytes']} bytes)")
    else:
        print("✗ Could not list shots")
    
    # Upload video (if provided)
    video_path = input("\nEnter path to video file (or press Enter to skip): ").strip()
    if video_path:
        print(f"3. Uploading video: {video_path}")
        result = client.upload_video(video_path)
        if result:
            print(f"✓ Upload successful!")
            print(f"  Total shots: {result['total_shots']}")
            print(f"  Results file: {result['results_file']}")
            
            # Download and display results
            print("\n4. Downloading results...")
            results = client.download_results(os.path.basename(result['results_file']))
            if results:
                print(f"✓ Results downloaded successfully")
                print(f"  Processing status: {results['processing_status']}")
                print(f"  Total shots detected: {results['total_shots']}")
                
                # Display shot details
                for i, shot in enumerate(results['shots'][:2]):  # Show first 2 shots
                    print(f"\n  Shot {i+1} ({shot['shot_id']}):")
                    print(f"    Duration: {shot['segment_info']['duration']:.2f}s")
                    print(f"    Frames: {shot['analysis']['frame_count']}")
                    print(f"    Resolution: {shot['analysis']['resolution']}")
                    print(f"    Avg Motion: {shot['analysis']['motion_analysis']['avg_motion']:.1f}")
        else:
            print("✗ Upload failed")
    else:
        print("3. Skipping video upload")
    
    print("\n" + "=" * 40)
    print("Client demonstration complete!")
    print("You can also access the API documentation at:")
    print(f"  - Swagger UI: {client.base_url}/docs")
    print(f"  - ReDoc: {client.base_url}/redoc")

if __name__ == "__main__":
    main() 