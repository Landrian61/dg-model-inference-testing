#!/bin/bash

# Set headless mode (no GUI needed)
export QT_QPA_PLATFORM=offscreen

# Set PYTHONPATH to include the Torchvision package if needed (usually not necessary when installed)
export PYTHONPATH=$(pwd)

# Define directories
IMAGE_DIR="images/"
OUTPUT_DIR="results/$(date +'%Y_%m_%d_%H_%M_%S')"
mkdir -p "$OUTPUT_DIR"

# Initialize summary accumulators
total_latency=0
total_cpu=0
image_count=0

# Create a header for results
cat <<EOF > "$OUTPUT_DIR/README.md"
# RetinaNet Inference Results

| Image Name | Latency (ms) | CPU Usage (%) |
|------------|--------------|---------------|
EOF

# Loop over images in the folder
for IMAGE_PATH in "$IMAGE_DIR"*.jpg; do
    image_count=$((image_count + 1))
    IMAGE_NAME=$(basename "$IMAGE_PATH")

    # Get CPU usage before inference (snapshot)
    cpu_before=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage}')

    # Run inference using Python; adjust the path to inference.py if needed.
    OUTPUT=$(python inference.py --image "$IMAGE_PATH")
    
    # Extract latency from output (assuming the script prints "Latency: <value> ms")
    latency_ms=$(echo "$OUTPUT" | grep "Latency:" | awk '{print $2}')
    
    # Get CPU usage after inference
    cpu_after=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage}')
    cpu_usage=$(echo "($cpu_before + $cpu_after) / 2" | bc -l)

    # Append metrics to README
    printf "| %s | %.2f | %.2f |\n" "$IMAGE_NAME" "$latency_ms" "$cpu_usage" >> "$OUTPUT_DIR/README.md"

    # Accumulate totals
    total_latency=$(echo "$total_latency + $latency_ms" | bc -l)
    total_cpu=$(echo "$total_cpu + $cpu_usage" | bc -l)

    echo "Processed $IMAGE_NAME: Latency=$latency_ms ms, CPU=$cpu_usage%"
done

# Compute average metrics
if [ "$image_count" -gt 0 ]; then
    avg_latency=$(echo "$total_latency / $image_count" | bc -l)
    avg_cpu=$(echo "$total_cpu / $image_count" | bc -l)
else
    avg_latency=0
    avg_cpu=0
fi

# Append summary to README
cat <<EOF >> "$OUTPUT_DIR/README.md"

## Summary Metrics

| Total Images | Average Latency (ms) | Average CPU Usage (%) |
|--------------|----------------------|-----------------------|
| $image_count | $(printf "%.2f" $avg_latency) | $(printf "%.2f" $avg_cpu) |

EOF

echo "All images processed. Results saved in $OUTPUT_DIR/README.md."
