#!/usr/bin/env nextflow

params.vcf = "test_data/*.vcf"
params.outdir = "results"
params.epochs = 100
params.batch_size = 32

// Proceso de Preparación de Datos
process PREPARE_DATA {
    container 'tensorflow/tensorflow:latest-gpu'

    input:
    path vcf

    output:
    path "processed_data.npz"

    script:
    """
    #!/usr/bin/env python3
    import allel
    import numpy as np

    # Cargar datos VCF
    callset = allel.read_vcf('${vcf}')
    genotypes = callset['calldata/GT']

    # Convertir a matriz numpy
    X = genotypes.reshape(genotypes.shape[0], -1)

    # Guardar datos procesados
    np.savez('processed_data.npz', X=X)
    """
}

// Proceso de Entrenamiento del Modelo
process TRAIN_MODEL {
    container 'tensorflow/tensorflow:latest-gpu'

    input:
    path data

    output:
    path "model.h5"

    script:
    """
    #!/usr/bin/env python3
    import numpy as np
    import tensorflow as tf

    # Cargar datos
    data = np.load('${data}')
    X = data['X']

    # Definir modelo CNN
    model = tf.keras.Sequential([
        tf.keras.layers.Conv1D(32, 3, activation='relu', input_shape=(X.shape[1], 1)),
        tf.keras.layers.MaxPooling1D(2),
        tf.keras.layers.Flatten(),
        tf.keras.layers.Dense(64, activation='relu'),
        tf.keras.layers.Dense(5, activation='softmax')
    ])

    # Compilar y entrenar
    model.compile(optimizer='adam', loss='sparse_categorical_crossentropy')
    model.fit(X, epochs=${params.epochs}, batch_size=${params.batch_size})

    # Guardar modelo
    model.save('model.h5')
    """
}

// Proceso de Predicción
process PREDICT {
    container 'tensorflow/tensorflow:latest-gpu'

    input:
    path model
    path data

    output:
    path "predictions.txt"

    script:
    """
    #!/usr/bin/env python3
    import numpy as np
    import tensorflow as tf

    # Cargar modelo y datos
    model = tf.keras.models.load_model('${model}')
    data = np.load('${data}')
    X = data['X']

    # Realizar predicciones
    predictions = model.predict(X)
    np.savetxt('predictions.txt', predictions)
    """
}

workflow {
    vcf_ch = Channel.fromPath(params.vcf)

    processed_data = PREPARE_DATA(vcf_ch)
    trained_model = TRAIN_MODEL(processed_data)
    PREDICT(trained_model, processed_data)
}
