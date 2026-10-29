process CAREAMICS_PREDICT {
    tag "${meta.id ?: task.process}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container {
        def is_singularity = workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container

        if (is_singularity) {
            return 'oras://ghcr.io/careamics/careamics-sif:0.3.5-cuda11.8'
        }
        else {
            return 'ghcr.io/careamics/careamics:0.3.5-cuda11.8'
        }
    }

    input:
    tuple val(meta), path(data), path(model)

    output:
    tuple val(meta), path("predictions/*"), emit: predictions
    path "versions.yml", emit: versions, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    predict.py \\
        --ckpt_path ${model} \\
        --data ${data} \\
        ${args}

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
        careamics: "stub"
    END_VERSIONS
    """
}
