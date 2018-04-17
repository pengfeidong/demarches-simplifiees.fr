class Service < ApplicationRecord
  has_many :procedures
  belongs_to :administrateur

  enum type_organisme: {
    administration_centrale: 'administration_centrale',
    region: 'region',
    prefecture: 'prefecture',
    departement: 'departement',
    commune: 'commune'
  }

  validates :nom, presence: { message: 'doit être renseigné' }, allow_nil: false
  validates :type_organisme, presence: { message: 'doit être renseigné' }, allow_nil: false
  validates :administrateur, presence: { message: 'doit être renseigné' }, allow_nil: false
end
