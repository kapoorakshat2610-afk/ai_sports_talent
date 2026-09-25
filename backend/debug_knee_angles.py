import math
import cv2
import numpy as np
import mediapipe as mp

from mediapipe.tasks import python
from mediapipe.tasks.python import vision


VIDEO_PATH = "test_videos/test_running.mp4"
MODEL_PATH = "models/pose/pose_landmarker_full.task"


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


left_2d = []
right_2d = []
left_3d = []
right_3d = []

frame_idx = 0
frames_used = 0


while True:
    ok, frame = cap.read()

    if not ok:
        break

    frame_idx += 1

    if frame_idx % 5 != 0:
        continue

    rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

    mp_image = mp.Image(
    image_format=mp.ImageFormat.SRGB,
    data=rgb,
)
    result = landmarker.detect(mp_image)

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

    left_angle_2d = angle_3pts(
        p2(23),
        p2(25),
        p2(27),
    )

    right_angle_2d = angle_3pts(
        p2(24),
        p2(26),
        p2(28),
    )

    left_angle_3d = angle_3pts(
        p3(23),
        p3(25),
        p3(27),
    )

    right_angle_3d = angle_3pts(
        p3(24),
        p3(26),
        p3(28),
    )

    if not math.isnan(left_angle_2d):
        left_2d.append(left_angle_2d)

    if not math.isnan(right_angle_2d):
        right_2d.append(right_angle_2d)

    if not math.isnan(left_angle_3d):
        left_3d.append(left_angle_3d)

    if not math.isnan(right_angle_3d):
        right_3d.append(right_angle_3d)

    frames_used += 1


cap.release()
landmarker.close()


def avg(values):
    return float(np.mean(values)) if values else float("nan")


print()
print("========== KNEE ANGLE DIAGNOSTIC ==========")
print("Frames used:", frames_used)
print()
print("LEFT 2D average:", avg(left_2d))
print("RIGHT 2D average:", avg(right_2d))
print("LEFT 3D average:", avg(left_3d))
print("RIGHT 3D average:", avg(right_3d))
print()
print("2D combined average:", avg(left_2d + right_2d))
print("3D combined average:", avg(left_3d + right_3d))
print("============================================")