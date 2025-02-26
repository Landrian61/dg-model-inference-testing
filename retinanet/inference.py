import argparse
import time
import torch
from PIL import Image
from torchvision import transforms
from torchvision.models.detection import retinanet_resnet50_fpn

def main(image_path):
    # Load the pre-trained RetinaNet model and set to eval mode.
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

    # Print out latency and some basic prediction info (bounding boxes, labels, scores)
    print(f"Latency: {latency:.2f} ms")
    print("Predictions:", predictions[0])

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run RetinaNet Inference")
    parser.add_argument("--image", type=str, required=True, help="Path to the input image")
    args = parser.parse_args()
    main(args.image)
