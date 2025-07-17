from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse
from pydantic import BaseModel
import tempfile
import os
import logging
import time

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="VR AI World - 3D Model Inference Service (Test Mode)")

class ModelRequest(BaseModel):
    description: str
    guidance_scale: float = 15.0
    num_inference_steps: int = 64
    frame_size: int = 256

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "mode": "test",
        "message": "Running in test mode without GPU dependencies"
    }

@app.post("/generate")
async def generate_model(request: ModelRequest):
    if not request.description.strip():
        raise HTTPException(status_code=400, detail="Description cannot be empty")
    
    try:
        logger.info(f"Generating TEST model for: {request.description}")
        
        # Simulate model generation time
        time.sleep(2)
        
        # Create a simple test OBJ file
        obj_content = """# Test OBJ file for: {description}
# This is a simple cube
v -1.0 -1.0  1.0
v  1.0 -1.0  1.0
v  1.0  1.0  1.0
v -1.0  1.0  1.0
v -1.0 -1.0 -1.0
v  1.0 -1.0 -1.0
v  1.0  1.0 -1.0
v -1.0  1.0 -1.0

f 1 2 3 4
f 8 7 6 5
f 4 3 7 8
f 5 1 4 8
f 5 6 2 1
f 2 6 7 3
""".format(description=request.description)
        
        # Create temporary file for the OBJ
        with tempfile.NamedTemporaryFile(mode='w', suffix='.obj', delete=False) as tmp_file:
            tmp_file.write(obj_content)
            obj_path = tmp_file.name
        
        logger.info(f"TEST model generated successfully: {obj_path}")
        
        # Return the file
        return FileResponse(
            obj_path,
            media_type='application/octet-stream',
            filename=f"test_{request.description[:50]}.obj",
            background=lambda: os.unlink(obj_path)
        )
        
    except Exception as e:
        logger.error(f"Error generating TEST model: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Model generation failed: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)