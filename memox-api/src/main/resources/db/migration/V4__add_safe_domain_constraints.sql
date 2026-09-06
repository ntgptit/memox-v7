ALTER TABLE decks
    ADD CONSTRAINT ck_decks_sibling_position_non_negative CHECK (sibling_position >= 0),
    ADD CONSTRAINT ck_decks_scheduler_version_positive CHECK (scheduler_version IS NULL OR scheduler_version > 0),
    ADD CONSTRAINT ck_decks_scheduler_generation_positive CHECK (scheduler_generation IS NULL OR scheduler_generation > 0);

ALTER TABLE card_study_states
    ADD CONSTRAINT ck_card_study_states_scheduler_version_positive CHECK (scheduler_version > 0),
    ADD CONSTRAINT ck_card_study_states_scheduler_generation_positive CHECK (scheduler_generation > 0);

ALTER TABLE app_settings
    ADD CONSTRAINT ck_app_settings_card_limit_positive CHECK (card_limit > 0);
