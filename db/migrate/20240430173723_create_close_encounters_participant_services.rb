class CreateCloseEncountersParticipantServices < ActiveRecord::Migration[7.1]
  def change
    create_table :close_encounters_participant_services do |t|
      t.string :name, null: false
      if ActiveRecord::Base.connection.adapter_name.downcase.include?("postgresql")
        t.jsonb :connection_info
      else
        t.text :connection_info
      end

      t.timestamps
    end
  end
end
