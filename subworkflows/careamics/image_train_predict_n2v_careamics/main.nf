include { CAREAMICS_CONFIG_N2V          } from '../../../modules/careamics/config/n2v/main'
include { IMAGE_TRAIN_PREDICT_CAREAMICS } from '../image_train_predict_careamics/main'

workflow IMAGE_TRAIN_PREDICT_N2V_CAREAMICS {
    take:
    ch_config // channel: [ val(meta), val(experiment_name), val(data_type), val(axes), val(patch_size), val(batch_size) ]
    ch_train_data // channel: [ val(meta), path(train_data) ]
    ch_predict // channel: [ val(meta), path(data) ]

    main:
    CAREAMICS_CONFIG_N2V(ch_config)

    ch_train = CAREAMICS_CONFIG_N2V.out.careamics_config
        .combine(ch_train_data)
        .map { config_meta, careamics_config, train_meta, train_data, train_target ->
            def meta = config_meta + train_meta
            [meta, careamics_config, train_data, train_target, [], []]
        }

    IMAGE_TRAIN_PREDICT_CAREAMICS(ch_train, ch_predict)

    emit:
    careamics_config = CAREAMICS_CONFIG_N2V.out.careamics_config // [ val(meta), path(careamics_config) ]
    model            = IMAGE_TRAIN_PREDICT_CAREAMICS.out.model // [ val(meta), path(model) ]
    predictions      = IMAGE_TRAIN_PREDICT_CAREAMICS.out.predictions // [ val(meta), path(predictions) ]
    versions         = CAREAMICS_CONFIG_N2V.out.versions.mix(IMAGE_TRAIN_PREDICT_CAREAMICS.out.versions) // [ path(versions.yml) ]
}
