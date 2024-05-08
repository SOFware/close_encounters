class CreateCloseEncountersParticipantEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :close_encounters_participant_events do |t|
      t.text :response
      t.references :close_encounters_participant_service, null: false, foreign_key: true
      t.integer :status, null: false

      t.timestamps
    end
  end
end
