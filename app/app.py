import os
import logging
from flask import Flask, jsonify

# Configure logging (no secrets in logs!)
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

app = Flask(__name__)

@app.route('/')
def health_check():
    # Verify secrets exist in environment
    db_password = os.environ.get("DB_PASSWORD")
    api_key = os.environ.get("API_KEY")
    
    warnings = []
    
    if not db_password:
        warnings.append("Missing DB_PASSWORD")
    if not api_key:
        warnings.append("Missing API_KEY")
        
    if warnings:
        logger.error(f"Health check failed: {warnings}")
        return jsonify({"status": "error", "missing_config": warnings}), 500
        
    # In a real app, we would use these secrets to connect to services here.
    # We NEVER return the secrets in the response.
    logger.info("Health check passed. Secrets are present.")
    return jsonify({"status": "healthy", "message": "Application is running securely with injected secrets."}), 200

if __name__ == '__main__':
    port = int(os.environ.get("PORT", 5000))
    app.run(host='0.0.0.0', port=port)
