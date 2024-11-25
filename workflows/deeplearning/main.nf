#!/usr/bin/env nextflow

/*
 * Pipeline para análisis de genética de poblaciones usando Deep Learning
 * Incluye: Preprocesamiento, entrenamiento de modelos CNN/RNN y predicción
 */

// Parámetros por defecto
params.vcf = "$baseDir/test_data/*.vcf"
params.outdir = 'results'
params.epochs = 100
params.batch_size = 32

// Cabecera del workflow
log.info """
         WORKFLOW DE DEEP LEARNING PARA GENÉTICA DE POBLACIONES
         ====================================================
         vcf         : ${params.vcf}
         outdir      : ${params.outdir}
         epochs      : ${params.epochs}
         batch_size  : ${params.batch_size}
         """

process PREPARE_DATA {
    container 'tensorflow/tensorflow:latest-gpu'

    input:
    path vcf_files

    output:
    path 'processed_data'

    script:
    """
    #!/usr/bin/env python3
    import allel
    import numpy as np
    import os

    # Crear directorio para datos procesados
    os.makedirs('processed_data', exist_ok=True)

    # Cargar VCF y convertir a formato numpy
    callset = allel.read_vcf('${vcf_files}')
    genotypes = callset['calldata/GT']

    # Guardar datos procesados
    np.save('processed_data/genotypes.npy', genotypes)
    """
}

process TRAIN_MODEL {
    container 'tensorflow/tensorflow:latest-gpu'

    input:
    path processed_data

    output:
    path 'model'

    script:
    """
    #!/usr/bin/env python3
    import tensorflow as tf
    import numpy as np

    # Cargar datos
    X = np.load('${processed_data}/genotypes.npy')

    # Definir modelo CNN
    model = tf.keras.Sequential([
        tf.keras.layers.Conv1D(32, 3, activation='relu', input_shape=(X.shape[1], X.shape[2])),
        tf.keras.layers.MaxPooling1D(2),
        tf.keras.layers.Conv1D(64, 3, activation='relu'),
        tf.keras.layers.MaxPooling1D(2),
        tf.keras.layers.Flatten(),
        tf.keras.layers.Dense(64, activation='relu'),
        tf.keras.layers.Dense(10, activation='softmax')
    ])

    # Compilar y entrenar
    model.compile(optimizer='adam',
                 loss='sparse_categorical_crossentropy',
                 metrics=['accuracy'])

    model.fit(X, epochs=${params.epochs}, batch_size=${params.batch_size})

    # Guardar modelo
    model.save('model')
    """
}

process PREDICT {
    container 'tensorflow/tensorflow:latest-gpu'

    input:
    path model
    path test_data

    output:
    path 'predictions.txt'

    script:
    """
    #!/usr/bin/env python3
    import tensorflow as tf
    import numpy as np

    # Cargar modelo y datos
    model = tf.keras.models.load_model('${model}')
    X_test = np.load('${test_data}/genotypes.npy')

    # Realizar predicciones
    predictions = model.predict(X_test)

    # Guardar predicciones
    np.savetxt('predictions.txt', predictions)
    """
}

// Workflow principal
workflow {
    // Canal de entrada para archivos VCF
    vcf_files_ch = Channel
        .fromPath(params.vcf)
        .collect()

    // Ejecución de procesos
    processed_data = PREPARE_DATA(vcf_files_ch)
    trained_model = TRAIN_MODEL(processed_data)
    predictions = PREDICT(trained_model, processed_data)
}
