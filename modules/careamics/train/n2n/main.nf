process CAREAMICS_TRAIN_N2N {
    tag "$meta.id"
    label 'process_gpu_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    'oras://community.wave.seqera.io/library/careamics:0.0.21--5130b64e7194c8c6' :
    'community.wave.seqera.io/library/careamics:0.0.21--300ee53ce7b54c00' }"

    input:
    tuple val(meta), path(train_data), path(target_data,name: "target/*")

    output:
    tuple val(meta), path("*.yaml")             , emit: config
    tuple val(meta), path("checkpoints/last.ckpt"), emit: model
    path "versions.yml"                          , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args ?: ''
    def model_type = meta.model ?: 'n2n'
    """
    train_n2n.py \\
        --train_data $train_data \\
        --train_target $target_data \\
        --model $model_type \\
        --output_path . \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        careamics: \$(python -c "import careamics; print(careamics.__version__)")
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch "${prefix}_config.yaml"
    mkdir -p checkpoints
    touch checkpoints/last.ckpt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        careamics: \$(python -c "import careamics; print(careamics.__version__)")
    END_VERSIONS
    """
}
