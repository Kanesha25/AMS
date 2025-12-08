import io
import os
from typing import List

import firebase_admin
from fastapi import Depends, FastAPI, File, Header, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from firebase_admin import auth, credentials
from PIL import Image
from ultralytics import YOLO
import uvicorn


def _init_firebase() -> None:
    if firebase_admin._apps:  # type: ignore[attr-defined]
        return

    cred_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
    if cred_path and os.path.exists(cred_path):
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
    else:
        firebase_admin.initialize_app()


_init_firebase()

MODEL_PATH = os.getenv("YOLO_WEIGHTS_PATH", os.path.join(os.getcwd(), "best.pt"))
DEFAULT_CONF = float(os.getenv("YOLO_CONFIDENCE", "0.25"))
DEFAULT_IMAGE_SIZE = int(os.getenv("YOLO_IMAGE_SIZE", "640"))

try:
    yolov8_model = YOLO(MODEL_PATH)
except Exception as exc:  # pragma: no cover - startup failure
    raise RuntimeError(f"Unable to load YOLO model at {MODEL_PATH}") from exc

app = FastAPI(title="Accident Detection API")
app.add_middleware(
    CORSMiddleware,
    allow_origins=os.getenv("ALLOWED_ORIGINS", "*").split(","),
    allow_methods=["*"],
    allow_headers=["*"],
)


async def verify_firebase_token(authorization: str = Header(default="")) -> str:
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing Firebase token")

    token = authorization.split(" ", 1)[1]
    try:
        decoded = auth.verify_id_token(token)
        return decoded["uid"]
    except Exception as exc:  # pragma: no cover - external service
        raise HTTPException(status_code=401, detail="Invalid Firebase token") from exc


def _serialize_detections(result) -> List[dict]:
    detections: List[dict] = []
    for prediction in result:
        for box in prediction.boxes:
            detections.append(
                {
                    "label": yolov8_model.names[int(box.cls)],
                    "confidence": float(box.conf),
                    "bbox": [float(value) for value in box.xyxy[0].tolist()],
                }
            )
    return detections


@app.post("/detect")
async def detect_damage(
    image: UploadFile = File(...),
    uid: str = Depends(lambda: "debug-user"),
) -> dict:
    try:
        file_bytes = await image.read()
        pil_image = Image.open(io.BytesIO(file_bytes)).convert("RGB")
    except Exception as exc:
        raise HTTPException(status_code=400, detail="Invalid image payload") from exc

    try:
        result = yolov8_model.predict(
            pil_image,
            conf=DEFAULT_CONF,
            imgsz=DEFAULT_IMAGE_SIZE,
            verbose=False,
        )
    except Exception as exc:  # pragma: no cover - model inference error
        raise HTTPException(status_code=500, detail="Model inference failed") from exc

    return {"uid": uid, "detections": _serialize_detections(result)}


if __name__ == "__main__":  # pragma: no cover
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=int(os.getenv("PORT", "8000")),
        reload=os.getenv("UVICORN_RELOAD", "false").lower() == "true",
    )

