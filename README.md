# VR 3D World

![Demo](https://github.com/MustafaS1996/vr_ai_world/raw/main/vrdemo.gif)

Welcome to the VR 3D Object Creator project! This project aims to make it easier for users to create their own 3D objects and environments, a task that has traditionally been difficult on other 3D/VR platforms. By leveraging voice recognition and AI-powered 3D model generation, users can generate and interact with 3D objects in a VR environment.

## Features

- **Voice Recognition**: Users can describe the objects they want to create using their voice.
- **AI-Powered 3D Model Generation**: The project uses state-of-the-art AI models to generate 3D models based on user descriptions.
- **Interactive VR Environment**: Users can interact with the generated 3D objects in a VR environment.

## Installation

To set up the project, follow these steps:

1. **Clone the Repository**:
    ```sh
    git clone https://github.com/yourusername/vr-3d-object-creator.git
    cd vr-3d-object-creator
    ```

2. **Set Up a Python Virtual Environment**:
    ```sh
    python -m venv venv
    source venv/bin/activate  # On Windows use `venv\Scripts\activate`
    ```

3. **Install the Required Libraries**:
    ```sh
    pip install diffusers transformers accelerate trimesh
    ```

4. **Run the Flask Backend**:
    ```sh
    python main.py
    ```

5. **Open the `index.html` File in a Browser**:
    Open `localhost:5000` in a web browser to start interacting with the VR environment.

## Usage

1. **Start the Backend**:
    Ensure that the Flask backend is running. This backend handles the AI model generation and serves the generated 3D models.

2. **Open the VR Environment**:
    Open the `localhost:5000` file in your web browser. Make sure your browser supports WebXR and WebVR.

3. **Voice Command to Create Objects**:
    Click the "Start Speech Input" button and describe the object you want to create. The AI will generate the 3D model based on your description and add it to the VR environment.

## Contributing

We welcome contributions to the project! If you have any ideas, suggestions, or bug reports, please open an issue or submit a pull request.

## License

This project is licensed under the V.I.B.E. License. See the [LICENSE](LICENSE) file for more details.

## Acknowledgements

- [A-Frame](https://aframe.io/)
- [Diffusers](https://github.com/huggingface/diffusers)
- [Transformers](https://github.com/huggingface/transformers)
- [Trimesh](https://trimsh.org/)

## Contact

For any questions or inquiries, please contact [your-email@example.com](mailto:your-email@example.com).

