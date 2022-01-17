# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_09_28_113028) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "item_names", force: :cascade do |t|
    t.bigint "item_id"
    t.string "locale"
    t.string "name"
    t.index ["item_id"], name: "index_item_names_on_item_id"
  end

  create_table "items", force: :cascade do |t|
    t.integer "item_id"
    t.string "quality"
    t.integer "class_id"
    t.integer "subclass_id"
    t.string "binding"
    t.string "version"
    t.index ["item_id"], name: "index_items_on_item_id"
  end

  create_table "realm_names", force: :cascade do |t|
    t.bigint "realm_id"
    t.string "locale"
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["realm_id"], name: "index_realm_names_on_realm_id"
  end

  create_table "realms", force: :cascade do |t|
    t.integer "blizz_id"
    t.string "slug"
    t.integer "region"
    t.boolean "status"
    t.string "population"
    t.string "category"
    t.string "locale"
    t.string "timezone"
    t.string "realm_type"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

end
