import logging
from datetime import datetime

# Configurar logger
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

logger = logging.getLogger(__name__)

def log_info(message: str):
    """Log información"""
    logger.info(message)

def log_error(message: str):
    """Log error"""
    logger.error(message)

def log_warning(message: str):
    """Log warning"""
    logger.warning(message)
