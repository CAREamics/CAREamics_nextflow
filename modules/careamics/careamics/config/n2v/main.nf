process CAREAMICS_CONFIG_N2V {
    tag "${meta.id ?: task.process}"
    label 'process_medium'

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
    tuple val(meta), val(experiment_name), val(data_type), val(axes), val(patch_size), val(batch_size)

    output:
    tuple val(meta), path("careamics.yaml"), emit: careamics_config
    path "versions.yml", emit: versions, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    create_config_n2v.py \\
        --output_path . \\
        --experiment_name ${experiment_name} \\
        --data_type ${data_type} \\
        --axes ${axes} \\
        --patch_size ${patch_size} \\
        --batch_size ${batch_size} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        careamics: \$(python -c "import careamics; print(careamics.__version__)")
    END_VERSIONS
    """

    stub:
    """
    touch careamics.yaml

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        careamics: "stub"
    END_VERSIONS
    """
}
