from flask import Flask, send_from_directory, request, jsonify
from flask_cors import CORS
import requests
import os
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)

# Configuration
INFERENCE_SERVICE_URL = os.getenv('INFERENCE_SERVICE_URL', 'http://inference-service:8000')

@app.route('/')
def index():
    return send_from_directory(directory='static', path='index.html')

@app.route('/<path:path>')
def serve_static(path):
    """Serve static files"""
    return send_from_directory(directory='static', path=path)

@app.route('/api/model')
def get_model():
    """Proxy endpoint to inference service"""
    description = request.args.get('description', default='a chocolate donut', type=str)
    
    if not description.strip():
        return jsonify({'error': 'Description cannot be empty'}), 400
    
    try:
        logger.info(f"Requesting model generation for: {description}")
        
        # Forward request to inference service
        response = requests.post(
            f"{INFERENCE_SERVICE_URL}/generate",
            json={
                "description": description,
                "guidance_scale": 15.0,
                "num_inference_steps": 64,
                "frame_size": 256
            },
            timeout=300  # 5 minute timeout for model generation
        )
        
        if response.status_code == 200:
            # Return the OBJ file directly
            return response.content, 200, {
                'Content-Type': 'application/octet-stream',
                'Content-Disposition': f'attachment; filename="{description[:50]}.obj"'
            }
        else:
            logger.error(f"Inference service error: {response.status_code} - {response.text}")
            return jsonify({
                'error': f'Model generation failed: {response.text}'
            }), response.status_code
            
    except requests.exceptions.Timeout:
        logger.error("Timeout waiting for inference service")
        return jsonify({'error': 'Model generation timed out'}), 504
    except requests.exceptions.ConnectionError:
        logger.error(f"Cannot connect to inference service at {INFERENCE_SERVICE_URL}")
        return jsonify({'error': 'Inference service unavailable'}), 503
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/health')
def health_check():
    """Health check endpoint"""
    try:
        # Check if inference service is reachable
        response = requests.get(f"{INFERENCE_SERVICE_URL}/health", timeout=5)
        inference_healthy = response.status_code == 200
    except:
        inference_healthy = False
    
    return jsonify({
        'status': 'healthy',
        'inference_service': 'healthy' if inference_healthy else 'unhealthy',
        'inference_service_url': INFERENCE_SERVICE_URL
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=3000)