class Init < ActiveRecord::Migration[6.1]
  def change
    create_table :realms do |t|
      t.integer :blizz_id
      t.string :slug
      t.integer :region
      t.boolean :status
      t.string :population
      t.string :category
      t.string :locale
      t.string :timezone
      t.string :realm_type
      t.timestamps
    end

    create_table :realm_names do |t|
      t.belongs_to :realm
      t.string :locale
      t.string :name
      t.timestamps
    end

    create_table :items do |t|
      t.integer :item_id, index: true
      t.string :quality
      t.integer :class_id
      t.integer :subclass_id
      t.string :binding
      t.string :version
    end

    create_table :item_names do |t|
      t.belongs_to :item
      t.string :locale
      t.string :name
    end
  end
end
