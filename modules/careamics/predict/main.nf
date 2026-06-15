process CAREAMICS_PREDICT {
    tag "${meta.id}"
    label 'process_gpu_medium'

    conda "${moduleDir}/environment.yml"
    container {
        def use_gpu = task.ext.use_gpu ?: false
        def is_singularity = workflow.containerEngine in ['singularity', 'apptainer']

        if (use_gpu && is_singularity) {
            return 'oras://ghcr.io/careamics/careamics-gpu-sif:0.2.0'
        }
        else if (!use_gpu && is_singularity) {
            return 'oras://ghcr.io/careamics/careamics-cpu-sif:0.2.0'
        }
        else if (use_gpu && !is_singularity) {
            return 'ghcr.io/careamics/careamics-gpu:0.2.0'
        }
        else {
            return 'ghcr.io/careamics/careamics-cpu:0.2.0'
        }
    }

    input:
    tuple val(meta), path(test_data), path(model)

    output:
    tuple val(meta), path("predictions/*"), emit: predictions
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    predict.py \\
        --ckpt_path ${model} \\
        --data ${test_data} \\
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
        careamics: \$(python -c "import careamics; print(careamics.__version__)")
    END_VERSIONS
    """
}
