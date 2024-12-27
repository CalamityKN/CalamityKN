from flask import Flask, request

app = Flask(__name__)

@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return "No file part", 400
    file = request.files['file']
    if file.filename == '':
        return "No selected file", 400
    # Save the file
    file.save(f"./{file.filename}")
    return f"File uploaded successfully as {file.filename}"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)