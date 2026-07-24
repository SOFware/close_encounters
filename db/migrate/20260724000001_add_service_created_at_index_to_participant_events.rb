class AddServiceCreatedAtIndexToParticipantEvents < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    options = if self.class.adapter_name.match?(/postgres/i)
      {algorithm: :concurrently}
    else
      {}
    end

    # Supports the hot "newest event for a service" lookup:
    # WHERE close_encounters_participant_service_id = ? ORDER BY created_at DESC.
    add_index :close_encounters_participant_events,
      [:close_encounters_participant_service_id, :created_at],
      name: "idx_ce_events_on_service_and_created_at",
      **options
  end
end
