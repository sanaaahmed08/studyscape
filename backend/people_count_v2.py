import cv2
import numpy as np
import onnxruntime as ort
import firebase_admin
from firebase_admin import credentials, firestore
import time

sum_counts = 0
num_samples = 0
window_start = time.time()
window_seconds = 30

cred = credentials.Certificate("FIREBASE_KEY")
firebase_admin.initialize_app(cred)

db = firestore.client()

def send_count(count):
    doc_ref = db.collection("spaces").document("library_1")
    doc_ref.set({
        "occupancy": count,
        "timestamp": firestore.SERVER_TIMESTAMP
    })

session = ort.InferenceSession("MODEL_PATH")

input_name = session.get_inputs()[0].name

cap = cv2.VideoCapture(1)

def preprocess(frame):
    img = cv2.resize(frame, (640,640))
    img = img[:, :, ::-1]
    img = img.transpose(2,0,1)
    img = img.astype(np.float32) / 255.0
    img = np.expand_dims(img, axis=0)
    return img

def count_people(outputs, conf_threshold=0.3, iou_threshold=0.5):
    predictions = np.squeeze(outputs[0]).T
    
    boxes = []
    confidences = []

    for pred in predictions:
        scores = pred[4:]
        class_id = np.argmax(scores)
        confidence = scores[class_id]
    
        if class_id == 0 and confidence > conf_threshold:
            x,y,w,h = pred[0:4]

            x1 = int(x-w/2)
            y1 = int(y-h/2)
            boxes.append([x1,y1,int(w),int(h)])
            confidences.append(float(confidence))
    
    # Apply NMS
    if len(boxes) > 0:
        indices = cv2.dnn.NMSBoxes(boxes, confidences, conf_threshold, iou_threshold)
    else:
        indices = []

    return len(indices)

def process_count(current_count):
    global sum_counts, num_samples, window_start

    sum_counts += current_count
    num_samples += 1

    now = time.time()

    if now - window_start >= window_seconds:
        avg = round(sum_counts / num_samples)

        send_count(avg)
        print("Sent 30s avg: ", avg)

        sum_counts = 0
        num_samples = 0
        window_start = now

while True:
    ret, frame = cap.read()
    if not ret:
        break
    input_tensor = preprocess(frame)
    outputs = session.run(None, {input_name: input_tensor})
    
    count = count_people(outputs)
    print("Current Count: ", count)
    process_count(count)
    
cap.release()

