from flask_wtf import FlaskForm
from wtforms import SubmitField
from flask_wtf.file import FileField, FileAllowed, FileRequired


class UploadForm(FlaskForm):
    pickle_file = FileField('file', validators=[FileRequired(), FileAllowed(['pkl'], 'Only JSON and Text Files allowed!')])
    submit = SubmitField('Upload')
