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
    tuple val("${task.process}"), val('careamics'), eval('python -c "import careamics; print(careamics.__version__)"'), emit: versions_careamics, topic: versions

    script:
    def args = task.ext.args ?: ''
    """
    predict.py \\
        --ckpt_path ${model} \\
        --data ${data} \\
        ${args}

    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p predictions
    touch predictions/${prefix}_denoised.tiff

    """
}
