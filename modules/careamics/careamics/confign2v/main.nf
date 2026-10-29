process CAREAMICS_CONFIGN2V {
    tag "${meta.id ?: task.process}"
    label 'process_single'

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
