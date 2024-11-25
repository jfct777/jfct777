# Workflows de Genética de Poblaciones

Este repositorio contiene dos workflows de Nextflow para análisis de genética de poblaciones:

## 1. Workflow Tradicional

Realiza análisis tradicionales de genética de poblaciones:
- Control de calidad con FastQC
- Alineamiento con BWA
- Llamado de variantes con GATK
- Análisis de estructura poblacional con Admixture

## 2. Workflow de Deep Learning

Implementa análisis basados en aprendizaje profundo:
- Preprocesamiento de datos VCF
- Entrenamiento de modelo CNN
- Predicción de estructura poblacional

## Uso

### Workflow Tradicional
```bash
nextflow run workflows/traditional/main.nf \
    --reads 'test_data/fastq/*_{1,2}.fastq' \
    --genome 'test_data/reference/reference.fa'
```

### Workflow de Deep Learning
```bash
nextflow run workflows/deeplearning/main.nf \
    --vcf 'test_data/*.vcf'
```

## Requisitos
- Nextflow
- Docker/Singularity
- Python 3.8+
- TensorFlow 2.x
