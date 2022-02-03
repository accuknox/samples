import os
import sys
basedir = os.path.abspath(os.path.dirname(__file__))


class Config(object):

    # Normally don't revert to default, but this app is intentionally vulnerable soooo
    SECRET_KEY = os.environ.get('SECRET_KEY') or "e88e10cd-d4fc-44e6-ad66-f04c93633f17"

    UPLOAD_DIR = os.path.join(basedir, 'uploads')
    MAX_CONTENT_LENGTH = 16 * 1024 * 1024
