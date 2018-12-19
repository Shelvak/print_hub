class Upfront < ActiveRecord::Base
  KIND = [
    :upfront,
    :to_favor,
    :refunded
  ]

  establish_connection :"abaco_#{Rails.env}"
  self.table_name = 'movements'

  attr_accessor :auto_operator_name, :operator_id
  default_scope { where(kind: KIND.find_index(:upfront)) }

  belongs_to :user
  belongs_to :operator, foreign_key: :to_account_id, class_name: 'User'

  before_validation :assign_operator_attrs
  before_save :set_abaco_defaults

  def initialize(attributes={})
    super(attributes)

    self.kind ||= KIND.find_index(:upfront)
  end

  def assign_operator_attrs
    self.to_account_type = 'Operator'
    self.to_account_id   = operator_id
  end

  def set_abaco_defaults
    self.bought_at = Time.zone.now
    self.comment = I18n.t(
      'view.shift_closures.created_by_operator',
      name: self.user
    )
  end
end
