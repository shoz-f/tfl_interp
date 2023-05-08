import tensorflow as tf
from tensorflow import keras

inputs=keras.Input(shape=(10,10,1))
outputs = tf.compat.v1.extract_image_patches(inputs, ksizes=[1,3,3,1], strides=[1,1,1,1], rates=[1,1,1,1], padding='SAME')
model = keras.Model(inputs, outputs)
model.save('test_eip')

converter = tf.lite.TFLiteConverter.from_saved_model('test_eip')
converter.allow_custom_ops = True
tflite_model = converter.convert()

open('test_eip.tflite', 'wb').write(tflite_model)
