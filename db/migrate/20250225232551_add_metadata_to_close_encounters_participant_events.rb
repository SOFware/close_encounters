class AddMetadataToCloseEncountersParticipantEvents < ActiveRecord::Migration[7.1]
  def change
    if ActiveRecord::Base.connection.adapter_name.downcase.include?("postgresql")
      add_column :close_encounters_participant_events, :metadata, :jsonb
    else
      add_column :close_encounters_participant_events, :metadata, :text
    end
  end
end
