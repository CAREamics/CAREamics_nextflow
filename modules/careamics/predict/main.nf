process CAREAMICS_PREDICT {
    tag "$meta.id"
    label 'process_gpu_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    'oras://community.wave.seqera.io/library/careamics:0.0.21--5130b64e7194c8c6' :
    'community.wave.seqera.io/library/careamics:0.0.21--300ee53ce7b54c00' }"

    input:
    tuple val(meta), path(test_data), path(model)

    output:
    tuple val(meta), path("predictions/*")      , emit: predictions
    path "versions.yml"                          , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args ?: ''
    """
    predict.py \\
        --trained_model $model \\
        --test_data $test_data \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        careamics: \$(python -c "import careamics; print(careamics.__version__)")
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p predictions
    touch predictions/${prefix}_denoised.tiff

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        careamics: \$(python -c "import careamics; print(careamics.__version__)")
    END_VERSIONS
    """
}
