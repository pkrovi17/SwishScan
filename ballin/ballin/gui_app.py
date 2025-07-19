#!/usr/bin/env python3
"""
SwishScan Basketball Analysis - Desktop GUI Application
Uses FastAPI backend for processing
"""

import tkinter as tk
from tkinter import ttk, filedialog, messagebox, scrolledtext
import threading
import requests
import json
import os
from pathlib import Path
from datetime import datetime

class SwishScanGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("🏀 SwishScan Basketball Analysis")
        self.root.geometry("800x600")
        self.root.configure(bg='#f0f0f0')
        
        # API configuration
        self.api_url = "http://localhost:8000"
        self.is_processing = False
        
        self.setup_ui()
        self.check_api_status()
    
    def setup_ui(self):
        """Setup the user interface"""
        # Main frame
        main_frame = ttk.Frame(self.root, padding="10")
        main_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # Configure grid weights
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)
        main_frame.columnconfigure(1, weight=1)
        
        # Title
        title_label = ttk.Label(main_frame, text="🏀 SwishScan Basketball Analysis", 
                               font=('Arial', 16, 'bold'))
        title_label.grid(row=0, column=0, columnspan=3, pady=(0, 20))
        
        # API Status
        self.status_frame = ttk.LabelFrame(main_frame, text="API Status", padding="10")
        self.status_frame.grid(row=1, column=0, columnspan=3, sticky=(tk.W, tk.E), pady=(0, 20))
        
        self.status_label = ttk.Label(self.status_frame, text="Checking API status...")
        self.status_label.grid(row=0, column=0, sticky=tk.W)
        
        # Video Selection
        video_frame = ttk.LabelFrame(main_frame, text="Video Selection", padding="10")
        video_frame.grid(row=2, column=0, columnspan=3, sticky=(tk.W, tk.E), pady=(0, 20))
        video_frame.columnconfigure(1, weight=1)
        
        ttk.Label(video_frame, text="Video File:").grid(row=0, column=0, sticky=tk.W, padx=(0, 10))
        
        self.video_path_var = tk.StringVar()
        self.video_entry = ttk.Entry(video_frame, textvariable=self.video_path_var, width=50)
        self.video_entry.grid(row=0, column=1, sticky=(tk.W, tk.E), padx=(0, 10))
        
        self.browse_btn = ttk.Button(video_frame, text="Browse", command=self.browse_video)
        self.browse_btn.grid(row=0, column=2)
        
        # Process Button
        self.process_btn = ttk.Button(main_frame, text="Process Video", 
                                     command=self.process_video, state='disabled')
        self.process_btn.grid(row=3, column=0, columnspan=3, pady=(0, 20))
        
        # Progress Bar
        self.progress_var = tk.DoubleVar()
        self.progress_bar = ttk.Progressbar(main_frame, variable=self.progress_var, 
                                           maximum=100, mode='indeterminate')
        self.progress_bar.grid(row=4, column=0, columnspan=3, sticky=(tk.W, tk.E), pady=(0, 20))
        
        # Results Area
        results_frame = ttk.LabelFrame(main_frame, text="Analysis Results", padding="10")
        results_frame.grid(row=5, column=0, columnspan=3, sticky=(tk.W, tk.E, tk.N, tk.S), pady=(0, 20))
        results_frame.columnconfigure(0, weight=1)
        results_frame.rowconfigure(0, weight=1)
        main_frame.rowconfigure(5, weight=1)
        
        # Results text area
        self.results_text = scrolledtext.ScrolledText(results_frame, height=15, width=80)
        self.results_text.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # Buttons frame
        buttons_frame = ttk.Frame(main_frame)
        buttons_frame.grid(row=6, column=0, columnspan=3, pady=(10, 0))
        
        self.save_btn = ttk.Button(buttons_frame, text="Save Results", 
                                  command=self.save_results, state='disabled')
        self.save_btn.pack(side=tk.LEFT, padx=(0, 10))
        
        self.clear_btn = ttk.Button(buttons_frame, text="Clear Results", 
                                   command=self.clear_results)
        self.clear_btn.pack(side=tk.LEFT)
    
    def check_api_status(self):
        """Check if the API server is running"""
        def check():
            try:
                response = requests.get(f"{self.api_url}/api/status", timeout=5)
                if response.status_code == 200:
                    data = response.json()
                    self.root.after(0, self.update_status, True, data)
                else:
                    self.root.after(0, self.update_status, False, None)
            except requests.exceptions.RequestException:
                self.root.after(0, self.update_status, False, None)
        
        threading.Thread(target=check, daemon=True).start()
    
    def update_status(self, is_online, data):
        """Update the API status display"""
        if is_online:
            self.status_label.config(text=f"✓ API Online - Max file size: {data['max_file_size_mb']}MB")
            self.status_label.config(foreground='green')
            self.process_btn.config(state='normal')
        else:
            self.status_label.config(text="✗ API Offline - Start server with: python run.py")
            self.status_label.config(foreground='red')
            self.process_btn.config(state='disabled')
    
    def browse_video(self):
        """Open file dialog to select video"""
        filetypes = [
            ('Video files', '*.mp4 *.avi *.mov *.mkv *.wmv *.flv *.webm'),
            ('All files', '*.*')
        ]
        filename = filedialog.askopenfilename(
            title="Select Basketball Video",
            filetypes=filetypes
        )
        if filename:
            self.video_path_var.set(filename)
    
    def process_video(self):
        """Process the selected video using the API"""
        video_path = self.video_path_var.get()
        if not video_path:
            messagebox.showerror("Error", "Please select a video file")
            return
        
        if not os.path.exists(video_path):
            messagebox.showerror("Error", "Video file not found")
            return
        
        if self.is_processing:
            messagebox.showwarning("Warning", "Already processing a video")
            return
        
        self.is_processing = True
        self.process_btn.config(state='disabled')
        self.progress_bar.start()
        self.results_text.delete(1.0, tk.END)
        self.results_text.insert(tk.END, "Processing video...\n")
        
        # Run processing in background thread
        threading.Thread(target=self._process_video_thread, args=(video_path,), daemon=True).start()
    
    def _process_video_thread(self, video_path):
        """Process video in background thread"""
        try:
            # Upload video to API
            with open(video_path, 'rb') as f:
                files = {'video': (os.path.basename(video_path), f, 'video/mp4')}
                response = requests.post(f"{self.api_url}/upload", files=files)
            
            if response.status_code == 200:
                result = response.json()
                self.root.after(0, self._show_results, result)
            else:
                error_msg = f"Upload failed: {response.status_code}\n{response.text}"
                self.root.after(0, self._show_error, error_msg)
                
        except Exception as e:
            self.root.after(0, self._show_error, f"Error: {str(e)}")
        finally:
            self.root.after(0, self._processing_complete)
    
    def _show_results(self, result):
        """Display processing results"""
        self.results_text.delete(1.0, tk.END)
        
        # Display summary
        summary = f"""🏀 Analysis Complete!

📊 Summary:
• Total shots detected: {result['total_shots']}
• Processing status: {result['status']}
• Timestamp: {result['timestamp']}

📁 Results saved to: {result['results_file']}

"""
        self.results_text.insert(tk.END, summary)
        
        # Try to get detailed results
        try:
            filename = os.path.basename(result['results_file'])
            response = requests.get(f"{self.api_url}/results/{filename}")
            if response.status_code == 200:
                detailed_results = response.json()
                self._display_detailed_results(detailed_results)
        except Exception as e:
            self.results_text.insert(tk.END, f"Could not load detailed results: {e}\n")
        
        self.save_btn.config(state='normal')
    
    def _display_detailed_results(self, results):
        """Display detailed shot analysis"""
        self.results_text.insert(tk.END, "📈 Shot Analysis:\n")
        self.results_text.insert(tk.END, "=" * 50 + "\n\n")
        
        for i, shot in enumerate(results['shots'], 1):
            shot_info = f"""Shot {i} ({shot['shot_id']}):
• Duration: {shot['segment_info']['duration']:.2f}s
• Frames: {shot['analysis']['frame_count']}
• Resolution: {shot['analysis']['resolution']}
• Avg Motion: {shot['analysis']['motion_analysis']['avg_motion']:.1f}
• Max Motion: {shot['analysis']['motion_analysis']['max_motion']:.1f}
• Motion Variance: {shot['analysis']['motion_analysis']['motion_variance']:.1f}

"""
            self.results_text.insert(tk.END, shot_info)
    
    def _show_error(self, error_msg):
        """Display error message"""
        self.results_text.delete(1.0, tk.END)
        self.results_text.insert(tk.END, f"❌ Error:\n{error_msg}")
    
    def _processing_complete(self):
        """Called when processing is complete"""
        self.is_processing = False
        self.process_btn.config(state='normal')
        self.progress_bar.stop()
    
    def save_results(self):
        """Save results to file"""
        content = self.results_text.get(1.0, tk.END)
        if not content.strip():
            messagebox.showwarning("Warning", "No results to save")
            return
        
        filename = filedialog.asksaveasfilename(
            title="Save Results",
            defaultextension=".txt",
            filetypes=[("Text files", "*.txt"), ("All files", "*.*")]
        )
        
        if filename:
            try:
                with open(filename, 'w') as f:
                    f.write(content)
                messagebox.showinfo("Success", f"Results saved to {filename}")
            except Exception as e:
                messagebox.showerror("Error", f"Could not save file: {e}")
    
    def clear_results(self):
        """Clear the results area"""
        self.results_text.delete(1.0, tk.END)
        self.save_btn.config(state='disabled')

def main():
    """Main function"""
    root = tk.Tk()
    app = SwishScanGUI(root)
    root.mainloop()

if __name__ == "__main__":
    main() 