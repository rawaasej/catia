from flask import Flask, request, jsonify
import tensorflow as tf
from PIL import Image
import numpy as np
import cv2
import os
import tempfile
import base64
import paho.mqtt.client as mqtt

# Suppression des logs TensorFlow non nécessaires
import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'

app = Flask(__name__)

# Charger le modèle IA
model = tf.keras.models.load_model("./model/linear_model.keras")

# Charger le modèle Haar Cascade pour la détection de chat
haarcascade_path = "./model/haarcascade_frontalcatface.xml"
cat_cascade = cv2.CascadeClassifier(haarcascade_path)

# Paramètres MQTT
broker = "192.168.1.27"
port = 1883
input_topic = "camera/photo"
output_topic = "camera/result"

# Chemin du dossier où enregistrer les images
save_directory = "./images_received/"
os.makedirs(save_directory, exist_ok=True)  # Créer le dossier s'il n'existe pas
fixed_image_path = os.path.join(save_directory, "last_received_image.jpg")

# Fonction pour détecter un chat
def detect_cat(image):
    """Détecte les chats dans une image avec Haar Cascade."""
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    cats = cat_cascade.detectMultiScale(gray, scaleFactor=1.1, minNeighbors=5, minSize=(30, 30))
    return len(cats) > 0

# Fonction pour prédire à partir d'une image
def predict_image_from_mqtt(image_data):
    """Prédire le résultat pour une image reçue via MQTT."""
    img_array = np.frombuffer(image_data, dtype=np.uint8)
    img = cv2.imdecode(img_array, cv2.IMREAD_COLOR)

    if not detect_cat(img):
        return "Pas de chat détecté"

    img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    img_pil = Image.fromarray(img_rgb).resize((224, 224))
    img_array = np.array(img_pil) / 255.0
    img_array = np.expand_dims(img_array, axis=0)

    prediction = model.predict(img_array)
    return "Sain" if prediction[0][0] < 0.5 else "Malade"

# Fonction de callback MQTT pour traiter les messages
def on_message(client, userdata, msg):
    print(f"Message reçu sur {msg.topic}")
    try:
        # Décoder l'image reçue
        image_data = base64.b64decode(msg.payload)
        img_array = np.frombuffer(image_data, dtype=np.uint8)
        img = cv2.imdecode(img_array, cv2.IMREAD_COLOR)

        # Sauvegarder l'image dans le fichier fixe (cela écrasera l'image précédente)
        cv2.imwrite(fixed_image_path, img)
        print(f"Image sauvegardée : {fixed_image_path}")

        # Effectuer une prédiction sur l'image
        result = predict_image_from_mqtt(image_data)
        print(f"Résultat : {result}")

        # Publier le résultat sur le topic MQTT
        client.publish(output_topic, result)
    except Exception as e:
        print(f"Erreur lors du traitement de l'image : {e}")

# Initialisation MQTT
def init_mqtt():
    client = mqtt.Client()
    client.on_connect = lambda c, u, f, rc: print(f"Connecté au broker MQTT avec le code {rc}")
    client.on_message = on_message
    client.connect(broker, port, 60)
    client.subscribe(input_topic)
    return client

# Endpoints Flask pour les prédictions via HTTP
@app.route('/predict_image', methods=['POST'])
def predict_image():
    if 'file' not in request.files:
        return jsonify({"error": "Aucun fichier envoyé"}), 400

    file = request.files['file']
    img = Image.open(file.stream).convert('RGB')
    img_cv = np.array(img)

    if not detect_cat(img_cv):
        return jsonify({"result": "Pas de chat détecté"}), 200

    img_resized = img.resize((224, 224))
    img_array = np.array(img_resized) / 255.0
    img_array = np.expand_dims(img_array, axis=0)

    prediction = model.predict(img_array)
    result = "Sain" if prediction[0][0] < 0.5 else "Malade"
    return jsonify({"result": result})

@app.route('/last_analysis', methods=['GET'])
def last_analysis():
    if not os.path.exists(fixed_image_path):
        return jsonify({"error": "Aucune image trouvée"}), 404

    try:
        # Lire l'image depuis le dossier images_received
        with open(fixed_image_path, "rb") as image_file:
            image_data = base64.b64encode(image_file.read()).decode('utf-8')

        # Charger l'image pour effectuer la prédiction
        img = cv2.imread(fixed_image_path)

        if img is None:
            return jsonify({"error": "Erreur lors du chargement de l'image"}), 500

        result = predict_image_from_mqtt(cv2.imencode('.jpg', img)[1].tobytes())

        return jsonify({
            "image": image_data,
            "result": result
        }), 200
    except Exception as e:
        return jsonify({"error": f"Erreur lors du traitement : {str(e)}"}), 500

# Endpoint pour prédictions vidéo
@app.route('/predict_video', methods=['POST'])
def predict_video():
    if 'file' not in request.files:
        return jsonify({"error": "Aucun fichier envoyé"}), 400

    file = request.files['file']
    with tempfile.NamedTemporaryFile(delete=False, suffix=".mp4") as temp_video_file:
        temp_video_file.write(file.read())
        temp_video_path = temp_video_file.name

    cap = cv2.VideoCapture(temp_video_path)
    if not cap.isOpened():
        return jsonify({"error": "Erreur lors de l'ouverture de la vidéo"}), 400

    frame_predictions = []
    cat_detected = False

    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break

        if detect_cat(frame):
            cat_detected = True
            frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            img_pil = Image.fromarray(frame_rgb).resize((224, 224))
            img_array = np.array(img_pil) / 255.0
            img_array = np.expand_dims(img_array, axis=0)
            prediction = model.predict(img_array)
            result = "Sain" if prediction[0][0] < 0.5 else "Malade"
            frame_predictions.append(result)

    cap.release()
    os.remove(temp_video_path)

    if not cat_detected:
        return jsonify({"result": "Pas de chat détecté dans la vidéo"}), 200

    final_result = "Sain" if frame_predictions.count("Sain") > frame_predictions.count("Malade") else "Malade"
    return jsonify({"result": final_result})

if __name__ == '__main__':
    mqtt_client = init_mqtt()
    mqtt_client.loop_start()  # Démarrer la boucle MQTT dans un thread séparé
    app.run(debug=True, host="192.168.1.25", port=5000)
