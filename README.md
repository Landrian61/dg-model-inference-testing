# Object Detection Models Inference Testing

This repository contains inference testing results for various object detection models. The tests evaluate performance metrics including average FPS (for videos), latency, and CPU usage across different hardware configurations.

## Models Tested

### 1. NanoDet

**Model Description:** 
NanoDet is a lightweight anchor-free object detection model designed for edge devices and mobile applications.

**Test Configuration:**
- **Input Type:** Video streams
- **Hardware:** [Your hardware specifications]
- **Framework:** [PyTorch]

**Key Metrics:**
- **Average FPS:** [Your measured FPS]
- **CPU Usage:** [Average CPU % usage]
- **Memory Footprint:** [If measured]


### 2. RetinaNet (Torchvision)

**Model Description:**
RetinaNet is a single-stage object detector that uses a feature pyramid network (FPN) and focal loss. This implementation uses the Torchvision version of RetinaNet with ResNet50 backbone.

**Test Configuration:**
- **Input Type:** Static images (.jpg)
- **Hardware:** [Your hardware specifications]
- **Framework:** PyTorch (Torchvision)

**Key Metrics:**
- **Average Latency:** [Your measured latency in ms]
- **CPU Usage:** [Average CPU % usage]

**Notes:**
- Testing methodology involves batch processing of images
- Results are saved with timestamps for reproducibility
- See the [RetinaNet testing subfolder](./retinanet/) for detailed implementation

## Upcoming Models

More models are to be added to the repo for testing!


## Testing Methodology

### Image Inference
For static image testing, we measure:
1. Inference latency (milliseconds)
2. CPU usage percentage
3. Memory consumption
4. Detection accuracy (if ground truth available)

### Video Inference
For video stream testing, we measure:
1. Frames per second (FPS)
2. CPU/GPU utilization
3. Thermal performance (for edge devices)
4. Detection stability across frames


## Hardware Configurations

| Configuration | CPU | RAM | GPU | Operating System |
|---------------|-----|-----|-----|-----------------|
| Config 1      | [CPU details] | [RAM size] | [GPU details] | [OS details] |
| Config 2      | [CPU details] | [RAM size] | [GPU details] | [OS details] |

## Getting Started

To run inference tests on these models, follow the instructions in the specific model directories. Each model has its own setup and execution guidelines.

For general setup:

```bash
# Clone the repository
git clone <your-repo-url>
cd object-detection-testing

# Set up environment (example using conda)
conda create -n obj-detection python=3.10
conda activate obj-detection

# Install common dependencies
pip install torch torchvision opencv-python pillow psutil
```

## Results Summary

| Model | Input Type | Avg. Latency (ms) | Avg. FPS | CPU Usage (%) | Memory (MB) |
|-------|------------|-------------------|----------|---------------|-------------|
| NanoDet | Video | - | [Your FPS] | [CPU %] | [Memory] |
| RetinaNet | Images | [Your latency] | - | [CPU %] | [Memory] |

## Contributing

Guidelines for contributing additional model tests:
1. Follow the existing directory structure and naming conventions
2. Include complete setup instructions
3. Document all testing parameters
4. Provide raw results and summary statistics

## License

[Your license information]