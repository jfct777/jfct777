#!/usr/bin/env nextflow

/*
 * Pipeline para análisis tradicional de genética de poblaciones
 * Incluye: QC, alineamiento, variantes, estructura poblacional y análisis de diversidad
 */

// Parámetros por defecto
params.reads = "$baseDir/test_data/*_{1,2}.fastq.gz"
params.genome = "$baseDir/test_data/reference.fa"
params.outdir = 'results'

// Cabecera del workflow
log.info """
         WORKFLOW DE GENÉTICA DE POBLACIONES
         ===================================
         reads        : ${params.reads}
         genome      : ${params.genome}
         outdir      : ${params.outdir}
         """

// Procesos principales
process FASTQC {
    container 'quay.io/biocontainers/fastqc:0.11.9--0'

    input:
    tuple val(sample_id), path(reads)

    output:
    path "fastqc_${sample_id}_logs"

    script:
    """
    mkdir fastqc_${sample_id}_logs
    fastqc -o fastqc_${sample_id}_logs -f fastq -q ${reads}
    """
}

process BWA_ALIGN {
    container 'quay.io/biocontainers/bwa:0.7.17--h5bf99c6_8'

    input:
    tuple val(sample_id), path(reads)
    path genome

    output:
    tuple val(sample_id), path("${sample_id}.bam")

    script:
    """
    bwa mem $genome ${reads[0]} ${reads[1]} | \
    samtools sort -o ${sample_id}.bam
    """
}

process CALL_VARIANTS {
    container 'quay.io/biocontainers/gatk4:4.2.6.1--hdfd78af_0'

    input:
    tuple val(sample_id), path(bam)
    path genome

    output:
    path "${sample_id}.vcf"

    script:
    """
    gatk HaplotypeCaller \
        -R $genome \
        -I $bam \
        -O ${sample_id}.vcf
    """
}

process POPULATION_STRUCTURE {
    container 'quay.io/biocontainers/admixture:1.3.0--h516909a_1'

    input:
    path vcfs

    output:
    path "structure_results"

    script:
    """
    mkdir structure_results
    plink --vcf $vcfs --make-bed --out population
    admixture population.bed 3
    """
}

// Workflow principal
workflow {
    // Canal de entrada para los reads
    read_pairs_ch = Channel
        .fromFilePairs(params.reads, checkIfExists: true)

    // Canal para el genoma de referencia
    genome_ch = Channel.fromPath(params.genome)

    // Ejecución de procesos
    fastqc_results = FASTQC(read_pairs_ch)
    aligned_reads = BWA_ALIGN(read_pairs_ch, genome_ch)
    variants = CALL_VARIANTS(aligned_reads, genome_ch)
    population_structure = POPULATION_STRUCTURE(variants.collect())
}
