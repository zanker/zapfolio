class Usercp::BaseController < ApplicationController
  layout "usercp"
  respond_to :html, :json

  before_filter :require_logged_in
  before_filter :load_website

  protected
  def load_website
    @website = Website.where(:user_id => current_user._id).first
    return redirect_to setup_path unless @website
  end

  def optional_load_website
    @website = Website.where(:user_id => current_user._id).first
  end

  def default_kicker(inject=nil)
    @kicker = {:website => @website, :pages => @website ? @website.pages.sort(:_id) : nil, :albums => current_user.albums.sort(:_id)}
    @kicker.merge!(inject) if inject

    respond_with do |format|
      format.html { render :kicker }
    end
  end

  def respond_with_model(model, status=:ok, inject=nil)
    if model.errors.empty?
      render :json => inject ? inject.merge(model.serializable_hash) : model, :status => status
    else
      data = {:errors => {}.merge(model.errors.messages), :attributes => {}, :scope => model.class.collection_name.singularize}
      data[:errors].each_key {|e| data[:attributes][e] = model.class.human_attribute_name(e)}

      # Check for children
      data[:errors].merge!(load_model_errors(model, data[:attributes]))

      render :json => data, :status => :bad_request
    end
  end

  def load_model_errors(model, attrib_scope)
    errors = {}

    model.associations.each do |key, assoc|
      next unless assoc.embeddable? and model.errors[key]
      embedded = model.send(key)
      next unless embedded

      errors[key] = {}

      # Multiple embedded
      if assoc.is_a?(MongoMapper::Plugins::Associations::ManyAssociation)
        embedded.each do |child|
          next if child.errors.empty?

          errors[key][child._id] = {}.merge(child.errors.messages)
          errors[key][child._id].each_value {|v| v.uniq!}
          errors[key][child._id].each_key {|e| attrib_scope[e] = assoc.klass.human_attribute_name(e)}
          errors[key][child._id].merge!(load_model_errors(child, attrib_scope))
        end

      # Single embedded, merge any errors
      else
        errors[key].merge!(embedded.errors.messages)
        errors[key].each_value {|v| v.uniq!}
        errors[key].each_key {|e| attrib_scope[e] = assoc.klass.human_attribute_name(e)}

        errors[key].merge!(load_model_errors(embedded, attrib_scope))
      end

      if errors[key].empty?
        errors.delete(key)
        next
      end
    end

    errors
  end
end