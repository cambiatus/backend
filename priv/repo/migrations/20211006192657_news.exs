defmodule Cambiatus.Repo.Migrations.News do
  use Ecto.Migration

  def change do
    create table(:news) do
      add(:community_id, references(:communities, column: :symbol, type: :string, null: false))
      add(:title, :string, comment: "Title of the news, bring impact!")

      add(:description, :string,
        comment: "Full text. We store them using markdown pattern of QuillJS"
      )

      add(:scheduling, :utc_datetime,
        comment: "Datetime when the news will be available for everyone"
      )

      add(:user_id, references(:users, column: :account, type: :string), null: false)

      timestamps()
    end

    create table(:news_versions) do
      add(:news_id, references(:news))
      add(:title, :string, comment: "Title of the news, bring impact!")

      add(:description, :string,
        comment: "Full text. We store them using markdown pattern of QuillJS"
      )

      add(:scheduling, :utc_datetime,
        comment: "Datetime when the news will be available for everyone"
      )

      add(:user_id, references(:users, column: :account, type: :string))

      timestamps()
    end

    create table(:news_receipts) do
      add(:news_id, references(:news))
      add(:user_id, references(:users, column: :account, type: :string))
      add(:reactions, {:array, :string}, comment: "Reactions to the text")

      timestamps()
    end

    alter table(:communities) do
      add(:has_news, :boolean,
        default: false,
        comment:
          "Flag that indicates if the community has enabled news. Its possible to have old news and disable this option anyway (non destructive)"
      )

      add(:highlighted_news_id, references(:news),
        comment: "The current highlighted news from the community"
      )
    end
  end
end
