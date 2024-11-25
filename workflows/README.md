# Workflows de Genética de Poblaciones

Este repositorio contiene dos workflows de Nextflow para análisis de genética de poblaciones:

## 1. Workflow Tradicional
Ubicado en `workflows/traditional/main.nf`, este workflow incluye:
- Control de calidad con FastQC
- Alineamiento con BWA
- Llamado de variantes con GATK
- Análisis de estructura poblacional con Admixture

## 2. Workflow de Deep Learning
Ubicado en `workflows/deeplearning/main.nf`, este workflow incluye:
- Preprocesamiento de datos genómicos
- Entrenamiento de modelo CNN
- Predicción de estructura poblacional

## Requisitos
- Nextflow
- Docker/Singularity
- Python 3.8+
- GPU (recomendado para el workflow de deep learning)

## Uso
Para ejecutar los workflows:

```bash
# Workflow tradicional
nextflow run workflows/traditional/main.nf --reads 'data/*_{1,2}.fastq.gz' --genome 'reference.fa'

# Workflow de deep learning
nextflow run workflows/deeplearning/main.nf --vcf 'data/*.vcf'
```
