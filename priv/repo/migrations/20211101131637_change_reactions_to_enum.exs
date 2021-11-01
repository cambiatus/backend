defmodule Cambiatus.Repo.Migrations.ChangeReactionsToEnum do
  use Ecto.Migration

  def up do
    execute("""
    CREATE TYPE reaction_type As ENUM
    (
      'grinning_face_with_big_eyes',
      'smiling_face_with_heart_eyes',
      'slightly_frowning_face',
      'face_with_raised_eyebrow',
      'thumbs_up',
      'thumbs_down',
      'clapping_hands',
      'party_popper',
      'red_heart',
      'rocket'
    )
    """)

    alter table(:news_receipts) do
      remove(:reactions)
      add(:reactions, {:array, :reaction_type}, comment: "Reactions to the text")
    end
  end

  def down do
    alter table(:news_receipts) do
      remove(:reactions)
      add(:reactions, {:array, :string}, comment: "Reactions to the text")
    end

    execute("DROP TYPE reaction_type")
  end
end
