import math

import cv2
import numpy as np
import pandas as pd
import mediapipe as mp

from mediapipe.tasks import python
from mediapipe.tasks.python import vision


VIDEO_PATH = "test_videos/test_running.mp4"
MODEL_PATH = "models/pose/pose_landmarker_full.task"
CSV_PATH = "knee_angles_training.csv"


def angle_3pts(a, b, c):
    ba = a - b
    bc = c - b

    denom = np.linalg.norm(ba) * np.linalg.norm(bc)

    if denom == 0:
        return float("nan")

    cosang = np.dot(ba, bc) / denom
    cosang = float(np.clip(cosang, -1.0, 1.0))

    return math.degrees(math.acos(cosang))


base_options = python.BaseOptions(
    model_asset_path=MODEL_PATH
)

options = vision.PoseLandmarkerOptions(
    base_options=base_options,
    running_mode=vision.RunningMode.IMAGE,
    num_poses=1,
    min_pose_detection_confidence=0.5,
    min_pose_presence_confidence=0.5,
    min_tracking_confidence=0.5,
)

landmarker = vision.PoseLandmarker.create_from_options(options)

cap = cv2.VideoCapture(VIDEO_PATH)

if not cap.isOpened():
    raise RuntimeError("Could not open video.")


rows = []

frame_idx = 0

while True:
    ok, frame = cap.read()

    if not ok:
        break

    frame_idx += 1

    rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

    image = mp.Image(
        image_format=mp.ImageFormat.SRGB,
        data=rgb,
    )

    result = landmarker.detect(image)

    if not result.pose_landmarks:
        continue

    lm = result.pose_landmarks[0]

    def p2(i):
        return np.array(
            [lm[i].x, lm[i].y],
            dtype=np.float32,
        )

    def p3(i):
        return np.array(
            [lm[i].x, lm[i].y, lm[i].z],
            dtype=np.float32,
        )

    left_2d = angle_3pts(
        p2(23),
        p2(25),
        p2(27),
    )

    right_2d = angle_3pts(
        p2(24),
        p2(26),
        p2(28),
    )

    left_3d = angle_3pts(
        p3(23),
        p3(25),
        p3(27),
    )

    right_3d = angle_3pts(
        p3(24),
        p3(26),
        p3(28),
    )

    values_2d = [
        x for x in [left_2d, right_2d]
        if not math.isnan(x)
    ]

    values_3d = [
        x for x in [left_3d, right_3d]
        if not math.isnan(x)
    ]

    if not values_2d or not values_3d:
        continue

    rows.append({
        "frame": frame_idx,
        "angle_2d": float(np.mean(values_2d)),
        "angle_3d": float(np.mean(values_3d)),
    })


cap.release()
landmarker.close()


current = pd.DataFrame(rows)

training = pd.read_csv(CSV_PATH)

merged = training.merge(
    current,
    on="frame",
    how="inner",
)

print()
print("========== COMPARISON ==========")
print("Training CSV rows:", len(training))
print("Tasks rows:", len(current))
print("Matching frames:", len(merged))
print()

print("Training CSV mean:",
      round(training["knee_angle"].mean(), 3))

if len(merged) > 0:
    print("Training mean on matching frames:",
          round(merged["knee_angle"].mean(), 3))

    print("Tasks 2D mean on matching frames:",
          round(merged["angle_2d"].mean(), 3))

    print("Tasks 3D mean on matching frames:",
          round(merged["angle_3d"].mean(), 3))

    merged["diff_2d"] = (
        merged["angle_2d"] -
        merged["knee_angle"]
    )

    merged["diff_3d"] = (
        merged["angle_3d"] -
        merged["knee_angle"]
    )

    print()
    print("Mean absolute difference 2D:",
          round(merged["diff_2d"].abs().mean(), 3))

    print("Mean absolute difference 3D:",
          round(merged["diff_3d"].abs().mean(), 3))

    print()
    print("Sample comparisons:")
    print(
        merged[
            [
                "frame",
                "knee_angle",
                "angle_2d",
                "angle_3d",
            ]
        ].head(20).to_string(index=False)
    )

    print()
    print("Lowest training angles:")
    print(
        merged.nsmallest(
            15,
            "knee_angle"
        )[
            [
                "frame",
                "knee_angle",
                "angle_2d",
                "angle_3d",
            ]
        ].to_string(index=False)
    )

print("================================")