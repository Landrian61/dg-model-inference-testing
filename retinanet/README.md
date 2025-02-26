# RetinaNet Inference Testing Project

This project demonstrates how to run inference tests using a RetinaNet model from Torchvision. The full Torchvision repository is included as a Git submodule so that the complete package structure (and relative imports) are preserved.

## Project Structure

```
my-retinanet-project/
├── README.md                # This file – setup and usage instructions
├── run_inference.sh         # Bash script for batch inference on images
├── inference.py             # Python script to run inference on a single image
├── images/                  # Folder with sample images (e.g., img_01.jpg, img_02.jpg, ...)
├── results/                 # Created at runtime to store inference results and metrics
├── torchvision/             # Git submodule: full Torchvision repository
│   ├── .git
│   ├── setup.py
│   └── ... (rest of Torchvision source)
└── .gitmodules              # Git submodule configuration file
```

## Setup Instructions

### 1. Clone This Repository and Initialize Submodules

Clone your main repository (if not already cloned), then add the Torchvision submodule:

```bash
git clone <your-main-repo-url> my-retinanet-project
cd my-retinanet-project
git submodule update --init --recursive
```

### 2. Set Up the Conda Environment

If you have an old environment (retinanet-env) that you no longer need, delete it:

```bash
conda remove --name retinanet-env --all
```

Then, create and activate a new conda environment:

```bash
conda create --name retinanet-env python=3.10 -y
conda activate retinanet-env
```

### 3. Install Dependencies

Since the Torchvision repository does not include a requirements.txt, install Torchvision in editable mode from the submodule:

```bash
pip install -e torchvision
```

Then, install the additional required packages:

```bash
pip install torch pillow opencv-python psutil memory_profiler
```

**Note:** Make sure you have PyTorch installed. If not, you may install it via Conda or Pip:

For CPU-only:
```bash
conda install pytorch torchvision cpuonly -c pytorch
```

For GPU (e.g., CUDA 11.8):
```bash
conda install pytorch torchvision pytorch-cuda=11.8 -c pytorch -c nvidia
```

## Running Inference Tests

### Single-Image Inference

To run inference on a single image (for example, images/img_01.jpg), execute:

```bash
python inference.py --image images/img_01.jpg
```

This script loads the pre-trained RetinaNet model (using Torchvision's retinanet_resnet50_fpn), processes the image, and prints the latency (in milliseconds) along with prediction details.

### Batch Inference Testing

To run batch inference on all images in the images/ folder and collect performance metrics (latency and CPU usage), run the Bash script:

```bash
chmod +x run_inference.sh
./run_inference.sh
```

The script will:
1. Iterate over each .jpg file in the images/ directory.
2. Run inference using inference.py.
3. Capture and log latency and CPU usage metrics.
4. Save detailed results and a summary report in a timestamped directory under results/.

## Troubleshooting

### Submodule Issues:
If you encounter issues with the Torchvision submodule, ensure that it is correctly initialized with:

```bash
git submodule update --init --recursive
```

### Relative Import Errors:
If you experience relative import errors, verify that you are running the scripts from the project root so that Python can locate the torchvision package.

### Dependencies:
Ensure that all required packages (PyTorch, Pillow, OpenCV, etc.) are installed in your conda environment.

## Additional Files

### run_inference.sh

```bash
#!/bin/bash

# Set headless mode (no GUI needed)
export QT_QPA_PLATFORM=offscreen

# Set PYTHONPATH to include the project root (if needed)
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

    # Run inference using Python and capture output
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
```

### inference.py

```python
import argparse
import time
import torch
from PIL import Image
from torchvision import transforms
from torchvision.models.detection import retinanet_resnet50_fpn

def main(image_path):
    # Load the pre-trained RetinaNet model and set it to evaluation mode.
    model = retinanet_resnet50_fpn(weights="DEFAULT")
    model.eval()

    # Define the image transform: convert image to tensor with values in [0, 1]
    transform = transforms.Compose([transforms.ToTensor()])

    # Load and transform the image
    image = Image.open(image_path).convert("RGB")
    inputs = [transform(image)]

    # Warm-up (important if using GPU)
    for _ in range(3):
        with torch.no_grad():
            _ = model(inputs)

    # Measure inference time
    start_time = time.time()
    with torch.no_grad():
        predictions = model(inputs)
    end_time = time.time()

    latency = (end_time - start_time) * 1000  # convert to milliseconds

    # Print out latency and prediction details
    print(f"Latency: {latency:.2f} ms")
    print("Predictions:", predictions[0])

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run RetinaNet Inference")
    parser.add_argument("--image", type=str, required=True, help="Path to the input image")
    args = parser.parse_args()
    main(args.image)
```

## Final Notes

- **Submodule Update**: Always run `git submodule update --init --recursive` after cloning the main repository.
- **Environment Setup**: Follow the instructions in the README to create a fresh conda environment and install all dependencies.

Happy testing!