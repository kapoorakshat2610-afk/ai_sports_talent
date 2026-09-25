import math

import cv2
import numpy as np
import pandas as pd
import mediapipe as mp


VIDEO_PATH = "test_videos/test_running.mp4"
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


cap = cv2.VideoCapture(VIDEO_PATH)

if not cap.isOpened():
    raise RuntimeError("Could not open video.")


pose = mp.solutions.pose.Pose(
    static_image_mode=False,
    model_complexity=1,
    smooth_landmarks=True,
    enable_segmentation=False,
    min_detection_confidence=0.5,
    min_tracking_confidence=0.5,
)


rows = []
frame_idx = 0


while True:
    ok, frame = cap.read()

    if not ok:
        break

    frame_idx += 1

    rgb = cv2.cvtColor(
        frame,
        cv2.COLOR_BGR2RGB,
    )

    result = pose.process(rgb)

    if not result.pose_landmarks:
        continue

    lm = result.pose_landmarks.landmark

    def p(i):
        return np.array(
            [lm[i].x, lm[i].y],
            dtype=np.float32,
        )

    left = angle_3pts(
        p(23),
        p(25),
        p(27),
    )

    right = angle_3pts(
        p(24),
        p(26),
        p(28),
    )

    values = [
        x for x in [left, right]
        if not math.isnan(x)
    ]

    if not values:
        continue

    rows.append({
        "frame": frame_idx,
        "left_2d": left,
        "right_2d": right,
        "average_2d": float(np.mean(values)),
    })


cap.release()
pose.close()


legacy = pd.DataFrame(rows)
training = pd.read_csv(CSV_PATH)

merged = training.merge(
    legacy,
    on="frame",
    how="inner",
)


def mad(column):
    return float(
        (merged[column] - merged["knee_angle"])
        .abs()
        .mean()
    )


print()
print("========== KNEE SOURCE COMPARISON ==========")
print("Matching frames:", len(merged))
print()

print(
    "CSV mean:",
    round(float(merged["knee_angle"].mean()), 3)
)

print(
    "Left 2D mean:",
    round(float(merged["left_2d"].mean()), 3)
)

print(
    "Right 2D mean:",
    round(float(merged["right_2d"].mean()), 3)
)

print(
    "Average 2D mean:",
    round(float(merged["average_2d"].mean()), 3)
)

print()

print(
    "Mean absolute difference - LEFT:",
    round(mad("left_2d"), 3)
)

print(
    "Mean absolute difference - RIGHT:",
    round(mad("right_2d"), 3)
)

print(
    "Mean absolute difference - AVERAGE:",
    round(mad("average_2d"), 3)
)

print()
print("=============================================")