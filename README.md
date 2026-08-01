# HooperMetrics

A Flutter application that analyzes basketball shooting consistency using computer vision and Dynamic Time Warping.

<p align="center">
  <img src="Screenshot%202026-07-31%20235610.png" width="600">
</p>

## Overview

HooperMetrics analyzes basketball shooting videos and generates a consistency report within seconds.

The application uses MediaPipe pose estimation to track body landmarks throughout a shot, extracts joint-angle sequences from the detected movement, and applies Dynamic Time Warping (DTW) to compare shooting attempts.

Instead of comparing raw body positions, HooperMetrics analyzes the structure of the motion itself. Using joint angles and temporal alignment makes the analysis more robust to differences in camera position, player distance, and shooting speed.

## Features

- Flutter mobile application
- Video-based basketball shot analysis
- Human pose estimation using MediaPipe
- Joint-angle extraction from body landmarks
- Dynamic Time Warping (DTW) shot comparison
- Overall shooting consistency scoring
- Joint-specific consistency analysis
- Automated feedback based on shot variation

## Processing Pipeline

1. User records a basketball shooting video.
2. The video is processed using MediaPipe pose estimation.
3. Body landmarks are converted into joint-angle sequences.
4. Dynamic Time Warping aligns shots across different speeds.
5. The application generates consistency scores and feedback.

## Tech Stack

- Flutter
- Dart
- MediaPipe Pose
- Dynamic Time Warping
- Computer Vision
- Signal Processing

## Future Improvements

- Multi-camera analysis
- Automatic shot phase segmentation
- ML-based coaching recommendations
- Player-to-player comparison
- Larger datasets for improved feedback accuracy
