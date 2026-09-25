import math
import cv2
import numpy as np
import mediapipe as mp


VIDEO_PATH = "test_videos/test_running.mp4"


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
    raise RuntimeError("Cannot open video")


mp_pose = mp.solutions.pose

pose = mp_pose.Pose(
    static_image_mode=False,
    model_complexity=1,
    smooth_landmarks=True,
    enable_segmentation=False,
    min_detection_confidence=0.5,
    min_tracking_confidence=0.5,
)


frame_step = 5

angles = []
left_angles = []
right_angles = []

frames_used = 0
frame_idx = 0


while True:
    ok, frame = cap.read()

    if not ok:
        break

    frame_idx += 1

    if frame_idx % frame_step != 0:
        continue

    rgb = cv2.cvtColor(
        frame,
        cv2.COLOR_BGR2RGB
    )

    results = pose.process(rgb)

    if not results.pose_landmarks:
        continue

    lm = results.pose_landmarks.landmark

    def pt(i):
        return np.array(
            [
                lm[i].x,
                lm[i].y,
                lm[i].z
            ],
            dtype=np.float32
        )

    left = angle_3pts(
        pt(23),
        pt(25),
        pt(27)
    )

    right = angle_3pts(
        pt(24),
        pt(26),
        pt(28)
    )

    values = []

    if not math.isnan(left):
        left_angles.append(left)
        values.append(left)

    if not math.isnan(right):
        right_angles.append(right)
        values.append(right)

    if not values:
        continue

    frame_average = float(
        np.mean(values)
    )

    angles.append(frame_average)
    frames_used += 1


cap.release()
pose.close()


if not angles:
    raise RuntimeError(
        "No valid knee angles detected."
    )


print()
print("========== LEGACY MEDIAPIPE 3D TEST ==========")
print("MediaPipe version:", mp.__version__)
print("Video frames:", frame_idx)
print("Sampled every:", frame_step)
print("Frames analyzed:", frames_used)
print()
print("Left knee average:",
      round(float(np.mean(left_angles)), 3))

print("Right knee average:",
      round(float(np.mean(right_angles)), 3))

print("Combined average:",
      round(float(np.mean(angles)), 3))

print("Minimum angle:",
      round(float(np.min(angles)), 3))

print("Maximum angle:",
      round(float(np.max(angles)), 3))

print()
print("Training CSV average: 169.519")
print("===============================================")