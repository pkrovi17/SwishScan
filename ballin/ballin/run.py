#!/usr/bin/env python3
"""
Startup script for SwishScan FastAPI application
"""

import os
import sys
from pathlib import Path
import uvicorn

def main():
    """Start the FastAPI application"""
    print("🏀 Starting SwishScan Basketball Analysis API...")
    print("=" * 50)
    
    # Check if required directories exist
    required_dirs = ['uploads', 'results']
    for dir_name in required_dirs:
        if not os.path.exists(dir_name):
            os.makedirs(dir_name)
            print(f"✓ Created directory: {dir_name}")
    
    # Import and run the FastAPI app
    try:
        from app import app
        print("✓ FastAPI app loaded successfully")
        print("✓ API documentation will be available at:")
        print("  - Swagger UI: http://localhost:8000/docs")
        print("  - ReDoc: http://localhost:8000/redoc")
        print("✓ API root: http://localhost:8000")
        print("✓ Press Ctrl+C to stop the server")
        print("=" * 50)
        
        uvicorn.run(
            "app:app",
            host="0.0.0.0",
            port=8000,
            reload=True,
            log_level="info"
        )
        
    except ImportError as e:
        print(f"✗ Error importing FastAPI app: {e}")
        print("Please ensure all dependencies are installed:")
        print("pip install -r requirements.txt")
    except Exception as e:
        print(f"✗ Error starting FastAPI app: {e}")

if __name__ == "__main__":
    main() 