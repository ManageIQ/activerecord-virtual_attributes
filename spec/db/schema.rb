# encoding: UTF-8

ActiveRecord::Schema.define(:version => 0) do
  self.verbose = false

  create_table "samples", :force => true do |t|
    t.string "name"
  end

  add_index "samples", [:name], :unique => true
#  add_index "label_hierarchies", [:ancestor_id, :descendant_id, :generations], :unique => true, :name => "lh_anc_desc_idx"
#  add_foreign_key(:menu_item_hierarchies, :menu_items, :column => 'descendant_id')

  create_table :test_classes, :force => true do |t|
    t.integer :col1
  end

  create_table :test_other_classes, :force => true do |t|
    t.integer :ocol1
    t.string  :ostr
  end
end
