# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2019 Ekylibre SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: registered_phytosanitary_products
#
#  active_compounds             :string
#  allowed_mentions             :jsonb
#  firm_name                    :string
#  id                           :integer          not null, primary key
#  in_field_reentry_delay       :integer
#  maaid                        :string           not null
#  mix_category_code            :string           not null
#  name                         :string           not null
#  nature                       :string
#  operator_protection_mentions :text
#  other_name                   :string
#  product_type                 :string
#  restricted_mentions          :string
#  started_on                   :date
#  state                        :string           not null
#  stopped_on                   :date
#
require 'test_helper'

class RegisteredPhytosanitaryProductTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  # Add tests here...
end