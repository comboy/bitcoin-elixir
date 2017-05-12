defmodule Bitcoin.Node.Storage.Engine.Postgres.Migration do
  use Ecto.Migration

  # TODO would be nice to switch to natural primary keys (hashes or hash + index in case of txin/out)
  # didn't yet test how well ecto plays with them

  # Also in many places there's just unsigned int and we are using bigint (there's no unsigned int in pg)
  # We could do https://gist.github.com/comboy/6b0edc7e51d1f94e0eabf8219ae0b805 but I'm not sure saving
  # a few bytes is worth having less clean database data.

  def change do

    #
    # Block
    #

    create table(:block) do
      add :version,        :integer, null: false
      add :previous_block, :binary,  null: false
      add :merkle_root,    :binary,  null: false
      add :timestamp,      :integer, null: false
      add :bits,           :integer, null: false
      add :nonce,          :bigint,  null: false
      add :transactions,   {:array, :binary}, null: false

      add :hash,           :binary,  null: false
      add :height,         :integer, null: false
      add :main_chain,     :boolean
    end

    create unique_index(:block, :hash)
    create index(:block, [:height, :main_chain])
    # version is signed
    create constraint(:block, "height_non_negative", check: "height >= 0")
    create constraint(:block, "nonce_non_negative", check: "nonce >= 0")
    create constraint(:block, "bits_non_negative", check: "bits >= 0")
    create constraint(:block, "timestamp_non_negative", check: "timestamp >= 0")

    #
    # Tx
    #

    create table(:tx) do
      add :hash,      :binary,  null: false
      add :version,   :integer, null: false
      add :lock_time, :bigint,  null: false
    end

    create unique_index(:tx, :hash)

    create constraint(:tx, "lock_time_non_negative", check: "lock_time >= 0")
    # version is signed

    #
    # TxOutput

    create table(:tx_output) do
      add :value,     :bigint, null: false
      add :pk_script, :binary, null: false

      add :tx_hash,   references(:tx, column: :hash, type: :binary)
      add :index,     :bigint, null: false
    end

    create unique_index(:tx_output, [:tx_hash, :index])

    #
    # TxInput
    #

    create table(:tx_input) do
      add :prevout_hash,  :binary, null: false
      add :prevout_index, :bigint, null: false
      add :sig_script,    :binary, null: false
      add :sequence,      :bigint, null: false

      add :tx_hash,       references(:tx, column: :hash, type: :binary)
      add :index,         :bigint, null: false
    end

    create unique_index(:tx_input, [:tx_hash, :index])

  end
end

