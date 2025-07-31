# 🧯 Industrial Safety Object Detection using YOLOv8

This repository contains our solution for the BuildWithIndia 2.0 Hackathon organized by SunHacks, where we trained a YOLOv8 model to detect **Fire Extinguishers**, **Tool Boxes**, and **Oxygen Tanks** in industrial environments using computer vision.

---

## 🚀 Project Overview

The aim of this project is to ensure workplace safety using real-time object detection of essential equipment. By leveraging YOLOv8 and ONNX, our solution can run across various platforms — and is optimized for Flutter (mobile) integration.

### 📌 Objects Detected:
- 🔥 Fire Extinguisher
- 🧰 Tool Box
- 🧪 Oxygen Tank

---

## 📊 Final Results

After training and evaluation, the model achieved:

| Class            | Precision | Recall | mAP@0.5 | mAP@0.5:0.95 |
|------------------|-----------|--------|---------|---------------|
| Fire Extinguisher| **1.000** | 0.936  | **0.977** | 0.914 |
| Tool Box         | 0.992     | 0.883  | **0.948** | 0.916 |
| Oxygen Tank      | 0.965     | 0.873  | **0.901** | 0.822 |
| **Overall**      | 0.986     | 0.898  | **0.942** | **0.884** |

> ✅ Model: `YOLOv8m`  
> ✅ GPU: NVIDIA GeForce RTX 4050 (6GB)  
> ✅ Framework: PyTorch + Ultralytics + ONNX

---

## 📁 Folder Structure

```bash

HackWithDelhi2.0/
┣ 📁 data/              ← ⚠️ Copy this folder manually (see note below)
┃ ┣ 📁 train/
┃ ┃ ┣ 📁 images/
┃ ┃ ┗ 📁 labels/
┃ ┣ 📁 val/
┃ ┃ ┣ 📁 images/
┃ ┃ ┗ 📁 labels/
┃ ┣ 📁 predict/
┃ ┃ ┣ 📁 images/
┃ ┃ ┗ 📁 labels/
┃ ┗ 📄 data.yaml
┣ 📁 runs/              ← YOLO training logs and result artifacts
┣ 📜 Train\_YOLOv8.ipynb ← 📓 Full notebook: training, predicting & exporting
┣ 📜 train.py           ← 🔁 Training script (alternative to notebook)
┣ 📜 predict.py         ← 🧠 Run inference using trained model
┗ 📜 README.md          ← 📄 You're here!

```

---

## 📦 Dataset

The dataset used in this project is not included in this GitHub repo due to its size (\~3.9GB).
Please download it from this link:

🔗 **[Download Dataset (Google Drive)](https://drive.google.com/file/d/1Ok7KHy4YqOVjZhRWr56Lg0RvmvNfzMYj/view?usp=sharing)**

Once downloaded:

* Copy the extracted `data/` folder into the root directory of this repo.
* Structure must contain: `train/`, `val/`, `predict/` folders with images + labels + `data.yaml`.

---

## 🧠 Model Training & Export

All training, validation, and ONNX export steps are documented in:

📓 `Train_YOLOv8.ipynb`

Exported model:

```bash
runs/detect/train/weights/best.onnx  ✅
```

---

## 📱 Flutter Integration (via ONNX)

This repo is designed to integrate the exported ONNX model (`best.onnx`) into a mobile app using **Flutter**.

Flutter + ONNX support is still evolving, but you can use it with the help of:

---

## 📸 Result Samples

Here are visual examples of how our YOLOv8 model detects objects like fire extinguishers, toolboxes, and oxygen tanks in real-world images.

### 🔹 Validation Batch Predictions
Visualized predicted labels during validation phase using `val_batch1_labels.jpg`:

![Validation Results](runs/detect/train/val_batch1_labels.jpg)

### 🔹 Training Batch Samples
Sample training images used by YOLOv8 (`train_batch1.jpg`) showing bounding boxes during model training:

![Training Batch](runs/detect/train/train_batch1.jpg)

### 🔹 Inference Sample
A real inference result from our `best.onnx` model on a test image (`bus.jpg`):

![Inference Example](bus.jpg)

> All these visuals are automatically generated and stored in the `runs/detect/train/` directory after training.




