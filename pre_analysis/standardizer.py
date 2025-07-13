import cv2
import numpy as np
import os
import json
from typing import List, Dict, Any, Tuple, Optional
from pathlib import Path
import tempfile
from datetime import datetime
import mediapipe as mp

class VideoStandardizer:
    def __init__(self):
        self.min_shot_duration = 1.0  # Minimum shot duration in seconds
        self.max_shot_duration = 10.0  # Maximum shot duration in seconds
        self.motion_threshold = 0.1  # Threshold for motion detection
        self.frame_rate = 30  # Target frame rate for standardization
        
        # Create tracked_data directory
        self.tracked_data_dir = "tracked_data"
        os.makedirs(self.tracked_data_dir, exist_ok=True)
        
        # Initialize MediaPipe for pose and hand tracking
        self.mp_pose = mp.solutions.pose
        self.mp_hands = mp.solutions.hands
        self.mp_drawing = mp.solutions.drawing_utils
        self.mp_drawing_styles = mp.solutions.drawing_styles
        
        # Pose detection settings
        self.pose = self.mp_pose.Pose(
            min_detection_confidence=0.5,
            min_tracking_confidence=0.5,
            model_complexity=1
        )
        
        # Hand detection settings
        self.hands = self.mp_hands.Hands(
            min_detection_confidence=0.5,
            min_tracking_confidence=0.5,
            max_num_hands=2
        )
        
    def standardize_video(self, video_path: str) -> List[Dict[str, Any]]:
        """
        Main function to standardize a basketball video and split into individual shots
        
        Args:
            video_path (str): Path to the input video file
            
        Returns:
            List of dictionaries containing standardized shot data
        """
        print(f"Starting video standardization for: {video_path}")
        
        # Step 1: Load and validate video
        cap = cv2.VideoCapture(video_path)
        if not cap.isOpened():
            raise ValueError(f"Could not open video file: {video_path}")
        
        # Get video properties
        fps = cap.get(cv2.CAP_PROP_FPS)
        total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
        height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
        duration = total_frames / fps
        
        print(f"Video properties: {width}x{height}, {fps} FPS, {duration:.2f}s duration")
        
        # Step 2: Detect shot segments
        shot_segments = self._detect_shot_segments(cap, fps)
        cap.release()
        
        print(f"Detected {len(shot_segments)} shot segments")
        
        # Step 3: Process each shot segment
        standardized_shots = []
        for i, segment in enumerate(shot_segments):
            print(f"Processing shot {i+1}/{len(shot_segments)}")
            shot_data = self._process_shot_segment(video_path, segment, i)
            if shot_data:
                standardized_shots.append(shot_data)
        
        return standardized_shots
    
    def _detect_shot_segments(self, cap: cv2.VideoCapture, fps: float) -> List[Dict[str, Any]]:
        """
        Detect individual shot segments in the video using motion analysis
        
        Args:
            cap: OpenCV video capture object
            fps: Frames per second of the video
            
        Returns:
            List of shot segment dictionaries with start/end frame info
        """
        segments = []
        frame_count = 0
        motion_scores = []
        prev_frame = None
        
        # Calculate motion scores for each frame
        while True:
            ret, frame = cap.read()
            if not ret:
                break
                
            # Convert to grayscale for motion detection
            gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
            gray = cv2.GaussianBlur(gray, (21, 21), 0)
            
            if prev_frame is not None:
                # Calculate frame difference
                frame_diff = cv2.absdiff(prev_frame, gray)
                motion_score = np.mean(frame_diff) / 255.0
                motion_scores.append(motion_score)
            else:
                motion_scores.append(0.0)
            
            prev_frame = gray
            frame_count += 1
        
        # Reset video to beginning
        cap.set(cv2.CAP_PROP_POS_FRAMES, 0)
        
        # Detect shot boundaries based on motion patterns
        segments = self._find_shot_boundaries(motion_scores, fps)
        
        return segments
    
    def _find_shot_boundaries(self, motion_scores: List[float], fps: float) -> List[Dict[str, Any]]:
        """
        Find shot boundaries based on motion analysis and pose detection
        
        Args:
            motion_scores: List of motion scores for each frame
            fps: Frames per second
            
        Returns:
            List of shot segment dictionaries
        """
        segments = []
        min_frames = int(self.min_shot_duration * fps)
        max_frames = int(self.max_shot_duration * fps)
        
        # Find periods of high motion (potential shots)
        high_motion_frames = [i for i, score in enumerate(motion_scores) 
                            if score > self.motion_threshold]
        
        if not high_motion_frames:
            # If no clear motion detected, treat entire video as one shot
            segments.append({
                "start_frame": 0,
                "end_frame": len(motion_scores) - 1,
                "start_time": 0.0,
                "end_time": len(motion_scores) / fps,
                "duration": len(motion_scores) / fps
            })
            return segments
        
        # Group consecutive high motion frames into segments
        current_segment = {"start": high_motion_frames[0]}
        
        for i in range(1, len(high_motion_frames)):
            if high_motion_frames[i] - high_motion_frames[i-1] > fps:  # Gap > 1 second
                # End current segment and start new one
                current_segment["end"] = high_motion_frames[i-1]
                segments.append(current_segment)
                current_segment = {"start": high_motion_frames[i]}
        
        # Add final segment
        current_segment["end"] = high_motion_frames[-1]
        segments.append(current_segment)
        
        # Filter segments by duration and add precise padding
        filtered_segments = []
        for segment in segments:
            duration = (segment["end"] - segment["start"]) / fps
            
            if min_frames <= (segment["end"] - segment["start"]) <= max_frames:
                # Add minimal padding - just enough to capture the complete shot
                padding_frames = int(0.3 * fps)  # 0.3 second padding for precise cutting
                
                start_frame = max(0, segment["start"] - padding_frames)
                end_frame = min(len(motion_scores) - 1, segment["end"] + padding_frames)
                
                filtered_segments.append({
                    "start_frame": start_frame,
                    "end_frame": end_frame,
                    "start_time": start_frame / fps,
                    "end_time": end_frame / fps,
                    "duration": (end_frame - start_frame) / fps
                })
        
        return filtered_segments
    
    def _process_shot_segment(self, video_path: str, segment: Dict[str, Any], shot_index: int) -> Optional[Dict[str, Any]]:
        """
        Process an individual shot segment and extract standardized data
        
        Args:
            video_path: Path to the original video
            segment: Shot segment information
            shot_index: Index of the shot
            
        Returns:
            Dictionary containing standardized shot data
        """
        try:
            # Extract the shot segment as a separate video with tracking
            shot_video_path = self._extract_shot_video(video_path, segment, shot_index)
            
            # Analyze the shot video
            shot_analysis = self._analyze_shot_video(shot_video_path, segment)
            
            # Keep the tracked video file for analysis
            # The video now contains motion tracking overlays
            
            return {
                "shot_id": f"shot_{shot_index:03d}",
                "segment_info": segment,
                "video_path": shot_video_path,
                "tracking_file": os.path.join(self.tracked_data_dir, f"shot_{shot_index:03d}_tracking.json"),
                "analysis": shot_analysis,
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            print(f"Error processing shot {shot_index}: {str(e)}")
            return None
    
    def _extract_shot_video(self, video_path: str, segment: Dict[str, Any], shot_index: int) -> str:
        """
        Extract a shot segment as a separate video file with motion tracking overlays
        
        Args:
            video_path: Path to the original video
            segment: Shot segment information
            shot_index: Index of the shot
            
        Returns:
            Path to the extracted shot video with tracking overlays
        """
        cap = cv2.VideoCapture(video_path)
        
        # Get video properties
        fps = cap.get(cv2.CAP_PROP_FPS)
        width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
        height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
        
        # Create output video writer
        output_path = os.path.join(self.tracked_data_dir, f"shot_{shot_index:03d}_tracked.mp4")
        fourcc = cv2.VideoWriter_fourcc(*'mp4v')
        out = cv2.VideoWriter(output_path, fourcc, fps, (width, height))
        
        # Seek to start frame
        cap.set(cv2.CAP_PROP_POS_FRAMES, segment["start_frame"])
        
        # Track motion data for overlays
        pose_trajectories = []
        hand_trajectories = []
        ball_trajectories = []
        
        # Extract frames for the shot segment with tracking
        for frame_idx in range(segment["start_frame"], segment["end_frame"] + 1):
            ret, frame = cap.read()
            if not ret:
                break
            
            # Create a copy for drawing
            annotated_frame = frame.copy()
            
            # Detect pose and hands
            pose_results = self.pose.process(cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))
            hand_results = self.hands.process(cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))
            
            # Draw pose landmarks
            if pose_results.pose_landmarks:
                self.mp_drawing.draw_landmarks(
                    annotated_frame,
                    pose_results.pose_landmarks,
                    self.mp_pose.POSE_CONNECTIONS,
                    landmark_drawing_spec=self.mp_drawing_styles.get_default_pose_landmarks_style()
                )
                
                # Track arm positions
                left_wrist = pose_results.pose_landmarks.landmark[self.mp_pose.PoseLandmark.LEFT_WRIST]
                right_wrist = pose_results.pose_landmarks.landmark[self.mp_pose.PoseLandmark.RIGHT_WRIST]
                left_shoulder = pose_results.pose_landmarks.landmark[self.mp_pose.PoseLandmark.LEFT_SHOULDER]
                right_shoulder = pose_results.pose_landmarks.landmark[self.mp_pose.PoseLandmark.RIGHT_SHOULDER]
                
                # Convert to pixel coordinates
                left_wrist_pos = (int(left_wrist.x * width), int(left_wrist.y * height))
                right_wrist_pos = (int(right_wrist.x * width), int(right_wrist.y * height))
                left_shoulder_pos = (int(left_shoulder.x * width), int(left_shoulder.y * height))
                right_shoulder_pos = (int(right_shoulder.x * width), int(right_shoulder.y * height))
                
                # Store trajectories
                pose_trajectories.append({
                    'frame': frame_idx,
                    'left_wrist': left_wrist_pos,
                    'right_wrist': right_wrist_pos,
                    'left_shoulder': left_shoulder_pos,
                    'right_shoulder': right_shoulder_pos
                })
                
                # Draw arm lines
                cv2.line(annotated_frame, left_shoulder_pos, left_wrist_pos, (0, 255, 0), 3)
                cv2.line(annotated_frame, right_shoulder_pos, right_wrist_pos, (0, 255, 0), 3)
            
            # Draw hand landmarks
            if hand_results.multi_hand_landmarks:
                for hand_landmarks in hand_results.multi_hand_landmarks:
                    self.mp_drawing.draw_landmarks(
                        annotated_frame,
                        hand_landmarks,
                        self.mp_hands.HAND_CONNECTIONS,
                        self.mp_drawing_styles.get_default_hand_landmarks_style(),
                        self.mp_drawing_styles.get_default_hand_connections_style()
                    )
                    
                    # Track hand positions
                    wrist = hand_landmarks.landmark[self.mp_hands.HandLandmark.WRIST]
                    wrist_pos = (int(wrist.x * width), int(wrist.y * height))
                    hand_trajectories.append({
                        'frame': frame_idx,
                        'wrist': wrist_pos
                    })
            
            # Detect and track ball (simple color-based detection)
            ball_pos = self._detect_ball(frame)
            if ball_pos:
                ball_trajectories.append({
                    'frame': frame_idx,
                    'position': ball_pos
                })
                # Draw ball tracking
                cv2.circle(annotated_frame, ball_pos, 15, (0, 0, 255), -1)
                cv2.circle(annotated_frame, ball_pos, 20, (255, 255, 255), 2)
            
            # Draw trajectory trails
            self._draw_trajectory_trails(annotated_frame, pose_trajectories, hand_trajectories, ball_trajectories)
            
            # Add frame counter and shot info
            cv2.putText(annotated_frame, f"Shot {shot_index+1}", (10, 30), 
                       cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 255), 2)
            cv2.putText(annotated_frame, f"Frame: {frame_idx}", (10, 70), 
                       cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2)
            
            out.write(annotated_frame)
        
        cap.release()
        out.release()
        
        # Store tracking data
        tracking_data = {
            'pose_trajectories': pose_trajectories,
            'hand_trajectories': hand_trajectories,
            'ball_trajectories': ball_trajectories
        }
        
        # Save tracking data
        tracking_file = os.path.join(self.tracked_data_dir, f"shot_{shot_index:03d}_tracking.json")
        with open(tracking_file, 'w') as f:
            json.dump(tracking_data, f, indent=2, default=str)
        
        return output_path
    
    def _detect_ball(self, frame: np.ndarray) -> Optional[Tuple[int, int]]:
        """
        Detect basketball in the frame using color-based detection
        
        Args:
            frame: Input frame
            
        Returns:
            Ball position (x, y) or None if not detected
        """
        # Convert to HSV for better color detection
        hsv = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)
        
        # Define orange/brown color range for basketball
        lower_orange = np.array([5, 50, 50])
        upper_orange = np.array([25, 255, 255])
        
        # Create mask for orange/brown objects
        mask = cv2.inRange(hsv, lower_orange, upper_orange)
        
        # Find contours
        contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        
        if contours:
            # Find the largest contour (likely the ball)
            largest_contour = max(contours, key=cv2.contourArea)
            area = cv2.contourArea(largest_contour)
            
            # Filter by size (ball should be reasonably sized)
            if area > 100:  # Minimum area threshold
                # Get the center of the contour
                M = cv2.moments(largest_contour)
                if M["m00"] != 0:
                    cx = int(M["m10"] / M["m00"])
                    cy = int(M["m01"] / M["m00"])
                    return (cx, cy)
        
        return None
    
    def _draw_trajectory_trails(self, frame: np.ndarray, pose_trajectories: List[Dict], 
                               hand_trajectories: List[Dict], ball_trajectories: List[Dict]):
        """
        Draw trajectory trails on the frame
        
        Args:
            frame: Frame to draw on
            pose_trajectories: Pose tracking data
            hand_trajectories: Hand tracking data
            ball_trajectories: Ball tracking data
        """
        # Draw pose trails (last 10 frames)
        if len(pose_trajectories) > 1:
            for i in range(max(0, len(pose_trajectories) - 10), len(pose_trajectories) - 1):
                if i + 1 < len(pose_trajectories):
                    # Draw wrist trails
                    cv2.line(frame, pose_trajectories[i]['left_wrist'], 
                            pose_trajectories[i + 1]['left_wrist'], (0, 255, 255), 2)
                    cv2.line(frame, pose_trajectories[i]['right_wrist'], 
                            pose_trajectories[i + 1]['right_wrist'], (255, 0, 255), 2)
        
        # Draw hand trails
        if len(hand_trajectories) > 1:
            for i in range(max(0, len(hand_trajectories) - 10), len(hand_trajectories) - 1):
                if i + 1 < len(hand_trajectories):
                    cv2.line(frame, hand_trajectories[i]['wrist'], 
                            hand_trajectories[i + 1]['wrist'], (255, 255, 0), 2)
        
        # Draw ball trajectory
        if len(ball_trajectories) > 1:
            for i in range(max(0, len(ball_trajectories) - 15), len(ball_trajectories) - 1):
                if i + 1 < len(ball_trajectories):
                    cv2.line(frame, ball_trajectories[i]['position'], 
                            ball_trajectories[i + 1]['position'], (0, 255, 0), 3)
    
    def _analyze_shot_video(self, shot_video_path: str, segment: Dict[str, Any]) -> Dict[str, Any]:
        """
        Analyze a shot video to extract key metrics
        
        Args:
            shot_video_path: Path to the shot video
            segment: Shot segment information
            
        Returns:
            Dictionary containing shot analysis data
        """
        cap = cv2.VideoCapture(shot_video_path)
        
        if not cap.isOpened():
            return {"error": "Could not open shot video"}
        
        # Get video properties
        fps = cap.get(cv2.CAP_PROP_FPS)
        total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
        height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
        
        # Extract key frames and motion data
        frames = []
        motion_data = []
        prev_frame = None
        
        while True:
            ret, frame = cap.read()
            if not ret:
                break
                
            frames.append(frame)
            
            # Calculate motion
            if prev_frame is not None:
                gray_prev = cv2.cvtColor(prev_frame, cv2.COLOR_BGR2GRAY)
                gray_curr = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
                
                frame_diff = cv2.absdiff(gray_prev, gray_curr)
                motion_score = np.mean(frame_diff)
                motion_data.append(motion_score)
            else:
                motion_data.append(0)
            
            prev_frame = frame.copy()
        
        cap.release()
        
        # Calculate shot metrics
        analysis = {
            "frame_count": len(frames),
            "duration": len(frames) / fps,
            "resolution": f"{width}x{height}",
            "fps": fps,
            "motion_analysis": {
                "max_motion": max(motion_data) if motion_data else 0,
                "avg_motion": np.mean(motion_data) if motion_data else 0,
                "motion_variance": np.var(motion_data) if motion_data else 0
            },
            "key_frames": {
                "start_frame": frames[0] if frames else None,
                "middle_frame": frames[len(frames)//2] if frames else None,
                "end_frame": frames[-1] if frames else None
            }
        }
        
        return analysis
    
    def save_standardized_data(self, shot_data: List[Dict[str, Any]], output_path: str = None):
        """
        Save standardized shot data to a JSON file
        
        Args:
            shot_data: List of standardized shot data
            output_path: Optional output path
        """
        if output_path is None:
            output_path = os.path.join(self.tracked_data_dir, f"analysis_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json")
        
        # Convert numpy arrays to lists for JSON serialization
        serializable_data = []
        for shot in shot_data:
            serializable_shot = shot.copy()
            if "analysis" in serializable_shot:
                analysis = serializable_shot["analysis"].copy()
                if "motion_analysis" in analysis:
                    motion = analysis["motion_analysis"]
                    motion["max_motion"] = float(motion["max_motion"])
                    motion["avg_motion"] = float(motion["avg_motion"])
                    motion["variance"] = float(motion["motion_variance"])
                analysis["duration"] = float(analysis["duration"])
                serializable_shot["analysis"] = analysis
            serializable_data.append(serializable_shot)
        
        with open(output_path, 'w') as f:
            json.dump(serializable_data, f, indent=2, default=str)
        
        print(f"Standardized data saved to: {output_path}")
    
    def cleanup(self):
        """Clean up MediaPipe resources"""
        if hasattr(self, 'pose'):
            self.pose.close()
        if hasattr(self, 'hands'):
            self.hands.close()
