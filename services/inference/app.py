from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse
from pydantic import BaseModel
from diffusers import ShapEPipeline
from diffusers.utils import export_to_obj
import torch
import os
import tempfile
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="VR AI World - 3D Model Inference Service")

# Initialize device and model
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
use_gpu = torch.cuda.is_available() and device.type == "cuda"

# Test GPU access
if use_gpu:
    try:
        # Try to allocate a small tensor on GPU to verify access
        test_tensor = torch.zeros(1).to(device)
        logger.info(f"Using GPU device: {device} - {torch.cuda.get_device_name()}")
        del test_tensor
        torch.cuda.empty_cache()
    except Exception as e:
        logger.warning(f"GPU detected but not accessible: {e}")
        use_gpu = False
        device = torch.device("cpu")

logger.info(f"Using device: {device}, GPU enabled: {use_gpu}")

# Load model on startup
pipe = None

@app.on_event("startup")
async def startup_event():
    global pipe
    logger.info("Loading ShapE model...")
    
    if use_gpu:
        # Load with GPU optimizations
        logger.info("Loading model for GPU with float16...")
        pipe = ShapEPipeline.from_pretrained(
            "openai/shap-e", 
            torch_dtype=torch.float16, 
            variant="fp16"
        )
    else:
        # Load for CPU with float32
        logger.info("Loading model for CPU with float32...")
        pipe = ShapEPipeline.from_pretrained(
            "openai/shap-e", 
            torch_dtype=torch.float32
        )
    
    pipe = pipe.to(device)
    logger.info(f"Model loaded successfully on {device}")

class ModelRequest(BaseModel):
    description: str
    guidance_scale: float = 15.0
    num_inference_steps: int = 64
    frame_size: int = 256

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "device": str(device),
        "cuda_available": torch.cuda.is_available(),
        "gpu_enabled": use_gpu,
        "model_loaded": pipe is not None
    }

@app.post("/generate")
async def generate_model(request: ModelRequest):
    if pipe is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    if not request.description.strip():
        raise HTTPException(status_code=400, detail="Description cannot be empty")
    
    try:
        logger.info(f"Generating model for: {request.description}")
        
        # Generate 3D model
        result = pipe(
            request.description,
            guidance_scale=request.guidance_scale,
            num_inference_steps=request.num_inference_steps,
            frame_size=request.frame_size,
            output_type="mesh"
        ).images
        
        # Create temporary file for the OBJ
        with tempfile.NamedTemporaryFile(suffix='.obj', delete=False) as tmp_file:
            obj_path = tmp_file.name
        
        # Export to OBJ format
        export_to_obj(result[0], obj_path)
        
        logger.info(f"Model generated successfully: {obj_path}")
        
        # Return the file
        return FileResponse(
            obj_path,
            media_type='application/octet-stream',
            filename=f"{request.description[:50]}.obj",
            background=lambda: os.unlink(obj_path)  # Clean up file after response
        )
        
    except Exception as e:
        logger.error(f"Error generating model: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Model generation failed: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)