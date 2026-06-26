include { CAREAMICS_TRAIN   } from '../../../modules/careamics/train/main'
include { CAREAMICS_PREDICT } from '../../../modules/careamics/predict/main'

workflow IMAGE_TRAIN_PREDICT_CAREAMICS {
    take:
    ch_train // [ val(meta), path(careamics_config), path(train_data), path(train_target), path(val_data), path(val_target) ]
    ch_predict // [ val(meta), path(data) ]

    main:
    CAREAMICS_TRAIN(ch_train)

    ch_predict_input = ch_predict
        .combine(CAREAMICS_TRAIN.out.model)
        .map { predict_meta, data, model_meta, model ->
            def meta = predict_meta + [model_id: model_meta.id]
            [meta, data, model]
        }

    CAREAMICS_PREDICT(ch_predict_input)

    emit:
    model       = CAREAMICS_TRAIN.out.model // [ val(meta), path(model) ]
    predictions = CAREAMICS_PREDICT.out.predictions // [ val(meta), path(predictions) ]
    versions    = CAREAMICS_TRAIN.out.versions.mix(CAREAMICS_PREDICT.out.versions) // [ path(versions.yml) ]
}
