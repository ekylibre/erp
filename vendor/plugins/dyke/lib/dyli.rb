# Dyli
module Ekylibre
  module Dyke
    module Dyli
      module Controller
        
        def self.included(base)
          base.extend(ClassMethods)
        end
        
        
        module ClassMethods
          
          include ERB::Util
          include ActionView::Helpers::TagHelper
          include ActionView::Helpers::UrlHelper
          
          #
          def dyli(name_db, options = {})
           
            options = {:limit => 12,:attributes => [:name], :filter => {:number => 'X%'}, :partial => nil}.merge(options)
                
            if options[:model].nil?
              model = name_db.to_s.camelize.constantize
            else
              model = options[:model].to_s.camelize.constantize
            end
            
                    
            unless options[:joins].nil?
               model_join = options[:joins].to_s.pluralize#.camelize.constantize
             end

            names_db = name_db.to_s.pluralize

            select = names_db.to_s+'.id, '
            select += names_db.to_s+"."+options[:attributes].each do |attribute|
              attribute.to_s
            end.join(', '+names_db.to_s+'.')

            displays = {}
            displays[:attributes]= options[:attributes]

            if options[:attributes_join]
              displays[:joins] = options[:attributes_join]
              select+= ', '
              options[:attributes_join].each do |join|
                select += options[:joins].to_s.first.to_s+'.'+join.to_s
              end.join(',')
            end
            
            code = ""
            
            #
            code += "def dyli_"+name_db.to_s+"\n"
            code += "conditions = [\"\"]\n"
            code += "search = params[:search].downcase\n"
            options[:conditions].collect do |key, value| 
              code += "conditions << "+sanitize_conditions(value)+"\n"
              code += "conditions[0] += '"+names_db.to_s+"."+key.to_s+" = ? AND '\n"
            end
            code += "conditions[0 ] += '"+names_db.to_s+".id = '+params[:real_object].to_s+' AND ' unless params[:real_object].nil?\n"
            code += "conditions[0] += '('\n"
            code += "conditions[0] += "+options[:attributes].inspect+".collect do |attribute|\n"
            code += "format = ("+options[:filter].inspect+"[attribute] ||'%X%').gsub('X', search)\n"
            code += "conditions << format\n"
            code += "'LOWER("+names_db.to_s+".'+attribute.to_s+') LIKE ? '\n"
            code += "end.join(\" OR \")\n"
            
            if model_join
              code += "joins = 'INNER JOIN "+model_join.to_s+" "+model_join.first.to_s+" ON "+model_join.first.to_s+".id = "+(options[:model] || name_db).to_s.pluralize.to_s+"."+options[:joins].to_s+"_id'\n"
              code += "conditions[0] += ' OR '\n"
              code += "conditions[0] += "+options[:attributes_join].inspect+".collect do |attribute|\n"
              code += "format = ("+options[:filter].inspect+"[attribute] ||'%X%').gsub('X', search)\n"
              code += "conditions << format\n"
              code += "'LOWER("+model_join.first.to_s+".'+attribute.to_s+') LIKE ? '\n"
              code += "end.join(\" OR \")\n"
            end
           
            code += "conditions[0] += ')'\n"
            code += "find_options = {" 
            code += ":select => "+select.inspect+","
            code += ":conditions => conditions,"
            code += ":joins => joins," unless model_join.nil?
            code += ":order => \"#{options[:attributes][0]} ASC\","
            code += ":limit => "+options[:limit].to_s+" }\n"
           
            code += "@items = "+model.to_s+".find(:all, find_options)\n" 
            
            if options[:partial]
              code += "render :inline => '<%= dyli_result(@items, '+search.to_s.inspect+',"+displays.inspect+","+options[:partial].inspect+") %>'\n"
            else
              code += "render :inline => '<%= dyli_result(@items, '+search.to_s.inspect+',"+displays.inspect+") %>'\n"
            end
            code += "end\n"        
            
            code += "def dyli_one_"+name.to_s+"\n"
            code += "search = params[:search].downcase\n"
            code += "conditions = [\"\"]\n"
            options[:conditions].collect do |key, value| 
              code += "conditions << "+sanitize_conditions(value)+"\n"
              code += "conditions[0] += '"+key.to_s+" = ? AND '\n"
            end
            
            code += "conditions[0] += '('\n"
            code += "conditions[0] += "+options[:attributes].inspect+".collect do |attribute|\n"
            code += "format = ("+options[:filter].inspect+"[attribute] ||'%X%').gsub('X', search)\n"
            code += "conditions << format\n"
            code += "'LOWER('+attribute.to_s+') LIKE ? '\n"
            code += "end.join(\" OR \")\n"
            code += "conditions[0] += ')'\n"
            code += "find_options = {" 
            code += ":conditions => conditions,"
            code += ":order => \"#{options[:attributes][0]} ASC\","
            code += ":limit => "+options[:limit].to_s+" }\n"
            code += "@item = "+model.to_s+".find(:first, find_options)\n"
           
            code += "@li_content=''\n"
            code += "@li_content = "+options[:attributes].inspect+".collect do |attribute|\n"
            code += "@item.send(attribute)\n"
            code += "end.join(', ')\n"

            code += "tf_id = params['tf']\n"
            code += "hf_id = params['hf']\n"
            code += "li_id = '"+model.to_s.downcase+"_'+@item.send(:id).to_s\n"
                      
            code += "render :inline => content_tag('li', @li_content.to_s+tag('input', :type =>'hidden', :value =>@item.send(:id).to_s, :id =>'record'), :id => li_id) \n"
           

            code += "end\n"        
           
            module_eval(code)
                     
          end
        end 
        
        def sanitize_conditions(value)
          if value.is_a? Array
            if value.size==1 and value[0].is_a? String
              value[0].to_s
            else
              value.inspect
            end
          elsif value.is_a? String
            '"'+value.gsub('"','\"')+'"'
          elsif [Date, DateTime].include? value.class
            '"'+value.to_formatted_s(:db)+'"'
          else
            value.to_s
          end
        end
        
      end
      
      
      module View
 
               #
        def dyli_tag(name_html, name_db, options={}, tag_options={}, completion_options={})
          tf_name  = "[search]"
          tf_value = nil
          hf_name  = "#{name_html}"
          hf_value =  nil
          options  = {:action => "dyli_#{name_db}"}.merge(options)
          
          completion_options[:skip_style] = true;
          
          dyli_completer(tf_name, tf_value, hf_name, hf_value, options, tag_options, completion_options)
        end
 
       
        #
        def dyli(object, association, name_db, options={}, tag_options={}, completion_options={})
          real_object = instance_variable_get("@#{object}")
          association = association.to_s[0..-4].to_sym if association.to_s.match(/_id$/)
          reflection  = real_object.class.reflect_on_association(association)
          raise Exception.new("Unknown reflection #{association} for #{real_object.class}") if reflection.nil?
          foreign_key = reflection.primary_key_name
                    
          name = name_db || association.to_s
          
          tf_name  = "[search]"
          tf_value = nil
          
          hf_name  = "#{object}[#{foreign_key}]"
          hf_value = (real_object.send(foreign_key) rescue nil)
          options  = { :action => "dyli_#{name}"}.merge(options)
          options[:real_object] = real_object.send(foreign_key) unless real_object.new_record?
           
          completion_options[:skip_style] = true;
          
          dyli_completer(tf_name, tf_value, hf_name, hf_value, options, tag_options, completion_options)
        end
        
        #
        def dyli_result(models, search, displays=[], partial=nil)
          # We can't assume dom_id(model) is available because the plugin does not require Rails 2 by now.
          prefix = models.first.class.name.underscore.tr('/', '_') unless models.empty?
          
         
          items = models.map do |model|
            li_id      = "#{prefix}_#{model.id}"
            li_content = displays[:attributes].collect {|display| model.send(display)}.join(', ')
            li_content += ','+displays[:joins].collect {|display| model.send(display)}.join(', ') if displays.include? :joins
            # if a partial is used or not to display the research.
            if partial
              content_tag('li', (render :partial => partial.to_s, :locals =>{:record=> model, :li_content => li_content, :search => search })+tag('input', :type =>'hidden', :value =>li_content, :id =>'record_'+model.id.to_s), :id => li_id)
            else
              content_tag('li', highlight(li_content, search)+tag('input', :type =>'hidden', :value =>li_content, :id =>'record_'+model.id.to_s), :id => li_id)
            end
          end
          content_tag('ul', items.uniq)
       end
        
        
        # tag
        def dyli_completer(tf_name, tf_value, hf_name, hf_value, options={}, tag_options={}, completion_options={})
          options = {
            :regexp_for_id        => '(\d+)$',
            :append_random_suffix => true,
            :allow_free_text      => false,
            :submit_on_return     => false,
            :controller           => controller.controller_name,
            :action               => 'dyli_' + tf_name.sub(/\[/, '_').gsub(/\[\]/, '_').gsub(/\[?\]$/, ''),
            :after_update_element => 'Prototype.emptyFunction'
          }.merge(options)
          
          options[:submit_on_return] = options[:send_on_return] if options[:send_on_return]
          
         
          hf_id, tf_id = determine_field_ids(options)
          determine_tag_options(tf_name, tf_value, hf_id, tf_id, options, tag_options)
          determine_completion_options(tf_id, hf_id, options, completion_options)
     
          return <<-HTML
       #{dyli_complete_stylesheet unless completion_options[:skip_style]}    
       #{hidden_field_tag(hf_name, hf_value, :id => hf_id)}
       #{text_field_tag(tf_name, tf_value, tag_options)}
       #{content_tag("div", " ", :id => "#{tf_id}_dyli_complete", :class => "dyli_complete")}
       #{dyli_complete_field tf_id, completion_options}
     HTML
        end
        
        #
        def dyli_complete_field(field_id, options = {})
          
          function =  "var #{field_id}_dyli_completer = new Ajax.Autocompleter("
          function << "'#{field_id}', "
          function << "'" + (options[:update] || "#{field_id}_dyli_complete") + "',"
          function << "'#{url_for(options[:url])}'"
          
          js_options = {}
          js_options[:tokens] = array_or_string_for_javascript(options[:tokens]) if options[:tokens]
          js_options[:callback]   = "function(element, value) { return #{options[:with]} }" if options[:with]
          js_options[:indicator]  = "'#{options[:indicator]}'" if options[:indicator]
          js_options[:select]     = "'#{options[:select]}'" if options[:select]
          js_options[:paramName]  = "'#{options[:param_name]}'" if options[:param_name]
          js_options[:frequency]  = "'#{options[:frequency]}'" if options[:frequency]
          js_options[:method]     = "'#{options[:method].to_s}'" if options[:method]

          { :after_update_element => :afterUpdateElement, 
            :on_show => :onShow, :on_hide => :onHide, :min_chars => :minChars }.each do |k,v|
            js_options[v] = options[k] if options[k]
          end

          function << (', ' + options_for_javascript(js_options) + ')')

          javascript_tag(function)
        end
        
        
        private
        
        #
        def dyli_complete_stylesheet
          content_tag('style', <<-EOT, :type => Mime::CSS)
        div.dyli_complete {
          width: 350px;
        }
        div.dyli_complete ul {
          position: fixed; 
          border:1px solid #888;
          margin:0;
          padding:0;
          width:30%;
          list-style-type:none;
        }
        div.dyli_complete ul li {
          background-color: #B1D1F9;
          margin:0;
          padding:3px;
        }
        div.dyli_complete ul li.selected {
          background-color: #C9D7F1;
        }
        div.dyli_complete ul strong.highlight {
          color: #800; 
          margin:0;
          padding:0;
        }
      EOT
        end
        
        #
        def determine_field_ids(options)
          hf_id = 'dyli_hf'
          tf_id = 'dyli_tf'
          if options[:append_random_suffix]
            rand_id = Digest::SHA1.hexdigest(Time.now.to_s.split(//).sort_by {rand}.join)
            hf_id << "_#{rand_id}"
           # tf_id << "_#{rand_id}"
          end
          return hf_id, tf_id
        end
        
        #  
        def determine_tag_options(tf_name, tf_value, hf_id, tf_id, options, tag_options)
          tag_options.update({
                               :id      => tf_id,
                               
                               # Cache the default text field value when the field gets focus.
                              # :onfocus => "this.value  = 4"
                               #:onfocus => "if (this.dyli == undefined) {this.dyli = this.value}"
                              # :onblur => remote_function(:update=> tf_id, :url => {:action => 'dyli_one_' + tf_name.sub(/\[/, '_').gsub(/\[\]/, '_').gsub(/\[?\]$/, ''), :tf => tf_id, :hf=> hf_id}, :with => "'search='+this.value")+";$('#{hf_id}').value= $('record').value;event.keyCode = Event.KEY_RETURN; $('#{tf_id}').size = ($('#{tf_id}').value.length > 128 ? 128 : $('#{tf_id}').value.length);"
                               
                             })


       #     tag_options[:onfocus] =  if  not options[:allow_free_text]
#                                      "if (this.dyli == undefined) {this.dyli = this.value}"
#                                     else
#                                       "this.dyli = 2"
#                                     end


            tag_options[:onchange] = if not options[:allow_free_text]             
                                       "window.setTimeout(function () {if (this.value != this.dyli) {$('#{hf_id}').value = ''} this.value=this.dyli;}.bind(this), 1000) "
                                     else
                                      # "window.setTimeout(function () {$('#{tf_id}').value = this.dyli},200)" #.bind(this), 200)"
                                     end
          
         
          # if the user presses the button return to validate his choice from the list of completion. 
    #       unless options[:submit_on_return]
            
#            tag_options[:onkeypress] = 'if (event.keyCode == Event.KEY_RETURN && '+options[:resize].to_s+') {'+
#              'this.value = this.dyli; }'
#           end
          
        end

        
        # Determines the actual completion options, taken into account the ones from
        # the user.
       def determine_completion_options(tf_id, hf_id, options, completion_options) #:nodoc:
  
          # dyli_completer does most of its work in the afterUpdateElement hook of the
          # standard autocompletion mechanism. Here we generate the JavaScript that goes there.
          completion_options[:after_update_element] = <<-JS.gsub(/\s+/, ' ')
      function(element, value) {
          var model_id = /#{options[:regexp_for_id]}/.exec(value.id)[1];
          $("#{hf_id}").value = model_id;
          element.dyli=element.value; 
          element.size = (element.dyli.length > 50 ? 50 : element.dyli.length);               
          event.keyCode = Event.KEY_RETURN;
          JS
  #element.value;
         if options[:resize]
           completion_options[:after_update_element] += <<-JS.gsub(/\s+/, ' ')
             element.size = (element.dyli.length > 50 ? 50 : element.dyli.length);               
             JS
         end
         
         completion_options[:after_update_element] += <<-JS.gsub(/\s+/, ' ')
            (#{options[:after_update_element]})(element, value, $("#{hf_id}"), model_id);
            }
            JS
        
          
          # :url has higher priority than :action and :controller.
          completion_options[:url] = options[:url] || url_for(
                                                              :controller => options[:controller],
                                                              :action     => options[:action],
                                                              :real_object => options[:id]
                                                              )
          
        end
        
      end
      
    end

  end
end






