#!/usr/bin/env nextflow

params.reads = "test_data/fastq/*_{1,2}.fastq"
params.genome = "test_data/reference/reference.fa"
params.outdir = "results"

// Proceso de Control de Calidad
process FASTQC {
    container 'quay.io/biocontainers/fastqc:0.11.9--0'

    input:
    tuple val(name), path(reads)

    output:
    path "fastqc_results"

    script:
    """
    mkdir fastqc_results
    fastqc -o fastqc_results ${reads}
    """
}

// Proceso de Alineamiento
process BWA_ALIGN {
    container 'quay.io/biocontainers/bwa:0.7.17--h5bf99c6_8'

    input:
    tuple val(name), path(reads)
    path genome

    output:
    path "${name}.bam"

    script:
    """
    bwa mem ${genome} ${reads[0]} ${reads[1]} | \
    samtools sort -o ${name}.bam
    """
}

// Proceso de Llamado de Variantes
process GATK_HC {
    container 'broadinstitute/gatk:4.2.6.1'

    input:
    path bam
    path genome

    output:
    path "variants.vcf"

    script:
    """
    gatk HaplotypeCaller \
        -R ${genome} \
        -I ${bam} \
        -O variants.vcf
    """
}

// Proceso de Análisis de Estructura Poblacional
process ADMIXTURE {
    container 'quay.io/biocontainers/admixture:1.3.0--h516909a_1'

    input:
    path vcf

    output:
    path "population_structure"

    script:
    """
    mkdir population_structure
    plink --vcf ${vcf} --make-bed --out data
    admixture data.bed 5 --cv
    """
}

workflow {
    reads_ch = Channel.fromFilePairs(params.reads)
    genome_ch = Channel.fromPath(params.genome)

    FASTQC(reads_ch)
    BWA_ALIGN(reads_ch, genome_ch)
    GATK_HC(BWA_ALIGN.out, genome_ch)
    ADMIXTURE(GATK_HC.out)
}
