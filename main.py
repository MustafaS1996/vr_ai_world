from flask import Flask, send_from_directory, request
from flask_cors import CORS
from diffusers import ShapEPipeline
from diffusers.utils import export_to_obj
import torch
import os

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

pipe = ShapEPipeline.from_pretrained("openai/shap-e", torch_dtype=torch.float16, variant="fp16")
pipe = pipe.to(device)

def get_ai_3d_model(modeldesc):
    guidance_scale = 15.0
    prompt = modeldesc

    result = pipe(prompt, guidance_scale=guidance_scale, num_inference_steps=64, frame_size=256, output_type="mesh").images

    obj_path = os.path.join('models', f'{modeldesc}.obj')
    export_to_obj(result[0], obj_path)

    return obj_path

@app.route('/model')
def get_model():
    modeldesc = request.args.get('description', default='a chocolate donut', type=str)
    obj_path = get_ai_3d_model(modeldesc)
    return send_from_directory(directory='models', path=f'{modeldesc}.obj')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)