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

session = ort.InferenceSession("yolov8n.onnx")

input_name = session.get_inputs()[0].name

cap = cv2.VideoCapture(1)

def preprocess(frame):
    img = cv2.resize(frame, (640,640))
    img = img[:, :, ::-1]
    img = img.transpose(2,0,1)
    img = img.astype(np.float32) / 255.0
    img = np.expand_dims(img, axis=0)
    return img

def count_people(outputs, frame, conf_threshold=0.3, iou_threshold=0.5):
    predictions = np.squeeze(outputs[0]).T
    
    boxes = []
    confidences = []

    for pred in predictions:
        scores = pred[4:]
        class_id = np.argmax(scores)
        confidence = scores[class_id]
    
        if class_id == 0 and confidence > conf_threshold:
            x,y,w,h = pred[0:4]

            # Scale from 640x640 to frame size
            x_scale = frame.shape[1] / 640
            y_scale = frame.shape[0] / 640
            
            x1 = int((x - w/2) * x_scale)
            y1 = int((y - h/2) * y_scale)
            w_scaled = int(w * x_scale)
            h_scaled = int(h * y_scale)
            
            boxes.append([x1, y1, w_scaled, h_scaled])
            confidences.append(float(confidence))
    
    # Apply NMS
    if len(boxes) > 0:
        indices = cv2.dnn.NMSBoxes(boxes, confidences, conf_threshold, iou_threshold)
    else:
        indices = []
    
    # Draw bounding boxes on frame
    for i in indices:
        x1, y1, w, h = boxes[i]
        x2 = x1 + w
        y2 = y1 + h
        cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 255, 0), 2)
    
    return len(indices), frame

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
    
    count, annotated_frame = count_people(outputs, frame)
    print("Current Count: ", count)
    
    # Display count on frame
    cv2.putText(
        annotated_frame,
        f"People Count: {count}",
        (20, 40),
        cv2.FONT_HERSHEY_SIMPLEX,
        1,
        (0, 255, 0),
        2,
    )
    
    # Show window with camera and bounding boxes
    cv2.imshow("Person Detection - Real-time Feed", annotated_frame)
    
    process_count(count)
    
    # Press 'q' to quit
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()

