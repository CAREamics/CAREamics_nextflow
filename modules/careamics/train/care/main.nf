process CAREAMICS_TRAIN_CARE {
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
    tuple val(meta), path(train_data, name: "train_data"), path(target_data, name: "target_data"), path(val_data, name: "val_data"), path(val_target, name: "val_target")

    output:
    tuple val(meta), path("*.yaml"), emit: config
    // TODO: get real checkpoint name from CAREamist.get_checkpoints
    tuple val(meta), path("checkpoints/*/*last.ckpt"), emit: model
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    if ((val_data && !val_target) || (!val_data && val_target)) {
        error "Both val_data and val_target must be provided for ${task.process}, or neither."
    }
    def val_args = val_data ? "--val_data ${val_data} --val_target ${val_target}" : ''
    """
    train_care.py \\
        --train_data ${train_data} \\
        --train_target ${target_data} \\
        ${val_args} \\
        --output_path . \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        careamics: \$(python -c "import careamics; print(careamics.__version__)")
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch "${prefix}_config.yaml"
    mkdir -p checkpoints/stub
    touch checkpoints/stub/last.ckpt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        careamics: stub
    END_VERSIONS
    """
}
