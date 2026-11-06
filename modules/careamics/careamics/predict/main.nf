process CAREAMICS_PREDICT {
    tag "${meta.id ?: task.process}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container {
        def active_profiles = workflow.profile ? workflow.profile.tokenize(',') : []
        def is_oras_profile = active_profiles.any { it in ['singularity_oras', 'apptainer_oras'] }

        if (is_oras_profile) {
            return 'oras://ghcr.io/careamics/careamics-sif:0.3.5-cuda11.8'
        } else {
            return 'ghcr.io/careamics/careamics:0.3.5-cuda11.8'
        }
    }

    input:
    tuple val(meta), path(data), path(model)

    output:
    tuple val(meta), path("predictions/*"), emit: predictions
    tuple val("${task.process}"), val('careamics'), eval('python -c "import careamics; print(careamics.__version__)"'), emit: versions_careamics, topic: versions
    tuple val("${task.process}"), val('torch'), eval('python -c "import torch; print(torch.__version__)"'), emit: versions_torch, topic: versions
    tuple val("${task.process}"), val('cuda'), eval('python -c "import torch; print(torch.version.cuda or \'no CUDA available\')"'), emit: versions_cuda, topic: versions
    tuple val("${task.process}"), val('python'), eval('python -c "import platform; print(platform.python_version())"'), emit: versions_python, topic: versions

    when:
    task.ext.when == null || task.ext.when

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
