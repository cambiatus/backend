defmodule Cambiatus.Repo.Migrations.CommunityContacts do
  use Ecto.Migration

  def change do
    alter table(:contacts) do
      add(
        :community_id,
        references(:communities,
          column: :symbol,
          type: :string
        ),
        comment: "Reference to the community this contact belongs to."
      )

      add(:label, :text,
        comment: "Optional label that can be used to better identify a contact information."
      )

      modify(:user_id, references(:users, column: :account, type: :string),
        comment: "Reference to the user this contact belongs to.",
        from: references(:users, column: :account, type: :string)
      )

      modify(:type, :contact_type,
        null: false,
        comment: "Type of the contact: check contact_type Enum"
      )

      modify(:external_id, :string,
        null: false,
        comment: "External ID. Can be in any format allowed by the type"
      )
    end

    create(
      constraint(:contacts, :contact_must_belong_user_or_community,
        check: "(community_id IS NULL) <> (user_id IS NULL)"
      )
    )
  end
end
