#!/bin/bash

# Set environment variable to run headless (no display)
export QT_QPA_PLATFORM=offscreen

# Define paths
CONFIG_PATH="nanodet/config/nanodet-plus-m_416.yml"
MODEL_PATH="weights/nanodet-plus-m-1.5x_416.pth"
VIDEO_DIR="videos/"
OUTPUT_BASE_DIR="result/nanodet-plus-m_416/$(date +'%Y_%m_%d_%H_%M_%S')"
mkdir -p "$OUTPUT_BASE_DIR"

# Initialize summary accumulators
total_fps=0
total_latency=0
total_cpu=0
video_count=0

# Create header for README.md
cat <<EOF > README.md
# Inference Results

| Video                  | Resolution | FPS   | Latency (ms) | CPU Usage (%) |
|------------------------|------------|-------|--------------|---------------|
EOF

# Loop over all MP4 videos in the videos/ directory
for VIDEO_PATH in "$VIDEO_DIR"*.mp4; do
    video_count=$((video_count + 1))
    VIDEO_NAME=$(basename "$VIDEO_PATH")
    
    # Get video resolution and frame count using Python & OpenCV
    resolution=$(python3 -c "import cv2; cap=cv2.VideoCapture('$VIDEO_PATH'); print(f'{int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))}x{int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))}'); cap.release()")
    frame_count=$(python3 -c "import cv2; cap=cv2.VideoCapture('$VIDEO_PATH'); print(int(cap.get(cv2.CAP_PROP_FRAME_COUNT))); cap.release()")
    
    # Get a CPU usage snapshot before inference
    cpu_before=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage}')
    
    # Create a unique output directory for this video
    OUTPUT_DIR="$OUTPUT_BASE_DIR/${VIDEO_NAME%.*}"
    mkdir -p "$OUTPUT_DIR"
    
    # Run inference and measure time
    start_time=$(date +%s.%N)
    python nanodet/demo/demo.py video --config "$CONFIG_PATH" --model "$MODEL_PATH" --path "$VIDEO_PATH" --save_result > "$OUTPUT_DIR/inference_log.txt" 2>&1
    end_time=$(date +%s.%N)
    latency=$(echo "$end_time - $start_time" | bc -l)
    latency_ms=$(echo "$latency * 1000" | bc -l)
    
    # Get a CPU usage snapshot after inference
    cpu_after=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage}')
    cpu_usage=$(echo "($cpu_before + $cpu_after) / 2" | bc -l)
    
    # Calculate FPS as (total frames) / (inference time in seconds)
    if (( $(echo "$latency > 0" | bc -l) )); then
        fps=$(echo "$frame_count / $latency" | bc -l)
    else
        fps=0
    fi
    
    # Append this video's metrics to README.md
    printf "| %s | %s | %.2f | %.2f | %.2f |\n" "$VIDEO_NAME" "$resolution" "$fps" "$latency_ms" "$cpu_usage" >> README.md

    # Accumulate totals for averaging
    total_fps=$(echo "$total_fps + $fps" | bc -l)
    total_latency=$(echo "$total_latency + $latency_ms" | bc -l)
    total_cpu=$(echo "$total_cpu + $cpu_usage" | bc -l)
    
    echo "Processed $VIDEO_NAME: Resolution=$resolution, FPS=$(printf '%.2f' $fps), Latency=$(printf '%.2f' $latency_ms) ms, CPU=$(printf '%.2f' $cpu_usage)%"
done

# Calculate average metrics if any videos were processed
if [ "$video_count" -gt 0 ]; then
    avg_fps=$(echo "$total_fps / $video_count" | bc -l)
    avg_latency=$(echo "$total_latency / $video_count" | bc -l)
    avg_cpu=$(echo "$total_cpu / $video_count" | bc -l)
else
    avg_fps=0
    avg_latency=0
    avg_cpu=0
fi

# Append a summary section to README.md
cat <<EOF >> README.md

## Summary Metrics

| Batch Size (videos) | Average FPS | Average Latency (ms) | Average CPU Usage (%) |
|---------------------|-------------|----------------------|-----------------------|
| $video_count        | $(printf "%.2f" $avg_fps) | $(printf "%.2f" $avg_latency) | $(printf "%.2f" $avg_cpu) |

EOF

echo "All videos processed. Results saved in README.md."
