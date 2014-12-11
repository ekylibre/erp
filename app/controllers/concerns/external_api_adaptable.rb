# module ExternalApiAdaptable
# this module is intended to adapt easily Ekylibre
# to external APIs just by telling the controller
# how to translate API input/output to its Ekylibre equivalent

module ExternalApiAdaptable
  extend ActiveSupport::Concern

  module ClassMethods
    def manage_restfully(defaults = {})
      options = defaults.extract! :only, :except
      actions  = [:index, :show, :new, :create, :edit, :update, :destroy]
      actions &= [options[:only]].flatten   if options[:only]
      actions -= [options[:except]].flatten if options[:except]

      name = self.controller_name
      record_name = name.to_s.singularize
      model = name.to_s.singularize.classify.constantize
      records = model.name.underscore.pluralize

      methods =
        {
          index:  lambda{@records = model.all; render template: "layouts/json/index"},
          show:   lambda{@record = model.find(permitted_params[:id]); render template: "layouts/json/show"}
        }

      actions.each do |action|
        define_method action, methods[action]
      end

      define_method :permitted_params do
        params.permit!
      end
      private :permitted_params
    end
  end
end
